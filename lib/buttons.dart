// =============================
// ButtonsPage: 1000 Buttons Challenge Interface
//
// This file contains the 1000 buttons challenge interface with:
// 1. State Management: Challenge state and button selection tracking
// 2. Initialization: Data loading and lifecycle management
// 3. Challenge Logic: 30-second challenge with countdown and scoring
// 4. Button Interactions: Selection and deselection with sound effects
// 5. Timer Management: Challenge countdown and result handling
// 6. UI Layout: Button panels and challenge interface
// 7. Result Display: Score display and ranking integration
// =============================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'common_widget.dart';
import 'games_manager.dart';
import 'main.dart';
import 'menu.dart';
import 'extension.dart';
import 'constant.dart';
import 'audio_manager.dart';

class ButtonsPage extends HookConsumerWidget {
  const ButtonsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // --- Challenge State Management ---
    // Button selection tracking and challenge state variables
    final isSelectedButtonsList = useState(panelMax.listListAllFalse(rowMax, columnMax));
    final isDarkBack = useState(false);
    final isBeforeCount = useState(false);
    final isChallengeStart = useState(false);
    final isChallengeFinish = useState(false);
    final isLoadingData = useState(false);

    // --- Timer and Counter State ---
    // Challenge timing and score tracking
    final beforeCount = useState(0);
    final counter = useState(0);
    final currentSeconds = useState(0);

    // --- Riverpod State ---
    // App-wide state providers
    final isMenu = ref.watch(isMenuProvider);
    final isGamesSignIn = ref.watch(gamesSignInProvider);
    final bestScore = ref.watch(bestScoreProvider);

    final lifecycle = useAppLifecycleState();

    // --- Manager Instances ---
    // Audio manager for sound effects
    final audioManager = useMemoized(() => AudioManager());

    // --- Widget Instances ---
    // Common widgets and buttons-specific widget instances
    final common = CommonWidget(context: context);
    final buttons = ButtonsWidget(context: context);

    // --- Initialization Functions ---
    // App initialization and data loading
    // Initialize button states, games sign-in, and best score
    initState() async {
      isLoadingData.value = true;
      try {
        isSelectedButtonsList.value = panelMax.listListAllFalse(rowMax, columnMax);
        ref.read(gamesSignInProvider.notifier).state = await gamesSignIn(isGamesSignIn);
        ref.read(bestScoreProvider.notifier).state = await getBestScore(isGamesSignIn);
        isLoadingData.value = false;
      } catch (e) {
        "Error: $e".debugPrint();
        isLoadingData.value = false;
      }
    }

    // --- Lifecycle Management ---
    // Handle app lifecycle changes (pause/inactive states)
    useEffect(() {
      if (lifecycle == AppLifecycleState.inactive || lifecycle == AppLifecycleState.paused) {
        if (context.mounted) audioManager.stopAll();
      }
      return null;
    }, [lifecycle]);

