// =============================
// Extension Methods for LETS ELEVATOR
//
// 1. StringExt      : String utilities, SharedPreferences helpers, image path helpers, style helpers
// 2. ContextExt     : BuildContext utilities, localization, UI helpers
// 3. IntExt         : Integer utilities for floor, button, and elevator logic
// 4. ListIntExt     : List<int> helpers for floor and button matrix
// 5. ListStringExt  : List<String> helpers for room images and names
// 6. BoolExt        : Boolean helpers for UI and logic
// 7. ListBoolExt    : List<bool> helpers for button images
// 8. ListDynamicExt : Generic List<T> matrix helpers
// =============================

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'audio_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constant.dart';
import 'l10n/app_localizations.dart' show AppLocalizations;

// =============================
// StringExt: String utilities, SharedPreferences helpers, image path helpers, style helpers
// =============================
extension StringExt on String {

  // --- Debug Utilities ---
  // Provides debug printing functionality for development
  void debugPrint() {
    if (kDebugMode) print(this);
  }

  // --- SharedPreferences Helpers ---
  // Comprehensive set of methods for storing and retrieving data from SharedPreferences
  // All methods include debug logging for development tracking
  void setSharedPrefString(SharedPreferences prefs, String value) {
    "Saved ${replaceAll("Key", "")}: $value".debugPrint();
    prefs.setString(this, value);
  }
  void setSharedPrefInt(SharedPreferences prefs, int value) {
    "Saved ${replaceAll("Key", "")}: $value".debugPrint();
    prefs.setInt(this, value);
  }
  void setSharedPrefBool(SharedPreferences prefs, bool value) {
    "Saved ${replaceAll("Key", "")}: $value".debugPrint();
    prefs.setBool(this, value);
  }
  void setSharedPrefListString(SharedPreferences prefs, List<String> value) {
    "Saved ${replaceAll("Key", "")}: $value".debugPrint();
    prefs.setStringList(this, value);
  }
  void setSharedPrefListInt(SharedPreferences prefs, List<int> value) {
    for (int i = 0; i < value.length; i++) {
      prefs.setInt("$this$i", value[i]);
    }
    "Saved ${replaceAll("Key", "")}: $value".debugPrint();
  }
  void setSharedPrefListBool(SharedPreferences prefs, List<bool> value) {
    for (int i = 0; i < value.length; i++) {
      prefs.setBool("$this$i", value[i]);
    }
    "Saved ${replaceAll("Key", "")}: $value".debugPrint();
  }
  String getSharedPrefString(SharedPreferences prefs, String defaultString) {
    String value = prefs.getString(this) ?? defaultString;
    "Get ${replaceAll("Key", "")}: $value".debugPrint();
    return value;
  }
  int getSharedPrefInt(SharedPreferences prefs, int defaultInt) {
    int value = prefs.getInt(this) ?? defaultInt;
    "Get ${replaceAll("Key", "")}: $value".debugPrint();
    return value;
  }
  bool getSharedPrefBool(SharedPreferences prefs, bool defaultBool) {
    bool value = prefs.getBool(this) ?? defaultBool;
    "Get ${replaceAll("Key", "")}: $value".debugPrint();
    return value;
  }
  List<String> getSharedPrefListString(SharedPreferences prefs, List<String> defaultList) {
    List<String> values = prefs.getStringList(this) ?? defaultList;
    "Get ${replaceAll("Key", "")}: $values".debugPrint();
    return values;
  }
  List<int> getSharedPrefListInt(SharedPreferences prefs, List<int> defaultList) {
    List<int> values = [];
    for (int i = 0; i < defaultList.length; i++) {
      int v = prefs.getInt("$this$i") ?? defaultList[i];
      values.add(v);
    }
    "Get ${replaceAll("Key", "")}: $values".debugPrint();
    return (values == []) ? defaultList: values;
  }
  List<bool> getSharedPrefListBool(SharedPreferences prefs, List<bool> defaultList) {
    List<bool> values = [];
    for (int i = 0; i < defaultList.length; i++) {
      bool v = prefs.getBool("$this$i") ?? defaultList[i];
      values.add(v);
    }
    "Get ${replaceAll("Key", "")}: $values".debugPrint();
    return (values == []) ? defaultList: values;
  }

  // --- Image Path Helpers ---
  // Methods for creating and managing image assets and file-based images
  String backGroundImage() => "$assetsCommon$this.png";

  // --- Button Shape Helpers ---
  // Methods for managing button shape configurations and indices
  int buttonShapeIndex() => buttonShapeList.contains(this) ? buttonShapeList.indexOf(this): 0;
}

// =============================
// ContextExt: BuildContext utilities, localization, UI helpers
// =============================
extension ContextExt on BuildContext {

  // --- Navigation & UI Basics ---
  // Core navigation and UI utility methods for screen management and responsive design
  void pushFadeReplacement(Widget page, {Duration duration = const Duration(milliseconds: 500)}) {
    AudioManager().playEffectSound(index: 0, asset: changeModeSound, volume: 1.0);
    Navigator.pushReplacement(this, PageRouteBuilder(
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      transitionDuration: duration,
    ));
  }
  void pushNoBack(Widget page) => Navigator.pushAndRemoveUntil(this,
      MaterialPageRoute(builder: (_) => page),
      (route) => false
    );
  void popPage() => Navigator.pop(this);

  double width() => MediaQuery.of(this).size.width;
  double height() => MediaQuery.of(this).size.height;
  String lang() => Localizations.localeOf(this).languageCode;

  // --- Progress Indicator Sizing ---
  // Responsive sizing utilities for circular progress indicators
  double circleSize() => ((height() > width()) ? width(): height()) * 0.1;
  double circleStrokeWidth() => ((height() > width()) ? width(): height()) * 0.012;

