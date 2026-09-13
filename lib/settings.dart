// ===== SettingsPage: app settings and configuration interface =====
// Button style, shape, numbers, background, floor management, reward unlocks, dialogs

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'admob_rewarded.dart';
import 'analytics_manager.dart';
import 'common_widget.dart';
import 'floor_manager.dart';
import 'extension.dart';
import 'constant.dart';
import 'games_manager.dart';
import 'homepage.dart';
import 'main.dart';
import 'menu.dart';
import 'plan_provider.dart';
import 'premium_page.dart';
import 'purchase_manager.dart';

class SettingsPage extends HookConsumerWidget {
  /// initialTab: a rewarded ad rebuilds this page, and landing back on the
  /// first tab hides the design the video just unlocked
  const SettingsPage({super.key, this.initialTab = 0});

  final int initialTab;

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
    final isPremium = ref.watch(planProvider).isPremium;

    // --- Local State Variables ---
    // Settings interface state and animation
    final floorManager = useMemoized(() => FloorManager());
    final isButtonOn = useState(List.generate(4, (_) => List.generate(4, (_) => false)));
    final selectedNumber = useState(0);
    final showSettingNumber = useState(initialTab);
    final buttonLockList = useState(initialButtonLock);
    final backgroundLockList = useState(initialBackgroundLock);
    final floorLockList = useState(initialFloorLock);
    // Premium and the test build open everything. Derived once, so the plate and
    // the guards below can never disagree and leave a dead button
    bool isFloorLocked(int index) =>
      !isTest && !isPremium && floorLockList.value[index];
    final isStyleUnlocked = useState(false);
    final isLoadingData = useState(false);
    // The price the store returned, empty until it answers. Every purchase entry point
    // is drawn from this, never from the SDK having started
    final storePrice = useState("");
    final animationController = useAnimationController(duration:Duration(milliseconds: flashTime))..repeat(reverse: true);

