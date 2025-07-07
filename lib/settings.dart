// =============================
// SettingsPage: App Settings and Configuration Interface
//
// This file contains the settings interface with:
// 1. State Management: Riverpod providers and local state management
// 2. Initialization: Data loading and lifecycle management
// 3. Settings Categories: Button style, shape, numbers, and background
// 4. Floor Management: Floor number and stop configuration
// 5. Reward System: Ad-based unlocking mechanism
// 6. UI Components: Settings widgets and dialogs
// =============================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'admob_rewarded.dart';
import 'common_widget.dart';
import 'floor_manager.dart';
import 'extension.dart';
import 'constant.dart';
import 'games_manager.dart';
import 'homepage.dart';
import 'main.dart';
import 'menu.dart';

class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // --- State Management ---
    // Riverpod providers for app-wide state
    final isMenu = ref.watch(isMenuProvider);
    final isGamesSignIn = ref.watch(gamesSignInProvider);
    final bestScore = ref.watch(bestScoreProvider);

    // Settings-related providers
    final floorNumbers = ref.watch(floorNumbersProvider);
    final floorStops = ref.watch(floorStopsProvider);
    final buttonShape = ref.watch(buttonShapeProvider);
    final buttonStyle = ref.watch(buttonStyleProvider);
    final backgroundStyle = ref.watch(backgroundStyleProvider);

    // --- Local State Variables ---
    // Settings interface state and animation
    final floorManager = useMemoized(() => FloorManager());
    final isButtonOn = useState(List.generate(4, (_) => List.generate(4, (_) => false)));
    final selectedNumber = useState(0);
    final showSettingNumber = useState(0);
    final buttonLockList = useState(initialButtonLock);
    final isLoadingData = useState(false);
    final animationController = useAnimationController(duration:Duration(milliseconds: flashTime))..repeat(reverse: true);

    // --- Manager Instances ---
    // Reward ad manager for unlocking features
    final RewardedAd? ad = rewardedAd();

    // --- Widget Instances ---
    // Common widgets and settings-specific widget instances
    final common = CommonWidget(context: context);
    final settings = SettingsWidget(
      context: context,
      floorNumbers: floorNumbers,
      floorStops: floorStops,
      buttonStyle: buttonStyle,
      buttonShape: buttonShape,
      backgroundStyle: backgroundStyle,
    );

    // --- Data Persistence ---
    // Load button lock status from shared preferences
    // Retrieve saved lock states for premium features
    Future<List<bool>> getButtonLockList() async {
      final prefs = await SharedPreferences.getInstance();
      final List<bool> lockList = List<bool>.from(buttonLockList.value);
      for (int i = 0; i < lockList.length; i++) {
        final newData = (i < 3) ? false: "lockKey$i".getSharedPrefBool(prefs, initialButtonLock[i]);
        lockList[i] = newData;
      }
      "lockList: $lockList".debugPrint();
      return lockList;
    }

    // --- Initialization Functions ---
    // App initialization and data loading
    // Initialize games sign-in, best score, and button lock states
    initState() async {
      isLoadingData.value = true;
      try {
        ref.read(gamesSignInProvider.notifier).state = await gamesSignIn(isGamesSignIn);
        ref.read(bestScoreProvider.notifier).state = await getBestScore(isGamesSignIn);
        buttonLockList.value = await getButtonLockList();
        isLoadingData.value = false;
      } catch (e) {
        "Error: $e".debugPrint();
        isLoadingData.value = false;
      }
    }

    // --- Lifecycle Management ---
    // Initialize app on first build
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await initState();
      });
      return null;
    }, []);

    // --- Reward System ---
    // Ad-based feature unlocking mechanism
    // Handle reward ad completion and unlock features
    void earnedRewardAd(int i, AdWithoutView ad, RewardItem reward) async {
      "showRewardedAd".debugPrint();
      if (reward.amount > 0) {
        'rewardEarned: ${reward.type}, rewardAmount: ${reward.amount}'.debugPrint();
        final newList = List<bool>.from(buttonLockList.value);
        newList[i] = false;
        final prefs = await SharedPreferences.getInstance();
        "lockKey$i".setSharedPrefBool(prefs, false);
        buttonLockList.value = newList;
        "newList: $newList".debugPrint();
      }
      if (context.mounted) context.pushNoBack(SettingsPage());
    }

    // Show reward ad dialog for feature unlocking
    void showRewardAdAlertDialog(int i) {
      Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      "$ad".debugPrint();
      // Check if reward ad is available and show dialog
      if (ad != null) {
        showDialog(context: context,
          builder: (context) => settings.rewardAdAlertDialog(
            title: context.unlockTitle(),
            content: context.unlockDesc(),
            onPressed: () => ad.show(
              onUserEarnedReward: (AdWithoutView ad, RewardItem reward) => earnedRewardAd(i, ad, reward)
            ),
          )
        );
      }
    }

    // --- Settings Category Selection ---
    // Handle settings category button selection
    void changeSelectButton(int i) {
      Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      showSettingNumber.value = i;
    }

    // --- Button Style Settings ---
    // Change button style with persistence
    Future<void> changeButtonStyle(int row) async {
      Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      ref.read(buttonStyleProvider.notifier).state = await floorManager.changeSettingsIntValue(
        key: "buttonStyleKey",
        current: buttonStyle,
        next: row
      );
    }

    // --- Button Shape Settings ---
    // Change button shape with persistence
    Future<void> changeButtonShape(String value) async {
      Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      ref.read(buttonShapeProvider.notifier).state = await floorManager.changeSettingsStringValue(
        key: "buttonShapeKey",
        current: buttonShape,
        next: value
      );
    }

    // --- Floor Number Management ---
    // Floor number selection and configuration
    void floorNumberSelect(int number, int row, int col) {
      selectedNumber.value = floorNumbers.selectedFloor(number, row, col);
      "Select number: ${selectedNumber.value}".debugPrint();
    }

    // Save floor number changes
    Future<void> floorNumberSelectOKAction(int row, int col) async {
      ref.read(floorNumbersProvider.notifier).state = await floorManager.saveFloorNumber(
        currentList: floorNumbers,
        newIndex: reversedButtonIndex[row][col],
        newValue: selectedNumber.value
      );
      if (context.mounted) context.popPage();
    }

    // Reset button state after floor number selection
    Future<void> floorNumberSelectThenAction(int row, int col) async {
      isButtonOn.value[row][col] = false;
      isButtonOn.value = List.from(isButtonOn.value);
    }

    // Handle floor number button changes
    void changeButtonNumber(int row, int col) {
      if (!isNotSelectFloor(row, col)) {
        Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
        isButtonOn.value[row][col] = true;
        isButtonOn.value = List.from(isButtonOn.value);
        settings.floorNumberSelectDialog(row, col,
          select: (int index) => floorNumberSelect(index, row, col),
          action: () => floorNumberSelectOKAction(row, col),
          then: () => floorNumberSelectThenAction(row, col)
        );
      }
    }

    // --- Floor Stop Management ---
    // Change floor stop flag with persistence
    Future<void> changeFloorStopFlag(bool value, int row, int col) async {
      if (!isNotSelectFloor(row, col)) {
        Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
        ref.read(floorStopsProvider.notifier).state = await floorManager.saveFloorStops(
          currentList: floorStops,
          newIndex: reversedButtonIndex[row][col],
          newValue: value
        );
      }
    }

    // --- Background Style Settings ---
    // Change background style with persistence
    Future<void> changeBackgroundStyle(String value) async {
      Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      ref.read(backgroundStyleProvider.notifier).state = await floorManager.changeSettingsStringValue(
        key: "backgroundStyleKey",
        current: backgroundStyle,
        next: value
      );
    }

    // --- Navigation ---
    // Back button navigation to home page
    void pressedBack() {
      ref.read(isShimadaProvider.notifier).state = false;
      ref.read(isMenuProvider.notifier).state = false;
      context.pushFadeReplacement(HomePage());
    }

    // --- UI Layout ---
    // Main settings interface layout with responsive design
    return Scaffold(
      backgroundColor: blackColor,
      appBar: isMenu ? null: settings.settingsAppBar(
        animation: animationController,
        onPressed: pressedBack
      ),
      body: Stack(alignment: Alignment.center,
        children: [
          // Background image with dynamic selection
          common.commonBackground(
            width: context.width(),
            image: ((showSettingNumber.value == 2) ? backgroundStyle: backgroundStyleList[0]).backGroundImage(),
          ),
          // Main content container with settings categories
          Column(children: [
            // --- Settings Category Buttons ---
            // Category selection buttons for different settings
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(settingsItemList.length, (i) =>
                settings.selectButtonWidget(
                  image: showSettingNumber.value.settingsButton(i),
                  onTap: () => changeSelectButton(i)
                ),
              ),
            ),
            settings.settingsDivider(),
            // --- Dynamic Settings Content ---
            // Button style settings with lock overlay
            (showSettingNumber.value == 0) ? Stack(alignment: Alignment.center,
              children: [
                settings.settingsButtonStyleWidget(onTap: changeButtonStyle),
                if (!buttonLockList.value.every((e) => e == false) && !isTest && bestScore < 100) settings.settingsLockContainer(
                  width: context.settingsButtonStyleLockWidth(),
                  height: context.settingsButtonStyleLockHeight(),
                  top: context.settingsButtonStyleLockMargin(),
                ),
              ]
            ):
            // Floor number and stop configuration
            (showSettingNumber.value == 1) ? settings.settingsButtonNumberWidget(
              isButtonOn: isButtonOn.value,
              changeButtonNumber: changeButtonNumber,
              changeFloorStopFlag: changeFloorStopFlag
            // Background style selection with lock overlay
            ): Stack(alignment: Alignment.topCenter,
              children: [
                settings.settingsBackgroundSelectWidget(onTap: (value) => changeBackgroundStyle(value)),
                if (!buttonLockList.value.every((e) => e == false) && !isTest && bestScore < 100) settings.settingsLockContainer(
                  width: context.settingsBackgroundStyleLockWidth(),
                  height: context.settingsBackgroundStyleLockHeight(),
                  top: context.settingsBackgroundStyleLockMargin(),
                ),
              ]
            ),
            if (showSettingNumber.value == 0) settings.settingsDivider(),
            // Button shape selection with reward system
            if (showSettingNumber.value == 0) settings.settingsButtonShapeWidget(
              bestScore: bestScore,
              buttonLockList: buttonLockList.value,
              changeButtonShape: changeButtonShape,
              showRewardAdAlertDialog: showRewardAdAlertDialog
            ),
          ]),
          // --- Overlay Elements ---
          // Menu overlay when menu is active
          if (isMenu) const MenuPage(isHome: true),
          // Ad banner with menu toggle functionality
          common.commonAdBanner(
            image: isMenu.buttonChanBackGround(),
            onTap: () async => ref.read(isMenuProvider.notifier).state = await isMenu.pressedMenu()
          ),
          // Loading indicator during data initialization
          if (isLoadingData.value) common.commonCircularProgressIndicator(),
        ]
      ),
    );
  }
}


