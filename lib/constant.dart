import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ===== APP CONFIGURATION =====

/// Application title displayed throughout the app
const String appTitle = "LETS ELEVATOR";

/// RevenueCat configuration. Keys come from assets/.env; the entitlement id matches
/// LETS ELEVATOR NEO on purpose so both apps report into the same shape
String revenueCatApiKey = (Platform.isIOS || Platform.isMacOS) ?
  "REVENUE_CAT_IOS_API_KEY":
  "REVENUE_CAT_ANDROID_API_KEY";
const String premiumEntitlementID = "premium";

/// Game Center best score that unlocks every button without paying or watching
/// an ad. Named here because the lock checks and the analytics both need it
const int unlockAllBestScore = 100;


// ===== ELEVATOR CONFIGURATION =====

/// Elevator floor range configuration
/// Defines the minimum and maximum floors available in the elevator system
const int min = -6;  // Basement floors (B6)
const int max = 163; // Maximum floor (163F)

/// Elevator door operation timing constants
/// Controls the timing of door opening, closing, and waiting periods
const int initialOpenTime = 10; // Door opening duration in seconds
const int initialWaitTime = 2;  // Wait time after door opens in seconds
const int flashTime = 500;      // Flash animation duration in milliseconds
const int operationTime = 300;  // Operation button duration in milliseconds

/// Haptic feedback configuration for user interaction
const int vibTime = 200; // Vibration duration in milliseconds
const int vibAmp = 128;  // Vibration amplitude (0-255)

// ===== ELEVATOR STATE MANAGEMENT =====

/// Door state boolean arrays for state management
/// Each array represents a specific door state: [opened, closed, opening, closing]
final List<bool> openedState = [true, false, false, false];
final List<bool> closedState = [false, true, false, false];
final List<bool> openingState = [false, false, true, false];
final List<bool> closingState = [false, false, false, true];

// ===== BUTTON LAYOUT AND INDEXING =====

/// Button layout helper functions for 4x4 elevator panel
/// Manages button positioning and indexing for different floor layouts
bool isBasement(int row, int col) => (row == 3);
/// How far the two 1F controls are faded. They are dimmed rather than covered:
/// a black plate over the cell hides the floor number itself
const double fixedFloorOpacity = 0.35;

/// CupertinoSwitch fades itself by 0.5 when onChanged is null
/// (`cupertino/switch.dart` _kDisabledOpacity), so the switch needs a
/// lighter touch to land on the same 0.35 as the button beside it
const double fixedFloorSwitchOpacity = fixedFloorOpacity * 2;

/// Only 1F is fixed. The top and the bottom move too, within the range above
bool isNotSelectFloor(int row, int col) => (col == 0 && row == 2);

/// The last stop above or below 1F cannot be turned off: the car needs
/// somewhere to go on each side of the fixed floor
bool isOnlyStop(List<bool> stops, int index) {
  if (!stops[index]) return false;
  for (int i = 0; i < stops.length; i++) {
    if (i == index || i == oneFloorIndex) continue;
    if ((i < oneFloorIndex) == (index < oneFloorIndex) && stops[i]) return false;
  }
  return true;
}

/// The gap a button may move within: strictly between its neighbours, inside
/// min..max, and never floor 0. Both the picker and the save use this
bool isInFloorGap(List<int> list, int index, int value) {
  if (value == 0 || value < min || max < value) return false;
  if (index == oneFloorIndex) return false;
  if (index > 0 && value <= list[index - 1]) return false;
  if (index < list.length - 1 && value >= list[index + 1]) return false;
  return true;
}