    // --- Manager Instances --- rewarded ad for unlocking features. The hook only
    // requests once the SDK allows it, so ad is null before consent; prepare covers that
    final rewarded = useRewardedAd();
    final RewardedAd? ad = rewarded.ad;

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
      isPremium: isPremium,
    );

    // --- Data Persistence ---
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

    // The button style section used to open on the bulk unlock the old rule gave
    // away. That path is gone, but a user who already had it keeps it
    Future<bool> getStyleUnlocked(List<bool> shapeLocks) async {
      final prefs = await SharedPreferences.getInstance();
      if (!styleMigratedKey.getSharedPrefBool(prefs, false)) {
        final granted = hadBulkUnlock(
          savedBestScore: "bestScore".getSharedPrefInt(prefs, 0),
          shapeLocks: shapeLocks,
        );
        if (granted) styleUnlockedKey.setSharedPrefBool(prefs, true);
        styleMigratedKey.setSharedPrefBool(prefs, true);
      }
      return styleUnlockedKey.getSharedPrefBool(prefs, false);
    }

    // Floors are locked one at a time too, and in a fixed order. One lock covers
    // the floor number and the stop switch of the same button
    Future<List<bool>> getFloorLockList() async {
      final prefs = await SharedPreferences.getInstance();
      if (!floorMigratedKey.getSharedPrefBool(prefs, false)) {
        // A panel saved before the locks existed. Whatever the user had already
        // changed stays theirs. A fresh install has saved nothing to compare,
        // and its basement differs from the old default anyway
        final grants = floorMigrationGrants(
          hadPanel: prefs.containsKey("numbersKey0")
            || prefs.containsKey("stopsKey0"),
          savedNumbers: "numbersKey".getSharedPrefListInt(prefs, preLockFloorNumbers),
          savedStops: "stopsKey".getSharedPrefListBool(prefs, initialFloorStops),
        );
        for (int i = 0; i < grants.length; i++) {
          if (grants[i]) floorLockKey(i).setSharedPrefBool(prefs, false);
        }
        floorMigratedKey.setSharedPrefBool(prefs, true);
      }
      return List<bool>.generate(initialFloorLock.length, (i) => initialFloorLock[i]
        && floorLockKey(i).getSharedPrefBool(prefs, true));
    }

    // Backgrounds are locked one at a time, under their own keys so the shapes
    // a user has already paid a video for are untouched.
    //
    // Until today the whole section opened at once, on a best score of 100 or on
    // every shape being unlocked. Anyone who had reached that keeps the
    // backgrounds: taking them back is not what the new rule is for. The result
    // is written the first time this screen opens, so it no longer depends on a
    // score that can be reset
    Future<List<bool>> getBackgroundLockList(List<bool> shapeLocks) async {
      final prefs = await SharedPreferences.getInstance();
      if (!backgroundMigratedKey.getSharedPrefBool(prefs, false)) {
        // Read the score from storage, not from the provider. getBestScore
        // writes the larger of local and leaderboard but returns the smaller on
        // the launch that first pulls it down, and the migration runs only once
        final grant = hadBulkUnlock(
          savedBestScore: "bestScore".getSharedPrefInt(prefs, 0),
          shapeLocks: shapeLocks,
        );
        if (grant) {
          for (int i = 0; i < initialBackgroundLock.length; i++) {
            backgroundLockKey(i).setSharedPrefBool(prefs, false);
          }
        }
        backgroundMigratedKey.setSharedPrefBool(prefs, true);
      }
      final locks = List<bool>.generate(initialBackgroundLock.length,
        (i) => initialBackgroundLock[i]
          && backgroundLockKey(i).getSharedPrefBool(prefs, true));
      // Never leave the design in use behind a lock
      final inUse = backgroundStyleList.indexOf(backgroundStyle);
      if (inUse >= 0 && locks[inUse]) {
        locks[inUse] = false;
        backgroundLockKey(inUse).setSharedPrefBool(prefs, false);
      }
      return locks;
    }

    // --- Initialization Functions ---
    // Initialize games sign-in, best score, and button lock states
    initState() async {
      isLoadingData.value = true;
      try {
        ref.read(gamesSignInProvider.notifier).update(await gamesSignIn(isGamesSignIn));
        ref.read(bestScoreProvider.notifier).update(await getBestScore(isGamesSignIn));
        buttonLockList.value = await getButtonLockList();
        backgroundLockList.value = await getBackgroundLockList(buttonLockList.value);
        floorLockList.value = await getFloorLockList();
        isStyleUnlocked.value = await getStyleUnlocked(buttonLockList.value);
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
        // Settings is a deliberate navigation long after the first frame, so starting the
        // store SDK here costs the launch nothing. The price decides whether to show the offer
        final price = await PurchaseManager.fetchPrice();
        if (!context.mounted) return;
        if (price != null) {
          storePrice.value = price;
          ref.read(planProvider.notifier).setPrice(price);
        }
      });
      return null;
    }, []);

    // --- Premium Purchase --- the paid way out of every lock. The rewarded ad below
    // stays the free one: buying is a shortcut past the video, not a replacement

    /// Run the purchase or restore flow and report the result to the user
    Future<void> runPurchase({required bool isRestore, required String source}) async {
      isLoadingData.value = true;
      try {
        final purchased = await PurchaseManager.buyPremium(
          isRestore: isRestore,
          source: source,
        );
        if (!context.mounted) return;
        if (purchased) {
          await ref.read(planProvider.notifier).setCurrentPlan(true);
          if (!context.mounted) return;
          common.commonSnackBar(context.premiumThanks());
        } else if (isRestore) {
          common.commonSnackBar(context.premiumRestoreFailed());
        }
      } catch (e) {
        "Purchase error: $e".debugPrint();
        // Nothing to sell is not a failed purchase. The reviewer sees this one
        // while the product is still attached to the submission
        if (context.mounted) {
          common.commonSnackBar((e is StoreUnavailableException)
            ? context.premiumUnavailable()
            : context.premiumFailed());
        }
      } finally {
        isLoadingData.value = false;
      }
    }

    /// Open the upgrade dialog, shared by every purchase entry point. The price is
    /// fetched again since the offering or network can vanish; an empty answer is reported
    Future<void> openUpgrade(String source) async {
      isLoadingData.value = true;
      final price = await PurchaseManager.fetchPrice();
      if (!context.mounted) return;
      isLoadingData.value = false;
      // An empty price still opens the page: the button says "Buy" without an
      // amount, and pressing it reports why nothing happened
      storePrice.value = price ?? "";
      ref.read(planProvider.notifier).setPrice(price ?? "");
      await AnalyticsManager.upgradeOffered(source);
      if (!context.mounted) return;
      context.pushPage(PremiumPage(
        price: price ?? "",
        onBuy: () async {
          context.popPage();
          await runPurchase(isRestore: false, source: source);
        },
        onRestore: () async {
          context.popPage();
          await runPurchase(isRestore: true, source: source);
        },
      ));
    }

    /// Offer the purchase from a lock that has no video behind it. The tap is
    /// logged first, always, so the demand signal survives a build with no store
    Future<void> showUpgrade(String feature) async {
      // Backgrounds and floors do not open on a score, so there is no shortage
      await AnalyticsManager.unlockBlocked(
        feature: feature,
        requiredPoint: (feature == "button_shape" || feature == "button_style")
          ? unlockAllBestScore : 0,
        currentPoint: bestScore,
      );
      await openUpgrade(feature);
    }


    // --- Reward System ---
    // Handle reward ad completion and unlock features
    void earnedRewardAd(String kind, int i, AdWithoutView ad, RewardItem reward) async {
      "showRewardedAd".debugPrint();
      final isShape = (kind == "button_shape");
      final isFloor = (kind == "floor_number");
      if (reward.amount > 0) {
        'rewardEarned: ${reward.type}, rewardAmount: ${reward.amount}'.debugPrint();
        final current = isShape ? buttonLockList.value
          : isFloor ? floorLockList.value : backgroundLockList.value;
        final newList = List<bool>.from(current)..[i] = false;
        final prefs = await SharedPreferences.getInstance();
        (isShape ? "lockKey$i"
          : isFloor ? floorLockKey(i) : backgroundLockKey(i)
        ).setSharedPrefBool(prefs, false);
        if (isShape) {
          buttonLockList.value = newList;
        } else if (isFloor) {
          floorLockList.value = newList;
        } else {
          backgroundLockList.value = newList;
        }
        "newList: $newList".debugPrint();
      }
      if (context.mounted) {
        context.pushNoBack(SettingsPage(initialTab: isShape ? 0 : isFloor ? 1 : 2));
      }
    }

    // Confirmation dialog for an ad that is ready to play. It offers the purchase as a
    // third choice; the video stays the default and the paid option needs a store price
    void showUnlockDialog(String kind, int i, RewardedAd loadedAd) {
      showDialog(context: context,
        builder: (context) => settings.rewardAdAlertDialog(
          title: context.unlockTitle(),
          content: context.unlockDesc(),
          onPressed: () => loadedAd.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem reward) =>
              earnedRewardAd(kind, i, ad, reward)
          ),
        )
      );
    }

    // Show reward ad dialog for feature unlocking. The press must answer every time:
    // run the consent flow, offer the privacy options form, only then say there is no ad
    void showRewardAdAlertDialog(String kind, int i) async {
      Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      "$ad".debugPrint();
      // Logged before anything can fail, so the demand signal survives a build with
      // no ad and no store. required/current: best score threshold and this user's score
      // Backgrounds no longer open on a score, so there is no shortage to report
      await AnalyticsManager.unlockBlocked(
        feature: kind,
        requiredPoint: (kind == "button_shape" || kind == "button_style")
          ? unlockAllBestScore : 0,
        currentPoint: bestScore,
      );
      if (ad != null) {
        showUnlockDialog(kind, i, ad);
        return;
      }
      // The consent form and the ad request both take a round trip, and the
      // button looks dead while they run
      isLoadingData.value = true;
      final preparedAd = await rewarded.prepare();
      if (!context.mounted) return;
      isLoadingData.value = false;
      if (preparedAd != null) {
        showUnlockDialog(kind, i, preparedAd);
        return;
      }
      // Consent stayed declined or nothing filled; both are actionable, so say it.
      // The purchase is offered too, so the user has something to press
      showDialog(context: context,
        builder: (context) => settings.rewardAdUnavailableDialog(
          content: context.rewardAdUnavailable(),
        )
      );
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
      ref.read(buttonStyleProvider.notifier).update(await floorManager.changeSettingsIntValue(
        key: "buttonStyleKey",
        current: buttonStyle,
        next: row
      ));
    }

    // --- Button Shape Settings ---
    // Change button shape with persistence
    Future<void> changeButtonShape(String value) async {
      Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      ref.read(buttonShapeProvider.notifier).update(await floorManager.changeSettingsStringValue(
        key: "buttonShapeKey",
        current: buttonShape,
        next: value
      ));
    }

    // --- Floor Number Management ---
    // Floor number selection and configuration
    void floorNumberSelect(int number, int row, int col) {
      selectedNumber.value = floorNumbers.selectedFloor(number, row, col);
      "Select number: ${selectedNumber.value}".debugPrint();
    }

    // Save floor number changes
    Future<void> floorNumberSelectOKAction(int row, int col) async {
      ref.read(floorNumbersProvider.notifier).update(await floorManager.saveFloorNumber(
        currentList: floorNumbers,
        newIndex: reversedButtonIndex[row][col],
        newValue: selectedNumber.value
      ));
      if (context.mounted) context.popPage();
    }

    // Reset button state after floor number selection
    Future<void> floorNumberSelectThenAction(int row, int col) async {
      isButtonOn.value[row][col] = false;
      isButtonOn.value = List.from(isButtonOn.value);
    }

    // Handle floor number button changes
    void changeButtonNumber(int row, int col) {
      if (isFloorLocked(reversedButtonIndex[row][col])) return;
      if (!isNotSelectFloor(row, col)) {
        Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
        isButtonOn.value[row][col] = true;
        isButtonOn.value = List.from(isButtonOn.value);
        // The picker does not report the row it opens on, so seed it here or OK
        // would save whatever the previous dialog left behind
        selectedNumber.value = floorNumbers[reversedButtonIndex[row][col]];
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
      if (isFloorLocked(reversedButtonIndex[row][col])) return;
      if (!isNotSelectFloor(row, col)) {
        Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
        ref.read(floorStopsProvider.notifier).update(await floorManager.saveFloorStops(
          currentList: floorStops,
          newIndex: reversedButtonIndex[row][col],
          newValue: value
        ));
      }
    }

    // --- Background Style Settings ---
    // Change background style with persistence
    Future<void> changeBackgroundStyle(String value) async {
      Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      ref.read(backgroundStyleProvider.notifier).update(await floorManager.changeSettingsStringValue(
        key: "backgroundStyleKey",
        current: backgroundStyle,
        next: value
      ));
    }

    // --- Navigation ---
    // Back button navigation to home page
    void pressedBack() {
      ref.read(isShimadaProvider.notifier).update(false);
      ref.read(isMenuProvider.notifier).update(false);
      context.pushFadeReplacement(HomePage());
    }

    // --- UI Layout ---
    // Main settings interface layout with responsive design
    return Scaffold(
      backgroundColor: blackColor,
      appBar: isMenu ? null: settings.settingsAppBar(
        animation: animationController,
        onPressed: pressedBack,
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
                // Score or purchase. Unlocking every shape no longer opens this
                if (!isTest && !isPremium && !isStyleUnlocked.value && bestScore < unlockAllBestScore) settings.settingsLockContainer(
                  width: context.settingsButtonStyleLockWidth(),
                  height: context.settingsButtonStyleLockHeight(),
                  top: context.settingsButtonStyleLockMargin(),
                  onTap: () => showUpgrade("button_style"),
                ),
              ]
            ):
            // Floor number and stop configuration
            (showSettingNumber.value == 1) ? settings.settingsButtonNumberWidget(
              isButtonOn: isButtonOn.value,
              floorLockList: List<bool>.generate(
                initialFloorLock.length, isFloorLocked,
              ),
              changeButtonNumber: changeButtonNumber,
              changeFloorStopFlag: changeFloorStopFlag,
              showRewardAdAlertDialog: (i) => showRewardAdAlertDialog("floor_number", i),
              onBuy: () => showUpgrade("floor_number"),
            // Background style selection, one lock per design
            ): settings.settingsBackgroundSelectWidget(
              backgroundLockList: (isTest || isPremium)
                ? List.filled(initialBackgroundLock.length, false)
                : backgroundLockList.value,
              onTap: (value) => changeBackgroundStyle(value),
              showRewardAdAlertDialog: (i) => showRewardAdAlertDialog("background", i),
              onBuy: () => showUpgrade("background"),
            ),
            if (showSettingNumber.value == 0) settings.settingsDivider(),
            // Button shape selection with reward system
            if (showSettingNumber.value == 0) settings.settingsButtonShapeWidget(
              bestScore: bestScore,
              buttonLockList: buttonLockList.value,
              changeButtonShape: changeButtonShape,
              showRewardAdAlertDialog: (i) => showRewardAdAlertDialog("button_shape", i),
              onBuy: () => showUpgrade("button_shape"),
            ),
          ]),
          // --- Overlay Elements ---
          // Menu overlay when menu is active
          if (isMenu) const MenuPage(isHome: true),
          // Ad banner with menu toggle functionality
          common.commonAdBanner(
            image: isMenu.buttonChanBackGround(),
            onTap: pressedBack,
            isPremium: isPremium,
          ),
          // Loading indicator during data initialization
          if (isLoadingData.value) common.commonCircularProgressIndicator(),
        ]
      ),
    );
  }
}