  // --- Localized Strings ---
  // Comprehensive collection of localized strings for all app features
  // Common app strings
  // String thisApp() => AppLocalizations.of(this)!.thisApp;
  String rooftop() => AppLocalizations.of(this)!.rooftop;
  String ground() => AppLocalizations.of(this)!.ground;
  String openDoor() => AppLocalizations.of(this)!.openDoor;
  String closeDoor() => AppLocalizations.of(this)!.closeDoor;
  String emergency() => AppLocalizations.of(this)!.emergency;
  String pushNumber() => AppLocalizations.of(this)!.pushNumber;
  String return1st() => AppLocalizations.of(this)!.return1st;
  String upFloor() => AppLocalizations.of(this)!.upFloor;
  String downFloor() => AppLocalizations.of(this)!.downFloor;
  String notStop() => AppLocalizations.of(this)!.notStop;
  String basement(int counter) => (counter < 0) ? AppLocalizations.of(this)!.basement: "";
  String floor(String number) => AppLocalizations.of(this)!.floor(number);
  String platform() => AppLocalizations.of(this)!.platform;
  String dog() => AppLocalizations.of(this)!.dog;
  String spa() => AppLocalizations.of(this)!.spa;
  String vip() => AppLocalizations.of(this)!.vip;
  String parking() => AppLocalizations.of(this)!.parking;
  String paradise() => AppLocalizations.of(this)!.paradise;
  String soundPlace(int counter, bool isShimada) =>
      (!isShimada) ? "":
      (counter == 3) ? platform():
      (counter == 7) ? dog():
      (counter == 14) ? spa():
      (counter == 154) ? vip():
      (counter == -2) ? parking():
      (counter == max) ? paradise():
      "";
  String soundFloor(int counter) =>
      (counter == max) ? rooftop():
      (counter == 0) ? ground():
      (lang() == "en") ? floor("${counter.enRankNumber()}${basement(counter)}"):
      floor("${basement(counter)}${counter.abs()}");
  String openingSound(int counter, bool isShimada) =>
      "${soundFloor(counter)}${soundPlace(counter, isShimada)}${openDoor()}";

  // --- 1000 Button Mode and Settings ---
  // Text localization for 1000-button challenge mode and settings interface
  String newRecord() => AppLocalizations.of(this)!.newRecord;
  String best() => AppLocalizations.of(this)!.best;
  String start() => AppLocalizations.of(this)!.start;
  String challenge() => AppLocalizations.of(this)!.challenge;
  String yourScore() => AppLocalizations.of(this)!.yourScore;

  String settings() => AppLocalizations.of(this)!.settings;
  String ok() => AppLocalizations.of(this)!.ok;
  String cancel() => AppLocalizations.of(this)!.cancel;
  String stop() => AppLocalizations.of(this)!.stop;
  String bypass() => AppLocalizations.of(this)!.bypass;
  String changeNumber() => AppLocalizations.of(this)!.changeNumber;
  String changeBasementNumber() => AppLocalizations.of(this)!.changeBasementNumber;
  String changeNumberTitle(bool isBasement) => isBasement ? changeBasementNumber(): changeNumber();
  String unlock() => AppLocalizations.of(this)!.unlock;
  String unlockTitle() => AppLocalizations.of(this)!.unlockTitle;
  String unlockDesc() => AppLocalizations.of(this)!.unlockDesc;
  String unlockAllTitle() => AppLocalizations.of(this)!.unlockAllTitle;
  List<String> unlockAll() => [
    AppLocalizations.of(this)!.unlockAll1,
    AppLocalizations.of(this)!.unlockAll2
  ];

  // --- Menu and Navigation ---
  // Menu system localization
  String menu() => AppLocalizations.of(this)!.menu;
  String back() => AppLocalizations.of(this)!.back;
  String ranking() => AppLocalizations.of(this)!.ranking;
  String terms() => AppLocalizations.of(this)!.terms;
  String officialPage() =>  AppLocalizations.of(this)!.officialPage;
  String officialShop() => AppLocalizations.of(this)!.officialShop;

  // --- External Links ---
  // Dynamic link generation for external resources with language-specific routing
  String shimaxLink() =>
    (lang() == "ja") ? shimadaJa:
    (lang() == "zh") ? shimadaZh:
    (lang() == "ko") ? shimadaKo: shimadaEn;
  String landingPageLink() => (lang() == "ja") ? landingPageJa: landingPageEn;
  String privacyPolicyLink() => (lang() == "ja") ? privacyPolicyJa: privacyPolicyEn;
  String youtubeLink() => (lang() == "ja") ? youtubeJa: youtubeEn;

  // --- Menu Configuration ---
  // Menu button layouts and link configurations for different app states
  List<List<String>> menuButtons(bool isHome, bool isShimada, bool isGamesSignIn) => [
    [isHome.modeChangeButton(isShimada), isHome.modeChallengeButton(isGamesSignIn)],
    [settingsButton, aboutShimadaButton],
  ];

  List<String> linkLogos() => [
    // if (lang() == "ja") twitterLogo,
    // if (lang() == "ja") instagramLogo,
    if (Platform.isAndroid) youtubeLogo,
    landingPageLogo,
    privacyPolicyLogo,
    if (lang() == "ja") shopPageLogo,
  ];
  List<String> linkLinks() => [
    // if (lang() == "ja") elevatorTwitter,
    // if (lang() == "ja") elevatorInstagram,
    if (Platform.isAndroid) youtubeLink(),
    landingPageLink(),
    privacyPolicyLink(),
    if (lang() == "ja") shopLink,
  ];
  List<String> linkTitles() => [
    // if (lang() == "ja") "X",
    // if (lang() == "ja") "Instagram",
    if (Platform.isAndroid) "Youtube",
    officialPage(),
    terms(),
    if (lang() == "ja") officialShop(),
  ];

  // --- Responsive Design ---
  // Core responsive sizing utilities for adaptive layouts across different devices
  double responsible() => (height() < 1000) ? height(): 1000;
  double widthResponsible() => (width() < 600) ? width(): 600;

  // --- Display Layout ---
  // Elevator display panel sizing and positioning for floor indicators and arrows
  double displayHeight() => responsible() * 0.25;
  double displayWidth() => widthResponsible();
  double displayMargin() => responsible() * 0.05;
  double displayNumberHeight() => responsible() * 0.15;
  double displayNumberWidth() => responsible() * 0.26;
  double displayNumberFontSize() => responsible() * 0.09;
  double displayNumberMargin(int buttonStyle) => responsible() * (buttonStyle == 0 ? 0.06: 0.00);
  double displayNumberHeaderMargin() => responsible() * 0.02;
  double displayNumberHeaderFontSize() => responsible() * 0.14;
  double displayArrowHeight() => responsible() * 0.08;
  double displayArrowWidth() => responsible() * 0.08;
  double shimadaLogoHeight() => responsible() * 0.1;
  double shimadaLogoTopMargin() => responsible() * 0.05;

