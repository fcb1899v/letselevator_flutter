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
  String get menu => 'メニュー';

  @override
  String get settings => '各種設定';

  @override
  String get start => 'スタート';

  @override
  String get back => '戻る';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'キャンセル';

  @override
  String get basement => '地下';

  @override
  String floor(Object NUMBER) {
    return '$NUMBER階です。　';
  }

  @override
  String get ground => '地上階です。　';

  @override
  String get openDoor => 'ドアがひらきます。　';

  @override
  String get closeDoor => 'ドアがしまります。　';

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
  String get bypass => '通過階';

  @override
  String get stop => '停止階';

  @override
  String get changeNumber => '行き先階数の変更';

  @override
  String get changeBasementNumber => '地下階数の変更';

  @override
  String get rooftop => '屋上です。　';

  @override
  String get vip => 'VIP階です。　';

  @override
  String get spa => '温泉です。　';

  @override
  String get parking => '駐車場です。　';

  @override
  String get platform => 'ホーム階です。　';

  @override
  String get paradise => '楽園です。　';

  @override
  String get dog => '犬です。　';

  @override
  String get unlock => '解放';

  @override
  String get unlockTitle => '動画を見て\n新ボタンを解放！';

  @override
  String get unlockDesc => '\nこの動画を最後まで見ると\n新しいボタンが使えます。\nOKをタップしてね！';

  @override
  String get rewardAdUnavailable =>
      '\n今は動画を再生できません。\n広告の同意設定を確認するか、\n少し待ってからもう一度お試しください。';

  @override
  String get unlockByScore => '30秒チャレンジで100個以上を達成';

  @override
  String get challenge => '30秒チャレンジ';

  @override
  String get best => 'ベスト ';

  @override
  String get yourScore => 'スコア';

  @override
  String get newRecord => 'ベストスコア更新！';

  @override
  String get termsAndPrivacyPolicy => '利用規約・プライバシーポリシー';

  @override
  String get terms => '利用規約';

  @override
  String get officialPage => '公式ページ';

  @override
  String get officialShop => '公式ショップ';

  @override
  String get ranking => 'ランキング';

  @override
  String get premiumTitle => 'プレミアムパック';

  @override
  String get premiumNoAds => '広告表示がなくなります';

  @override
  String get premiumUnlockAll =>
      '30秒チャレンジ100個以上の達成や\n広告動画を見ることなしに\n全てのデザインや機能が使えます';

  @override
  String get premiumOneTime => '1回だけの購入です';

  @override
  String premiumPrice(Object PRICE) {
    return '$PRICEで購入する';
  }

  @override
  String get premiumBuy => '購入する';

  @override
  String get premiumRestore => '購入を復元';

  @override
  String get premiumThanks => 'ありがとうございます！すべて解放されました。';

  @override
  String get premiumFailed => '購入を完了できませんでした。';

  @override
  String get premiumRestoreFailed => '復元できる購入が見つかりませんでした。';

  @override
  String get premiumUnavailable => 'いま購入手続きを開始できません。\n時間をおいてお試しください。';
}
