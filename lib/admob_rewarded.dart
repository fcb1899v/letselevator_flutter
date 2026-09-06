import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'extension.dart';
import 'constant.dart';

// =============================
// useRewardedAd: consent gated rewarded ad
//
// Every request sits behind canRequestAds, the SDK's own verdict on whether this
// device may be asked for ads at all. It already weighs the region, the TCF
// consent string and Additional Consent, so the app must not read ConsentStatus
// and decide for itself. A false answer also covers "the SDK could not tell",
// and letting that through is exactly what serving without consent looks like
// in the EEA.
//
// Gating on its own would break the feature in silence. The unlock button
// already did nothing when no ad was loaded, and a user who has not answered the
// consent form would never get one, so the button would stay dead forever. The
// press path (prepare) therefore runs the consent flow itself and continues from
// its answer. Every branch ends in something the user can see: the consent form,
// the privacy options form, or a null return the caller turns into a message.
// =============================

/// Retries are capped. The button reloads on demand anyway, and requests that
/// never fill cannot become impressions
const int _maxRetryAttempt = 3;

/// The consent round trip can hang on a bad network, and the press path must
/// not leave the button spinning forever
const Duration _consentTimeout = Duration(seconds: 15);

/// What the caller gets: the ad to show right now, and the on demand path to
/// run when the button is pressed with nothing loaded.
/// A class rather than a record: pubspec declares sdk '>=2.18.0', so the
/// package language version predates records
class RewardedAdHandle {
  const RewardedAdHandle({required this.ad, required this.prepare});

  /// Non null only when an ad is loaded and ready to show
  final RewardedAd? ad;

  /// Runs the consent flow if it has not run yet, then requests an ad.
  /// Returns the ad when one became available, null when it did not
  final Future<RewardedAd?> Function() prepare;
}