  // --- Button Layout ---
  // Floor and operation button sizing with responsive margins and typography
  double floorButtonSize() => responsible() * 0.075;
  double operationButtonSize() =>  responsible() * 0.075;
  double operationButtonMargin() =>  responsible() * 0.02;
  double buttonNumberFontSize() => responsible() * 0.025;
  double buttonMargin() => responsible() * 0.03;
  double floorButtonMargin() => widthResponsible() * 0.02;
  double floorButtonNumberFontSize(int i) => widthResponsible() * 0.03;
  double floorButtonNumberBottomMargin(int i) =>
      widthResponsible() * floorButtonNumberMarginFactor[i] * 0.01;
  double floorButtonNumberMarginTop(int i) =>
      floorButtonNumberMarginFactor[i] < 0 ? 0: widthResponsible() * floorButtonNumberMarginFactor[i];
  double floorButtonNumberMarginBottom(int i) =>
      floorButtonNumberMarginFactor[i] > 0 ? 0: -1 * widthResponsible() * floorButtonNumberMarginFactor[i];

  // --- Advertisement Layout ---
  // AdMob banner sizing for different screen heights
  double admobHeight() => (height() < 600) ? 50: (height() < 1000) ? 50 + (height() - 600) / 8: 100;
  double admobWidth() => width() - 100;

  // --- Menu Layout ---
  // Main menu screen layout with app bar, buttons, and external links
  double menuAppBarHeight() => height() * 0.07;
  double menuAppBarFontSize() => height() * (lang() == "en" ? 0.045: 0.032);
  double menuTitleFontSize() => height() * (lang() == "en" ? 0.05: 0.032);
  double menuButtonSize() => widthResponsible() * 0.33;
  double menuButtonMargin() => responsible() * 0.05;
  double menuLinksLogoSize() => widthResponsible() * 0.16;
  double menuLinksTitleSize() => widthResponsible() *  (lang() == "en" ? 0.030: 0.025);
  double menuLinksTitleMargin() => widthResponsible() * 0.02;
  double menuLinksMargin() => widthResponsible() * 0.04;

  // --- Settings Layout ---
  // Comprehensive settings screen layout with dividers, app bar, locks, and tooltips
  // Divider: Visual separators between settings sections
  double settingsDividerHeight() => height() * 0.015;
  double settingsDividerThickness() => height() * 0.001;
  // AppBar: Top navigation bar with back button and title
  double settingsAppBarHeight() => height() * 0.07;
  double settingsAppBarFontSize() => height() * (lang() == "en" ? 0.045: 0.032);
  double settingsAppBarBackButtonSize() => height() * 0.05;
  double settingsAppBarBackButtonMargin() => height() * 0.01;
  // Lock: Premium feature indicators and unlock buttons
  double settingsLockSize() => height() * 0.10;
  double settingsLockFontSize() => height() * 0.01;
  double settingsLockIconSize() => height() * 0.035;
  double settingsLockMargin() => height() * 0.01;
  double settingsAllLockIconSize() => height() * 0.1;
  double settingsAllLockIconMargin() => height() * 0.01;
  double settingsAllLockFontSize() => height() * 0.022;
  double settingsLockFreeButtonWidth() => height() * 0.08;
  double settingsLockFreeButtonHeight() => height() * 0.03;
  double settingsLockFreeBorderRadius() => height() * 0.015;
  double settingsLockFreeFontSize() => height() * 0.018;
  // Tooltip: Help text overlays for setting explanations
  double settingsTooltipIconSize() => widthResponsible() * 0.08;
  double settingsTooltipHeight() => widthResponsible() * 0.2;
  double settingsTooltipMargin() => widthResponsible() * 0.185;
  double settingsTooltipTitleFontSize() => widthResponsible() * 0.05;
  double settingsTooltipDescFontSize() => widthResponsible() *0.04;
  double settingsTooltipTitleMargin() => widthResponsible() * 0.01;
  double settingsTooltipPaddingSize() => widthResponsible() * 0.04;
  double settingsTooltipMarginSize() => widthResponsible() * 0.02;
  double settingsTooltipBorderRadius() => widthResponsible() * 0.04;
  double settingsTooltipOffsetSize() => widthResponsible() * 0.02;

  // --- Settings Controls ---
  // Interactive controls for settings including buttons, number inputs, and toggles
  // Select button: Navigation buttons for different setting categories
  double settingsSelectButtonSize() => height() * 0.06;
  double settingsSelectButtonIconSize() => height() * 0.03;
  double settingsSelectButtonMarginTop() => height() * 0.015;
  double settingsSelectButtonMarginBottom() => height() * 0.007;
  // Change button number: Floor count configuration controls
  double settingsButtonSize() => height() * 0.07;
  double settingsNumberButtonWidth() => height() * 0.07;
  double settingsNumberButtonHeight() => height() * 0.142;
  double settingsNumberButtonFontSize() => height() * 0.03;
  double settingsNumberButtonMargin() => height() * 0.015;
  double settingsNumberButtonHideWidth() => height() * 0.08;
  double settingsNumberButtonHideHeight() => height() * 0.145;
  double settingsNumberButtonHideMargin() => height() * 0.01;
  // Change floor stop: Toggle switches for floor stop configuration
  double settingsFloorStopFontSize() => height() * 0.015;
  double settingsFloorStopMargin() => height() * 0.005;
  double settingsFloorStopToggleScale() => height() * 0.001;
  // Change button style: Visual style selection for elevator buttons
  double settingsButtonStyleSize() => height() * 0.07;
  double settingsButtonStyleMargin() => height() * 0.03;
  double settingsButtonStyleLockWidth() => width() * 0.90;
  double settingsButtonStyleLockHeight() => height() * 0.19;
  double settingsButtonStyleLockMargin() => height() * 0.095;
  // Change button shape: Geometric shape selection for button appearance
  double settingsButtonShapeSize() => height() * 0.07;
  double settingsButtonShapeFontSize() => height() * 0.022;
  double settingsButtonShapeMargin() => height() * 0.005;
  // Change background image: Background image selection and preview
  double settingsBackgroundSize() => height() * 0.17;
  double settingsBackgroundMargin() => height() * 0.035;
  double settingsBackgroundSelectBorderWidth() =>  height() * 0.007;
  double settingsBackgroundStyleLockWidth() => width() * 0.90;
  double settingsBackgroundStyleLockHeight() => height() * 0.4;
  double settingsBackgroundStyleLockMargin() => height() * 0.23;
  // Settings Alert Dialog: Modal dialogs for configuration changes
  double settingsAlertTitleFontSize() => widthResponsible() * 0.05;
  double settingsAlertDescFontSize() => widthResponsible() * 0.04;
  double settingsAlertCloseIconSize() =>  widthResponsible() * 0.1;
  double settingsAlertCloseIconSpace() =>  widthResponsible() * 0.05;
  double settingsAlertSelectFontSize() => widthResponsible() * 0.05;
  double settingsAlertFloorNumberPickerHeight() => widthResponsible() * 0.4;
  double settingsAlertFloorNumberHeight() => widthResponsible() * 0.16;
  double settingsAlertFloorNumberFontSize() => widthResponsible() * 0.1;
  double settingsAlertIconSize() => widthResponsible() * 0.06;
  double settingsAlertIconMargin() => widthResponsible() * 0.01;
  double settingsAlertLockFontSize() => widthResponsible() * 0.07;
  double settingsAlertLockIconSize() => widthResponsible() * 0.05;
  double settingsAlertLockSpaceSize() => widthResponsible() * 0.02;
  double settingsAlertLockBorderWidth() => widthResponsible() * 0.002;
  double settingsAlertLockBorderRadius() => widthResponsible() * 0.04;

