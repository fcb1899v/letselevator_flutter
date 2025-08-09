import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// =============================================================================
// APP CONFIGURATION
// =============================================================================

/// Application title displayed throughout the app
const String appTitle = "LETS ELEVATOR";

/// Firebase App Check providers for security validation
/// Uses debug providers in debug mode, production providers in release mode
final androidProvider = kDebugMode ? AndroidProvider.debug: AndroidProvider.playIntegrity;
final appleProvider = kDebugMode ? AppleProvider.debug: AppleProvider.deviceCheck;

// =============================================================================
// ELEVATOR CONFIGURATION
// =============================================================================

/// Elevator floor range configuration
/// Defines the minimum and maximum floors available in the elevator system
const int min = -6;  // Basement floors (B6)
const int max = 163; // Maximum floor (163F)

/// Elevator door operation timing constants
/// Controls the timing of door opening, closing, and waiting periods
const int initialOpenTime = 10; // Door opening duration in seconds
const int initialWaitTime = 2;  // Wait time after door opens in seconds
const int flashTime = 500;      // Flash animation duration in milliseconds
const int toolTipTime = 10000;  // Tooltip display duration in milliseconds
const int operationTime = 300;  // Operation button duration in milliseconds

/// Haptic feedback configuration for user interaction
const int vibTime = 200; // Vibration duration in milliseconds
const int vibAmp = 128;  // Vibration amplitude (0-255)

// =============================================================================
// ELEVATOR STATE MANAGEMENT
// =============================================================================

/// Door state boolean arrays for state management
/// Each array represents a specific door state: [opened, closed, opening, closing]
final List<bool> openedState = [true, false, false, false];
final List<bool> closedState = [false, true, false, false];
final List<bool> openingState = [false, false, true, false];
final List<bool> closingState = [false, false, false, true];

// =============================================================================
// BUTTON LAYOUT AND INDEXING
// =============================================================================

/// Button layout helper functions for 4x4 elevator panel
/// Manages button positioning and indexing for different floor layouts
bool isBasement(int row, int col) => (row == 3);
bool isNotSelectFloor(int row, int col) =>
    (col == 0 && row == 2) || (col == 3 && row == 0);

/// Reversed button index mapping for 4x4 panel layout
/// Maps visual button positions to logical indices
const List<List<int>> reversedButtonIndex = [
  [12, 13, 14, 15],
  [8, 9, 10, 11],
  [4, 5, 6, 7],
  [3, 2, 1, 0],
];

// =============================================================================
// 1000 BUTTON MODE CONFIGURATION
// =============================================================================

/// 1000 button mode panel configuration
/// Defines the layout and behavior for the 1000-button elevator simulation
const int panelMax = 9;    // Maximum number of panels
const int rowMax = 11;     // Maximum number of rows per panel
const int columnMax = 11;  // Maximum number of columns per panel

/// Row minus configuration for 1000 button layout
/// Defines special button configurations for each row
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

/// Local storage key for 30-second best score
const String lBID30Sec = "bestscore.30sec";

// =============================================================================
// AUDIO CONFIGURATION
// =============================================================================

/// Audio player configuration and sound file paths
/// Defines all audio assets used throughout the application
const String openSound = "assets/audios/pingpong.mp3";
const String closeSound = "assets/audios/ping.mp3";
const String countdown = "assets/audios/pon.mp3";
const String countdownFinish = "assets/audios/chan.mp3";
const String bestScoreSound = "assets/audios/jajan.mp3";
const String selectSound = "assets/audios/kako.mp3";
const String cancelSound = "assets/audios/hi.mp3";
const String changeModeSound = "assets/audios/popi.mp3";
const String callSound = "assets/audios/call.mp3";

// =============================================================================
// FONT CONFIGURATION
// =============================================================================

/// Font family definitions for different UI elements
/// Provides consistent typography across the application
const List<String> numberFont = ["lcd", "dseg", "dseg"];
const List<String> alphabetFont = ["lcd", "letsgo", "letsgo"];

// =============================================================================
// ASSET PATH CONFIGURATION
// =============================================================================

/// Asset folder paths for organized resource management
/// Centralizes all image asset locations for easy maintenance
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

// =============================================================================
// IMAGE ASSETS
// =============================================================================

/// Common UI element images used across multiple screens
const String silver = "${assetsCommon}metal.png";
const String wood = "${assetsCommon}wood.png";
const String matte = "${assetsCommon}marble.png";
const String buttonChan = "${assetsCommon}button.png";
const String pressedButtonChan = "${assetsCommon}pButton.png";
const String shimadaImage = "${assetsCommon}shimada.png";
const String transpImage = "${assetsCommon}transparent.png";
const String realTitleImage = "${assetsCommon}title1000Buttons.png";

/// 1000 button mode specific images
const String circleButton = "${assetsNormal}circle.png";
const String shimadaOpen = "${assets1000}sOpen.png";
const String pressedShimadaOpen = "${assets1000}sPressedOpen.png";
const String shimadaClose = "${assets1000}sClose.png";
const String pressedShimadaClose = "${assets1000}sPressedClose.png";
const String shimadaAlert = "${assets1000}sPhone.png";
const String pressedShimadaAlert = "${assets1000}sPressedPhone.png";