RewardedAdHandle useRewardedAd() {
  final rewardedAd = useState<RewardedAd?>(null);
  // Refs, not state: the SDK and the consent forms call back after this screen
  // can be gone, and writing to a disposed ValueNotifier asserts in debug.
  // retryAttempt used to be state with the effect keyed on it, so every retry
  // re-ran the effect, completed the cancel token in its cleanup, and the ad
  // that arrived next was thrown away without ever being disposed
  final retryAttempt = useRef(0);
  final isRequesting = useRef(false);
  // One consent update per screen. The answer does not change on its own while
  // the user stands here, and the round trip is slow
  final consentUpdated = useRef(false);
  // Completed by the load callbacks so prepare can report the outcome
  final pendingLoad = useRef<Completer<RewardedAd?>?>(null);
  final cancelToken = useMemoized(() => Completer<void>(), []);

  String rewardedAdId =
    (kDebugMode && Platform.isIOS) ? iosRewardedTestId:
    (kDebugMode && Platform.isAndroid) ? androidRewardedTestId:
    (Platform.isIOS) ? dotenv.get("IOS_REWARDED_UNIT_ID"):
    dotenv.get("ANDROID_REWARDED_UNIT_ID");

  void finishPending(RewardedAd? ad) {
    final pending = pendingLoad.value;
    pendingLoad.value = null;
    if (pending != null && !pending.isCompleted) pending.complete(ad);
  }

  /// Join a load that is already running, creating the completer when the load
  /// started without one. The retry below calls loadAd directly, so a press
  /// during the backoff would otherwise be handed a null while a request is
  /// still in flight
  Future<RewardedAd?>? joinLoadInFlight() {
    if (!isRequesting.value) return null;
    return (pendingLoad.value ??= Completer<RewardedAd?>()).future;
  }

  void loadAd() {
    // The retry below re-enters here without going through the gate, so the
    // claim has to live in this function. Without it a press during the
    // backoff starts a second request and the first filled ad leaks
    if (cancelToken.isCompleted || isRequesting.value || rewardedAd.value != null) return;
    isRequesting.value = true;
    RewardedAd.load(
      adUnitId: rewardedAdId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          isRequesting.value = false;
          // The screen is gone: release the ad rather than leak a filled one
          if (cancelToken.isCompleted) {
            ad.dispose();
            finishPending(null);
            return;
          }
          'ad loaded'.debugPrint();
          rewardedAd.value = ad;
          retryAttempt.value = 0;
          finishPending(ad);
        },
        onAdFailedToLoad: (LoadAdError error) {
          'Ad failed to load: $error'.debugPrint();
          isRequesting.value = false;
          if (cancelToken.isCompleted) {
            finishPending(null);
            return;
          }
          // Answer the waiting press now instead of holding it behind the
          // backoff. The retry below keeps running for the next press
          finishPending(null);
          retryAttempt.value += 1;
          if (retryAttempt.value > _maxRetryAttempt) return;
          Future.delayed(Duration(seconds: 2 * retryAttempt.value), () {
            if (!cancelToken.isCompleted) loadAd();
          });
        },
      ),
    );
  }

  // The single gate for the ad request. Nothing is asked for unless the SDK
  // says this device may be asked
  Future<RewardedAd?> requestAdIfAllowed() async {
    final ready = rewardedAd.value;
    if (ready != null) return ready;
    // A load is already in flight: wait for it instead of starting a second one
    final joined = joinLoadInFlight();
    if (joined != null) return joined;
    if (!await ConsentInformation.instance.canRequestAds()) return null;
    // Callers race across that await. The state can have moved while this one
    // was suspended, so the checks run again
    if (cancelToken.isCompleted) return null;
    if (rewardedAd.value != null) return rewardedAd.value;
    final rejoined = joinLoadInFlight();
    if (rejoined != null) return rejoined;
    final completer = Completer<RewardedAd?>();
    pendingLoad.value = completer;
    loadAd();
    // loadAd returns without a callback when its own guard stops it, and then
    // nothing would ever complete the completer
    if (!isRequesting.value) finishPending(null);
    return completer.future;
  }

  // Runs the consent info update and lets the SDK present a form if it wants
  // one. This is the only path by which an undecided user reaches the form
  Future<void> updateConsent() {
    final completer = Completer<void>();
    void done() {
      if (!completer.isCompleted) completer.complete();
    }
    ConsentInformation.instance.requestConsentInfoUpdate(ConsentRequestParameters(
      // consentDebugSettings: ConsentDebugSettings(
      //   debugGeography: DebugGeography.debugGeographyEea,
      //   testIdentifiers: ['2793ca2a-5956-45a2-96c0-16fafddc1a15'],
      // ),
    ), () async {
      // The SDK decides whether a form is required, loads it and presents it.
      // Assembling that by hand from isConsentFormAvailable, loadConsentForm
      // and getConsentStatus re-implements rules that Google changes on their
      // side. This call does nothing when no form is required
      await ConsentForm.loadAndShowConsentFormIfRequired((formError) {
        if (formError != null) {
          "formError: ${formError.errorCode}: ${formError.message}".debugPrint();
        }
        done();
      });
    }, (FormError error) {
      // The update failed, but consent given in an earlier session still stands
      // and canRequestAds can still say yes, so the request is worth trying
      "error: ${error.errorCode}: ${error.message}".debugPrint();
      done();
    });
    return completer.future.timeout(_consentTimeout, onTimeout: done);
  }

  // The press path: what happens when the user asks for the reward and nothing
  // is loaded. It must never end in silence
  Future<RewardedAd?> prepare() async {
    final ready = rewardedAd.value;
    if (ready != null) return ready;
    if (!consentUpdated.value) {
      consentUpdated.value = true;
      await updateConsent();
      if (cancelToken.isCompleted) return null;
    }
    final requested = await requestAdIfAllowed();
    if (requested != null) return requested;
    if (cancelToken.isCompleted) return null;
    // Still not allowed. canRequestAds turns false only while the consent flow
    // has not completed, not because the user said no: declining still permits
    // non personalised ads. Landing here means the flow was cut short, so the
    // privacy options form is offered as a second chance to finish it. The
    // message below catches whatever that does not fix
    if (!await ConsentInformation.instance.canRequestAds()) {
      final status =
        await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      if (status != PrivacyOptionsRequirementStatus.required) return null;
      await ConsentForm.showPrivacyOptionsForm((formError) {
        if (formError != null) {
          "privacyFormError: ${formError.errorCode}: ${formError.message}".debugPrint();
        }
      });
      if (cancelToken.isCompleted) return null;
      return await requestAdIfAllowed();
    }
    // Consent is fine and the request came back empty
    return null;
  }

  useEffect(() {
    // Preload only when the SDK already says yes from an earlier session. A
    // user who has not consented gets nothing requested here; the press path
    // above runs the consent form for them instead
    requestAdIfAllowed();
    return () {
      if (!cancelToken.isCompleted) {
        cancelToken.complete();
      }
      rewardedAd.value?.dispose();
    };
  }, []);

  return RewardedAdHandle(ad: rewardedAd.value, prepare: prepare);
}