  // --- 1000 Button Challenge Layout ---
  // Challenge mode interface layout for 1000-button speed test
  // Logo and branding elements
  double logo1000ButtonsWidth() => widthResponsible() * 0.5;
  double logo1000ButtonsPadding() => widthResponsible() * 0.01;
  // Start button for challenge mode
  double challengeStartButtonWidth() => widthResponsible() * 0.2;
  double challengeStartButtonHeight() => widthResponsible() * 0.125;
  double challengeButtonFontSize() => widthResponsible() * ((lang() == "ja" || lang() == "en") ? 0.022: 0.03);
  double challengeStartFontSize() => widthResponsible() * 0.04;
  // Countdown timer display
  double countdownFontSize() => widthResponsible() * 0.075;
  double countdownPaddingTop() => widthResponsible() * 0.007;
  double countdownPaddingLeft() => widthResponsible() *  0.01;
  double countdownPaddingBottom() => widthResponsible() * 0.006;
  // Score and progress display
  double countDisplayWidth() => widthResponsible() * 0.28;
  double countDisplayHeight() => widthResponsible() * 0.12;
  double countDisplayPaddingLeft() => widthResponsible() * 0.012;
  double countDisplayPaddingBottom() => widthResponsible() * 0.01;
  // Pre-countdown animation elements
  double beforeCountdownCircleSize() => widthResponsible() * 0.4;
  double beforeCountdownNumberSize() => widthResponsible() * 0.2;
  // Score display typography
  double yourScoreFontSize() => widthResponsible() * 0.24;
  double bestScoreFontSize() => widthResponsible() * 0.12;
  double scoreTitleFontSize() => widthResponsible() * 0.09;
  double bestFontSize() => widthResponsible() * 0.09;
  // Navigation and control buttons
  double backButtonFontSize() => widthResponsible() * 0.045;
  double backButtonWidth() => widthResponsible() * 0.3;
  double backButtonHeight() => widthResponsible() * 0.1;
  double backButtonBorderRadius() => widthResponsible() * 0.02;
  // Button grid layout for challenge mode
  double defaultButtonLength() => 0.07 * height() - 2;
  double buttonWidth(int p, i, j) => p.buttonWidthFactor(i, j) * defaultButtonLength();
  double buttonHeight() => defaultButtonLength();
  double largeButtonWidth(double ratio) => ratio * defaultButtonLength();
  double largeButtonHeight(double ratio) => ratio * defaultButtonLength();
  double buttonsPadding() => (height() < 1100) ? 0.014 * height() - 3: 12.4 + 0.038 * (height() - 1100);
  // Visual styling for challenge interface
  double startBorderWidth() => (width() < 800) ? width() / 400: 2.0;
  double startCornerRadius() => (width() < 800) ? width() / 40: 20.0;
  double dividerHeight() => height() * 0.72;
  double dividerMargin() => widthResponsible() * 0.03;
}

extension IntExt on int {

  // --- Settings UI ---
  // Settings screen button states and operation button style management
  // Selected number indicator for settings buttons
  String selected(int i) => (this == i) ? "Pressed": "";
  String settingsButton(int i) => "$assetsSettings${settingsItemList[i]}Settings${selected(i)}.png";
  // Operation button style assets for different button types
  String openButton() => "${assetsButton}open${this + 1}.png";
  String closeButton() => "${assetsButton}close${this + 1}.png";
  String alertButton() => "${assetsButton}phone${this + 1}.png";
  String pressedOpenButton() => "${assetsButton}open${this + 1}Pressed.png";
  String pressedCloseButton() => "${assetsButton}close${this + 1}Pressed.png";
  String pressedAlertButton() => "${assetsButton}phone${this + 1}Pressed.png";

  // --- Matrix Utilities ---
  // List index calculation for 2D matrix operations
  int listNum(int row, int col) => this * row + col;

  // --- Floor Sound Generation ---
  // English ordinal number generation for floor announcements
  String enRankNumber() =>
      (abs() % 10 == 1 && abs() ~/ 10 != 1) ? "${abs()}st ":
      (abs() % 10 == 2 && abs() ~/ 10 != 1) ? "${abs()}nd ":
      (abs() % 10 == 3 && abs() ~/ 10 != 1) ? "${abs()}rd ":
      "${abs()}th ";

  // --- Display Logic ---
  // Floor number display formatting for elevator display panel
  // Current floor counter display with special symbols
  String displayNumber() =>
      (this == max) ? "R":
      (this == 0) ? "G":
      (this < 0) ? "B${abs()}":
      "$this";
  // Floor number header display for elevator display panel
  String displayNumberHeader() =>
      (this == max) ? "R":
      (this == 0) ? "G":
      (this < 0) ? "B":
      " ";
  // Direction arrow image selection based on movement and destination
  String arrowImage(bool isMoving, int nextFloor, int buttonStyle) =>
      (isMoving && this < nextFloor) ? "${assetsCommon}up${buttonStyle + 1}.png":
      (isMoving && this > nextFloor) ? "${assetsCommon}down${buttonStyle + 1}.png":
      transpImage;

