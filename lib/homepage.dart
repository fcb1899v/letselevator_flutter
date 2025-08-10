// =============================
// HomePage: Main Elevator Simulator Interface
//
// This file contains the main elevator simulator interface with:
// 1. State Management: Riverpod providers and local state management
// 2. Initialization: App lifecycle and data loading
// 3. Elevator Movement: Up/down movement logic and floor selection
// 4. Door Control: Opening/closing door operations
// 5. Button Interactions: Floor and operation button handling
// 6. UI Layout: Display, buttons, and responsive design
// =============================

import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'common_widget.dart';
import 'extension.dart';
import 'constant.dart';
import 'games_manager.dart';
import 'main.dart';
import 'menu.dart';
import 'audio_manager.dart';
import 'tts_manager.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // --- State Management ---
    // Riverpod providers for app-wide state management
    final isGamesSignIn = ref.watch(gamesSignInProvider);
    final isShimada = ref.watch(isShimadaProvider);
    final isMenu = ref.watch(isMenuProvider);
    final floorNumbers = ref.watch(floorNumbersProvider);
    final floorStops = ref.watch(floorStopsProvider);
    final buttonShape = ref.watch(buttonShapeProvider);
    final buttonStyle = ref.watch(buttonStyleProvider);
    final backgroundStyle = ref.watch(backgroundStyleProvider);

    // --- Local State Variables ---
    // Elevator position and movement state
    final counter = useState(1);
    final currentFloor = useState(1);
    final nextFloor = useState(1);
    final isMoving = useState(false);
    final isEmergency = useState(false);
    final isDoorState = useState(closedState); //[opened, closed, opening, closing]
    final isPressedOperationButtons = useState([false, false, false]);  //open, close, alert
    final isAboveSelectedList = useState(List.generate(max + 1, (_) => false));
    final isUnderSelectedList = useState(List.generate(min * (-1) + 1, (_) => false));
    final isLoadingData = useState(false);
    final waitTime = useState(initialWaitTime);
    final openTime = useState(initialOpenTime);
    final lifecycle = useAppLifecycleState();

    // --- Manager Instances ---
    // Audio and text-to-speech managers for sound effects
    final ttsManager = useMemoized(() => TtsManager(context: context));
    final audioManager = useMemoized(() => AudioManager());

    // --- Widget Instances ---
    // Common widgets and home-specific widget instances
    final common = CommonWidget(context: context);
    final home = HomeWidget(
      context: context,
      floorNumbers: floorNumbers,
      floorStops: floorStops,
      buttonStyle: buttonStyle,
      buttonShape: buttonShape
    );

    // --- Initialization Functions ---
    // App initialization and lifecycle management
    // Initialize app data including TTS, games sign-in, and best score
    initState() async {
      isLoadingData.value = true;
      try {
        await ttsManager.initTts();
        ref.read(gamesSignInProvider.notifier).state = await gamesSignIn(isGamesSignIn);
        ref.read(bestScoreProvider.notifier).state = await getBestScore(isGamesSignIn);
      } catch (e) {
        "Error: $e".debugPrint();
      } finally {
        isLoadingData.value = false;
        FlutterNativeSplash.remove();
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

    // --- App Lifecycle Effect ---
    // Handle app lifecycle changes (pause, resume) to stop audio and TTS
    useEffect(() {
      Future<void> handleLifecycleChange() async {
        if (!context.mounted) return;
        if (lifecycle == AppLifecycleState.inactive || lifecycle == AppLifecycleState.paused) {
          try {
            await audioManager.stopAudio();
            await ttsManager.stopTts();
          } catch (e) {
            'Error handling stop for player: $e'.debugPrint();
          }
        }
      }
      handleLifecycleChange();
      return null;
    }, [lifecycle, context.mounted]);

    // --- Elevator Movement Logic ---
    // Core elevator movement functions for up and down travel
    // Move elevator upward to target floor with speed calculation
    counterUp() async {
      if (!isMoving.value && isDoorState.value == closedState) {
        await Future.delayed(Duration(seconds: waitTime.value)).then((_) async {
          if (!isMoving.value && isDoorState.value == closedState) {
            isMoving.value = true;
            int count = 0;
            if (context.mounted) await ttsManager.speakText(context.upFloor(), true);
            Future.forEach(counter.value.upFromToNumber(nextFloor.value), (int i) async {
              await Future.delayed(Duration(milliseconds: i.elevatorSpeed(count, nextFloor.value))).then((_) async {
                if (isMoving.value) {
                  count++;
                  if (counter.value < nextFloor.value && nextFloor.value < max + 1) counter.value = counter.value + 1;
                  if (counter.value == 0) counter.value = 1;
                  if (counter.value == nextFloor.value || counter.value == max) {
                    if (context.mounted) ttsManager.speakText(context.openingSound(counter.value, isShimada), true);
                    counter.value.clearLowerFloor(isAboveSelectedList.value, isUnderSelectedList.value);
                    nextFloor.value = counter.value.upNextFloor(up: isAboveSelectedList.value, down: isUnderSelectedList.value);
                    currentFloor.value = counter.value;
                    "currentFloor: ${currentFloor.value}, nextFloor: ${nextFloor.value}".debugPrint();
                    isMoving.value = false;
                    isEmergency.value = false;
                    audioManager.playEffectSound(asset: openSound, volume: 1.0);
                    isDoorState.value = openingState;
                    "isDoorState: ${isDoorState.value}".debugPrint();
                  }
                } else {
                  return;
                }
              });
            });
          }
        });
      }
    }

    // Move elevator downward to target floor with speed calculation
    counterDown() async {
      if (!isMoving.value && isDoorState.value == closedState) {
        await Future.delayed(Duration(seconds: waitTime.value)).then((_) async {
          if (!isMoving.value && isDoorState.value == closedState) {
            isMoving.value = true;
            int count = 0;
            if (context.mounted) await ttsManager.speakText(context.downFloor(), true);
            Future.forEach(counter.value.downFromToNumber(nextFloor.value), (int i) async {
              await Future.delayed(Duration(milliseconds: i.elevatorSpeed(count, nextFloor.value))).then((_) async {
                if (isMoving.value) {
                  count++;
                  if (min - 1 < nextFloor.value && nextFloor.value < counter.value) counter.value = counter.value - 1;
                  if (counter.value == 0) counter.value = -1;
                  if (counter.value == nextFloor.value || counter.value == min) {
                    if (context.mounted) ttsManager.speakText(context.openingSound(counter.value, isShimada), true);
                    counter.value.clearUpperFloor(isAboveSelectedList.value, isUnderSelectedList.value);
                    nextFloor.value = counter.value.downNextFloor(up: isAboveSelectedList.value, down: isUnderSelectedList.value);
                    currentFloor.value = counter.value;
                    "currentFloor: ${currentFloor.value}, nextFloor: ${nextFloor.value}".debugPrint();
                    isMoving.value = false;
                    isEmergency.value = false;
                    audioManager.playEffectSound(asset: openSound, volume: 1.0);
                    isDoorState.value = openingState;
                    "isDoorState: ${isDoorState.value}".debugPrint();
                  }
                } else {
                  return;
                }
              });
            });
          }
        });
      }
    }

    // --- Floor Selection Logic ---
    // Floor button selection and deselection handling
    // Handle floor button selection with validation and movement logic
    floorSelected(int i, bool selectFlag) async {
      audioManager.playEffectSound(asset: selectSound, volume: 0.8);
      Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      if (!isEmergency.value) {
        if (i == counter.value) {
          if (context.mounted && !isMoving.value && i == nextFloor.value) ttsManager.speakText(context.pushNumber(), true);
        } else if (!selectFlag) {
          if (context.mounted) ttsManager.speakText(context.notStop(), true);
        } else if (!i.isSelected(up: isAboveSelectedList.value, down: isUnderSelectedList.value)) {
          i.trueSelected(up: isAboveSelectedList.value, down: isUnderSelectedList.value);
          if (counter.value < i && i < nextFloor.value) nextFloor.value = i;
          if (counter.value > i && i > nextFloor.value) nextFloor.value = i;
          if (i.onlyTrue(up: isAboveSelectedList.value, down: isUnderSelectedList.value)) nextFloor.value = i;
          "nextFloor: ${nextFloor.value}".debugPrint();
          await Future.delayed(Duration(seconds: waitTime.value)).then((_) async {
            if (!isMoving.value && !isEmergency.value && isDoorState.value == closedState) {
              (counter.value < nextFloor.value) ? counterUp() :
              (counter.value > nextFloor.value) ? counterDown() :
              (context.mounted) ? ttsManager.speakText(context.pushNumber(), true): null;
            }
          });
        }
      }
    }

    // Handle floor button deselection with next floor recalculation
    floorCanceled(int i) async {
      if (i.isSelected(up: isAboveSelectedList.value, down: isUnderSelectedList.value) && i != nextFloor.value) {
        audioManager.playEffectSound(asset: cancelSound, volume: 1.0);
        Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
        i.falseSelected(up: isAboveSelectedList.value, down: isUnderSelectedList.value);
        if (i == nextFloor.value) {
          nextFloor.value = (counter.value < nextFloor.value) ?
          counter.value.upNextFloor(up: isAboveSelectedList.value, down: isUnderSelectedList.value) :
          counter.value.downNextFloor(up: isAboveSelectedList.value, down: isUnderSelectedList.value);
        }
        "nextFloor: ${nextFloor.value}".debugPrint();
      } else {
        audioManager.playEffectSound(asset: selectSound, volume: 0.8);
        Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      }
    }

    // --- Door Control Logic ---
    // Functions for managing elevator door states and operations

    // Open elevator doors with state management and movement continuation
    doorsOpening() async {
      if (!isMoving.value && !isEmergency.value && isDoorState.value != openedState && isDoorState.value != openingState) {
        if (context.mounted) ttsManager.speakText(context.openDoor(), true);
        isDoorState.value = openingState;
        "isDoorState: ${isDoorState.value}".debugPrint();
        await Future.delayed(Duration(seconds: waitTime.value)).then((_) {
          if (!isMoving.value && !isEmergency.value && isDoorState.value == openingState) {
            isDoorState.value = openedState;
            "isDoorState: ${isDoorState.value}".debugPrint();
          }
        });
      }
    }

    // Close elevator doors with state management and movement continuation
    doorsClosing() async {
      if (!isMoving.value && !isEmergency.value && isDoorState.value != closedState && isDoorState.value != closingState) {
        await audioManager.playEffectSound(asset: closeSound, volume: 1.0);
        if (context.mounted) await ttsManager.speakText(context.closeDoor(), true);
        isDoorState.value = closingState;
        "isDoorState: ${isDoorState.value}".debugPrint();
        await Future.delayed(Duration(seconds: waitTime.value)).then((_) {
          if (!isMoving.value && !isEmergency.value && isDoorState.value == closingState) {
            isDoorState.value = closedState;
            "isDoorState: ${isDoorState.value}".debugPrint();
            (counter.value < nextFloor.value) ? counterUp():
            (counter.value > nextFloor.value) ? counterDown():
            (context.mounted) ? ttsManager.speakText(context.pushNumber(), true): null;
          }
        });
      }
    }

    // --- Operation Button Logic ---
    // Open, close, and alert button handling with state management
    // Handle open button press with door opening logic
    pressedOpenAction(bool isLongPressed) async {
      if (!isPressedOperationButtons.value[0] && !isMoving.value) {
        audioManager.playEffectSound(asset: selectSound, volume: 0.8);
        Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
        if (!isMoving.value && !isEmergency.value) {
          isPressedOperationButtons.value = isPressedOperationButtons.value.setOperationButtonLamp(true, 0);
          Future.delayed(const Duration(milliseconds: operationTime)).then((_) {
            if (!isLongPressed) isPressedOperationButtons.value = isPressedOperationButtons.value.setOperationButtonLamp(false, 0);
            doorsOpening();
          });
        }
      }
    }

    // Handle close button press with door closing logic
    pressedCloseAction(bool isLongPressed) async {
      if (!isPressedOperationButtons.value[1]) {
        audioManager.playEffectSound(asset: selectSound, volume: 0.8);
        Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
        if (!isMoving.value && !isEmergency.value) {
          isPressedOperationButtons.value = isPressedOperationButtons.value.setOperationButtonLamp(true, 1);
          if (!isMoving.value && !isEmergency.value) {
            Future.delayed(const Duration(milliseconds: operationTime)).then((_) {
              if (!isLongPressed) isPressedOperationButtons.value = isPressedOperationButtons.value.setOperationButtonLamp(false, 1);
              doorsClosing();
            });
          }
        }
      }
    }

    // Handle alert button press with emergency logic and return to first floor
    pressedAlertAction(bool isLongPressed) async {
      isPressedOperationButtons.value = isPressedOperationButtons.value.setOperationButtonLamp(true, 2);
      audioManager.playEffectSound(asset: selectSound, volume: 0.8);
      Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
      Future.delayed(const Duration(milliseconds: operationTime)).then((_) async {
        if (isLongPressed) {
          if (isMoving.value && !isEmergency.value && ((currentFloor.value - counter.value).abs() > 5) && ((nextFloor.value - counter.value).abs() > 5)) {
            isEmergency.value = true;
            isMoving.value = false;
            await audioManager.playEffectSound(asset: callSound, volume: 1.0);
            await Future.delayed(Duration(seconds: waitTime.value)).then((_) {
              if (context.mounted) ttsManager.speakText(context.emergency(), true);
              nextFloor.value = counter.value;
              counter.value.clearLowerFloor(isAboveSelectedList.value, isUnderSelectedList.value);
              counter.value.clearUpperFloor(isAboveSelectedList.value, isUnderSelectedList.value);
            });
            await Future.delayed(Duration(seconds: openTime.value)).then((_) async {
              if (context.mounted) ttsManager.speakText(context.return1st(), true);
            });
            await Future.delayed(Duration(seconds: waitTime.value)).then((_) async {
              if (counter.value != 1) {
                nextFloor.value = 1;
                "nextFloor: ${nextFloor.value}".debugPrint();
                (counter.value < nextFloor.value) ? counterUp() : counterDown();
              } else {
                if (context.mounted) ttsManager.speakText(context.openDoor(), true);
                isDoorState.value = openingState;
                "isDoorState: ${isDoorState.value}".debugPrint();
              }
            });
          }
        } else {
          isPressedOperationButtons.value = isPressedOperationButtons.value.setOperationButtonLamp(false, 2);
        }
      });
    }

    // --- Door State Management ---
    // Automatic door state transitions and timing management
    useEffect(() {
      if (isDoorState.value == openingState) {
        Future.delayed(Duration(seconds: waitTime.value)).then((_) {
          isDoorState.value = openedState;
          "isDoorState: ${isDoorState.value}".debugPrint();
          if (!isMoving.value && !isEmergency.value && isDoorState.value == openedState) {
            Future.delayed(Duration(seconds: openTime.value)).then((_) async => doorsClosing());
          }
        });
      } else if (isDoorState.value == closingState) {
        doorsClosing();
      }
      return null;
    }, [isDoorState.value]);

    // --- UI Layout ---
    // Main elevator interface layout with responsive design
    return Scaffold(
      backgroundColor: blackColor,
      body: Stack(alignment: Alignment.center,
        children: [
          // Background image with responsive sizing
          common.commonBackground(
            width: context.widthResponsible(),
            image: backgroundStyle.backGroundImage(),
          ),
          // Main content container with display and buttons
          Container(
            alignment: Alignment.center,
            width: context.displayWidth(),
            height: context.height(),
            child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              // --- Display Panel ---
              // Elevator display with floor number and direction arrow
              Container(
                width: context.displayWidth(),
                height: context.displayHeight(),
                color: displayBackgroundColor[buttonStyle],
                child: Stack(alignment: Alignment.center,
                  children: [
                    if (isShimada) home.displayShimadaLogo(),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        home.displayArrow(counter.value.arrowImage(isMoving.value, nextFloor.value, buttonStyle)),
                        home.displayNumber(counter.value),
                      ]
                    )
                  ],
                ),
              ),
              // --- Operation Buttons ---
              // Open, close, and alert button row with gesture handling
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => pressedOpenAction(false),
                    onLongPress: () => pressedOpenAction(true),
                    onLongPressStart: (_) => isPressedOperationButtons.value = isPressedOperationButtons.value.setOperationButtonLamp(!isMoving.value && !isEmergency.value, 0),
                    onLongPressEnd:(_) => isPressedOperationButtons.value = isPressedOperationButtons.value.setOperationButtonLamp(false, 0),
                    child: home.operationButton(isShimada.operateBackGround(isPressedOperationButtons.value, buttonStyle)[0])
                  ),
                  GestureDetector(
                    onTap: () => pressedCloseAction(false),
                    onLongPress: () => pressedCloseAction(true),
                    onLongPressStart: (_) => isPressedOperationButtons.value = isPressedOperationButtons.value.setOperationButtonLamp(!isMoving.value && !isEmergency.value, 1),
                    onLongPressEnd:(_) => isPressedOperationButtons.value = isPressedOperationButtons.value.setOperationButtonLamp(false, 1),
                    child: home.operationButton(isShimada.operateBackGround(isPressedOperationButtons.value, buttonStyle)[1])
                  ),
                  SizedBox(width: context.operationButtonSize()),
                  GestureDetector(
                    onTap: () => pressedAlertAction(false),
                    onLongPress: () => pressedAlertAction(true),
                    onLongPressStart: (_) => isPressedOperationButtons.value = isPressedOperationButtons.value.setOperationButtonLamp(!isEmergency.value, 2),
                    onLongPressEnd:(_) => isPressedOperationButtons.value = isPressedOperationButtons.value.setOperationButtonLamp(false, 2),
                    child: home.operationButton(isShimada.operateBackGround(isPressedOperationButtons.value, buttonStyle)[2]),
                  ),
                ],
              ),
              // --- Floor Buttons Grid ---
              // Dynamic floor button grid with selection handling
              Column(children: floorNumbers.toReversedMatrix(4).asMap().entries.map((row) =>
                Column(children: [
                  SizedBox(height: context.buttonMargin()),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: row.value.asMap().entries.map((col) => Row(children: [
                      GestureDetector(
                        onTap: () => floorSelected(col.value, floorStops.toReversedMatrix(4)[row.key][col.key]),
                        onLongPress: () => floorCanceled(col.value),
                        onDoubleTap: () => floorCanceled(col.value),
                        child: common.floorButtonImage(
                          image: col.value.floorButtonBackgroundImage(
                            shimada: isShimada,
                            row: row.key,
                            col: col.key,
                            up: isAboveSelectedList.value,
                            down: isUnderSelectedList.value,
                            style: buttonStyle,
                            shape: buttonShape,
                          ),
                          size: context.floorButtonSize(),
                          number: isShimada ? "": col.value.buttonNumber(),
                          fontSize: context.buttonNumberFontSize(),
                          color: col.value.floorButtonNumberColor(
                            up: isAboveSelectedList.value,
                            down: isUnderSelectedList.value,
                            style: buttonStyle,
                            shape: buttonShape,
                          ),
                          marginTop: context.floorButtonNumberMarginTop(buttonShape.buttonShapeIndex()),
                          marginBottom: context.floorButtonNumberMarginBottom(buttonShape.buttonShapeIndex()),
                        ),
                      ),
                    ])).toList(),
                  ),
                  if (row.key == floorNumbers.toReversedMatrix(4).length - 1) SizedBox(height: context.buttonMargin()),
                ])
              ).toList()),
              // Ad space reservation
              SizedBox(height: context.admobHeight()),
            ]),
          ),
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
// HomeWidget: Display Components for Elevator Interface
//
// This class provides display widgets for the elevator interface including:
// 1. Display Arrow: Direction indicator for elevator movement
// 2. Display Number: Floor number display with different styles
// 3. Shimada Logo: Brand logo display for Shimada mode
// =============================

