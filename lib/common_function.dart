import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:games_services/games_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constant.dart';
import 'extension.dart';
import 'main.dart';

///App Tracking Transparency
Future<void> initATTPlugin() async {
  if (Platform.isIOS || Platform.isMacOS) {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }
}

///LifecycleEventHandler
class LifecycleEventHandler extends WidgetsBindingObserver {
  final AsyncCallback resumeCallBack;
  final AsyncCallback suspendingCallBack;

  LifecycleEventHandler({required this.resumeCallBack, required this.suspendingCallBack});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        resumeCallBack();
        break;
      case AppLifecycleState.paused:
        suspendingCallBack();
        break;
      default:
        break;
    }
  }
}

///Signing in to Game Services
gamesSignIn() async {
  try {
    await GamesServices.signIn();
    final isSignedIn = await GamesServices.isSignedIn;
    'Success to sign in to game services: $isSignedIn'.debugPrint();
  } catch (e) {
    'Fail to sign in to game services: $e'.debugPrint();
  }
}

///Submitting games score
gamesSubmitScore(int value) async {
  if (!(await GamesServices.isSignedIn)) await gamesSignIn();
  if (await GamesServices.isSignedIn) {
    try {
      await GamesServices.submitScore(
        score: Score(
          androidLeaderboardID: dotenv.get("ANDROID_LEADERBOARD_ID"),
          iOSLeaderboardID: dotenv.get("IOS_LEADERBOARD_ID"),
          value: value,
        ),
      );
      "Success submitting leaderboard: $value".debugPrint();
    } catch (e) {
      'Error submitting score: $e'.debugPrint();
    }
  }
}

///Showing games leaderboards
gamesShowLeaderboard() async {
  if (!(await GamesServices.isSignedIn)) await gamesSignIn();
  if (await GamesServices.isSignedIn) {
    try {
      await GamesServices.showLeaderboards(
        androidLeaderboardID: dotenv.get("ANDROID_LEADERBOARD_ID"),
        iOSLeaderboardID: dotenv.get("IOS_LEADERBOARD_ID")
      );
      "Success showing leaderboard".debugPrint();
    } catch (e) {
      'Error showing leaderboards: $e'.debugPrint();
    }
  }
}

///Get best score games leaderboards
Future<int> getBestScore() async {
  int gamesBestScore;
  if (!(await GamesServices.isSignedIn)) await gamesSignIn();
  if (await GamesServices.isSignedIn) {
    try {
      gamesBestScore = await GamesServices.getPlayerScore(
        androidLeaderboardID: dotenv.get("ANDROID_LEADERBOARD_ID"),
        iOSLeaderboardID: dotenv.get("IOS_LEADERBOARD_ID"),
      ) ?? 0;
      "gamesBestScore: $gamesBestScore".debugPrint();
    } catch(e) {
      "gamesBestScore: 0: Fail to get".debugPrint();
      gamesBestScore = 0;
    }
  } else {
    "gamesBestScore: 0: Can't sign in".debugPrint();
    gamesBestScore = 0;
  }
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final prefBestScore = prefs.getInt('bestScore') ?? 0;
  "prefBestScore: $prefBestScore".debugPrint();
  if (prefBestScore >= gamesBestScore) {
    if (!isTest && gamesBestScore != 0) gamesSubmitScore(prefBestScore);
    "bestScore: $prefBestScore".debugPrint();
    return prefBestScore;
  } else {
    if (!isTest) await "pointKey".setSharedPrefInt(prefs, gamesBestScore);
    "bestScore: $gamesBestScore".debugPrint();
    return gamesBestScore;
  }
}

class AudioPlayerManager {
  // シングルトンインスタンス
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();
  factory AudioPlayerManager() => _instance;
  final List<AudioPlayer> audioPlayers = [];
  // 4つの AudioPlayer インスタンスを初期化
  AudioPlayerManager._internal() {
    for (int i = 0; i < audioPlayerNumber; i++) {
      audioPlayers.add(AudioPlayer());
    }
  }
  /// 全ての AudioPlayer を dispose する
  Future<void> disposeAll() async {
    for (var player in audioPlayers) {
      try {
        await player.dispose();
      } catch (e) {
        'Error disposing AudioPlayer: $e'.debugPrint();
      }
    }
  }
}

// アプリが終了する際に disposeAll を呼び出す
void handleLifecycleChange(AppLifecycleState state) {
  if (state == AppLifecycleState.detached) {
    AudioPlayerManager().disposeAll();
  }
}
