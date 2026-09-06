import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'extension.dart';
import 'main.dart';
import 'constant.dart';

// =============================
// AdBannerWidget: bottom anchored banner
//
// The request carries no npa flag. Forcing nonPersonalizedAds on every request
// applied to every user in every region, including ones that never required it,
// and it shrinks the pool of bidders. Whether a request has to be
// non personalized is the SDK's call, made from the consent state below.
// =============================
class AdBannerWidget extends HookWidget {
  const AdBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final adLoaded = useState(false);
    final adFailedLoading = useState(false);
    final bannerAd = useState<BannerAd?>(null);
    // The old AdSize.largeBanner asked for a fixed 320x100 while the box was
    // sized by a hand written formula that returned under 100 on most screens,
    // so the creative never fitted. Inline adaptive is the one size that takes a
    // ceiling from the app: inlineBannerMaxHeight caps it and Google picks the
    // height under that, full slot width. The slot stays at the ceiling either
    // way, so the layout never moves when a shorter creative comes back
    // Ref, not state: the consent callbacks resolve after this widget can be
    // gone, and writing to a disposed ValueNotifier asserts in debug
    final isAdRequested = useRef(false);
    // final testIdentifiers = ['2793ca2a-5956-45a2-96c0-16fafddc1a15'];

    // バナー広告ID
    String bannerUnitId() =>
        (!kDebugMode && Platform.isIOS) ? dotenv.get("IOS_BANNER_UNIT_ID"):
        (!kDebugMode && Platform.isAndroid) ? dotenv.get("ANDROID_BANNER_UNIT_ID"):
        (Platform.isIOS) ? iosBannerTestId:
        // Debug on Android used to fall through to the production unit, so
        // development traffic landed on the live ad unit
        androidBannerTestId;

    // slotWidth comes from LayoutBuilder, so it is the width this slot really
    // gets. MediaQuery would be the whole screen, which is not what the banner
    // occupies once the menu button takes its share
    Future<void> loadAdBanner(int slotWidth) async {
      // Inline adaptive carries the ceiling and a width and reports height 0
      // here: Google picks the height per request, at or under the ceiling, and
      // only getPlatformAdSize knows what was served. Large anchored was the
      // alternative and it does fill its request, measured at 349x109 served on
      // an iPhone, but it pins the height to the slot width over 3.2 with no way
      // to cap it, and this row cannot give up that much of the screen
      final size = AdSize.getInlineAdaptiveBannerAdSize(slotWidth, inlineBannerMaxHeight);
      final adBanner = BannerAd(
        adUnitId: bannerUnitId(),
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) async {
            'Ad: $ad loaded.'.debugPrint();
            if (kDebugMode) {
              // The slot is the ceiling regardless, so this only reports how
              // much of it the creative filled. Google's demo unit served 109
              // of a 109 request on an iPhone and 52 of a 105 request on a
              // Pixel, so a short creative here is the demo inventory
              final served = await (ad as BannerAd).getPlatformAdSize();
              'AdSize served: ${served?.width} x ${served?.height} (slot: $slotWidth, cap: $inlineBannerMaxHeight)'.debugPrint();
            }
            // That debug await can let this land after unmount, where the write
            // below would assert on a disposed notifier
            if (!context.mounted) return;
            adLoaded.value = true;
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            'Ad: $ad failed to load: $error'.debugPrint();
            adFailedLoading.value = true;
            // Dead as written: adFailedLoading was just set true, so the guard
            // below can never pass and this retry has never fired. Left as is;
            // enabling it changes how often the app requests ads
            Future.delayed(const Duration(seconds: 30), () {
              if (!adLoaded.value && !adFailedLoading.value) loadAdBanner(slotWidth);
            });
          },
        ),
      );
      await adBanner.load();
      bannerAd.value = adBanner;
    }

    // The single gate for the ad request. canRequestAds is the SDK's own
    // verdict: it already weighs the region, the TCF consent string and
    // Additional Consent, so the app must not read ConsentStatus and decide for
    // itself. A false answer also covers "the SDK could not tell", and letting
    // that through is exactly what serving without consent looks like in the EEA
    Future<void> requestAdIfAllowed(int slotWidth) async {
      if (isAdRequested.value) return;
      if (!await ConsentInformation.instance.canRequestAds()) return;
      // Both callers below race across that await. Claiming the request happens
      // with no await in between, so whoever resumes second always sees the
      // flag and no second BannerAd is created for the same slot
      if (isAdRequested.value) return;
      isAdRequested.value = true;
      await loadAdBanner(slotWidth);
    }

    // The slot width is only known inside LayoutBuilder, which runs during build.
    // The consent flow must start once, not on every layout pass, so the width
    // lands in a ref and the effect waits for the first non zero value
    final slotWidthRef = useRef<int>(0);
    final hasWidth = useState(false);

    useEffect(() {
      if (!hasWidth.value) return null;
      final slotWidth = slotWidthRef.value;
      ConsentInformation.instance.requestConsentInfoUpdate(ConsentRequestParameters(
        // consentDebugSettings: ConsentDebugSettings(
        //   debugGeography: DebugGeography.debugGeographyEea,
        //   testIdentifiers: testIdentifiers,
        // ),
      ), () async {
        // The SDK decides whether a form is required, loads it and presents it.
        // Assembling that by hand from isConsentFormAvailable, loadConsentForm
        // and getConsentStatus re-implements rules that Google changes on their
        // side. This call does nothing when no form is required
        await ConsentForm.loadAndShowConsentFormIfRequired((formError) async {
          if (formError != null) {
            "formError: ${formError.errorCode}: ${formError.message}".debugPrint();
          }
          await requestAdIfAllowed(slotWidth);
        });
      }, (FormError error) async {
        // The update failed, but consent given in an earlier session still
        // stands and canRequestAds can still say yes. Stopping here would throw
        // away impressions the SDK would have allowed
        "error: ${error.errorCode}: ${error.message}".debugPrint();
        await requestAdIfAllowed(slotWidth);
      });
      "bannerAd: ${bannerAd.value}".debugPrint();
      return () => bannerAd.value?.dispose();      // unmount時に広告を破棄する
    }, [hasWidth.value]);

    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      if (w.isFinite && w > 0 && slotWidthRef.value == 0) {
        slotWidthRef.value = w.truncate();
        // Set after this frame: hasWidth drives an effect, and flipping it
        // during build would rebuild while the tree is still being built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) hasWidth.value = true;
        });
      }
      // Which half of the gate below is still false when the slot stays empty
      if (kDebugMode) {
        'AdWidget gate: adLoaded=${adLoaded.value} bannerAd=${bannerAd.value != null}'.debugPrint();
      }
      // The ceiling, not the served height. Sizing to what was served would move
      // everything above this row every time Google returns a shorter creative,
      // and the row is at the bottom of the screen where that reads as a jump
      return SizedBox(
        width: double.infinity,
        height: inlineBannerMaxHeight.toDouble(),
        // bannerAd is assigned after load returns, so onAdLoaded can fire first
        child: (adLoaded.value && bannerAd.value != null && !isTest)
            ? AdWidget(ad: bannerAd.value!)
            : null,
      );
    });
  }
}