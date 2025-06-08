import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'sound_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constant.dart';
import 'l10n/app_localizations.dart' show AppLocalizations;

extension StringExt on String {

  ///Common
  void debugPrint() {
    if (kDebugMode) print(this);
  }

  //SharedPreferences this is key
  void setSharedPrefString(SharedPreferences prefs, String value) {
    "${replaceAll("Key", "")}: $value".debugPrint();
    prefs.setString(this, value);
  }
  void setSharedPrefInt(SharedPreferences prefs, int value) {
    "${replaceAll("Key", "")}: $value".debugPrint();
    prefs.setInt(this, value);
  }
  void setSharedPrefBool(SharedPreferences prefs, bool value) {
    "${replaceAll("Key", "")}: $value".debugPrint();
    prefs.setBool(this, value);
  }
  void setSharedPrefListString(SharedPreferences prefs, List<String> value) {
    "${replaceAll("Key", "")}: $value".debugPrint();
    prefs.setStringList(this, value);
  }
  void setSharedPrefListInt(SharedPreferences prefs, List<int> value) {
    for (int i = 0; i < value.length; i++) {
      prefs.setInt("$this$i", value[i]);
    }
    "${replaceAll("Key", "")}: $value".debugPrint();
  }
  void setSharedPrefListBool(SharedPreferences prefs, List<bool> value) {
    for (int i = 0; i < value.length; i++) {
      prefs.setBool("$this$i", value[i]);
    }
    "${replaceAll("Key", "")}: $value".debugPrint();
  }
  String getSharedPrefString(SharedPreferences prefs, String defaultString) {
    String value = prefs.getString(this) ?? defaultString;
    "${replaceAll("Key", "")}: $value".debugPrint();
    return value;
  }
  int getSharedPrefInt(SharedPreferences prefs, int defaultInt) {
    int value = prefs.getInt(this) ?? defaultInt;
    "${replaceAll("Key", "")}: $value".debugPrint();
    return value;
  }
  bool getSharedPrefBool(SharedPreferences prefs, bool defaultBool) {
    bool value = prefs.getBool(this) ?? defaultBool;
    "${replaceAll("Key", "")}: $value".debugPrint();
    return value;
  }
  List<String> getSharedPrefListString(SharedPreferences prefs, List<String> defaultList) {
    List<String> values = prefs.getStringList(this) ?? defaultList;
    "${replaceAll("Key", "")}: $values".debugPrint();
    return values;
  }
  List<int> getSharedPrefListInt(SharedPreferences prefs, List<int> defaultList) {
    List<int> values = [];
    for (int i = 0; i < defaultList.length; i++) {
      int v = prefs.getInt("$this$i") ?? defaultList[i];
      values.add(v);
    }
    "${replaceAll("Key", "")}: $values".debugPrint();
    return (values == []) ? defaultList: values;
  }
  List<bool> getSharedPrefListBool(SharedPreferences prefs, List<bool> defaultList) {
    List<bool> values = [];
    for (int i = 0; i < defaultList.length; i++) {
      bool v = prefs.getBool("$this$i") ?? defaultList[i];
      values.add(v);
    }
    "${replaceAll("Key", "")}: $values".debugPrint();
    return (values == []) ? defaultList: values;
  }

  String backGroundImage() => "$assetsCommon$this.png";

  int buttonShapeIndex() => buttonShapeList.contains(this) ? buttonShapeList.indexOf(this): 0;
}

extension ContextExt on BuildContext {

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

  ///Common
  double width() => MediaQuery.of(this).size.width;
  double height() => MediaQuery.of(this).size.height;
  String lang() => Localizations.localeOf(this).languageCode;
  void popPage() => Navigator.pop(this);