// =============================
// SettingsWidget: Settings Interface Components
//
// This class provides settings interface components including:
// 1. AppBar: Settings header with animated back button
// 2. Category Selection: Settings category buttons
// 3. Button Style: Button style selection interface
// 4. Button Shape: Button shape selection with reward system
// 5. Floor Management: Floor number and stop configuration
// 6. Background Selection: Background style selection interface
// 7. Dialogs: Alert dialogs and reward ad dialogs
// =============================

class SettingsWidget {
  final BuildContext context;
  final List<int> floorNumbers;
  final List<bool> floorStops;
  final int buttonStyle;
  final String buttonShape;
  final String backgroundStyle;

  SettingsWidget({
    required this.context,
    required this.floorNumbers,
    required this.floorStops,
    required this.buttonStyle,
    required this.buttonShape,
    required this.backgroundStyle,
  });

  // --- Common Components ---
  // Settings divider for visual separation
  Divider settingsDivider() => Divider(
    height: context.settingsDividerHeight(),
    thickness: context.settingsDividerThickness(),
    color: blackColor,
  );

  // Lock icon for premium features
  Icon lockIcon(double size) =>
      Icon(CupertinoIcons.lock_fill, color: lampColor, size: size,);

  // --- AppBar Component ---
  // Settings header with animated back button
  AppBar settingsAppBar({
    required AnimationController animation,
    required void Function() onPressed,
  }) => AppBar(
    toolbarHeight: context.settingsAppBarHeight(),
    backgroundColor: blackColor,
    centerTitle: true,
    shadowColor: darkBlackColor,
    iconTheme: IconThemeData(color: whiteColor),
    title: Text(context.settings(),
      style: TextStyle(
        color: whiteColor,
        fontSize: context.settingsAppBarFontSize(),
        fontFamily: context.font(),
      ),
    ),
    leading: FadeTransition(
      opacity: animation,
      child: Container(
        margin: EdgeInsets.only(left: context.settingsAppBarBackButtonMargin()),
        child: IconButton(
          iconSize: context.settingsAppBarBackButtonSize(),
          icon: Icon(CupertinoIcons.arrow_left_circle_fill),
          onPressed: onPressed,
        ),
      ),
    ),
  );

