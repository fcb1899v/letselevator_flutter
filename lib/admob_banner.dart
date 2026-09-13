import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'extension.dart';
import 'main.dart';
import 'constant.dart';
import 'plan_provider.dart';

// ===== AdBannerWidget: bottom anchored banner =====
// No npa flag on the request: whether it must be non personalized is the SDK's call
class AdBannerWidget extends HookConsumerWidget {
  const AdBannerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read before the hooks below, and acted on only after all of them have
    // run: a conditional early return above a hook changes the hook order
    final isPremium = ref.watch(planProvider).isPremium;
    final adLoaded = useState(false);
    final adFailedLoading = useState(false);
    final bannerAd = useState<BannerAd?>(null);
    // Inline adaptive: inlineBannerMaxHeight caps the height, Google picks one under it,
    // and the slot stays at the ceiling. Ref, not state: callbacks can land after dispose
    final isAdRequested = useRef(false);
    // final testIdentifiers = ['2793ca2a-5956-45a2-96c0-16fafddc1a15'];

    // Resolved in constant.dart so this placement and the rewarded one cannot drift
    // apart; debug builds get Google's demo unit there
    String bannerUnitId() => bannerAdUnitID;

    // slotWidth comes from LayoutBuilder: the width this slot really gets, not the
    // whole screen, once the menu button takes its share
    Future<void> loadAdBanner(int slotWidth) async {
      // Inline adaptive reports height 0 here; only getPlatformAdSize knows what was
      // served. Large anchored pins height to width / 3.2 with no cap: too tall for this row
      final size = AdSize.getInlineAdaptiveBannerAdSize(slotWidth, inlineBannerMaxHeight);
      final adBanner = BannerAd(
        adUnitId: bannerUnitId(),
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) async {
            'Ad: $ad loaded.'.debugPrint();
            if (kDebugMode) {
              // The slot is the ceiling regardless; this only reports how much of it the
              // creative filled. The demo unit often serves a short creative
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
            // Dead as written: adFailedLoading was just set true, so the guard below never
            // passes. Left as is; enabling it changes how often the app requests ads
            Future.delayed(const Duration(seconds: 30), () {
              if (!adLoaded.value && !adFailedLoading.value) loadAdBanner(slotWidth);
            });
          },
        ),
      );
      await adBanner.load();
      bannerAd.value = adBanner;
    }

    // The single gate for the ad request. canRequestAds is the SDK's own verdict
    // (region, TCF string, Additional Consent); the app must not read ConsentStatus itself
    Future<void> requestAdIfAllowed(int slotWidth) async {
      // A premium user is never sent an ad request at all. Hiding the widget
      // alone would still cost them an impression request and a consent form
      if (ref.read(planProvider).isPremium) return;
      if (isAdRequested.value) return;
      if (!await ConsentInformation.instance.canRequestAds()) return;
      // Both callers below race across that await. Claiming with no await in between
      // means whoever resumes second sees the flag and no second BannerAd is created
      if (isAdRequested.value) return;
      isAdRequested.value = true;
      await loadAdBanner(slotWidth);
    }

    // The slot width is only known inside LayoutBuilder. The consent flow must start
    // once, not per layout pass, so the width lands in a ref and the effect waits for it
    final slotWidthRef = useRef<int>(0);
    final hasWidth = useState(false);

    useEffect(() {
      if (!hasWidth.value) return null;
      if (isPremium) return null;
      final slotWidth = slotWidthRef.value;
      ConsentInformation.instance.requestConsentInfoUpdate(ConsentRequestParameters(
        // consentDebugSettings: ConsentDebugSettings(
        //   debugGeography: DebugGeography.debugGeographyEea,
        //   testIdentifiers: testIdentifiers,
        // ),
      ), () async {
        // The SDK decides whether a form is required, loads and presents it; doing that
        // by hand re-implements rules Google changes. No-op when no form is required
        await ConsentForm.loadAndShowConsentFormIfRequired((formError) async {
          if (formError != null) {
            "formError: ${formError.errorCode}: ${formError.message}".debugPrint();
          }
          await requestAdIfAllowed(slotWidth);
        });
      }, (FormError error) async {
        // The update failed, but consent from an earlier session still stands and
        // canRequestAds can still say yes, so do not stop here
        "error: ${error.errorCode}: ${error.message}".debugPrint();
        await requestAdIfAllowed(slotWidth);
      });
      "bannerAd: ${bannerAd.value}".debugPrint();
      return () => bannerAd.value?.dispose();      // unmount時に広告を破棄する
    }, [hasWidth.value]);

    // Premium removes the banner, so the row this sits in collapses to the
    // height of the menu button beside it and no empty strip is left behind
    if (isPremium) return const SizedBox.shrink();

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
      // The ceiling, not the served height: sizing to what was served would shift the
      // layout above this bottom row whenever a shorter creative comes back
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