/// A saved panel from an older build may break the rule above: before the
/// pickers were bounded, the basement buttons could be set independently. Repair
/// what is broken and keep the rest, rather than throw the whole panel away
List<int> normalizedFloorNumbers(List<int> numbers) {
  if (numbers.length != initialFloorNumbers.length) return initialFloorNumbers;
  final list = List<int>.from(numbers)..[oneFloorIndex] = 1;
  for (int i = oneFloorIndex - 1; i >= 0; i--) {
    if (list[i] >= list[i + 1]) list[i] = list[i + 1] - 1;
    if (list[i] == 0) list[i] = -1;
  }
  for (int i = oneFloorIndex + 1; i < list.length; i++) {
    if (list[i] <= list[i - 1]) list[i] = list[i - 1] + 1;
  }
  // Pushing can run off either end. Nothing sensible is left to keep there
  if (list.first < min || max < list.last) return initialFloorNumbers;
  return list;
}

/// Each side of 1F needs a stop. A save made before that rule may have none
List<bool> normalizedFloorStops(List<bool> stops) {
  if (stops.length != initialFloorStops.length) return initialFloorStops;
  final list = List<bool>.from(stops)..[oneFloorIndex] = true;
  if (!list.sublist(0, oneFloorIndex).contains(true)) list[oneFloorIndex - 1] = true;
  if (!list.sublist(oneFloorIndex + 1).contains(true)) list[oneFloorIndex + 1] = true;
  return list;
}

/// Reversed button index mapping for 4x4 panel layout
/// Maps visual button positions to logical indices
const List<List<int>> reversedButtonIndex = [
  [12, 13, 14, 15],
  [8, 9, 10, 11],
  [4, 5, 6, 7],
  [3, 2, 1, 0],
];

// ===== 1000 BUTTON MODE CONFIGURATION =====

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

// ===== AUDIO CONFIGURATION =====

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

// ===== FONT CONFIGURATION =====

/// Font family definitions for different UI elements
/// Provides consistent typography across the application
const List<String> numberFont = ["lcd", "dseg", "dseg"];
const List<String> alphabetFont = ["lcd", "letsgo", "letsgo"];

// ===== ASSET PATH CONFIGURATION =====

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

// ===== IMAGE ASSETS =====

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
const String purchaseButton = "${assetsMenu}purchase.png";

// ===== UI CUSTOMIZATION SETTINGS =====

/// Initial floor configuration for elevator simulation
const List<int> initialFloorNumbers = [
  -6, -4, -2, -1, 1, 2, 3, 4, 5, 6, 7, 8, 14, 100, 154, max,
];

/// The floor buttons that start locked, each list in the order it opens.
/// One lock covers both the floor number and the stop switch of that button.
/// 1F never moves, and the buttons next to it stay free so the panel is usable
/// from the first launch
const List<List<int>> floorUnlockOrders = [
  [11, 12, 13, 14, 15],  // 8F and up
  [2, 1, 0],             // B2, B4, B6
];

/// Saved under its own name, beside the shape and background locks
String floorLockKey(int i) => "floorLockKey$i";

/// Lock plate geometry, as plain arithmetic so it can be checked without a
/// screen. The plate holds the Unlock pill and the invisible tap padding around
/// it, and is capped by the width so four plates always fit on a row
const double lockPillWidthFactor = 0.08;
const double lockPillPaddingFactor = 0.008;
const double lockPlateHeightFactor = 0.098;
const double lockPlatesPerRow = 4.4;

double floorLockPlateWidth(double width, double height) {
  final byHeight = height * lockPlateHeightFactor;
  final byWidth = width / lockPlatesPerRow;
  return (byHeight < byWidth) ? byHeight : byWidth;
}

/// What sits inside the plate: the Unlock pill, and the floor cell the plate
/// covers. Both want 0.08h and both give way to the plate, so the plate is never
/// narrower than the thing it hides
double lockPillWidth(double width, double height) {
  final wanted = height * lockPillWidthFactor;
  final room = floorLockPlateWidth(width, height)
    - height * lockPillPaddingFactor * 2;
  return (wanted < room) ? wanted : room;
}

/// CupertinoSwitch's natural size. The floor cell sizes the switch from it
/// instead of Transform.scale, which would keep laying it out at full size
const Size cupertinoSwitchSize = Size(59.0, 39.0);