    // --- Timer Management ---
    // Challenge countdown timer and result handling
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        initState();
        final timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) async {
          if (currentSeconds.value < 0 && isChallengeStart.value) {
            // Challenge finished - handle results
            isDarkBack.value = true;
            isChallengeStart.value = false;
            isChallengeFinish.value = true;
            if (counter.value > bestScore) {
              // New best score achieved
              audioManager.playEffectSound(index: 0, asset: bestScoreSound, volume: 1.0);
              ref.read(bestScoreProvider.notifier).state = counter.value;
              await gamesSubmitScore(bestScore, isGamesSignIn);
              final SharedPreferences prefs = await SharedPreferences.getInstance();
              'bestScore'.setSharedPrefInt(prefs, bestScore);
            }
            "Your Score: ${counter.value}, Best score: $bestScore".debugPrint();
            timer.cancel;
          } else if (isChallengeStart.value) {
            // Challenge countdown in progress
            currentSeconds.value = currentSeconds.value - 1;
            if (currentSeconds.value < 4) audioManager.playEffectSound(index: 0, asset: countdown, volume: 1.0);
            if (currentSeconds.value == 0) audioManager.playEffectSound(index: 0, asset: countdownFinish, volume: 1.0);
          }
        });
        timer.cancel;
      });
      return null;
    }, const []);

    // --- Button Interaction Logic ---
    // Button selection and deselection with sound effects
    // Select button and increment counter
    buttonSelected(int p, i, j) async {
      if (!isSelectedButtonsList.value[p][i][j] && !p.isTranspButton(i, j)) {
        if (!isChallengeStart.value) {
          audioManager.playEffectSound(index: 0, asset: selectButton, volume: 1.0);
          Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
        }
        counter.value = counter.value + 1;
        isSelectedButtonsList.value[p][i][j] = true;
      }
    }

    // Deselect button and decrement counter
    buttonDeSelected(int p, i, j) async {
      if (isSelectedButtonsList.value[p][i][j] && !p.isTranspButton(i, j)) {
        if (!isChallengeStart.value) {
          audioManager.playEffectSound(index: 0, asset: cancelButton, volume: 1.0);
          Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
        }
        counter.value = counter.value - 1;
        isSelectedButtonsList.value[p][i][j] = false;
      }
    }

    // --- Challenge Logic ---
    // Pre-challenge countdown display
    beforeCountdown(int i) {
      audioManager.playEffectSound(index: 0, asset: countdown, volume: 1.0);
      isBeforeCount.value = true;
      beforeCount.value = i;
    }

    // Finish pre-challenge countdown and start challenge
    finishBeforeCountdown() {
      audioManager.playEffectSound(index: 0, asset: countdownFinish, volume: 1.0);
      isDarkBack.value= false;
      isChallengeStart.value = true;
      currentSeconds.value = 30;
    }

    // Start 30-second challenge with countdown sequence
    challengeStart() async {
      counter.value = 0;
      isSelectedButtonsList.value = panelMax.listListAllFalse(rowMax, columnMax);
      isDarkBack.value = true;
      beforeCountdown(3);
      await Future.delayed(const Duration(milliseconds: 500)).then((_) async => isBeforeCount.value = false);
      await Future.delayed(const Duration(milliseconds: 500)).then((_) async => beforeCountdown(2));
      await Future.delayed(const Duration(milliseconds: 500)).then((_) async => isBeforeCount.value = false);
      await Future.delayed(const Duration(milliseconds: 500)).then((_) async => beforeCountdown(1));
      await Future.delayed(const Duration(milliseconds: 500)).then((_) async => isBeforeCount.value = false);
      await Future.delayed(const Duration(milliseconds: 500)).then((_) async => finishBeforeCountdown());
    }

    // Stop 30-second challenge
    challengeStop() {
      counter.value = 0;
      isSelectedButtonsList.value = panelMax.listListAllFalse(rowMax, columnMax);
      isChallengeStart.value = false;
      currentSeconds.value = 0;
    }

    // Return to 1000 buttons interface
    back1000Buttons() {
      isDarkBack.value = false;
      isChallengeFinish.value = false;
    }

    // --- UI Layout ---
    // Main 1000 buttons challenge interface layout
    return Scaffold(
      body: SizedBox(
        width: context.width(),
        height: context.height(),
        child: Stack(children: [
          // Background image with metal decoration
          common.commonBackground(
            width: context.width(),
            image: backgroundStyleList[0].backGroundImage()
          ),
          // Main content container with header and button panels
          Column(children: [
            const Spacer(flex: 3),
            // --- Header Row ---
            // Logo, challenge controls, and score counter
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
              // 1000 buttons logo with leaderboard access
              buttons.titleLogo(isGamesSignIn),
              // Challenge countdown or start button
              (isChallengeStart.value) ? GestureDetector(
                onTap: () => challengeStop(),
                child: buttons.challengeCountdown(currentSeconds.value),
              // Challenge start button
              ): GestureDetector(
                onTap: () => challengeStart(),
                child: buttons.challengeStartButton(),
              ),
              // Button counter display
              buttons.buttonCounter(counter.value),
            ]),
            const Spacer(flex: 1),
            // --- Button Panels ---
            // Scrollable button panels with interactive viewer
            SingleChildScrollView(
              controller: ScrollController(),
              scrollDirection: Axis.horizontal,
              child: InteractiveViewer(
                child: Row(children: [
                  for(int p = 0; p < panelMax; p++) ... {
                    Stack(children: [
                      // Normal size buttons grid
                      Column(children: List.generate(columnMax, (col) =>
                        Row(children: List.generate(rowMax - rowMinus[p][col], (row) =>
                          buttons.normalSizeButton(panel: p, row: row, col: col,
                            isSelected: isSelectedButtonsList.value,
                            select: (p, row, col) => buttonSelected(p, row, col),
                            deSelect: (p, row, col) => buttonDeSelected(p, row, col),
                          ),
                        ))
                      )),
                      // Large circle button in panel 2
                      if (p == 1) Row(children: [
                        SizedBox(width: 1.9 * context.defaultButtonLength()),
                        Column(children: [
                          SizedBox(height: 5.9 * context.defaultButtonLength()),
                          buttons.largeSizeButton(panel: 1, row: 2, col: 6,
                            ratioW: 2.2, ratioH: 2.2,
                            isSelected: isSelectedButtonsList.value,
                            select: (p, row, col) => buttonSelected(1, 2, 6),
                            deSelect: (p, row, col) => buttonDeSelected(1, 2, 6),
                          ),
                        ]),
                      ]),
                      // Long rectangle buttons in panel 3
                      if (p == 3) Row(children: [
                        SizedBox(width: 9 * context.defaultButtonLength()),
                        Column(children: [
                          SizedBox(height: 2 * context.defaultButtonLength()),
                          ...List.generate(2, (i) =>
                            buttons.largeSizeButton(panel: 3, row: 7 + 2 * i, col: 2 + 2 * i,
                              ratioW: 1.0, ratioH: 1.5,
                              isSelected: isSelectedButtonsList.value,
                              select: (p, r, c) => buttonSelected(3, 7 + 2 * i, 2 + 2 * i),
                              deSelect: (p, r, c) => buttonDeSelected(3, 7 + 2 * i, 2 + 2 * i),
                            ),
                          ),
                        ]),
                      ]),
                      // Large circle buttons in panel 4
                      if (p == 4) Row(children: [
                        SizedBox(width: 6.1 * context.defaultButtonLength()),
                        Column(children: [
                          SizedBox(height: 5.8 * context.defaultButtonLength()),
                          Row(children: List.generate(2, (i) =>
                            buttons.largeSizeButton(panel: 4, row: 6 + i, col: 6,
                              ratioW: 1.4, ratioH: 1.4,
                              isSelected: isSelectedButtonsList.value,
                              select: (p, r, c) => buttonSelected(4, 6 + i, 6),
                              deSelect: (p, r, c) => buttonDeSelected(4, 6 + i, 6),
                            ),
                          )),
                        ]),
                      ]),
                      // Large up buttons in panel 4
                      if (p == 4) Row(children: [
                        SizedBox(width: 5.35 * context.defaultButtonLength()),
                        Column(children: [
                          SizedBox(height: 1.85 * context.defaultButtonLength()),
                          buttons.largeSizeButton(panel: 4, row: 5, col: 2,
                            ratioW: 1.3, ratioH: 1.3,
                            isSelected: isSelectedButtonsList.value,
                            select: (p, row, col) => buttonSelected(4, 5, 2),
                            deSelect: (p, row, col) => buttonDeSelected(4, 5, 2),
                          )
                        ]),
                      ]),
                      // Large down buttons in panel 4
                      if (p == 4) Row(children: [
                        SizedBox(width: 1.35 * context.defaultButtonLength()),
                        Column(children: [
                          SizedBox(height: 4.85 * context.defaultButtonLength()),
                          buttons.largeSizeButton(panel: 4, row: 1, col: 5,
                            ratioW: 1.3, ratioH: 1.3,
                            isSelected: isSelectedButtonsList.value,
                            select: (p, row, col) => buttonSelected(4, 1, 5),
                            deSelect: (p, row, col) => buttonDeSelected(4, 1, 5),
                          ),
                        ]),
                      ]),
                    ]),
                    // Panel divider for visual separation
                    if (p != panelMax - 1) buttons.panelDivider(),
                  },
                ]),
              ),
            ),
            const Spacer(flex: 1),
            // Ad space reservation
            SizedBox(height: context.admobHeight()),
          ]),
          // --- Overlay Elements ---
          // Challenge overlay with countdown and results
          if (isDarkBack.value) Container(
            width: context.width(),
            height: context.height(),
            color: transpBlackColor,
            child: Stack(alignment: Alignment.center,
              children: [
                // Pre-challenge countdown display
                if (isBeforeCount.value) buttons.startCountdown(beforeCount.value),
                // Challenge result display
                if (isChallengeFinish.value) Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Spacer(flex: 3),
                    // Challenge result title
                    buttons.resultTitle(),
                    const Spacer(flex: 1),
                    // Challenge result score
                    buttons.resultScore(counter.value),
                    const Spacer(flex: 1),
                    // Challenge best score
                    buttons.resultBestScore(bestScore),
                    const Spacer(flex: 2),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Ranking button
                        buttons.resultRankingButton(isGamesSignIn),
                        // Back button
                        buttons.resultBackButton(onBack: () => back1000Buttons()),
                      ]
                    ),
                    const Spacer(flex: 5),
                  ]
                ),
              ]
            ),
          ),
          // Menu overlay when menu is active
          if (isMenu) const MenuPage(isHome: false),
          // Ad banner with menu toggle functionality
          common.commonAdBanner(
            image: isMenu.buttonChanBackGround(),
            onTap: () async => ref.read(isMenuProvider.notifier).state = await isMenu.pressedMenu()
          ),
          // Loading indicator during data initialization
          if (isLoadingData.value) common.commonCircularProgressIndicator(),
        ]),
      ),
    );
  }
}