  ///Text to Speech
  String ttsLang() =>
      (lang() != "en") ? lang(): "en";
  String ttsVoice() =>
      (lang() == "ja") ? "ja-JP":
      (lang() == "ko") ? "ko-KR":
      (lang() == "zh") ? "zh-CN":
      "en-US";
  String voiceName(bool isAndroid) =>
      isAndroid ? (
          lang() == "ja" ? "ja-JP-language":
          lang() == "ko" ? "ko-KR-language":
          lang() == "zh" ? "ko-CN-language":
          "en-US-language"
      ): (
          lang() == "ja" ? "Kyoko":
          lang() == "ko" ? "Yuna":
          lang() == "zh" ? "Lili":
          "Samantha"
      );

  ///Progress Indicator
  double circleSize() => ((height() > width()) ? width(): height()) * 0.1;
  double circleStrokeWidth() => ((height() > width()) ? width(): height()) * 0.012;

  ///LETS ELEVATOR
  String thisApp() => AppLocalizations.of(this)!.thisApp;
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

  ///1000 Buttons
  String newRecord() => AppLocalizations.of(this)!.newRecord;
  String best() => AppLocalizations.of(this)!.best;
  String start() => AppLocalizations.of(this)!.start;
  String challenge() => AppLocalizations.of(this)!.challenge;
  String yourScore() => AppLocalizations.of(this)!.yourScore;

  ///Settings
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
  String unlockAll() => AppLocalizations.of(this)!.unlockAll;

  ///Menu
  String menu() => AppLocalizations.of(this)!.menu;
  String back() => AppLocalizations.of(this)!.back;
  String ranking() => AppLocalizations.of(this)!.ranking;
  String normalMode() => AppLocalizations.of(this)!.normalMode;
  String elevatorMode() => AppLocalizations.of(this)!.elevatorMode;
  String buttonsMode() => AppLocalizations.of(this)!.buttonsMode;
  String aboutButtons() => AppLocalizations.of(this)!.aboutButtons;
  String shimax() => AppLocalizations.of(this)!.aboutShimax;
  String letsElevator() => AppLocalizations.of(this)!.aboutLetsElevator;
  String terms() => AppLocalizations.of(this)!.terms;
  String officialPage() =>  AppLocalizations.of(this)!.officialPage;
  String officialShop() => AppLocalizations.of(this)!.officialShop;
  String reproButtons() => AppLocalizations.of(this)!.reproButtons;
  String challengeRanking() => AppLocalizations.of(this)!.challengeRanking;
  String shimaxLink() =>
    (lang() == "ja") ? shimadaJa:
    (lang() == "zh") ? shimadaZh:
    (lang() == "ko") ? shimadaKo: shimadaEn;
  String landingPageLink() => (lang() == "ja") ? landingPageJa: landingPageEn;
  String privacyPolicyLink() => (lang() == "ja") ? privacyPolicyJa: privacyPolicyEn;
  String youtubeLink() => (lang() == "ja") ? youtubeJa: youtubeEn;

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

  ///Responsible
  double responsible() => (height() < 1000) ? height(): 1000;
  double widthResponsible() => (width() < 600) ? width(): 600;

  ///Display
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

  ///Button
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

  ///Admob
  double admobHeight() => (height() < 600) ? 50: (height() < 1000) ? 50 + (height() - 600) / 8: 100;
  double admobWidth() => width() - 100;

  ///Menu
  double menuTitleFontSize() => height() * (lang() == "en" ? 0.05: 0.032);
  double menuButtonSize() => widthResponsible() * 0.33;
  double menuButtonMargin() => responsible() * 0.05;
  double menuLinksLogoSize() => widthResponsible() * 0.16;
  double menuLinksTitleSize() => widthResponsible() *  (lang() == "en" ? 0.030: 0.025);
  double menuLinksTitleMargin() => widthResponsible() * 0.02;
  double menuLinksMargin() => widthResponsible() * 0.04;

