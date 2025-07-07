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
  String get unlockAllTitle => '해제 조건: 1. 또는 2.';

  @override
  String get unlockAll1 => '1. 30초 챌린지에서 100점 이상 달성!';

  @override
  String get unlockAll2 => '2. 모든 버튼 모양 해제!!';

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
}
