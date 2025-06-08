import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'extension.dart';

RewardedAd? rewardedAd() {
  final rewardedAd = useState<RewardedAd?>(null);
  final retryAttempt = useState(0);
  final cancelToken = useMemoized(() => Completer<void>(), []);

  String rewardedAdId =
    (kDebugMode && Platform.isIOS) ? dotenv.get("IOS_REWARDED_TEST_ID"):
    (kDebugMode && Platform.isAndroid) ? dotenv.get("ANDROID_REWARDED_TEST_ID"):
    (Platform.isIOS) ? dotenv.get("IOS_REWARDED_UNIT_ID"):
    dotenv.get("ANDROID_REWARDED_UNIT_ID");

  void loadAd() {
    RewardedAd.load(
      adUnitId: rewardedAdId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) async {
          if (!cancelToken.isCompleted) {
            'ad loaded'.debugPrint();
            rewardedAd.value = ad;
            retryAttempt.value = 0;
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          'Ad failed to load: $error'.debugPrint();
          if (!cancelToken.isCompleted) {
            Future.delayed(Duration(seconds: 2 * retryAttempt.value), () {
              if (!cancelToken.isCompleted) {
                retryAttempt.value += 1;
                loadAd();
              }
            });
          }
        },
      ),
    );
  }

  useEffect(() {
    if (!cancelToken.isCompleted) {
      loadAd();
    }

    return () {
      if (!cancelToken.isCompleted) {
        cancelToken.complete();
      }
      rewardedAd.value?.dispose();
    };
  }, [retryAttempt.value]);

  return rewardedAd.value;
}