  ///Settings
  //Divider
  double settingsDividerHeight() => height() * 0.015;
  double settingsDividerThickness() => height() * 0.001;
  //Lock
  double settingsLockSize() => height() * 0.10;
  double settingsLockFontSize() => height() * 0.01;
  double settingsLockIconSize() => height() * 0.035;
  double settingsLockMargin() => height() * 0.01;
  double settingsAllLockIconSize() => height() * 0.05;
  double settingsAllLockIconMargin() => height() * 0.01;
  double settingsAllLockFontSize() => height() * 0.022;
  double settingsLockFreeButtonWidth() => height() * 0.08;
  double settingsLockFreeButtonHeight() => height() * 0.03;
  double settingsLockFreeBorderRadius() => height() * 0.015;
  double settingsLockFreeFontSize() => height() * 0.018;
  //Select button
  double settingsSelectButtonSize() => height() * 0.06;
  double settingsSelectButtonIconSize() => height() * 0.03;
  double settingsSelectButtonMarginTop() => height() * 0.015;
  double settingsSelectButtonMarginBottom() => height() * 0.007;
  //Change button number
  double settingsButtonSize() => height() * 0.07;
  double settingsNumberButtonHeight() => height() * 0.142;
  double settingsNumberButtonWidth() => height() * 0.07;
  double settingsNumberButtonFontSize() => height() * 0.03;
  double settingsNumberButtonMargin() => height() * 0.02;
  //Change floor stop
  double settingsFloorStopFontSize() => height() * 0.015;
  double settingsFloorStopMargin() => height() * 0.005;
  //Change button style
  double settingsButtonStyleSize() => height() * 0.07;
  double settingsButtonStyleMargin() => height() * 0.03;
  double settingsButtonStyleLockWidth() => width() * 0.90;
  double settingsButtonStyleLockHeight() => height() * 0.19;
  double settingsButtonStyleLockMargin() => height() * 0.095;
  //Change button shape
  double settingsButtonShapeSize() => height() * 0.07;
  double settingsButtonShapeFontSize() => height() * 0.022;
  double settingsButtonShapeMargin() => height() * 0.005;
  //Change background image
  double settingsBackgroundSize() => height() * 0.17;
  double settingsBackgroundMargin() => height() * 0.04;
  double settingsBackgroundSelectBorderWidth() =>  height() * 0.007;
  double settingsBackgroundStyleLockWidth() => width() * 0.90;
  double settingsBackgroundStyleLockHeight() => height() * 0.42;
  double settingsBackgroundStyleLockMargin() => height() * 0.23;
  //Settings Alert Dialog
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

  ///1000 Buttons
  double logo1000ButtonsWidth() => widthResponsible() * 0.5;
  double logo1000ButtonsPadding() => widthResponsible() * 0.01;
  double challengeStartButtonWidth() => widthResponsible() * 0.2;
  double challengeStartButtonHeight() => widthResponsible() * 0.125;
  double challengeButtonFontSize() => widthResponsible() * ((lang() == "ja" || lang() == "en") ? 0.022: 0.03);
  double challengeStartFontSize() => widthResponsible() * 0.04;
  double countdownFontSize() => widthResponsible() * 0.075;
  double countdownPaddingTop() => widthResponsible() * 0.007;
  double countdownPaddingLeft() => widthResponsible() *  0.01;
  double countdownPaddingBottom() => widthResponsible() * 0.006;
  double countDisplayWidth() => widthResponsible() * 0.28;
  double countDisplayHeight() => widthResponsible() * 0.12;
  double countDisplayPaddingLeft() => widthResponsible() * 0.012;
  double countDisplayPaddingBottom() => widthResponsible() * 0.01;
  double beforeCountdownCircleSize() => widthResponsible() * 0.4;
  double beforeCountdownNumberSize() => widthResponsible() * 0.2;
  double yourScoreFontSize() => widthResponsible() * 0.24;
  double bestScoreFontSize() => widthResponsible() * 0.12;
  double scoreTitleFontSize() => widthResponsible() * 0.09;
  double bestFontSize() => widthResponsible() * 0.09;
  double backButtonFontSize() => widthResponsible() * 0.045;
  double backButtonWidth() => widthResponsible() * 0.3;
  double backButtonHeight() => widthResponsible() * 0.1;
  double backButtonBorderRadius() => widthResponsible() * 0.02;
  double defaultButtonLength() => 0.07 * height() - 2;
  double buttonWidth(int p, i, j) => p.buttonWidthFactor(i, j) * defaultButtonLength();
  double buttonHeight() => defaultButtonLength();
  double largeButtonWidth(double ratio) => ratio * defaultButtonLength();
  double largeButtonHeight(double ratio) => ratio * defaultButtonLength();
  double buttonsPadding() => (height() < 1100) ? 0.014 * height() - 3: 12.4 + 0.038 * (height() - 1100);
  double startBorderWidth() => (width() < 800) ? width() / 400: 2.0;
  double startCornerRadius() => (width() < 800) ? width() / 40: 20.0;
  double dividerHeight() => height() * 0.72;
  double dividerMargin() => widthResponsible() * 0.03;
}