// ===== SettingsWidget: settings interface components =====
// AppBar, category selection, button style/shape, floor management, background, dialogs

class SettingsWidget {
  final BuildContext context;
  final List<int> floorNumbers;
  final List<bool> floorStops;
  final int buttonStyle;
  final String buttonShape;
  final String backgroundStyle;
  /// Premium opens every lock at once, so no overlay is drawn for these users
  final bool isPremium;

  SettingsWidget({
    required this.context,
    required this.floorNumbers,
    required this.floorStops,
    required this.buttonStyle,
    required this.buttonShape,
    required this.backgroundStyle,
    required this.isPremium,
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
    // No purchase action here on purpose: a bare padlock in the bar reads as a
    // status, the same glyph the lock overlays use. the lock overlay is the only offer on this screen
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
    required void Function() onTap,
  }) => GestureDetector(
    // The lock used to be scenery. Pressing it is the only purchase path the
    // settings screen offers, so it has to answer
    onTap: onTap,
    child: Container(
      alignment: Alignment.center,
      color: transpLockColor,
      margin: EdgeInsets.only(top: top),
      width: width,
      height: height,
      // The one way out besides buying, said plainly under the padlock
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          lockIcon(context.settingsAllLockIconSize()),
          SizedBox(height: context.settingsLockTextMargin()),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.settingsLockTextMargin(),
            ),
            // Shrunk rather than wrapped: the French line is the longest and
            // does not fit the plate at full size
            child: FittedBox(fit: BoxFit.scaleDown,
              child: Text(
                context.unlockByScore(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: whiteColor,
                  fontSize: context.settingsLockTextFontSize(),
                  fontWeight: FontWeight.bold,
                  fontFamily: context.font(),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  // --- Button Shape Component ---
  // Button shape selection with reward system integration
  Widget settingsButtonShapeWidget({
    required int bestScore,
    required List<bool> buttonLockList,
    required void Function(String) changeButtonShape,
    required void Function(int) showRewardAdAlertDialog,
    required void Function() onBuy,
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
              if (buttonLockList[3 * row.key + col.key] && !isTest && !isPremium && bestScore < unlockAllBestScore) settingsButtonLockContainer(
                onUnlock: () => showRewardAdAlertDialog(3 * row.key + col.key),
                onBuy: onBuy,
              )
            ]
          ),
        ),
      ).toList()),
    ),
  ]);

  // --- Button Lock Container Component ---
  // Individual button lock overlay with unlock button
  /// Two targets, not one. The padlock goes to the purchase page; only the
  /// Unlock pill starts a video, so the free path is never pressed by accident
  Widget settingsButtonLockContainer({
    required void Function() onUnlock,
    required void Function() onBuy,
    double? size,
    double? height,
    EdgeInsets margin = EdgeInsets.zero,
    Color color = transpLockColor,
    bool showUnlock = true,
  }) {
    final box = size ?? context.settingsLockSize();
    // The padlock keeps its share of the box. Fixed, it looked adrift on the
    // background tiles, which are larger than the button shapes it was sized for
    final icon = box
      * context.settingsLockIconSize() / context.settingsLockSize();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onBuy,
      child: Container(
    alignment: Alignment.center,
    color: color,
    margin: margin,
    width: box,
    height: height ?? box,
    child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          lockIcon(icon),
          // Padded so the free path has a target the thumb can hit. Missing the
          // pill would otherwise open the purchase page, which is the paid one
          if (showUnlock) GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onUnlock,
            child: Padding(
            padding: EdgeInsets.all(context.settingsLockFreeTapPadding()),
            child: Container(
            alignment: Alignment.center,
            width: context.settingsLockFreeButtonWidth(),
            height: context.settingsLockFreeButtonHeight(),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.settingsLockFreeBorderRadius()),
              color: lampColor,
            ),
            // Spanish and French run past the pill on one line. Shrunk rather
            // than wrapped: a second line would spill out of its height
            child: FittedBox(fit: BoxFit.scaleDown,
              child: Text(
                context.unlock(),
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: whiteColor,
                  fontSize: context.settingsLockFreeFontSize(),
                  fontFamily: context.font(),
                ),
              ),
            ),
          ),
          ),
          ),
        ],
      ),
    ),
    );
  }



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
    required List<bool> floorLockList,
    required void Function(int, int) changeButtonNumber,
    required void Function(bool, int, int) changeFloorStopFlag,
    required void Function(int) showRewardAdAlertDialog,
    required void Function() onBuy,
  }) => Column(children: [
    ...floorNumbers.toReversedMatrix(4).asMap().entries.map((row) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: row.value.asMap().entries.map((col) => Container(
          alignment: Alignment.center,
          // Every cell is the lock's width, locked or not. Sizing to the widest
          // child instead would shift the unlocked cells out of line
          width: context.settingsFloorLockWidth(),
          margin: EdgeInsets.only(top: (row.key == 0) ? context.settingsNumberButtonMargin(): 0.0),
          child: Stack(alignment: Alignment.center,
            children: [
              Container(
                width: context.settingsNumberButtonHideWidth(),
                height: context.settingsNumberButtonHideHeight(),
                margin: EdgeInsets.only(top: context.settingsNumberButtonHideMargin()),
                child: Column(children: [
                  // 1F never moves and always stops. Fade the button and the
                  // switch; the plate that used to cover the cell hid the floor
                  // number too, and the Stop label stays readable
                  Opacity(
                    opacity: isNotSelectFloor(row.key, col.key) ? fixedFloorOpacity : 1.0,
                    child: GestureDetector(
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
                  ),
                  settingsFloorStopToggleWidget(row.key, col.key,
                    changeFloorStopFlag: changeFloorStopFlag
                  )
                ]),
              ),
              // One lock over the whole cell: the floor number and the stop
              // switch open together. Only the next one in the order carries the
              // button, so the floors open one at a time
              if (floorLockList[reversedButtonIndex[row.key][col.key]])
                settingsButtonLockContainer(
                  onUnlock: () => showRewardAdAlertDialog(
                    reversedButtonIndex[row.key][col.key],
                  ),
                  onBuy: onBuy,
                  // The box the number and the switch share, widened to hold
                  // the Unlock pill and its tap padding without squeezing them
                  size: context.settingsFloorLockWidth(),
                  height: context.settingsNumberButtonHideHeight(),
                  margin: EdgeInsets.only(
                    top: context.settingsNumberButtonHideMargin(),
                  ),
                  showUnlock: nextFloorToUnlock(
                    floorLockList, reversedButtonIndex[row.key][col.key],
                  ) == reversedButtonIndex[row.key][col.key],
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
      // No filtering here: the range never contains floor 0, so dropping an item
      // would only make the index disagree with the value it reports
      children: List.generate(floorNumbers.selectDiffFloor(row, col), (int index) =>
        Container(
          alignment: Alignment.center,
          child: Text('${floorNumbers.selectedFloor(index, row, col).abs()}',
            style: TextStyle(
              color: lampColor,
              fontSize: context.settingsAlertFloorNumberFontSize(),
              fontFamily: numberFont[1],
            ),
          )
        )
      ),
    ),
  );

  // Floor stop toggle configuration
  Widget settingsFloorStopToggleWidget(int row, col, {
    required void Function(bool, int, int) changeFloorStopFlag,
  }) => Container(
    margin: EdgeInsets.only(top: context.settingsFloorStopMargin()),
    child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // One line, always: a wrapped label would make the cell taller than its
        // reserved height. Today's six labels fit; this guards a longer one
        FittedBox(fit: BoxFit.scaleDown,
          child: Text(floorStops[reversedButtonIndex[row][col]] ? context.stop(): context.bypass(),
            maxLines: 1,
            style: TextStyle(
              color: whiteColor,
              fontSize: context.settingsFloorStopFontSize(),
              fontFamily: context.font(),
            ),
          ),
        ),
        // Only the switch is faded for 1F. The Stop label above it stays legible
        Opacity(
          opacity: isNotSelectFloor(row, col) ? fixedFloorSwitchOpacity : 1.0,
          // Sized, not just scaled: Transform.scale leaves the layout at the
          // switch's full height, which pushed the cell over on a short screen
          child: SizedBox(
            width: cupertinoSwitchSize.width * context.settingsFloorStopToggleScale(),
            height: cupertinoSwitchSize.height * context.settingsFloorStopToggleScale(),
            child: FittedBox(
            child: CupertinoSwitch(
              activeTrackColor: lampColor,
              inactiveTrackColor: blackColor,
              thumbColor: whiteColor,
              value: floorStops[reversedButtonIndex[row][col]],
              // The last stop on its side of 1F stays on, so the switch is disabled
              onChanged: (isNotSelectFloor(row, col)
                  || isOnlyStop(floorStops, reversedButtonIndex[row][col]))
                ? null
                : (value) => changeFloorStopFlag(value, row, col),
            ),
            ),
          ),
        ),
      ]
    ),
  );

  // --- Background Selection Component ---
  // Background style selection interface
  Widget settingsBackgroundSelectWidget({
    required List<bool> backgroundLockList,
    required void Function(String) onTap,
    required void Function(int) showRewardAdAlertDialog,
    required void Function() onBuy,
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
              // One video per design: nothing here unlocks the others
              if (backgroundLockList[2 * row.key + col.key]) settingsButtonLockContainer(
                onUnlock: () => showRewardAdAlertDialog(2 * row.key + col.key),
                onBuy: onBuy,
                size: context.settingsBackgroundSize(),
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
      // Scaled down rather than clipped: the basement title is long in some languages
      Flexible(child: FittedBox(fit: BoxFit.scaleDown,
        child: Text(title,
          maxLines: 1,
          style: TextStyle(
            fontSize: context.settingsAlertTitleFontSize(),
            fontFamily: context.font(),
            color: whiteColor,
          ),
        ),
      )),
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

  /// No purchase button here: the padlock behind this dialog is the paid path,
  /// and the Unlock pill that opened it is the free one
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

  // Shown when no rewarded ad can be played. There is nothing to confirm here,
  // so it carries one button and states the reason instead of closing silently
  CupertinoAlertDialog rewardAdUnavailableDialog({
    required String content,
  }) => CupertinoAlertDialog(
    content: Text(content,
      style: TextStyle(
        color: blackColor,
        fontSize: context.settingsAlertDescFontSize(),
        fontFamily: context.font(),
      ),
    ),
    actions: [
      alertOKButton(
        color: blackColor,
        onPressed: () => context.popPage(),
      ),
    ],
  );
}