  // --- Elevator Movement Logic ---
  // Speed calculation based on distance and operation count
  int elevatorSpeed(int count, int nextFloor) {
    int l = (this - nextFloor).abs();
    return (count < 2 || l < 2) ? 2000:
    (count < 5 || l < 5) ? 1000:
    (count < 10 || l < 10) ? 500:
    (count < 20 || l < 20) ? 250: 100;
  }

  // --- Button State Management ---
  // Floor button number display with special symbols
  String buttonNumber() =>
      (this == max) ? "R":
      (this == 0) ? "G":
      (this < 0) ? "B${abs()}":
      "$this";

  // Button selection state checking for up/down direction lists
  bool isSelected({
    required List<bool> up,
    required List<bool> down
  }) => (this > 0) ? up[this]: down[this * (-1)];
  // Floor button background image selection based on selection state
  String floorButtonBackgroundImage({
    required bool shimada,
    required int row,
    required int col,
    required List<bool> up,
    required List<bool> down,
    required int style,
    required String shape,
  }) => shimada ? isSelected(up: up, down: down).shimadaButtonImage(row, col):
                  isSelected(up: up, down: down).numberBackground(style,shape);
  // Floor button number color selection based on selection state
  Color floorButtonNumberColor({
    required List<bool> up,
    required List<bool> down,
    required int style,
    required String shape,
  }) => (style != 0) ? blackColor:
    isSelected(up: up, down: down).floorButtonNumberColor(shape);

  // --- Floor Selection Management ---
  // Floor selection clearing operations for elevator control logic
  // Clear all floors above current position
  void clearUpperFloor(List<bool> isAboveSelectedList, isUnderSelectedList) {
    for (int j = max; j > this - 1; j--) {
      if (j > 0) isAboveSelectedList[j] = false;
      if (j < 0) isUnderSelectedList[j * (-1)] = false;
    }
  }
  // Clear all floors below current position
  void clearLowerFloor(List<bool> isAboveSelectedList, isUnderSelectedList) {
    for (int j = min; j < this + 1; j++) {
      if (j > 0) isAboveSelectedList[j] = false;
      if (j < 0) isUnderSelectedList[j * (-1)] = false;
    }
  }

  // --- Floor Range Generation ---
  // Generate floor lists for elevator movement sequences
  // Generate ascending floor list from current to target
  List<int> upFromToNumber(int nextFloor) {
    List<int> floorList = [];
    for (int i = this + 1; i < nextFloor + 1; i++) {
      floorList.add(i);
    }
    return floorList;
  }
  // Generate descending floor list from current to target
  List<int> downFromToNumber(int nextFloor) {
    List<int> floorList = [];
    for (int i = this - 1; i > nextFloor - 1; i--) {
      floorList.add(i);
    }
    return floorList;
  }

  // --- Next Floor Calculation ---
  // Intelligent next floor selection based on current position and button states
  // Calculate next floor when moving upward
  int upNextFloor({
    required List<bool> up,
    required List<bool> down,
  }) {
    int nextFloor = max;
    for (int k = this + 1; k < max + 1; k++) {
      bool isSelected = k.isSelected(up: up, down: down);
      if (k < nextFloor && isSelected) nextFloor = k;
    }
    if (nextFloor == max) {
      bool isMaxSelected = max.isSelected(up: up, down: down);
      if (isMaxSelected) {
        nextFloor = max;
      } else {
        nextFloor = min;
        bool isMinSelected = min.isSelected(up: up, down: down);
        for (int k = min; k < this; k++) {
          bool isSelected = k.isSelected(up: up, down: down);
          if (k > nextFloor && isSelected) nextFloor = k;
        }
        if (isMinSelected) nextFloor = min;
      }
    }
    bool allFalse = true;
    for (int k = 0; k < up.length; k++) {
      if (up[k]) allFalse = false;
    }
    for (int k = 0; k < down.length; k++) {
      if (down[k]) allFalse = false;
    }
    if (allFalse) nextFloor = this;
    return nextFloor;
  }
  // Calculate next floor when moving downward
  int downNextFloor({
    required List<bool> up,
    required List<bool> down,
  }) {
    int nextFloor = min;
    for (int k = min; k < this; k++) {
      bool isSelected = k.isSelected(up: up, down: down);
      if (k > nextFloor && isSelected) nextFloor = k;
    }
    if (nextFloor == min) {
      bool isMinSelected = min.isSelected(up: up, down: down);
      if (isMinSelected) {
        nextFloor = min;
      } else {
        nextFloor = max;
        bool isMaxSelected = max.isSelected(up: up, down: down);
        for (int k = max; k > this; k--) {
          bool isSelected = k.isSelected(up: up, down: down);
          if (k < nextFloor && isSelected) nextFloor = k;
        }
        if (isMaxSelected) nextFloor = max;
      }
    }
    bool allFalse = true;
    for (int k = 0; k < up.length; k++) {
      if (up[k]) allFalse = false;
    }
    for (int k = 0; k < down.length; k++) {
      if (down[k]) allFalse = false;
    }
    if (allFalse) nextFloor = this;
    return nextFloor;
  }

  // --- Button State Control ---
  // Direct manipulation of button selection states
  // Set button as selected (true)
  void trueSelected({
    required List<bool> up,
    required List<bool> down,
  }) {
    if (this > 0) up[this] = true;
    if (this < 0) down[this * (-1)] = true;
  }

  // Set button as unselected (false)
  void falseSelected({
    required List<bool> up,
    required List<bool> down,
  }) {
    if (this > 0) up[this] = false;
    if (this < 0) down[this * (-1)] = false;
  }
  // Check if this is the only selected button
  bool onlyTrue({
    required List<bool> up,
    required List<bool> down,
  }) {
    bool listFlag = false;
    if (isSelected(up: up, down: down)) listFlag = true;
    if (this > 0) {
      for (int k = 0; k < up.length; k++) {
        if (k != this && up[k]) listFlag = false;
      }
      for (int k = 0; k < down.length; k++) {
        if (down[k]) listFlag = false;
      }
    }
    if (this < 0) {
      for (int k = 0; k < down.length; k++) {
        if (k != this * (-1) && down[k]) listFlag = false;
      }
      for (int k = 0; k < up.length; k++) {
        if (up[k]) listFlag = false;
      }
    }
    return listFlag;
  }

