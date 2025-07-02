import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh')
  ];

  /// No description provided for @letsElevator.
  ///
  /// In en, this message translates to:
  /// **'LETS ELEVATOR'**
  String get letsElevator;

  ///
  ///
  /// In en, this message translates to:
  /// **'This app is a realistic elevator simulator.'**
  String get thisApp;

  /// Doors opening.
  ///
  /// In en, this message translates to:
  /// **'Doors opening. '**
  String get openDoor;

  /// Doors closing.
  ///
  /// In en, this message translates to:
  /// **'Doors closing. '**
  String get closeDoor;

  /// basement
  ///
  /// In en, this message translates to:
  /// **'basement '**
  String get basement;

  /// {NUMBER} floor
  ///
  /// In en, this message translates to:
  /// **'{NUMBER} floor, '**
  String floor(Object NUMBER);

  /// Ground floor
  ///
  /// In en, this message translates to:
  /// **'Ground floor, '**
  String get ground;

  /// Top floor
  ///
  /// In en, this message translates to:
  /// **'The top floor, '**
  String get rooftop;

  /// Platform floor
  ///
  /// In en, this message translates to:
  /// **'Platform floor, '**
  String get platform;

  /// Dog floor
  ///
  /// In en, this message translates to:
  /// **'Dog floor, '**
  String get dog;

  /// Spa floor
  ///
  /// In en, this message translates to:
  /// **'Spa floor, '**
  String get spa;

  /// VIP floor
  ///
  /// In en, this message translates to:
  /// **'VIP floor, '**
  String get vip;

  /// Parking floor
  ///
  /// In en, this message translates to:
  /// **'Parking floor, '**
  String get parking;

  /// Paradise floor
  ///
  /// In en, this message translates to:
  /// **'Paradise floor, '**
  String get paradise;

  /// Press button
  ///
  /// In en, this message translates to:
  /// **'Please press the button for the desired floor'**
  String get pushNumber;

  /// Going up.
  ///
  /// In en, this message translates to:
  /// **'Going up. '**
  String get upFloor;

  /// Going down.
  ///
  /// In en, this message translates to:
  /// **'Going down. '**
  String get downFloor;

  /// No description provided for @notStop.
  ///
  /// In en, this message translates to:
  /// **'Sorry, this floor is restricted. '**
  String get notStop;

  /// Emergency stop.
  ///
  /// In en, this message translates to:
  /// **'Emergency stop to check the status of the elevator. '**
  String get emergency;

  /// Return 1st floor.
  ///
  /// In en, this message translates to:
  /// **'Elevator status check completed. Return to the first floor. '**
  String get return1st;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @changeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change floor number'**
  String get changeNumber;

  /// No description provided for @changeBasementNumber.
  ///
  /// In en, this message translates to:
  /// **'Change basement floor number'**
  String get changeBasementNumber;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancel;

  /// No description provided for @bypass.
  ///
  /// In en, this message translates to:
  /// **'Bypass'**
  String get bypass;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// Menu
  ///
  /// In en, this message translates to:
  /// **'MENU'**
  String get menu;

  /// Normal mode
  ///
  /// In en, this message translates to:
  /// **'Normal\nmode'**
  String get normalMode;

  /// Elevator mode
  ///
  /// In en, this message translates to:
  /// **'Elevator\nmode'**
  String get elevatorMode;

  /// 1,000 elevator buttons mode
  ///
  /// In en, this message translates to:
  /// **'1000\nbuttons\nmode'**
  String get buttonsMode;

  /// No description provided for @reproButtons.
  ///
  /// In en, this message translates to:
  /// **'Reproduce!\n1000\nbuttons'**
  String get reproButtons;

  /// About Shimax
  ///
  /// In en, this message translates to:
  /// **'About\nShimax'**
  String get aboutShimax;

  /// about 1000 buttons
  ///
  /// In en, this message translates to:
  /// **'About\n1000\nbuttons'**
  String get aboutButtons;

  /// About LETS ELEVATOR
  ///
  /// In en, this message translates to:
  /// **'About LETS ELEVATOR'**
  String get aboutLetsElevator;

  /// Terms and privacy policy
  ///
  /// In en, this message translates to:
  /// **'Terms and privacy policy'**
  String get termsAndPrivacyPolicy;

  /// Terms
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get terms;

  /// Official Page
  ///
  /// In en, this message translates to:
  /// **'Official Page'**
  String get officialPage;

  /// No description provided for @officialShop.
  ///
  /// In en, this message translates to:
  /// **'Official Shop'**
  String get officialShop;

  /// start
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get start;

  /// 30sec challenge
  ///
  /// In en, this message translates to:
  /// **'30s Challenge'**
  String get challenge;

  /// best score
  ///
  /// In en, this message translates to:
  /// **'BEST'**
  String get best;

  /// 30sec Challenge Ranking
  ///
  /// In en, this message translates to:
  /// **'30sec\nChallenge\nRanking'**
  String get challengeRanking;

  /// ranking
  ///
  /// In en, this message translates to:
  /// **'RANKING'**
  String get ranking;

  /// your score
  ///
  /// In en, this message translates to:
  /// **'SCORE'**
  String get yourScore;

  /// back
  ///
  /// In en, this message translates to:
  /// **'BACK'**
  String get back;

  /// new record
  ///
  /// In en, this message translates to:
  /// **'NEW RECORD!!'**
  String get newRecord;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @unlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Watch to unlock\nthe new button!'**
  String get unlockTitle;

  /// No description provided for @unlockDesc.
  ///
  /// In en, this message translates to:
  /// **'\nWatch until the end\nto use the new button.\nPlease Tap OK!'**
  String get unlockDesc;

  /// No description provided for @unlockAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock Conditions: 1. or 2.'**
  String get unlockAllTitle;

  /// No description provided for @unlockAll1.
  ///
  /// In en, this message translates to:
  /// **'1. Score 100+ in 30 sec challenge.'**
  String get unlockAll1;

  /// No description provided for @unlockAll2.
  ///
  /// In en, this message translates to:
  /// **'2. Unlock all button shapes.'**
  String get unlockAll2;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