/// Menu and navigation related images
const String appLogo = "${assetsCommon}appTitle.png";
const String landingPageLogo = "${assetsMenu}web.png";
const String shopPageLogo = "${assetsMenu}cart.png";
const String youtubeLogo = "${assetsMenu}youtube.png";
const String privacyPolicyLogo = "${assetsMenu}privacyPolicy.png";
const String modeNormalButton = "${assetsMenu}modeNormal.png";
const String modeShimadaButton = "${assetsMenu}modeShimada.png";
const String mode1000Button = "${assetsMenu}mode1000.png";
const String rankingButton = "${assetsMenu}ranking.png";
const String settingsButton = "${assetsMenu}settings.png";
const String aboutShimadaButton = "${assetsMenu}aboutShimada.png";

// =============================================================================
// UI CUSTOMIZATION SETTINGS
// =============================================================================

/// Initial floor configuration for elevator simulation
const List<int> initialFloorNumbers = [
  -4, -3, -2, -1, 1, 2, 3, 4, 5, 6, 7, 8, 14, 100, 154, max,
];
List<bool> initialFloorStops = List.generate(initialFloorNumbers.length, (i) => (i != 8));

/// Default UI customization settings
const int initialButtonStyle = 0;
String initialBackgroundStyle = backgroundStyleList[0];
String initialButtonShape = buttonShapeList[1];

/// Settings configuration lists
const List<String> settingsItemList = [
  "button", "number", "style"
];
const List<String> buttonShapeList = [
  "normal", "circle", "square",
  "diamond", "hexagon", "clover",
  "star", "heart", "cat",
];
const List<String> backgroundStyleList = [
  "metal", "dark", "plastic", "wood", "marble", "old"
];

/// Margin adjustment factors for floor button numbers
const List<double> floorButtonNumberMarginFactor = [
  0.0, 0.0, 0.0,
  0.0, 0.0, 0.0,
  0.02, -0.016, 0.004,
];

/// Initial button lock states for premium features
List<bool> initialButtonLock = List.generate(buttonShapeList.length, (i) => (i > 2));

// =============================================================================
// EXTERNAL LINKS AND WEB PAGES
// =============================================================================

/// Landing page URLs for different languages
const String landingPageJa = "https://nakajimamasao-appstudio.web.app/elevator/ja/";
const String landingPageEn = "https://nakajimamasao-appstudio.web.app/elevator/";
const String privacyPolicyJa = "https://nakajimamasao-appstudio.web.app/terms/ja/";
const String privacyPolicyEn = "https://nakajimamasao-appstudio.web.app/terms/";

/// Social media and content links
const String youtubeJa = "https://www.youtube.com/watch?v=CQuYL0wG47E";
const String youtubeEn = "https://www.youtube.com/watch?v=oMhqBiNHAtA";
const String shopLink = "https://letselevator.designstore.jp";
const String twitterLink = "https://twitter.com/letselevator";
const String instagramLink = "https://www.instagram.com/letselevator/";

/// Shimada Electric related links in multiple languages
const String shimadaJa = "https://www.shimada.cc/oseba/";
const String shimadaZh = "https://www.gltjp.com/zh-hans/article/item/20908/";
const String shimadaEn = "https://www.gltjp.com/en/article/item/20908/";
const String shimadaKo = "https://www.gltjp.com/ko/article/item/20908/";

// =============================================================================
// COLOR DEFINITIONS
// =============================================================================

/// Primary colors
const Color lampColor = Color.fromRGBO(247, 178, 73, 1); //#f7b249
const Color transpLampColor = Color.fromRGBO(247, 178, 73, 0.7);
const Color blackColor = Color.fromRGBO(56, 54, 53, 1);
const Color whiteColor = Colors.white;
const Color transpColor = Colors.transparent;

/// Light colors for various UI elements
const Color lightBlueColor = Colors.lightBlue;
const Color goldLightColor = Color.fromRGBO(212, 175, 55, 1);
const Color pinkLightColor = Color.fromRGBO(255, 128, 192, 1);
const Color redLightColor = Color.fromRGBO(255, 64, 64, 1);
const Color blueLightColor = Color.fromRGBO(16, 192, 255, 1); //#10c0ff
const Color purpleLightColor = Color.fromRGBO(192, 128, 255, 1);
const Color greenLightColor = Color.fromRGBO(64, 255, 64, 1);
const Color lightGrayColor = Color.fromRGBO(192, 192, 192, 1);

/// Standard colors
const Color yellowColor = Color.fromRGBO(255, 234, 0, 1); //#ffea00
const Color greenColor = Color.fromRGBO(105, 184, 0, 1); //#69b800
const Color redColor = Color.fromRGBO(255, 0, 0, 1);
const Color grayColor = Colors.grey;
const Color darkBlackColor = Colors.black;

/// Transparent colors
const Color transpBlackColor = Color.fromRGBO(0, 0, 0, 0.6);
const Color transpWhiteColor = Color.fromRGBO(255, 255, 255, 0.95);
const Color transpDarkColor = Color.fromRGBO(0, 0, 0, 0.6);

/// Display color schemes
/// Background and text colors for different display themes
const List<Color> displayBackgroundColor = [
  darkBlackColor, darkBlackColor, lightBlueColor
];
const List<Color> displayNumberColor = [
  lampColor, whiteColor, whiteColor
];
const List<Color> numberColorList = [
  lampColor, lampColor, blueLightColor,
  redLightColor, purpleLightColor, greenLightColor,
  yellowColor, pinkLightColor, goldLightColor,
];

/// Color calculation notes

//＜Shimada's lamp　color＞
// [F7B249]
// Red = F7 = 247
// Green = B2 = 178
// Blue = 49 = 73

//＜Lamp color from temperature＞
// Temperature = 3000 K → FFB16E
// Red = 255 = FF
// Green = 99.47080 * Ln(30) - 161.11957 = 177 = B1
// Blue = 138.51773 * Ln(30-10) - 305.04480 = 110 = 6E