  // --- 1000 Button Challenge Layout ---
  // Button visibility and layout configuration for challenge mode panels
  // Transparent button positions for special layout effects
  bool isTranspButton(int i, j) =>
      //panel 2
      (this == 1 && i == 2 && j == 7) ? true:
      //panel 4
      (this == 3 && i == 9 && j == 3) ? true:
      false;
  // Missing button positions for realistic elevator panel layouts
  bool isNotHaveButton(int i, j) =>
      // panel 1
      (this == 0 && i == 0 && j == 2) ? true:
      (this == 0 && i == 0 && j == 4) ? true:
      (this == 0 && i == 0 && j == 10) ? true:
      (this == 0 && i == 1 && j == 1) ? true:
      (this == 0 && i == 1 && j == 2) ? true:
      (this == 0 && i == 1 && j == 9) ? true:
      (this == 0 && i == 1 && j == 10) ? true:
      (this == 0 && i == 2 && j == 6) ? true:
      (this == 0 && i == 2 && j == 9) ? true:
      (this == 0 && i == 2 && j == 10) ? true:
      (this == 0 && i == 5 && j == 4) ? true:
      (this == 0 && i == 5 && j == 5) ? true:
      (this == 0 && i == 6 && j == 5) ? true:
      (this == 0 && i == 7 && j == 3) ? true:
      (this == 0 && i == 7 && j == 8) ? true:
      (this == 0 && i == 8 && j == 7) ? true:
      (this == 0 && i == 8 && j == 9) ? true:
      (this == 0 && i == 9 && j == 5) ? true:
      (this == 0 && i == 10 && j == 1) ? true:
      // panel 2
      (this == 1 && i == 0 && j == 0) ? true:
      (this == 1 && i == 0 && j == 3) ? true:
      (this == 1 && i == 0 && j == 4) ? true:
      (this == 1 && i == 0 && j == 6) ? true:
      (this == 1 && i == 1 && j == 0) ? true:
      (this == 1 && i == 1 && j == 9) ? true:
      (this == 1 && i == 2 && j == 2) ? true:
      (this == 1 && i == 3 && j == 2) ? true:
      (this == 1 && i == 7 && j == 1) ? true:
      (this == 1 && i == 7 && j == 4) ? true:
      (this == 1 && i == 8 && j == 1) ? true:
      (this == 1 && i == 8 && j == 3) ? true:
      (this == 1 && i == 8 && j == 4) ? true:
      (this == 1 && i == 8 && j == 7) ? true:
      // panel 3
      (this == 2 && i == 0 && j == 0) ? true:
      (this == 2 && i == 1 && j == 7) ? true:
      (this == 2 && i == 1 && j == 8) ? true:
      (this == 2 && i == 1 && j == 9) ? true:
      (this == 2 && i == 2 && j == 6) ? true:
      (this == 2 && i == 3 && j == 0) ? true:
      (this == 2 && i == 4 && j == 5) ? true:
      (this == 2 && i == 4 && j == 6) ? true:
      (this == 2 && i == 5 && j == 10) ? true:
      (this == 2 && i == 7 && j == 9) ? true:
      (this == 2 && i == 8 && j == 7) ? true:
      (this == 2 && i == 9 && j == 5) ? true:
      (this == 2 && i == 10 && j == 1) ? true:
      (this == 2 && i == 10 && j == 4) ? true:
      // panel 4
      (this == 3 && i == 0 && j == 5) ? true:
      (this == 3 && i == 1 && j == 4) ? true:
      (this == 3 && i == 1 && j == 5) ? true:
      (this == 3 && i == 1 && j == 8) ? true:
      (this == 3 && i == 2 && j == 10) ? true:
      (this == 3 && i == 3 && j == 2) ? true:
      (this == 3 && i == 3 && j == 3) ? true:
      (this == 3 && i == 6 && j == 5) ? true:
      (this == 3 && i == 7 && j == 3) ? true:
      (this == 3 && i == 7 && j == 6) ? true:
      (this == 3 && i == 7 && j == 10) ? true:
      (this == 3 && i == 8 && j == 2) ? true:
      (this == 3 && i == 8 && j == 4) ? true:
      (this == 3 && i == 10 && j == 4) ? true:
      (this == 3 && i == 10 && j == 5) ? true:
      // panel 5
      (this == 4 && i == 0 && j == 3) ? true:
      (this == 4 && i == 0 && j == 5) ? true:
      (this == 4 && i == 0 && j == 6) ? true:
      (this == 4 && i == 0 && j == 8) ? true:
      (this == 4 && i == 0 && j == 9) ? true:
      (this == 4 && i == 1 && j == 8) ? true:
      (this == 4 && i == 2 && j == 6) ? true:
      (this == 4 && i == 3 && j == 1) ? true:
      (this == 4 && i == 3 && j == 4) ? true:
      (this == 4 && i == 3 && j == 9) ? true:
      (this == 4 && i == 5 && j == 8) ? true:
      (this == 4 && i == 6 && j == 1) ? true:
      (this == 4 && i == 6 && j == 9) ? true:
      (this == 4 && i == 7 && j == 7) ? true:
      (this == 4 && i == 8 && j == 7) ? true:
      (this == 4 && i == 8 && j == 9) ? true:
      (this == 4 && i == 9 && j == 7) ? true:
      (this == 4 && i == 9 && j == 8) ? true:
      (this == 4 && i == 10 && j == 3) ? true:
      (this == 4 && i == 10 && j == 8) ? true:
      // panel 6
      (this == 5 && i == 0 && j == 7) ? true:
      (this == 5 && i == 1 && j == 6) ? true:
      (this == 5 && i == 1 && j == 9) ? true:
      (this == 5 && i == 2 && j == 5) ? true:
      (this == 5 && i == 3 && j == 0) ? true:
      (this == 5 && i == 3 && j == 4) ? true:
      (this == 5 && i == 3 && j == 5) ? true:
      (this == 5 && i == 4 && j == 0) ? true:
      (this == 5 && i == 4 && j == 3) ? true:
      (this == 5 && i == 4 && j == 5) ? true:
      (this == 5 && i == 4 && j == 7) ? true:
      (this == 5 && i == 5 && j == 2) ? true:
      (this == 5 && i == 5 && j == 4) ? true:
      (this == 5 && i == 5 && j == 8) ? true:
      (this == 5 && i == 6 && j == 1) ? true:
      (this == 5 && i == 6 && j == 4) ? true:
      (this == 5 && i == 6 && j == 9) ? true:
      (this == 5 && i == 7 && j == 6) ? true:
      (this == 5 && i == 8 && j == 0) ? true:
      (this == 5 && i == 8 && j == 3) ? true:
      (this == 5 && i == 8 && j == 7) ? true:
      (this == 5 && i == 8 && j == 9) ? true:
      (this == 5 && i == 9 && j == 1) ? true:
      (this == 5 && i == 9 && j == 2) ? true:
      (this == 5 && i == 9 && j == 7) ? true:
      (this == 5 && i == 9 && j == 10) ? true:
      (this == 5 && i == 10 && j == 7) ? true:
      // panel 7
      (this == 6 && i == 0 && j == 2) ? true:
      (this == 6 && i == 1 && j == 9) ? true:
      (this == 6 && i == 2 && j == 1) ? true:
      (this == 6 && i == 2 && j == 2) ? true:
      (this == 6 && i == 2 && j == 10) ? true:
      (this == 6 && i == 3 && j == 2) ? true:
      (this == 6 && i == 3 && j == 6) ? true:
      (this == 6 && i == 3 && j == 7) ? true:
      (this == 6 && i == 4 && j == 1) ? true:
      (this == 6 && i == 6 && j == 8) ? true:
      (this == 6 && i == 7 && j == 10) ? true:
      (this == 6 && i == 10 && j == 0) ? true:
      // panel 8
      (this == 7 && i == 1 && j == 3) ? true:
      (this == 7 && i == 2 && j == 6) ? true:
      (this == 7 && i == 2 && j == 8) ? true:
      (this == 7 && i == 3 && j == 3) ? true:
      (this == 7 && i == 5 && j == 0) ? true:
      (this == 7 && i == 5 && j == 7) ? true:
      (this == 7 && i == 7 && j == 2) ? true:
      (this == 7 && i == 7 && j == 7) ? true:
      (this == 7 && i == 7 && j == 10) ? true:
      (this == 7 && i == 8 && j == 0) ? true:
      (this == 7 && i == 8 && j == 7) ? true:
      (this == 7 && i == 9 && j == 4) ? true:
      (this == 7 && i == 10 && j == 2) ? true:
      (this == 7 && i == 10 && j == 4) ? true:
      // panel 8
      (this == 8 && i == 0 && j == 4) ? true:
      (this == 8 && i == 0 && j == 9) ? true:
      (this == 8 && i == 1 && j == 1) ? true:
      (this == 8 && i == 1 && j == 2) ? true:
      (this == 8 && i == 2 && j == 3) ? true:
      (this == 8 && i == 2 && j == 9) ? true:
      (this == 8 && i == 3 && j == 4) ? true:
      (this == 8 && i == 3 && j == 5) ? true:
      (this == 8 && i == 3 && j == 7) ? true:
      (this == 8 && i == 3 && j == 8) ? true:
      (this == 8 && i == 5 && j == 3) ? true:
      (this == 8 && i == 5 && j == 4) ? true:
      (this == 8 && i == 5 && j == 6) ? true:
      (this == 8 && i == 5 && j == 8) ? true:
      (this == 8 && i == 6 && j == 7) ? true:
      (this == 8 && i == 6 && j == 10) ? true:
      (this == 8 && i == 7 && j == 9) ? true:
      (this == 8 && i == 8 && j == 2) ? true:
      (this == 8 && i == 8 && j == 8) ? true:
      (this == 8 && i == 9 && j == 5) ? true:
      (this == 8 && i == 10 && j == 8) ? true:
      // Other
      false;
  // Button width scaling factors for different panel layouts
  double buttonWidthFactor(int i, j) =>
      //panel 1
      (this == 0 && i == 1 && j == 8) ? 3:
      (this == 0 && i == 5 && j == 2) ? 3:
      (this == 0 && i == 8 && j == 10) ? 2:
      //panel 2
      (this == 1 && i == 2 && j == 6) ? 2:
      (this == 1 && i == 2 && j == 7) ? 2:
      (this == 1 && i == 5 && j == 1) ? 3:
      (this == 1 && i == 7 && j == 9) ? 3:
      //panel 3
      (this == 2 && i == 4 && j == 2) ? 1.5:
      (this == 2 && i == 5 && j == 2) ? 1.5:
      (this == 2 && i == 6 && j == 6) ? 3:
      //panel 4
      (this == 3 && i == 2 && j == 2) ? 3:
      //panel 5
      (this == 4 && i == 1 && j == 5) ? 2:
      (this == 4 && i == 1 && j == 9) ? 2:
      (this == 4 && i == 5 && j == 2) ? 2:
      (this == 4 && i == 6 && j == 6) ? 1.5:
      (this == 4 && i == 7 && j == 6) ? 1.5:
      //panel 6
      (this == 5 && i == 3 && j == 8) ? 3:
      (this == 5 && i == 7 && j == 1) ? 2:
      //panel 7
      (this == 6 && i == 3 && j == 3) ? 3:
      (this == 6 && i == 7 && j == 1) ? 2:
      (this == 6 && i == 7 && j == 8) ? 3:
      //panel 8
      (this == 7 && i == 6 && j == 5) ? 3:
      //panel 9
      (this == 8 && i == 1 && j == 6) ? 4:
      (this == 8 && i == 2 && j == 1) ? 4:
      (this == 8 && i == 7 && j == 3) ? 3:
      1;