// =============================
// ButtonsWidget: 1000 Buttons Challenge Components
//
// This class provides 1000 buttons challenge interface components including:
// 1. Header Components: Logo, challenge controls, and score display
// 2. Button Components: Normal and large size button widgets
// 3. Challenge Components: Countdown and start button interfaces
// 4. Result Components: Challenge result display and navigation
// 5. Layout Components: Panel dividers and spacing elements
// =============================

class ButtonsWidget {

  final BuildContext context;

  ButtonsWidget({
    required this.context,
  });

  // --- Header Components ---
  // 1000 buttons logo with leaderboard access
  Widget titleLogo(bool isGamesSignIn) =>  GestureDetector(
    onTap: () => gamesShowLeaderboard(isGamesSignIn),
    child: Container(
      width: context.logo1000ButtonsWidth(),
      padding: EdgeInsets.all(context.logo1000ButtonsPadding()),
      child: Image.asset(realTitleImage),
    ),
  );

  // Challenge start button with text styling
  Widget challengeStartButton() => Container(
    alignment: Alignment.center,
    width: context.challengeStartButtonWidth(),
    height: context.challengeStartButtonHeight(),
    padding: EdgeInsets.only(
      top: context.countdownPaddingTop(),
    ),
    decoration: BoxDecoration(
      color: blackColor,
      borderRadius: BorderRadius.circular(context.startCornerRadius()),
      border: Border.all(color: whiteColor, width: context.startBorderWidth()),
    ),
    child: Column(mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(context.challenge(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: context.challengeButtonFontSize(),
            fontWeight: FontWeight.bold,
            color: whiteColor,
          ),
        ),
        Text(context.start(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: context.challengeStartFontSize(),
            fontWeight: FontWeight.bold,
            color: whiteColor,
          ),
        ),
      ],
    ),
  );

  Widget challengeCountdown(int countdown) => Container(
    alignment: Alignment.center,
    width: context.challengeStartButtonWidth(),
    height: context.challengeStartButtonHeight(),
    padding: EdgeInsets.only(
      left: context.countdownPaddingLeft(),
      bottom: context.countdownPaddingBottom(),
    ),
    decoration: BoxDecoration(
      color: countdown.startButtonColor(),
      borderRadius: BorderRadius.circular(context.startCornerRadius()),
      border: Border.all(color: whiteColor, width: context.startBorderWidth()),
    ),
    // Countdown number display
    child: Text(countdown.countDownNumber(),
    textAlign: TextAlign.center,
    style: TextStyle(
      color: whiteColor,
      fontFamily: numberFont[0],
      fontSize: context.countdownFontSize(),
    )
  )
);

  // Button counter display with large number styling
  Widget buttonCounter(int counter) => Container(
    width: context.countDisplayWidth(),
    height: context.countDisplayHeight(),
    color: darkBlackColor,
    padding: EdgeInsets.only(
      left: context.countDisplayPaddingLeft(),
      bottom: context.countDisplayPaddingBottom(),
    ),
    child: FittedBox(
      fit: BoxFit.fitWidth,
      child: Text(counter.countNumber(),
        style: TextStyle(
          color: lampColor,
          fontFamily: numberFont[0],
          fontSize: 100,
        ),
      ),
    ),
  );


  // --- Button Components ---
  // Normal size button with gesture handling
  Widget normalSizeButton({
    required int panel,
    required int row,
    required int col,
    required List<List<List<bool>>> isSelected,
    required void Function(int, int, int) select,
    required void Function(int, int, int) deSelect,
  }) => GestureDetector(
    child: Container(
      width: context.buttonWidth(panel, row, col),
      height: context.buttonHeight(),
      padding: EdgeInsets.all(context.buttonsPadding()),
      alignment: Alignment.center,
      child: Image.asset(isSelected.buttonImage(panel, row, col)),
    ),
    onTap: () => select(panel, row, col),
    onLongPress: () => deSelect(panel, row, col),
    onDoubleTap: () => deSelect(panel, row, col),
  );

  // Large size button with customizable ratios
  Widget largeSizeButton({
    required int panel,
    required int row,
    required int col,
    required double ratioW,
    required double ratioH,
    required List<List<List<bool>>> isSelected,
    required void Function(int, int, int) select,
    required void Function(int, int, int) deSelect,
  }) => GestureDetector(
    child: Container(
      width: context.largeButtonWidth(ratioW),
      height: context.largeButtonHeight(ratioH),
      padding: EdgeInsets.all(context.buttonsPadding()),
      alignment: Alignment.center,
      child: Image.asset(isSelected.buttonImage(panel, row, col)),
    ),
    onTap: () => select(panel, row, col),
    onLongPress: () => deSelect(panel, row, col),
    onDoubleTap: () => deSelect(panel, row, col),
  );

  // --- Layout Components ---
  // Panel divider for visual separation
  Widget panelDivider() => Container(
    width: 1,
    height: context.dividerHeight(),
    margin: EdgeInsets.symmetric(horizontal: context.dividerMargin()),
    color: blackColor,
  );

  // --- Challenge Components ---
  // Pre-challenge countdown display with circle background
  Widget startCountdown(int beforeCount) => Stack(
    alignment: Alignment.center,
    children: [
      SizedBox(
        width: context.beforeCountdownCircleSize(),
        height: context.beforeCountdownCircleSize(),
        child: const FittedBox(
          fit: BoxFit.fitWidth,
          child: Image(image: AssetImage(circleButton))
        ),
      ),
      Text("$beforeCount",
        style: TextStyle(
          color: whiteColor,
          fontSize: context.beforeCountdownNumberSize(),
          fontWeight: FontWeight.bold,
          fontFamily: normalFont,
        )
      )
    ]
  );

  // --- Result Components ---
  // Challenge result title display
  Widget resultTitle() => Text(context.yourScore(),
    style: TextStyle(
      color: whiteColor,
      fontWeight: context.lang() == "en" ? FontWeight.normal: FontWeight.bold,
      fontSize: context.scoreTitleFontSize(),
      fontFamily: normalFont
    ),
  );

  // Challenge result score display
  Widget resultScore(int score) => Text(score.countNumber(),
    style: TextStyle(
      color: lampColor,
      fontFamily: numberFont[0],
      fontSize: context.yourScoreFontSize(),
    ),
  );

  // Challenge best score display
  Widget resultBestScore(int bestScore) => Row(mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text("${context.best()}:  ",
        style: TextStyle(
          color: whiteColor,
          fontWeight: context.lang() == "en" ? FontWeight.normal: FontWeight.bold,
          fontSize: context.bestFontSize(),
          fontFamily: normalFont,
        ),
      ),
      Text(bestScore.countNumber(),
        style: TextStyle(
          color: lampColor,
          fontSize: context.bestScoreFontSize(),
          fontFamily: numberFont[0],
        ),
      ),
    ]
  );

  // Ranking button with leaderboard access
  Widget resultRankingButton(bool isSignIn) =>  GestureDetector(
    onTap: () => gamesShowLeaderboard(isSignIn),
    child: Container(
      alignment: Alignment.center,
      width: context.backButtonWidth(),
      height: context.backButtonHeight(),
      decoration: BoxDecoration(
        color: lampColor,
        borderRadius: BorderRadius.circular(context.backButtonBorderRadius()),
      ),
      child: Text(context.ranking(),
        style: TextStyle(
          color: blackColor,
          fontWeight: FontWeight.bold,
          fontSize: context.backButtonFontSize(),
          fontFamily: normalFont,
        ),
      ),
    ),
  );

  // Back button for returning to main interface
  Widget resultBackButton({
    required void Function() onBack
  }) =>  GestureDetector(
    onTap: onBack,
    child: Container(
      alignment: Alignment.center,
      width: context.backButtonWidth(),
      height: context.backButtonHeight(),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(context.backButtonBorderRadius()),
      ),
      child: Text(context.back(),
        style: TextStyle(
          color: blackColor,
          fontWeight: FontWeight.bold,
          fontSize: context.backButtonFontSize(),
          fontFamily: normalFont,
        ),
      ),
    ),
  );
}