extension IntExt on int {

  ///Settings
  //this is selected number
  String selected(int i) => (this == i) ? "Pressed": "";
  String settingsButton(int i) => "$assetsSettings${settingsItemList[i]}Settings${selected(i)}.png";
  //this is operationButtonStyleNumber
  String openButton() => "${assetsButton}open${this + 1}.png";
  String closeButton() => "${assetsButton}close${this + 1}.png";
  String alertButton() => "${assetsButton}phone${this + 1}.png";
  String pressedOpenButton() => "${assetsButton}open${this + 1}Pressed.png";
  String pressedCloseButton() => "${assetsButton}close${this + 1}Pressed.png";
  String pressedAlertButton() => "${assetsButton}phone${this + 1}Pressed.png";

  int listNum(int row, int col) => this * row + col;

  ///Floor Sound
  String enRankNumber() =>
      (abs() % 10 == 1 && abs() ~/ 10 != 1) ? "${abs()}st ":
      (abs() % 10 == 2 && abs() ~/ 10 != 1) ? "${abs()}nd ":
      (abs() % 10 == 3 && abs() ~/ 10 != 1) ? "${abs()}rd ":
      "${abs()}th ";

  ///Display
  // this is counter
  String displayNumber() =>
      (this == max) ? "R":
      (this == 0) ? "G":
      (this < 0) ? "B${abs()}":
      "$this";

  String displayNumberHeader() =>
      (this == max) ? "R":
      (this == 0) ? "G":
      (this < 0) ? "B":
      " ";

  String arrowImage(bool isMoving, int nextFloor, int buttonStyle) =>
      (isMoving && this < nextFloor) ? "${assetsCommon}up${buttonStyle + 1}.png":
      (isMoving && this > nextFloor) ? "${assetsCommon}down${buttonStyle + 1}.png":
      transpImage;

  ///Speed
  //this is i
  int elevatorSpeed(int count, int nextFloor) {
    int l = (this - nextFloor).abs();
    return (count < 2 || l < 2) ? 2000:
    (count < 5 || l < 5) ? 1000:
    (count < 10 || l < 10) ? 500:
    (count < 20 || l < 20) ? 250: 100;
  }

  ///Button
  //this is i
  String buttonNumber() =>
      (this == max) ? "R":
      (this == 0) ? "G":
      (this < 0) ? "B${abs()}":
      "$this";

  //this is i and counter.
  bool isSelected({
    required List<bool> up,
    required List<bool> down
  }) => (this > 0) ? up[this]: down[this * (-1)];

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

  Color floorButtonNumberColor({
    required List<bool> up,
    required List<bool> down,
    required int style,
    required String shape,
  }) => (style != 0) ? blackColor:
    isSelected(up: up, down: down).floorButtonNumberColor(shape);