  // --- Challenge Mode Utilities ---
  // Number formatting and display utilities for challenge mode
  // Zero-padded number display for score counters
  String countNumber() =>
      (this > 999) ? "$this":
      (this > 99) ? "0$this":
      (this > 9) ? "00$this":
      "000$this";
  // Countdown timer number formatting
  String countDownNumber() =>
      (this > 9) ? "$this": (this < 0 || this > 99) ? "00": "0$this";
  // Start button color coding based on challenge state
  Color startButtonColor() =>
      (this == 0) ? redColor:
      (this % 2 == 1) ? blackColor:
      (this < 10) ? yellowColor:
      greenColor;

  // --- List Generation Utilities ---
  // 3D list generation for button state management
  // Generate 3D list filled with false values
  List<List<List<bool>>> listListAllFalse(int rowMax, int columnMax) =>
      List.generate(this, (_) => List.generate(rowMax, (_) => List.generate(columnMax, (_) => false)));
  // Generate 3D list filled with true values
  List<List<List<bool>>> listListAllTrue(int rowMax, int columnMax) =>
      List.generate(this, (_) => List.generate(rowMax, (_) => List.generate(columnMax, (_) => true)));
}

extension BoolExt on bool {

  // --- Button State Management ---
  // Button pressed state utilities for visual feedback and asset selection
  // Pressed state suffix for asset file names
  String pressed() => this ? 'Pressed': '';
  // Button background image selection based on style, shape, and pressed state
  String numberBackground(int buttonStyle, String buttonShape) => "$assetsButton$buttonShape${buttonStyle + 1}${pressed()}.png";
  // Button number color selection based on pressed state
  Color numberColor(int i) => this ? numberColorList[i]: whiteColor;
  // Floor button number color based on button shape and pressed state
  Color floorButtonNumberColor(String buttonShape) => numberColor(buttonShape.buttonShapeIndex());
  // Shimada button image selection for 1000 button challenge
  String shimadaButtonImage(int row, int col) =>
      '$assets1000${this ? "p": ""}${initialFloorNumbers.toReversedMatrix(4)[row][col].buttonNumber()}.png';