  // --- Category Selection Component ---
  // Settings category button widget
  Widget selectButtonWidget({
    required String image,
    required void Function() onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: context.settingsSelectButtonSize(),
      height: context.settingsSelectButtonSize(),
      margin: EdgeInsets.only(
        top: context.settingsSelectButtonMarginTop(),
        bottom: context.settingsSelectButtonMarginBottom(),
      ),
      child: Image.asset(image),
    )
  );

  // --- Button Style Component ---
  // Button style selection interface
  Widget settingsButtonStyleWidget({
    required void Function(int) onTap,
  }) => Column(
    children: List.generate(3, (row) => GestureDetector(
      onTap: () => onTap(row),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (col) => Container(
          width: context.settingsButtonStyleSize(),
          height: context.settingsButtonStyleSize(),
          margin: EdgeInsets.only(
            top: (row == 0) ? context.settingsButtonStyleMargin() : 0,
            bottom: context.settingsButtonStyleMargin(),
          ),
          child: Image.asset(
            List.filled(3, row == buttonStyle).operationButtonImage(row)[col],
          ),
        )),
      ),
    )),
  );

  // --- Lock Container Component ---
  // Premium feature lock overlay with tooltip
  Widget settingsLockContainer({
    required double width,
    required double height,
    required double top,
  }) => Container(
    alignment: Alignment.center,
    color: transpDarkColor,
    margin: EdgeInsets.only(top: top),
    width: width,
    height: height,
    child: Stack(alignment: Alignment.center,
      children: [
        lockIcon(context.settingsAllLockIconSize()),
        settingsTooltip()
      ],
    ),
  );

  // --- Button Shape Component ---
  // Button shape selection with reward system integration
  Widget settingsButtonShapeWidget({
    required int bestScore,
    required List<bool> buttonLockList,
    required void Function(String) changeButtonShape,
    required void Function(int) showRewardAdAlertDialog,
  }) => Column(children: [
    ...buttonShapeList.toMatrix(3).asMap().entries.map((row) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: row.value.asMap().entries.map((col) => Container(
          alignment: Alignment.center,
          width: context.settingsLockSize(),
          height: context.settingsLockSize(),
          margin: EdgeInsets.only(
            top: (row.key == 0) ? context.settingsButtonShapeMargin(): 0,
            bottom: context.settingsButtonShapeMargin()
          ),
          child: Stack(alignment: Alignment.center,
            children: [
              /// Number Button
              GestureDetector(
                onTap: () => changeButtonShape(row.value[col.key]),
                child: CommonWidget(context: context).floorButtonImage(
                  image: (buttonShape == row.value[col.key]).numberBackground(buttonStyle, row.value[col.key]),
                  size: context.settingsButtonShapeSize(),
                  number: "99",
                  fontSize: context.settingsButtonShapeFontSize(),
                  color: (buttonStyle != 0) ? blackColor:
                  buttonShape != buttonShapeList[3 * row.key + col.key] ? whiteColor:
                  numberColorList[3 * row.key + col.key],
                  marginTop: context.floorButtonNumberMarginTop(3 * row.key + col.key),
                  marginBottom: context.floorButtonNumberMarginBottom(3 * row.key + col.key),
                ),
              ),
              if (buttonLockList[3 * row.key + col.key] && !isTest && bestScore < 100) settingsButtonLockContainer(
                onTap: () => showRewardAdAlertDialog(3 * row.key + col.key)
              )
            ]
          ),
        ),
      ).toList()),
    ),
  ]);

  // --- Button Lock Container Component ---
  // Individual button lock overlay with unlock button
  Widget settingsButtonLockContainer({
    required void Function() onTap,
  }) => Container(
    alignment: Alignment.center,
    color: transpDarkColor,
    width: context.settingsLockSize(),
    height: context.settingsLockSize(),
    child: GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          lockIcon(context.settingsLockIconSize()),
          Container(
            alignment: Alignment.center,
            width: context.settingsLockFreeButtonWidth(),
            height: context.settingsLockFreeButtonHeight(),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.settingsLockFreeBorderRadius()),
              color: lampColor,
            ),
            child: Text(
              context.unlock(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: whiteColor,
                fontSize: context.settingsLockFreeFontSize(),
                fontFamily: context.font(),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  // --- Tooltip Component ---
  // Information tooltip for premium features
  Container settingsTooltip() => Container(
    height: context.settingsTooltipHeight(),
    alignment: Alignment.topCenter,
    margin: EdgeInsets.only(top: context.settingsTooltipMargin()),
    child: Tooltip(
      richMessage: TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: "${context.unlockAllTitle()}\n",
            style: TextStyle(
              color: lampColor,
              fontFamily: context.font(),
              decorationColor: whiteColor,
              fontSize: context.settingsTooltipTitleFontSize(),
            ),
          ),
          TextSpan(
            text: "${context.unlockAll()[0]}\n",
            style: TextStyle(
              color: blackColor,
              fontStyle: FontStyle.normal,
              fontFamily: context.font(),
              decoration: TextDecoration.none,
              fontSize: context.settingsTooltipDescFontSize(),
            ),
          ),
          TextSpan(
            text: context.unlockAll()[1],
            style: TextStyle(
              color: blackColor,
              fontStyle: FontStyle.normal,
              fontFamily: context.font(),
              decoration: TextDecoration.none,
              fontSize: context.settingsTooltipDescFontSize(),
            ),
          ),
        ],
      ),
      padding: EdgeInsets.all(context.settingsTooltipPaddingSize()),
      margin: EdgeInsets.all(context.settingsTooltipMarginSize()),
      verticalOffset: context.settingsTooltipOffsetSize(),
      preferBelow: true, //isBelow for tooltip position
      decoration: BoxDecoration(
        color: transpWhiteColor,
        borderRadius: BorderRadius.all(Radius.circular(context.settingsTooltipBorderRadius()))
      ),
      showDuration: const Duration(milliseconds: toolTipTime),
      triggerMode: TooltipTriggerMode.tap,
      enableFeedback: true,
      child: Icon(CupertinoIcons.question_circle,
        color: Colors.white,
        size: context.settingsTooltipIconSize(),
      ),
    ),
  );


  // --- Floor Management Components ---
  // Floor number selection dialog
  void floorNumberSelectDialog(int row, col, {
    required void Function(int) select,
    required void Function() action,
    required void Function() then,
  }) => showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: transpBlackColor,
      title: alertDialogTitle(context.changeNumberTitle(isBasement(row, col))),
      content: settingsFloorNumberContent(row, col,
        onSelectedItemChanged: select,
      ),
      actions: [
        alertCancelButton(
          color: whiteColor,
        ),
        alertOKButton(
          color: lampColor,
          onPressed: action,
        ),
      ]
    ),
  ).then((_) => then());

  // Floor number configuration interface
  Widget settingsButtonNumberWidget({
    required List<List<bool>> isButtonOn,
    required void Function(int, int) changeButtonNumber,
    required void Function(bool, int, int) changeFloorStopFlag,
  }) => Column(children: [
    ...floorNumbers.toReversedMatrix(4).asMap().entries.map((row) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: row.value.asMap().entries.map((col) => Container(
          alignment: Alignment.center,
          margin: EdgeInsets.only(top: (row.key == 0) ? context.settingsNumberButtonMargin(): 0.0),
          child: Stack(alignment: Alignment.center,
            children: [
              Container(
                width: context.settingsNumberButtonHideWidth(),
                height: context.settingsNumberButtonHideHeight(),
                margin: EdgeInsets.only(top: context.settingsNumberButtonHideMargin()),
                child: Column(children: [
                  GestureDetector(
                    child: CommonWidget(context: context).floorButtonImage(
                      image: isButtonOn[row.key][col.key].numberBackground(1, "normal"),
                      size: context.settingsButtonSize(),
                      number: col.value.buttonNumber(),
                      fontSize: context.settingsNumberButtonFontSize(),
                      color: blackColor,
                      marginTop: 0.0,
                      marginBottom: 0.0
                    ),
                    onTap: () => changeButtonNumber(row.key, col.key) ,
                  ),
                  settingsFloorStopToggleWidget(row.key, col.key,
                    changeFloorStopFlag: changeFloorStopFlag
                  )
                ]),
              ),
              if (isNotSelectFloor(row.key, col.key)) Container(
                alignment: Alignment.center,
                width: context.settingsNumberButtonHideWidth(),
                height: context.settingsNumberButtonHideHeight(),
                color: transpBlackColor,
              ),
            ])
        )).toList()
      )
    ),
  ]);

  Widget settingsFloorNumberContent(int row, col, {
    required void Function(int) onSelectedItemChanged,
  }) => Container(
    alignment: Alignment.center,
    height: context.settingsAlertFloorNumberPickerHeight(),
    child: CupertinoPicker(
      itemExtent: context.settingsAlertFloorNumberHeight(),
      scrollController: FixedExtentScrollController(
        initialItem: floorNumbers[reversedButtonIndex[row][col]] - floorNumbers.selectFirstFloor(row, col),
      ),
      onSelectedItemChanged: (int index) => onSelectedItemChanged(index),
      children: List.generate(floorNumbers.selectDiffFloor(row, col), (int index) =>
      (floorNumbers.selectedFloor(index, row, col) != 0) ? Container(
          alignment: Alignment.center,
          child: Text('${(floorNumbers.selectedFloor(index, row, col) < 0 ? -1: 1) * floorNumbers.selectedFloor(index, row, col)}',
            style: TextStyle(
              color: lampColor,
              fontSize: context.settingsAlertFloorNumberFontSize(),
              fontFamily: numberFont[1],
            ),
          )
      ): null
      ).whereType<Container>().toList(),
    ),
  );

  // Floor stop toggle configuration
  Widget settingsFloorStopToggleWidget(int row, col, {
    required void Function(bool, int, int) changeFloorStopFlag,
  }) => Container(
    margin: EdgeInsets.only(top: context.settingsFloorStopMargin()),
    child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text(floorStops[reversedButtonIndex[row][col]] ? context.stop(): context.bypass(),
          style: TextStyle(
            color: whiteColor,
            fontSize: context.settingsFloorStopFontSize(),
            fontFamily: context.font(),
          ),
        ),
        Transform.scale(
          scale: context.settingsFloorStopToggleScale(),
          child: CupertinoSwitch(
            activeTrackColor: lampColor,
            inactiveTrackColor: blackColor,
            thumbColor: whiteColor,
            value: floorStops[reversedButtonIndex[row][col]],
            onChanged: (value) => changeFloorStopFlag(value, row, col),
          ),
        ),
      ]
    ),
  );

  // --- Background Selection Component ---
  // Background style selection interface
  Widget settingsBackgroundSelectWidget({
    required void Function(String) onTap
  }) => Column(mainAxisAlignment: MainAxisAlignment.center,
      children: [...backgroundStyleList.toMatrix(2).asMap().entries.map((row) =>
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: row.value.asMap().entries.map((col) => Container(
            width: context.settingsBackgroundSize(),
            height: context.settingsBackgroundSize(),
            margin: EdgeInsets.only(top: context.settingsBackgroundMargin()),
            child: Stack(children: [
              GestureDetector(
                onTap: () => onTap(row.value[col.key]),
                child: ClipRect(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      child: Image.asset(row.value[col.key].backGroundImage()),
                    ),
                  ),
                ),
              ),
              if (backgroundStyleList.toMatrix(2)[row.key][col.key] == backgroundStyle) Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    width: context.settingsBackgroundSelectBorderWidth(),
                    color: lampColor
                  ),
                ),
              ),
            ]),
          )).toList(),
        )),
      ]
  );


  // --- Dialog Components ---
  // Alert dialog title with close button
  Widget alertDialogTitle(String title) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      Text(title,
        style: TextStyle(
          fontSize: context.settingsAlertTitleFontSize(),
          fontFamily: context.font(),
          color: whiteColor,
        ),
      ),
      SizedBox(width: context.settingsAlertCloseIconSpace()),
      // Close button for dialog
      GestureDetector(
        onTap: () => context.popPage(),
        child: Icon(Icons.close,
          size: context.settingsAlertCloseIconSize(),
          color: whiteColor,
        ),
      ),
    ]
  );

  // OK button for dialogs
  TextButton alertOKButton({
    required Color color,
    required void Function() onPressed,
  }) => TextButton(
    onPressed: onPressed,
    child: Text(context.ok(),
      style: TextStyle(
          color: color,
          fontSize: context.settingsAlertSelectFontSize(),
          fontFamily: context.font(),
      ),
    ),
  );

  // Cancel button for dialogs
  TextButton alertCancelButton({
    required Color color,
  }) => TextButton(
    onPressed: () => context.popPage(),
    child: Text(context.cancel(),
      style: TextStyle(
        color: color,
        fontSize: context.settingsAlertDescFontSize(),
        fontFamily: context.font(),
      ),
    ),
  );

  // Reward ad alert dialog
  CupertinoAlertDialog rewardAdAlertDialog({
    required String title,
    required String content,
    required void Function() onPressed,
  }) => CupertinoAlertDialog(
    title: Text(title,
      style: TextStyle(
        color: blackColor,
        fontSize: context.settingsAlertTitleFontSize(),
        fontFamily: context.font(),
      ),
    ),
    content: Text(context.unlockDesc(),
      style: TextStyle(
        color: blackColor,
        fontSize: context.settingsAlertDescFontSize(),
        fontFamily: context.font(),
      ),
    ),
    actions: [
      alertCancelButton(
        color: blackColor,
      ),
      alertOKButton(
        color: blackColor,
        onPressed: onPressed,
      ),
    ],
  );
}