/// The fixed height of one floor cell, and what has to fit inside it: the floor
/// button, the Stop label, the switch, and the margin between them.
/// 0.145 was short by 6.3px until the switch stopped laying out at its full
/// size; with that fixed it clears the content again, down to a 568 screen
const double floorCellHeightFactor = 0.145;
const double floorButtonFactor = 0.07;
const double floorStopMarginFactor = 0.005;
const double floorStopLabelFactor = 0.015;
const double floorStopSwitchScaleFactor = 0.001;

double floorCellHeight(double height) => height * floorCellHeightFactor;

double floorCellContentHeight(double height) =>
  height * floorButtonFactor
  + height * floorStopMarginFactor
  + height * floorStopLabelFactor * 1.4   // one line of the Stop label
  + cupertinoSwitchSize.height * height * floorStopSwitchScaleFactor;

/// The floor cell shares the lock plate's width, so the plate always covers it
double floorCellWidth(double width, double height) =>
  lockPillWidth(width, height);

/// Set once the one-off floor migration has run
const String floorMigratedKey = "floorMigratedKey";

/// Which locked buttons the one-off floor migration should hand back.
///
/// A button the user had already moved, or whose stop switch they had flipped,
/// was theirs before the locks existed. hadPanel is false on a fresh install,
/// which has saved nothing to compare and a different basement besides
List<bool> floorMigrationGrants({
  required bool hadPanel,
  required List<int> savedNumbers,
  required List<bool> savedStops,
}) => List<bool>.generate(initialFloorLock.length, (i) => initialFloorLock[i]
  && hadPanel
  && (savedNumbers[i] != preLockFloorNumbers[i]
    || savedStops[i] != initialFloorStops[i]));

/// The panel every install had before the floor locks arrived. A locked button
/// still holding this value was never touched, so it was nothing to take away
const List<int> preLockFloorNumbers = [
  -4, -3, -2, -1, 1, 2, 3, 4, 5, 6, 7, 8, 14, 100, 154, max,
];

/// Shimada mode draws one artwork per floor from assets/images/1000Mode/, so its
/// panel is pinned to the files that exist there. It does not follow
/// initialFloorNumbers, whose basement moved to B1/B2/B4/B6
const List<int> shimadaFloorNumbers = [
  -4, -3, -2, -1, 1, 2, 3, 4, 5, 6, 7, 8, 14, 100, 154, max,
];

List<bool> initialFloorLock = List.generate(initialFloorNumbers.length,
  (i) => floorUnlockOrders.any((order) => order.contains(i)));

/// The one button that may be opened next on its side of 1F, or null when that
/// side is finished. Only this one is offered, so the order is kept
int? nextFloorToUnlock(List<bool> locks, int index) {
  for (final order in floorUnlockOrders) {
    if (!order.contains(index)) continue;
    for (final i in order) {
      if (locks[i]) return i;
    }
    return null;
  }
  return null;
}
List<bool> initialFloorStops = List.generate(initialFloorNumbers.length, (i) => (i != 8));

/// How far the top and bottom buttons may travel.
///
/// 1F never moves, so the buttons above it must fit between 1 and the top, and
/// the buttons below it between the bottom and -1. With sixteen buttons and 1F
/// at index 4 that leaves twelve above ground and four below: the top cannot go
/// under 12F, and the bottom cannot rise above B4.
/// The picker enforces this by stopping at the neighbouring buttons
const int floorButtonCount = 16;
const int oneFloorIndex = 4;

/// Default UI customization settings
const int initialButtonStyle = 0;
String initialBackgroundStyle = backgroundStyleList[0];
String initialButtonShape = buttonShapeList[1];

/// Settings configuration lists
const List<String> settingsItemList = [
  "button", "number", "style"
];

/// Settings tabs that hold something the premium unlock opens. The paywall
/// draws one icon per entry, which keeps it correct when a tab gains a new
/// feature: the number tab joined the list when its floors gained locks
const List<String> premiumTabList = ["button", "number", "style"];
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