  // --- Floor Configuration ---
  // Basement floor configuration utilities
  // Floor symbol multiplier for basement vs above-ground floors
  int floorSymbol() => this ? -1: 1;
  // Selected floor number calculation with basement support
  int selectedFloorNumber(int index) => floorSymbol() * (index + 1);

  // --- Menu Navigation ---
  // Home screen menu button configuration
  // Mode change button selection based on current Shimada state
  String modeChangeButton(bool isShimada) => (this && !isShimada) ? modeShimadaButton: modeNormalButton;
  // Challenge mode button selection based on games sign-in status
  String modeChallengeButton(bool isGamesSignIn) => (!this && isGamesSignIn) ? rankingButton: mode1000Button;

  // --- Shimada Mode Styling ---
  // Shimada Electric brand styling for buttons and backgrounds
  // Button channel background selection
  String buttonChanBackGround() => (this) ? pressedButtonChan: buttonChan;
  // Open button background with Shimada or standard styling
  String openBackGround(bool isPressed, int buttonStyle) => (this) ?
      ((isPressed) ? pressedShimadaOpen: shimadaOpen):
      ((isPressed) ? buttonStyle.pressedOpenButton(): buttonStyle.openButton());
  // Close button background with Shimada or standard styling
  String closeBackGround(bool isPressed, int buttonStyle) => (this) ?
      ((isPressed) ? pressedShimadaClose: shimadaClose):
      ((isPressed) ? buttonStyle.pressedCloseButton(): buttonStyle.closeButton());
  // Phone/alert button background with Shimada or standard styling
  String phoneBackGround(bool isPressed, int buttonStyle) => (this) ?
      ((isPressed) ? pressedShimadaAlert: shimadaAlert):
      ((isPressed) ?  buttonStyle.pressedAlertButton(): buttonStyle.alertButton());

  // Operation button background list for all three buttons
  List<String> operateBackGround(List<bool> isPressedList, int buttonStyle) => [
    openBackGround(isPressedList[0], buttonStyle),
    closeBackGround(isPressedList[1], buttonStyle),
    phoneBackGround(isPressedList[2], buttonStyle)
  ];

  // --- Menu Interaction ---
  // Menu button press handling with audio and vibration feedback
  Future<bool> pressedMenu() async {
    await AudioManager().playEffectSound(index: 0, asset: selectButton, volume: 1.0);
    await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
    return !this;
  }
  
}

extension ListListListBoolExt on List<List<List<bool>>> {

  // --- 1000 Button Challenge Image Selection ---
  // Dynamic button image selection for challenge mode based on button state and position
  String buttonImage(int p, i, j) =>
      // Large Buttons => Transparent
      (p.isTranspButton(i, j)) ? transpImage:
      // Missing Buttons => Random image selection
      (p.isNotHaveButton(i, j) && this[p][i][j]) ? "${assetsRealOn}xp${(19 * i + 13 * j) % 184 + 1}.png":
      (p.isNotHaveButton(i, j)) ? "${assetsRealOff}x${(19 * i + 13 * j) % 184 + 1}.png":
      // Standard Buttons => State-based image selection
      (this[p][i][j]) ? "${assetsReal1000On}p${p + 1}/p${p + 1}_${i + 1}_${j + 1}.png":
      "$assetsReal1000Off${p + 1}/${p + 1}_${i + 1}_${j + 1}.png";
}

extension ListBoolExt on List<bool> {

  // --- Operation Button Image Management ---
  // Operation button image list generation for elevator control buttons
  List<String> operationButtonImage(int buttonStyle) => [
    false.openBackGround(this[0], buttonStyle),
    false.closeBackGround(this[1], buttonStyle),
    false.phoneBackGround(this[2], buttonStyle),
  ];
}

extension ListDynamicExt<T> on List<T> {

  // --- Matrix Transformation Utilities ---
  // Generic matrix transformation utilities for data restructuring
  // Convert list to 2D matrix with specified column count
  List<List<T>> toMatrix(int n) =>
      [for (var i = 0; i < length; i += n) sublist(i, (i + n <= length) ? i + n : length)];

  // Convert list to reversed 2D matrix for special layout requirements
  List<List<T>> toReversedMatrix(int n) {
    final chunks = <List<T>>[];
    for (int i = 0; i < length; i += n) {
      final end = (i + n).clamp(0, length);
      final chunk = (i == 0) ? sublist(i, end).reversed.toList(): sublist(i, end);
      chunks.add(chunk);
    }
    // "chunks: ${chunks.reversed.toList()}".debugPrint();
    return chunks.reversed.toList();
  }
}

extension ListInt on List<int> {

  // --- Floor Range Selection ---
  // Floor range calculation utilities for elevator button configuration
  // Select first floor in range based on button position
  int selectFirstFloor(int row, int col) =>
      (row == 3 && col == 3) ? min: this[reversedButtonIndex[row][col] - 1] + 1;
  // Select last floor in range based on button position
  int selectLastFloor(int row, int col) =>
      (row == 0 && col == 3) ? max: this[reversedButtonIndex[row][col] + 1] - 1;
  // Calculate floor range difference for button configuration
  int selectDiffFloor(int row, int col) =>
      selectLastFloor(row, col) - selectFirstFloor(row, col) + 1;
  // Calculate selected floor number based on index and position
  int selectedFloor(int index, int row, int col) =>
      index + selectFirstFloor(row, col);
}