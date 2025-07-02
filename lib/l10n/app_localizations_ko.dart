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
  String get thisApp => '이 앱은 실감나는 엘리베이터 시뮬레이터입니다.';

  @override
  String get openDoor => '문이 열립니다. ';

  @override
  String get closeDoor => '문이 닫힙니다. ';

  @override
  String get basement => '지하';

  @override
  String floor(Object NUMBER) {
    return '$NUMBER층 입니다. ';
  }

  @override
  String get ground => '지상 층 입니다. ';

  @override
  String get rooftop => '옥상 입니다. ';

  @override
  String get platform => '홈층 입니다. ';

  @override
  String get dog => '개 입니다. ';

  @override
  String get spa => '온천 입니다. ';

  @override
  String get vip => 'VIP 층 입니다. ';

  @override
  String get parking => '주차장 입니다. ';

  @override
  String get paradise => '낙원 입니다. ';

  @override
  String get pushNumber => '가고싶은 층 버튼을 누르십시오. ';

  @override
  String get upFloor => '올라갑니다. ';

  @override
  String get downFloor => '내려갑니다. ';

  @override
  String get notStop => '해당 층에는 정차하지 않습니다. ';

  @override
  String get emergency => '엘리베이터의 상태를 확인하기 위해 긴급 정지합니다. ';

  @override
  String get return1st => '확인이 완료되었습니다. 1층으로 돌아갑니다.  ';

  @override
  String get settings => '각종 설정';

  @override
  String get changeNumber => '목적지 층수 변경';

  @override
  String get changeBasementNumber => '지하 층수 변경';

  @override
  String get ok => '확인';

  @override
  String get cancel => '취소';

  @override
  String get bypass => '통과 층';

  @override
  String get stop => '정지 층';

  @override
  String get menu => '메뉴';

  @override
  String get normalMode => '정상\n모드';

  @override
  String get elevatorMode => '엘리베이터\n모드';

  @override
  String get buttonsMode => '1000개의\n버튼\n모드';

  @override
  String get reproButtons => '재현!\n1000개의\n버튼';

  @override
  String get aboutShimax => '島田電機\n製作所\n란';

  @override
  String get aboutButtons => '1000개의\n버튼\n란';

  @override
  String get aboutLetsElevator => '렛츠 엘리베이터 란';

  @override
  String get termsAndPrivacyPolicy => '이용약관 및 개인정보처리방침';

  @override
  String get terms => '이용약관';

  @override
  String get officialPage => '공식 페이지';

  @override
  String get officialShop => '공식 샵';

  @override
  String get start => '시작';

  @override
  String get challenge => '30초 도전';

  @override
  String get best => '최고 ';

  @override
  String get challengeRanking => '30초\n도전\n랭킹';

  @override
  String get ranking => '랭킹';

  @override
  String get yourScore => '점수';

  @override
  String get back => '뒤로';

  @override
  String get newRecord => '최고의 점수 경신하다!!';

  @override
  String get unlock => '해제';

  @override
  String get unlockTitle => '동영상을 보고\n새 버튼 잠금 해제!';

  @override
  String get unlockDesc => '\n동영상을 끝까지 보면\n새 버튼을 사용할 수 있어요.\n확인을 눌러주세요!';

  @override
  String get unlockAllTitle => '해방 조건: 1. 또는 2.';

  @override
  String get unlockAll1 => '1. 30초 챌린지에서 100개 이상 달성!';

  @override
  String get unlockAll2 => '2. 모든 버튼 모양 해방!!';
}