/// One lock per background. Only the one the app starts on is free: every other
/// design costs its own video, so nothing unlocks a batch at once
/// Saved under its own name so the shape locks keep theirs
String backgroundLockKey(int i) => "backgroundLockKey$i";

/// Set once the one-off background migration has reached a verdict
const String backgroundMigratedKey = "backgroundMigratedKey";

/// Set once the one-off style migration has run, and whether it granted
const String styleMigratedKey = "styleMigratedKey";
const String styleUnlockedKey = "styleUnlockedKey";

/// Did this user already have the bulk unlock the old rule gave away?
///
/// Until 2026-09-12 the whole background section opened at once, on a best score
/// of 100 or on every shape being unlocked. An upgrade keeps what it had.
///
/// Only what this install holds is consulted. A reinstall has none of it, and
/// loses the shapes and the floor numbers the same way; the purchase is what
/// comes back, through the store
bool hadBulkUnlock({
  required int savedBestScore,
  required List<bool> shapeLocks,
}) =>
  savedBestScore >= unlockAllBestScore || shapeLocks.every((locked) => !locked);

/// The first row of the grid is free, so the screen is not a wall of padlocks
/// on a fresh install
const int freeBackgroundCount = 2;

List<bool> initialBackgroundLock = List.generate(
  backgroundStyleList.length, (i) => (i >= freeBackgroundCount));

// ===== EXTERNAL LINKS AND WEB PAGES =====

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

// ===== COLOR DEFINITIONS =====

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
const Color transpDarkColor = Color.fromRGBO(0, 0, 0, 0.6);
/// Every lock plate. 0.6 left the white floor buttons plainly readable, and a
/// lock has to look shut. One value, so no plate looks lighter than its neighbour
const Color transpLockColor = Color.fromRGBO(0, 0, 0, 0.85);

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

// Shimada's lamp color F7B249: R = F7 = 247, G = B2 = 178, B = 49 = 73

// Lamp color from temperature, 3000 K -> FFB16E: R = FF,
// G = 99.47080 * ln(30) - 161.11957 = B1, B = 138.51773 * ln(30-10) - 305.04480 = 6E

// --- AdMob banner ceiling --- only the inline adaptive size takes one; anchored
// sizes derive height from slot width. Trade screen space against ad area here
const int inlineBannerMaxHeight = 90;

// --- AdMob demo ad units --- public constants published by Google, not secrets, so
// a missing .env key cannot break a debug build. Adaptive banners need their own unit
const String androidBannerTestId = "ca-app-pub-3940256099942544/9214589741";
const String iosBannerTestId = "ca-app-pub-3940256099942544/2435281174";
const String androidRewardedTestId = "ca-app-pub-3940256099942544/5224354917";
const String iosRewardedTestId = "ca-app-pub-3940256099942544/1712485313";

// No interstitial demo units: admob_interstitial.dart is commented out in full.
// Put them back alongside the code if interstitials ever return

/// Which ad unit each placement asks for, resolved here so both placements agree.
/// Release builds read assets/.env; debug builds return Google's public demo units
String bannerAdUnitID =
  (!kDebugMode && (Platform.isIOS || Platform.isMacOS)) ? dotenv.get("IOS_BANNER_UNIT_ID"):
  (!kDebugMode) ? dotenv.get("ANDROID_BANNER_UNIT_ID"):
  (Platform.isIOS || Platform.isMacOS) ? iosBannerTestId:
  androidBannerTestId;

String rewardedAdUnitID =
  (!kDebugMode && (Platform.isIOS || Platform.isMacOS)) ? dotenv.get("IOS_REWARDED_UNIT_ID"):
  (!kDebugMode) ? dotenv.get("ANDROID_REWARDED_UNIT_ID"):
  (Platform.isIOS || Platform.isMacOS) ? iosRewardedTestId:
  androidRewardedTestId;
