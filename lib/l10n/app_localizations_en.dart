// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get letsElevator => 'LETS ELEVATOR';

  @override
  String get thisApp => 'This app is a realistic elevator simulator.';

  @override
  String get openDoor => 'Doors opening. ';

  @override
  String get closeDoor => 'Doors closing. ';

  @override
  String get basement => 'basement ';

  @override
  String floor(Object NUMBER) {
    return '$NUMBER floor, ';
  }

  @override
  String get ground => 'Ground floor, ';

  @override
  String get rooftop => 'The top floor, ';

  @override
  String get platform => 'Platform floor, ';

  @override
  String get dog => 'Dog floor, ';

  @override
  String get spa => 'Spa floor, ';

  @override
  String get vip => 'VIP floor, ';

  @override
  String get parking => 'Parking floor, ';

  @override
  String get paradise => 'Paradise floor, ';

  @override
  String get pushNumber => 'Please press the button for the desired floor';

  @override
  String get upFloor => 'Going up. ';

  @override
  String get downFloor => 'Going down. ';

  @override
  String get notStop => 'Sorry, this floor is restricted. ';

  @override
  String get emergency =>
      'Emergency stop to check the status of the elevator. ';

  @override
  String get return1st =>
      'Elevator status check completed. Return to the first floor. ';

  @override
  String get settings => 'Settings';

  @override
  String get changeNumber => 'Change floor number';

  @override
  String get changeBasementNumber => 'Change basement floor number';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'CANCEL';

  @override
  String get bypass => 'Bypass';

  @override
  String get stop => 'Stop';

  @override
  String get menu => 'MENU';

  @override
  String get normalMode => 'Normal\nmode';

  @override
  String get elevatorMode => 'Elevator\nmode';

  @override
  String get buttonsMode => '1000\nbuttons\nmode';

  @override
  String get reproButtons => 'Reproduce!\n1000\nbuttons';

  @override
  String get aboutShimax => 'About\nShimax';

  @override
  String get aboutButtons => 'About\n1000\nbuttons';

  @override
  String get aboutLetsElevator => 'About LETS ELEVATOR';

  @override
  String get termsAndPrivacyPolicy => 'Terms and privacy policy';

  @override
  String get terms => 'Terms';

  @override
  String get officialPage => 'Official Page';

  @override
  String get officialShop => 'Official Shop';

  @override
  String get start => 'START';

  @override
  String get challenge => '30s Challenge';

  @override
  String get best => 'BEST';

  @override
  String get challengeRanking => '30sec\nChallenge\nRanking';

  @override
  String get ranking => 'RANKING';

  @override
  String get yourScore => 'SCORE';

  @override
  String get back => 'BACK';

  @override
  String get newRecord => 'NEW RECORD!!';

  @override
  String get unlock => 'Unlock';

  @override
  String get unlockTitle => 'Watch to unlock\nthe new button!';

  @override
  String get unlockDesc =>
      '\nWatch until the end\nto use the new button.\nPlease Tap OK!';

  @override
  String get unlockAllTitle => 'Unlock Conditions: 1. or 2.';

  @override
  String get unlockAll1 => '1. Score 100+ in 30 sec challenge.';

  @override
  String get unlockAll2 => '2. Unlock all button shapes.';
}