  //this is counter.
  void clearUpperFloor(List<bool> isAboveSelectedList, isUnderSelectedList) {
    for (int j = max; j > this - 1; j--) {
      if (j > 0) isAboveSelectedList[j] = false;
      if (j < 0) isUnderSelectedList[j * (-1)] = false;
    }
  }

  //this is counter.
  void clearLowerFloor(List<bool> isAboveSelectedList, isUnderSelectedList) {
    for (int j = min; j < this + 1; j++) {
      if (j > 0) isAboveSelectedList[j] = false;
      if (j < 0) isUnderSelectedList[j * (-1)] = false;
    }
  }

  //this is counter.
  List<int> upFromToNumber(int nextFloor) {
    List<int> floorList = [];
    for (int i = this + 1; i < nextFloor + 1; i++) {
      floorList.add(i);
    }
    return floorList;
  }

  //this is counter
  List<int> downFromToNumber(int nextFloor) {
    List<int> floorList = [];
    for (int i = this - 1; i > nextFloor - 1; i--) {
      floorList.add(i);
    }
    return floorList;
  }

  // this is counter
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

  // this is counter
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

  //this is i.
  void trueSelected({
    required List<bool> up,
    required List<bool> down,
  }) {
    if (this > 0) up[this] = true;
    if (this < 0) down[this * (-1)] = true;
  }

  //this is i.
  void falseSelected({
    required List<bool> up,
    required List<bool> down,
  }) {
    if (this > 0) up[this] = false;
    if (this < 0) down[this * (-1)] = false;
  }

  //this is i
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

  ///1000 Buttons
  bool isTranspButton(int i, j) =>
      //panel 2
      (this == 1 && i == 2 && j == 7) ? true:
      //panel 4
      (this == 3 && i == 9 && j == 3) ? true:
      false;

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

  String countNumber() =>
      (this > 999) ? "$this":
      (this > 99) ? "0$this":
      (this > 9) ? "00$this":
      "000$this";

  String countDownNumber() =>
      (this > 9) ? "$this": "0$this";

  Color startButtonColor() =>
      (this == 0) ? redColor:
      (this % 2 == 1) ? blackColor:
      (this < 10) ? yellowColor:
      greenColor;

  List<List<List<bool>>> listListAllFalse(int rowMax, int columnMax) =>
      List.generate(this, (_) => List.generate(rowMax, (_) => List.generate(columnMax, (_) => false)));

  List<List<List<bool>>> listListAllTrue(int rowMax, int columnMax) =>
      List.generate(this, (_) => List.generate(rowMax, (_) => List.generate(columnMax, (_) => true)));
}

extension BoolExt on bool {

  ///This is isPressed
  String pressed() => this ? 'Pressed': '';
  String numberBackground(int buttonStyle, String buttonShape) => "$assetsButton$buttonShape${buttonStyle + 1}${pressed()}.png";
  Color numberColor(int i) => this ? numberColorList[i]: whiteColor;
  Color floorButtonNumberColor(String buttonShape) => numberColor(buttonShape.buttonShapeIndex());
  String shimadaButtonImage(int row, int col) =>
      '$assets1000${this ? "p": ""}${initialFloorNumbers.toReversedMatrix(4)[row][col].buttonNumber()}.png';

  ///This is isBasement
  int floorSymbol() => this ? -1: 1;
  int selectedFloorNumber(int index) => floorSymbol() * (index + 1);
  // int selectFirstFloor(List<int> floorNumbers, int buttonIndex) =>
  //     this ? 1: floorNumbers[buttonIndex - 1] + 1;
  // int selectLastFloor(List<int> floorNumbers, int buttonIndex)  =>
  //     this ? 5: floorNumbers[buttonIndex + 1];
  // int selectDiffFloor(List<int> floorNumbers, int buttonIndex) =>
  //     selectLastFloor(floorNumbers, buttonIndex) - selectFirstFloor(floorNumbers, buttonIndex);
  // int selectInitialIndex(List<int> floorNumbers, int buttonIndex) =>
  //     this ? -1 * (floorNumbers[buttonIndex] + 1): (floorNumbers[buttonIndex] - selectFirstFloor(floorNumbers, buttonIndex));

