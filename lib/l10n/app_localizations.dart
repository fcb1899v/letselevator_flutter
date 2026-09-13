import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
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
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @letsElevator.
  ///
  /// In en, this message translates to:
  /// **'LETS ELEVATOR'**
  String get letsElevator;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'MENU'**
  String get menu;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get start;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'BACK'**
  String get back;

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

  /// No description provided for @basement.
  ///
  /// In en, this message translates to:
  /// **'basement '**
  String get basement;

  /// No description provided for @floor.
  ///
  /// In en, this message translates to:
  /// **'{NUMBER} floor, '**
  String floor(Object NUMBER);

  /// No description provided for @ground.
  ///
  /// In en, this message translates to:
  /// **'Ground floor, '**
  String get ground;

  /// No description provided for @openDoor.
  ///
  /// In en, this message translates to:
  /// **'Doors opening. '**
  String get openDoor;

  /// No description provided for @closeDoor.
  ///
  /// In en, this message translates to:
  /// **'Doors closing. '**
  String get closeDoor;

  /// No description provided for @pushNumber.
  ///
  /// In en, this message translates to:
  /// **'Please press the button for the desired floor'**
  String get pushNumber;

  /// No description provided for @upFloor.
  ///
  /// In en, this message translates to:
  /// **'Going up. '**
  String get upFloor;

  /// No description provided for @downFloor.
  ///
  /// In en, this message translates to:
  /// **'Going down. '**
  String get downFloor;

  /// No description provided for @notStop.
  ///
  /// In en, this message translates to:
  /// **'Sorry, this floor is restricted. '**
  String get notStop;

  /// No description provided for @emergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency stop for inspection. '**
  String get emergency;

  /// No description provided for @return1st.
  ///
  /// In en, this message translates to:
  /// **'Elevator status check complete. Returning to the first floor. '**
  String get return1st;

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

  /// No description provided for @rooftop.
  ///
  /// In en, this message translates to:
  /// **'The top floor, '**
  String get rooftop;

  /// No description provided for @vip.
  ///
  /// In en, this message translates to:
  /// **'VIP floor, '**
  String get vip;

  /// No description provided for @spa.
  ///
  /// In en, this message translates to:
  /// **'Spa floor, '**
  String get spa;

  /// No description provided for @parking.
  ///
  /// In en, this message translates to:
  /// **'Parking floor, '**
  String get parking;

  /// No description provided for @platform.
  ///
  /// In en, this message translates to:
  /// **'Platform floor, '**
  String get platform;

  /// No description provided for @paradise.
  ///
  /// In en, this message translates to:
  /// **'Paradise floor, '**
  String get paradise;

  /// No description provided for @dog.
  ///
  /// In en, this message translates to:
  /// **'Dog floor, '**
  String get dog;

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

  /// No description provided for @rewardAdUnavailable.
  ///
  /// In en, this message translates to:
  /// **'\nThe video cannot be played now.\nPlease check your ad consent setting,\nor try again in a moment.'**
  String get rewardAdUnavailable;

  /// No description provided for @unlockByScore.
  ///
  /// In en, this message translates to:
  /// **'Score 100+ in the 30-second challenge'**
  String get unlockByScore;

  /// No description provided for @challenge.
  ///
  /// In en, this message translates to:
  /// **'30s Challenge'**
  String get challenge;

  /// No description provided for @best.
  ///
  /// In en, this message translates to:
  /// **'BEST'**
  String get best;

  /// No description provided for @yourScore.
  ///
  /// In en, this message translates to:
  /// **'SCORE'**
  String get yourScore;

  /// No description provided for @newRecord.
  ///
  /// In en, this message translates to:
  /// **'NEW RECORD!!'**
  String get newRecord;

  /// No description provided for @termsAndPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Terms and privacy policy'**
  String get termsAndPrivacyPolicy;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get terms;

  /// No description provided for @officialPage.
  ///
  /// In en, this message translates to:
  /// **'Official Page'**
  String get officialPage;

  /// No description provided for @officialShop.
  ///
  /// In en, this message translates to:
  /// **'Official Shop'**
  String get officialShop;

  /// No description provided for @ranking.
  ///
  /// In en, this message translates to:
  /// **'RANKING'**
  String get ranking;

  /// No description provided for @premiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium Pack'**
  String get premiumTitle;

  /// No description provided for @premiumNoAds.
  ///
  /// In en, this message translates to:
  /// **'No more ads'**
  String get premiumNoAds;

  /// No description provided for @premiumUnlockAll.
  ///
  /// In en, this message translates to:
  /// **'Without scoring 100+ in the challenge\nor watching ad videos,\nevery design and feature is yours'**
  String get premiumUnlockAll;

  /// No description provided for @premiumOneTime.
  ///
  /// In en, this message translates to:
  /// **'A one-time purchase'**
  String get premiumOneTime;

  /// No description provided for @premiumPrice.
  ///
  /// In en, this message translates to:
  /// **'Buy for {PRICE}'**
  String premiumPrice(Object PRICE);

  /// No description provided for @premiumBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get premiumBuy;

  /// No description provided for @premiumRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get premiumRestore;

  /// No description provided for @premiumThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Everything is unlocked.'**
  String get premiumThanks;

  /// No description provided for @premiumFailed.
  ///
  /// In en, this message translates to:
  /// **'The purchase could not be completed.'**
  String get premiumFailed;

  /// No description provided for @premiumRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'No purchase was found to restore.'**
  String get premiumRestoreFailed;

  /// No description provided for @premiumUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Purchases are unavailable right now.\nPlease try again later.'**
  String get premiumUnavailable;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'es',
    'fr',
    'ja',
    'ko',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
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
    'that was used.',
  );
}
