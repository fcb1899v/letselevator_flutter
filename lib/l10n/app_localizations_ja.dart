// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get letsElevator => 'レッツ・エレベーター';

  @override
  String get thisApp => 'このアプリはリアルなエレベーターシミュレーターです。';

  @override
  String get openDoor => 'ドアがひらきます。　';

  @override
  String get closeDoor => 'ドアがしまります。　';

  @override
  String get basement => '地下';

  @override
  String floor(Object NUMBER) {
    return '$NUMBER階です。　';
  }

  @override
  String get ground => '地上階です。　';

  @override
  String get rooftop => '屋上です。　';

  @override
  String get platform => 'ホーム階です。　';

  @override
  String get dog => '犬です。　';

  @override
  String get spa => '温泉です。　';

  @override
  String get vip => 'VIP階です。　';

  @override
  String get parking => '駐車場です。　';

  @override
  String get paradise => '楽園です。　';

  @override
  String get pushNumber => '行き先階ボタンを押してください。　';

  @override
  String get upFloor => 'うえにまいります。　';

  @override
  String get downFloor => 'したにまいります。　';

  @override
  String get notStop => 'ただいま押されたかいにはとまりません。　';

  @override
  String get emergency => 'エレベーターの状態を確認するため、緊急停止します。 ';

  @override
  String get return1st => '確認が完了しました。一階に戻ります。 ';

  @override
  String get settings => '各種設定';

  @override
  String get changeNumber => '行き先階数の変更';

  @override
  String get changeBasementNumber => '地下階数の変更';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'キャンセル';

  @override
  String get bypass => '通過階';

  @override
  String get stop => '停止階';

  @override
  String get menu => 'メニュー';

  @override
  String get normalMode => 'ノーマル\nモード';

  @override
  String get elevatorMode => 'エレベーター\nモード';

  @override
  String get buttonsMode => '1000の\nボタン\nモード';

  @override
  String get reproButtons => '再現!\n1000の\nボタン';

  @override
  String get aboutShimax => '島田電機\n製作所\nとは';

  @override
  String get aboutButtons => '1000の\nボタン\nとは';

  @override
  String get aboutLetsElevator => 'レッツ・エレベーターとは';

  @override
  String get termsAndPrivacyPolicy => '利用規約・プライバシーポリシー';

  @override
  String get terms => '利用規約';

  @override
  String get officialPage => '公式ページ';

  @override
  String get officialShop => '公式ショップ';

  @override
  String get start => 'スタート';

  @override
  String get challenge => '30秒チャレンジ';

  @override
  String get best => 'ベスト ';

  @override
  String get challengeRanking => '30秒\nチャレンジ\nランキング';

  @override
  String get ranking => 'ランキング';

  @override
  String get yourScore => 'スコア';

  @override
  String get back => '戻る';

  @override
  String get newRecord => 'ベストスコア更新！';

  @override
  String get unlock => '解放';

  @override
  String get unlockTitle => '動画を見て\n新ボタンを解放！';

  @override
  String get unlockDesc => '\nこの動画を最後まで見ると\n新しいボタンが使えます。\nOKをタップしてね！';

  @override
  String get unlockAllTitle => '解放条件：1.または2.';

  @override
  String get unlockAll1 => '1. 30秒チャレンジで100個以上達成！';

  @override
  String get unlockAll2 => '2. 全てのボタン形状を解放!!';
}