  ///This is isHome
  String modeChangeButton(bool isShimada) => (this && !isShimada) ? modeShimadaButton: modeNormalButton;
  String modeChallengeButton(bool isGamesSignIn) => (!this && isGamesSignIn) ? rankingButton: mode1000Button;

  ///This is isShimada
  String buttonChanBackGround() => (this) ? pressedButtonChan: buttonChan;
  String openBackGround(bool isPressed, int buttonStyle) => (this) ?
      ((isPressed) ? pressedShimadaOpen: shimadaOpen):
      ((isPressed) ? buttonStyle.pressedOpenButton(): buttonStyle.openButton());
  String closeBackGround(bool isPressed, int buttonStyle) => (this) ?
      ((isPressed) ? pressedShimadaClose: shimadaClose):
      ((isPressed) ? buttonStyle.pressedCloseButton(): buttonStyle.closeButton());
  String phoneBackGround(bool isPressed, int buttonStyle) => (this) ?
      ((isPressed) ? pressedShimadaAlert: shimadaAlert):
      ((isPressed) ?  buttonStyle.pressedAlertButton(): buttonStyle.alertButton());

  List<String> operateBackGround(List<bool> isPressedList, int buttonStyle) => [
    openBackGround(isPressedList[0], buttonStyle),
    closeBackGround(isPressedList[1], buttonStyle),
    phoneBackGround(isPressedList[2], buttonStyle)
  ];

  //This is isMenu
  Future<bool> pressedMenu() async {
    await AudioManager().playEffectSound(index: 0, asset: selectButton, volume: 1.0);
    await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
    return !this;
  }
  
}

extension ListListListBoolExt on List<List<List<bool>>> {

  String buttonImage(int p, i, j) =>
      // Large Buttons => Transparent
      (p.isTranspButton(i, j)) ? transpImage:
      // not have Buttons => Random
      (p.isNotHaveButton(i, j) && this[p][i][j]) ? "${assetsRealOn}xp${(19 * i + 13 * j) % 184 + 1}.png":
      (p.isNotHaveButton(i, j)) ? "${assetsRealOff}x${(19 * i + 13 * j) % 184 + 1}.png":
      // Other Buttons
      (this[p][i][j]) ? "${assetsReal1000On}p${p + 1}/p${p + 1}_${i + 1}_${j + 1}.png":
      "$assetsReal1000Off${p + 1}/${p + 1}_${i + 1}_${j + 1}.png";
}

extension ListBoolExt on List<bool> {

  List<String> operationButtonImage(int buttonStyle) => [
    false.openBackGround(this[0], buttonStyle),
    false.closeBackGround(this[1], buttonStyle),
    false.phoneBackGround(this[2], buttonStyle),
  ];
}

extension ListDynamicExt<T> on List<T> {

  List<List<T>> toMatrix(int n) =>
      [for (var i = 0; i < length; i += n) sublist(i, (i + n <= length) ? i + n : length)];

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

  int selectFirstFloor(int row, int col) =>
      (row == 3 && col == 3) ? min: this[reversedButtonIndex[row][col] - 1] + 1;
  int selectLastFloor(int row, int col) =>
      (row == 0 && col == 3) ? max: this[reversedButtonIndex[row][col] + 1] - 1;
  int selectDiffFloor(int row, int col) =>
      selectLastFloor(row, col) - selectFirstFloor(row, col) + 1;
  int selectedFloor(int index, int row, int col) =>
      index + selectFirstFloor(row, col);
}