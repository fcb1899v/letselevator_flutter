import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

///アプリ名
const String appTitle = "LETS ELEVATOR";

///App Check
final androidProvider = kDebugMode ? AndroidProvider.debug: AndroidProvider.playIntegrity;
final appleProvider = kDebugMode ? AppleProvider.debug: AppleProvider.deviceCheck;

///最高階と最低階
const int min = -6;
const int max = 163;

/// バイブレーション
const int vibTime = 200;
const int vibAmp = 128;

/// エレベータードアの開閉時間
const int initialOpenTime = 10; //[sec]
const int initialWaitTime = 2;  //[sec]
const int flashTime = 500;      //[msec]
const int snackBarTime = 3;     //[sec]

/// エレベータードアの状態
final List<bool> openedState = [true, false, false, false];
final List<bool> closedState = [false, true, false, false];
final List<bool> openingState = [false, false, true, false];
final List<bool> closingState = [false, false, false, true];

/// エレベーターボタンの状態
final List<bool> noPressed = [false, false, false];
final List<bool> pressedOpen = [true, false, false];
final List<bool> pressedClose = [false, true, false];
final List<bool> pressedCall = [false, false, true];
final List<bool> allPressed = [true, true, true];

/// Button Index
bool isBasement(int row, int col) => (row == 3);
int buttonCol(int row, int col) => isBasement(row, col) ? (1 - col) : col;
int buttonIndex(int row, int col) => 2 * (4 - row) + buttonCol(row, col);
bool isNotSelectFloor(int row, int col) =>
    (col == 0 && row == 2) || (col == 3 && row == 0);


const List<List<int>> reversedButtonIndex = [
  [12, 13, 14, 15],
  [8, 9, 10, 11],
  [4, 5, 6, 7],
  [3, 2, 1, 0],
];

/// 1000のボタン
const int panelMax = 9;
const int rowMax = 11;
const int columnMax = 11;
const List<List<int>> rowMinus = [
  [0, 0, 2, 0, 0, 0, 0, 0, 2, 0, 1],
  [0, 2, 0, 0, 0, 0, 1, 1, 0, 2, 0],
  [0, 0, 1, 0, 0, 0, 2, 0, 0, 0, 0],
  [0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0],
  [0, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0],
  [0, 1, 0, 0, 0, 0, 0, 0, 2, 0, 0],
  [0, 1, 0, 2, 0, 0, 0, 0, 2, 0, 0],
  [0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0],
  [0, 3, 0, 2, 0, 0, 3, 0, 0, 0, 0],
];
const String lBID30Sec = "bestscore.30sec";

///Audio
const int audioPlayerNumber = 1;
const String countdown = "audios/pon.mp3";
const String countdownFinish = "audios/chan.mp3";
const String bestScoreSound = "audios/jajan.mp3";
const String selectButton = "audios/kako.mp3";
const String cancelButton = "audios/hi.mp3";
const String changeModeSound = "audios/popi.mp3";
const String changePageSound = "audios/tetete.mp3";
const String callSound = "audios/call.mp3";

///Font
const String elevatorFont = "cornerstone";
const String normalFont = "roboto";
const List<String> numberFont = ["lcd", "dseg", "dseg"];
const List<String> alphabetFont = ["lcd", "letsgo", "letsgo"];

///Image Folder
const String assetsCommon = "assets/images/common/";
const String assetsMenu = "assets/images/menu/";
const String assetsNormal = "assets/images/normalMode/";
const String assets1000 = "assets/images/1000Mode/";
const String assetsRealOn = "assets/images/realOn/";
const String assetsRealOff = "assets/images/realOff/";
const String assetsReal1000On = "assets/images/real1000On/";
const String assetsReal1000Off = "assets/images/real1000Off/";
const String assetsButton = "assets/images/button/";
const String assetsSettings = "assets/images/settings/";

///Image File
const String silver = "${assetsCommon}metal.png";
const String wood = "${assetsCommon}wood.png";
const String matte = "${assetsCommon}marble.png";
const String buttonChan = "${assetsCommon}button.png";
const String pressedButtonChan = "${assetsCommon}pButton.png";
const String shimadaImage = "${assetsCommon}shimada.png";
const String transpImage = "${assetsCommon}transparent.png";
const String realTitleImage = "${assetsCommon}title1000Buttons.png";
const String beforeCountImage = "${assetsNormal}circle.png";
const String circleButton = "${assetsNormal}circle.png";
const String pressedCircle = "${assetsNormal}pressedCircle.png";
const String squareButton = "${assetsMenu}square.png";
const String openButton = "${assetsNormal}open.png";
const String pressedOpenButton = "${assetsNormal}pressedOpen.png";
const String closeButton = "${assetsNormal}close.png";
const String pressedCloseButton = "${assetsNormal}pressedClose.png";
const String alertButton = "${assetsNormal}phone.png";
const String pressedAlertButton = "${assetsNormal}pressedPhone.png";

const String shimadaOpen = "${assets1000}sOpen.png";
const String pressedShimadaOpen = "${assets1000}sPressedOpen.png";
const String shimadaClose = "${assets1000}sClose.png";
const String pressedShimadaClose = "${assets1000}sPressedClose.png";
const String shimadaAlert = "${assets1000}sPhone.png";
const String pressedShimadaAlert = "${assets1000}sPressedPhone.png";