class HomeWidget {

  final BuildContext context;
  final List<int> floorNumbers;
  final List<bool> floorStops;
  final int buttonStyle;
  final String buttonShape;

  HomeWidget({
    required this.context,
    required this.floorNumbers,
    required this.floorStops,
    required this.buttonStyle,
    required this.buttonShape,
  });

  // --- Display Components ---
  // Direction arrow display for elevator movement indication
  Widget displayArrow(String image) => Container(
    width: context.displayArrowWidth(),
    height: context.displayArrowHeight(),
    margin: EdgeInsets.only(
      top: context.displayMargin(),
      left: context.displayMargin(),
    ),
    child: Image.asset(image),
  );

  // Floor number display with style-based formatting
  Widget displayNumber(int counter) => Container(
    alignment: Alignment.topRight,
    width: context.displayNumberWidth(),
    height: context.displayNumberHeight(),
    margin: EdgeInsets.only(
      top: context.displayNumberMargin(buttonStyle),
      right: context.displayMargin()
    ),
    child: useMemoized(() => HookBuilder(
      builder: (context) =>(buttonStyle == 0) ? Text(counter.displayNumber(),
        style: TextStyle(
          color: displayNumberColor[buttonStyle],
          fontSize: context.displayNumberFontSize(),
          fontWeight: FontWeight.normal,
          fontFamily: numberFont[buttonStyle],
        ),
      ): Text.rich(textAlign: TextAlign.right,
        TextSpan(children: [
          TextSpan(
            text: counter.displayNumberHeader(),
            style: TextStyle(
              color: displayNumberColor[buttonStyle],
              fontSize: context.displayNumberHeaderFontSize(),
              fontWeight: FontWeight.normal,
              fontFamily: alphabetFont[buttonStyle],
            ),
          ),
          TextSpan(
            text: " ",
            style: TextStyle(
              fontSize: context.displayNumberHeaderMargin(),
              fontFamily: numberFont[buttonStyle],
            ),
          ),
          TextSpan(
            text: "${counter.abs()}",
            style: TextStyle(
              color: displayNumberColor[buttonStyle],
              fontSize: context.displayNumberFontSize(),
              fontWeight: FontWeight.normal,
              fontFamily: numberFont[buttonStyle],
            ),
          ),
        ])
      ),
    ), [counter]),
  );

  // Shimada Electric brand logo display
  Widget displayShimadaLogo() => Container(
    margin: EdgeInsets.only(top: context.shimadaLogoTopMargin()),
    child: Image.asset(shimadaImage,
      height: context.shimadaLogoHeight(),
      color: transpDarkColor,
      colorBlendMode: BlendMode.darken,
    )
  );

  Widget operationButton(String image) => Container(
    width: context.operationButtonSize(),
    height: context.operationButtonSize(),
    margin: EdgeInsets.only(
      top: context.operationButtonMargin(),
    ),
    child: Image.asset(image),
  );
}