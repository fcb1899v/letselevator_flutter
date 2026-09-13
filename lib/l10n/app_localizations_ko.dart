// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get letsElevator => '렛츠 엘리베이터';

  @override
  String get menu => '메뉴';

  @override
  String get settings => '설정';

  @override
  String get start => '시작';

  @override
  String get back => '뒤로';

  @override
  String get ok => '확인';

  @override
  String get cancel => '취소';

  @override
  String get basement => '지하';

  @override
  String floor(Object NUMBER) {
    return '$NUMBER층에 도착하셨습니다. ';
  }

  @override
  String get ground => '지상층에 도착하셨습니다. ';

  @override
  String get openDoor => '문이 열립니다.';

  @override
  String get closeDoor => '문이 닫힙니다.';

  @override
  String get pushNumber => '층을 선택하세요.';

  @override
  String get upFloor => '올라갑니다.';

  @override
  String get downFloor => '내려갑니다.';

  @override
  String get notStop => '정차하지 않습니다.';

  @override
  String get emergency => '엘리베이터 점검을 위해 비상 정지합니다. ';

  @override
  String get return1st => '점검이 완료되었습니다. 1층으로 돌아갑니다. ';

  @override
  String get bypass => '통과 층';

  @override
  String get stop => '정차 층';

  @override
  String get changeNumber => '목적지 층수 변경';

  @override
  String get changeBasementNumber => '지하 층수 변경';

  @override
  String get rooftop => '옥상 층에 도착하셨습니다. ';

  @override
  String get vip => 'VIP 층에 도착하셨습니다. ';

  @override
  String get spa => '온천 층에 도착하셨습니다. ';

  @override
  String get parking => '주차장 층에 도착하셨습니다. ';

  @override
  String get platform => '홈 층에 도착하셨습니다. ';

  @override
  String get paradise => '낙원 층에 도착하셨습니다. ';

  @override
  String get dog => '개 층에 도착하셨습니다. ';

  @override
  String get unlock => '해제';

  @override
  String get unlockTitle => '영상을 보고\n새 버튼 잠금 해제!';

  @override
  String get unlockDesc => '\n영상을 끝까지 보면\n새 버튼을 사용할 수 있어요.\n확인을 눌러주세요!';

  @override
  String get rewardAdUnavailable =>
      '\n지금은 영상을 재생할 수 없어요.\n광고 동의 설정을 확인하거나\n잠시 후 다시 시도해 주세요.';

  @override
  String get unlockByScore => '30초 챌린지에서 100점 이상 달성';

  @override
  String get challenge => '30초 도전';

  @override
  String get best => '최고 ';

  @override
  String get yourScore => '점수';

  @override
  String get newRecord => '신기록 달성!!';

  @override
  String get termsAndPrivacyPolicy => '이용약관 및 개인정보처리방침';

  @override
  String get terms => '이용약관';

  @override
  String get officialPage => '공식 페이지';

  @override
  String get officialShop => '공식 샵';

  @override
  String get ranking => '랭킹';

  @override
  String get premiumTitle => '프리미엄 팩';

  @override
  String get premiumNoAds => '광고가 표시되지 않습니다';

  @override
  String get premiumUnlockAll =>
      '30초 챌린지 100개 이상 달성도\n광고 동영상 시청도 없이\n모든 디자인과 기능을 사용할 수 있습니다';

  @override
  String get premiumOneTime => '한 번만 결제합니다';

  @override
  String premiumPrice(Object PRICE) {
    return '$PRICE에 구매';
  }

  @override
  String get premiumBuy => '구매';

  @override
  String get premiumRestore => '구매 복원';

  @override
  String get premiumThanks => '감사합니다! 모두 잠금 해제되었습니다.';

  @override
  String get premiumFailed => '구매를 완료하지 못했습니다.';

  @override
  String get premiumRestoreFailed => '복원할 구매 내역을 찾을 수 없습니다.';

  @override
  String get premiumUnavailable => '지금은 구매를 진행할 수 없습니다.\n잠시 후 다시 시도해 주세요.';
}