///Menu
const String appLogo = "${assetsCommon}appTitle.png";
const String landingPageLogo = "${assetsMenu}web.png";
const String shopPageLogo = "${assetsMenu}cart.png";
const String twitterLogo = "${assetsMenu}x.png";
const String instagramLogo = "${assetsMenu}instagram.png";
const String youtubeLogo = "${assetsMenu}youtube.png";
const String privacyPolicyLogo = "${assetsMenu}privacyPolicy.png";
const String modeNormalButton = "${assetsMenu}modeNormal.png";
const String modeShimadaButton = "${assetsMenu}modeShimada.png";
const String mode1000Button = "${assetsMenu}mode1000.png";
const String rankingButton = "${assetsMenu}ranking.png";
const String settingsButton = "${assetsMenu}settings.png";
const String aboutShimadaButton = "${assetsMenu}aboutShimada.png";

///Button Settings
const List<int> initialFloorNumbers = [
  -4, -3, -2, -1, 1, 2, 3, 4, 5, 6, 7, 8, 14, 100, 154, max,
];
List<bool> initialFloorStops = List.generate(initialFloorNumbers.length, (i) => (i != 8));
const int initialButtonStyle = 0;
String initialBackgroundStyle = backgroundStyleList[0];
String initialButtonShape = buttonShapeList[1];
const List<Color> displayBackgroundColor = [darkBlackColor, darkBlackColor, lightBlueColor];
const List<Color> displayNumberColor = [lampColor, whiteColor, whiteColor];
const List<String> settingsItemList = ["button", "number", "style"];
const List<String> buttonShapeList = [
  "normal", "circle", "square",
  "diamond", "hexagon", "clover",
  "star", "heart", "cat",
];
const List<String> backgroundStyleList = ["metal", "dark", "plastic", "wood", "marble", "old"];
const List<Color> numberColorList = [
  lampColor, lampColor, blueLightColor,
  redLightColor, purpleLightColor, greenLightColor,
  yellowColor, pinkLightColor, goldLightColor,
];
const List<double> floorButtonNumberMarginFactor = [
  0.0, 0.0, 0.0,
  0.0, 0.0, 0.0,
  0.02, -0.016, 0.004,
];
List<bool> initialButtonLock = List.generate(buttonShapeList.length, (i) => (i > 2));


///Web Page
const String landingPageJa = "https://nakajimamasao-appstudio.web.app/elevator/ja/";
const String landingPageEn = "https://nakajimamasao-appstudio.web.app/elevator/";
const String privacyPolicyJa = "https://nakajimamasao-appstudio.web.app/terms/ja/";
const String privacyPolicyEn = "https://nakajimamasao-appstudio.web.app/terms/";
const String youtubeJa = "https://www.youtube.com/watch?v=CQuYL0wG47E";
const String youtubeEn = "https://www.youtube.com/watch?v=oMhqBiNHAtA";
const String shopLink = "https://letselevator.designstore.jp";
const String twitterLink = "https://twitter.com/letselevator";
const String instagramLink = "https://www.instagram.com/letselevator/";
const String shimadaJa = "https://www.shimada.cc/oseba/";
const String shimadaZh = "https://www.gltjp.com/zh-hans/article/item/20908/";
const String shimadaEn = "https://www.gltjp.com/en/article/item/20908/";
const String shimadaKo = "https://www.gltjp.com/ko/article/item/20908/";

/// Color
const Color lampColor = Color.fromRGBO(247, 178, 73, 1);  //
const Color transpLampColor = Color.fromRGBO(247, 178, 73, 0.7);
const Color lightBlueColor = Colors.lightBlue;
const Color goldLightColor = Color.fromRGBO(212, 175, 55, 1);
const Color pinkLightColor = Color.fromRGBO(255, 128, 192, 1);
const Color redLightColor = Color.fromRGBO(255, 64, 64, 1);
const Color blueLightColor = Color.fromRGBO(16, 192, 255, 1); //#10c0ff
const Color purpleLightColor = Color.fromRGBO(192, 128, 255, 1);
const Color greenLightColor = Color.fromRGBO(64, 255, 64, 1);
const Color yellowColor = Color.fromRGBO(255, 234, 0, 1); //#ffea00
const Color greenColor = Color.fromRGBO(105, 184, 0, 1); //#69b800
const Color redColor = Color.fromRGBO(255, 0, 0, 1);
const Color blackColor = Color.fromRGBO(56, 54, 53, 1);
const Color grayColor = Colors.grey;
const Color transpBlackColor = Color.fromRGBO(0, 0, 0, 0.8);
const Color transpDarkColor = Color.fromRGBO(0, 0, 0, 0.6);
const Color darkBlackColor = Colors.black;
const Color transpWhiteColor = Color.fromRGBO(255, 255, 255, 0.95);
const Color whiteColor = Colors.white;
const Color transpColor = Colors.transparent;
const Color metalColor1 = Colors.black12;
const Color metalColor2 = Colors.white24;
const Color metalColor3 = Colors.white54;
const Color metalColor4 = Colors.white10;
const Color metalColor5 = Colors.black12;
const List<Color> metalColor = [metalColor1, metalColor2, metalColor3, metalColor4, metalColor5];
const List<double> metalSort = [0.1, 0.3, 0.4, 0.7, 0.9];

//＜島田電機の電球色lampColor＞
// 島田電機の電球色 → F7B249
// Red = F7 = 247
// Green = B2 = 178
// Blue = 49 = 73

//＜色温度から算出する電球色lampColor＞
// Temperature = 3000 K → FFB16E
// Red = 255 = FF
// Green = 99.47080 * Ln(30) - 161.11957 = 177 = B1
// Blue = 138.51773 * Ln(30-10) - 305.04480 = 110 = 6E


// ///最高階と最低階
// const int maxBLE = 100;
// const int minBLE = 1;
//
// ///Floors
// const floors = [1, 2, 3, 100];
//
// ///UUID
// const serviceUUID = "";
// const characteristicTXUUID = "";
// const characteristicRXUUID = "";
//
// //
// const deviceName = "ESP32";

