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
// 7. Performance: ANR and crash prevention measures
// =============================

import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:async';
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

    // --- Performance Optimization ---
    // Timer management for preventing memory leaks
    final activeTimers = useState<List<Timer>>([]);
    final isInitialized = useState(false);

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

    // --- Timer Management ---
    // Safe timer creation and cleanup
    void addTimer(Timer timer) {
      activeTimers.value = [...activeTimers.value, timer];
    }

    void clearAllTimers() {
      for (final timer in activeTimers.value) {
        if (timer.isActive) {
          timer.cancel();
        }
      }
      activeTimers.value = [];
    }

    // --- Safe Async Operations ---
    // Wrapper for safe async operations with error handling
    Future<void> safeAsync(Future<void> Function() operation) async {
      try {
        if (context.mounted) {
          await operation();
        }
      } catch (e) {
        "Error in async operation: $e".debugPrint();
      }
    }

    // --- Initialization Functions ---
    // App initialization and lifecycle management
    // Initialize app data including TTS, games sign-in, and best score
    Future<void> initState() async {
      if (isInitialized.value) return;
      
      isLoadingData.value = true;
      try {
        await safeAsync(() async {
          await ttsManager.initTts();
          ref.read(gamesSignInProvider.notifier).state = await gamesSignIn(isGamesSignIn);
          ref.read(bestScoreProvider.notifier).state = await getBestScore(isGamesSignIn);
        });
        isInitialized.value = true;
      } catch (e) {
        "Error in initState: $e".debugPrint();
      } finally {
        isLoadingData.value = false;
      }
    }

    // --- Lifecycle Management ---
    // Initialize app on first build
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await initState();
      });
      return () {
        clearAllTimers();
        safeAsync(() async {
          await audioManager.stopAll();
          await ttsManager.stopTts();
        });
      };
    }, []);

    // Handle app lifecycle changes (pause/inactive states)
    useEffect(() {
      if (lifecycle == AppLifecycleState.inactive || lifecycle == AppLifecycleState.paused) {
        if (context.mounted) {
          safeAsync(() async {
            await audioManager.stopAll();
            await ttsManager.stopTts();
          });
        }
      }
      return null;
    }, [lifecycle]);

    // --- Elevator Movement Logic ---
    // Core elevator movement functions for up and down travel
    // Move elevator upward to target floor with speed calculation
    Future<void> counterUp() async {
      if (!context.mounted || isMoving.value) return;
      
      await safeAsync(() async {
        await ttsManager.speakText(context.upFloor(), true);
      });
      
      int count = 0;
      isMoving.value = true;
      if (isDoorState.value != closedState) isDoorState.value = closedState;
      
      final timer = Timer(Duration(seconds: waitTime.value), () async {
        if (!context.mounted || !isMoving.value) return;
        
        for (int i in counter.value.upFromToNumber(nextFloor.value)) {
          if (!context.mounted || !isMoving.value) break;
          
          final speedTimer = Timer(Duration(milliseconds: i.elevatorSpeed(count, nextFloor.value)), () {
            if (!context.mounted) return;
            
            if (isMoving.value) count++;
            if (isMoving.value && counter.value < nextFloor.value && nextFloor.value < max + 1) {
              counter.value = counter.value + 1;
            }
            if (counter.value == 0) counter.value = 1;
            
            if (isMoving.value && (counter.value == nextFloor.value || counter.value == max)) {
              safeAsync(() async {
                if (context.mounted) await ttsManager.speakText(context.openingSound(counter.value, isShimada), true);
              });
              
              counter.value.clearLowerFloor(isAboveSelectedList.value, isUnderSelectedList.value);
              nextFloor.value = counter.value.upNextFloor(up: isAboveSelectedList.value, down: isUnderSelectedList.value);
              currentFloor.value = counter.value;
              "currentFloor: ${currentFloor.value}, nextFloor: ${nextFloor.value}".debugPrint();
              isMoving.value = false;
              isEmergency.value = false;
              isDoorState.value = openingState;
              "isDoorState: ${isDoorState.value}".debugPrint();
            }
          });
          addTimer(speedTimer);
          
          // Add small delay to prevent UI blocking
          await Future.delayed(const Duration(milliseconds: 10));
        }
      });
      addTimer(timer);
    }

    // Move elevator downward to target floor with speed calculation
    Future<void> counterDown() async {
      if (!context.mounted || isMoving.value) return;
      
      await safeAsync(() async {
        await ttsManager.speakText(context.downFloor(), true);
      });
      
      int count = 0;
      isMoving.value = true;
      if (isDoorState.value != closedState) isDoorState.value = closedState;
      
      final timer = Timer(Duration(seconds: waitTime.value), () async {
        if (!context.mounted || !isMoving.value) return;
        
        for (int i in counter.value.downFromToNumber(nextFloor.value)) {
          if (!context.mounted || !isMoving.value) break;
          
          final speedTimer = Timer(Duration(milliseconds: i.elevatorSpeed(count, nextFloor.value)), () {
            if (!context.mounted) return;
            
            if (isMoving.value) count++;
            if (isMoving.value && min - 1 < nextFloor.value && nextFloor.value < counter.value) {
              counter.value = counter.value - 1;
            }
            if (counter.value == 0) counter.value = -1;
            
            if (isMoving.value && (counter.value == nextFloor.value || counter.value == min)) {
              safeAsync(() async {
                if (context.mounted) await ttsManager.speakText(context.openingSound(counter.value, isShimada), true);
              });
              
              counter.value.clearUpperFloor(isAboveSelectedList.value, isUnderSelectedList.value);
              nextFloor.value = counter.value.downNextFloor(up: isAboveSelectedList.value, down: isUnderSelectedList.value);
              currentFloor.value = counter.value;
              "currentFloor: ${currentFloor.value}, nextFloor: ${nextFloor.value}".debugPrint();
              isMoving.value = false;
              isEmergency.value = false;
              isDoorState.value = openingState;
              "isDoorState: ${isDoorState.value}".debugPrint();
            }
          });
          addTimer(speedTimer);
          
          // Add small delay to prevent UI blocking
          await Future.delayed(const Duration(milliseconds: 10));
        }
      });
      addTimer(timer);
    }

    // --- Floor Selection Logic ---
    // Floor button selection and deselection handling
    // Handle floor button selection with validation and movement logic
    Future<void> floorSelected(int i, bool selectFlag) async {
      if (!context.mounted || isEmergency.value) return;
      
      try {
        if (i == counter.value) {
          if (!isMoving.value && i == nextFloor.value) {
            await safeAsync(() async {
              await ttsManager.speakText(context.pushNumber(), true);
            });
          }
        } else if (!selectFlag) {
          await safeAsync(() async {
            await ttsManager.speakText(context.notStop(), true);
          });
        } else if (!i.isSelected(up: isAboveSelectedList.value, down: isUnderSelectedList.value)) {
          await safeAsync(() async {
            await audioManager.playEffectSound(index: 0, asset: selectButton, volume: 1.0);
            await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
          });
          
          i.trueSelected(up: isAboveSelectedList.value, down: isUnderSelectedList.value);
          if (counter.value < i && i < nextFloor.value) nextFloor.value = i;
          if (counter.value > i && i > nextFloor.value) nextFloor.value = i;
          if (i.onlyTrue(up: isAboveSelectedList.value, down: isUnderSelectedList.value)) nextFloor.value = i;
          "nextFloor: ${nextFloor.value}".debugPrint();
          
          final timer = Timer(Duration(seconds: waitTime.value), () async {
            if (!context.mounted) return;
            
            if (!isMoving.value && !isEmergency.value && isDoorState.value == closedState) {
              if (counter.value < nextFloor.value) {
                await counterUp();
              } else if (counter.value > nextFloor.value) {
                await counterDown();
              } else {
                await safeAsync(() async {
                  if (context.mounted) await ttsManager.speakText(context.pushNumber(), true);
                });
              }
            }
          });
          addTimer(timer);
        }
      } catch (e) {
        "Error in floorSelected: $e".debugPrint();
      }
    }

    // Handle floor button deselection with next floor recalculation
    Future<void> floorCanceled(int i) async {
      if (!context.mounted) return;
      
      try {
        if (i.isSelected(up: isAboveSelectedList.value, down: isUnderSelectedList.value) && i != nextFloor.value) {
          await safeAsync(() async {
            await audioManager.playEffectSound(index: 0, asset: cancelButton, volume: 1.0);
            await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
          });
          
          i.falseSelected(up: isAboveSelectedList.value, down: isUnderSelectedList.value);
          if (i == nextFloor.value) {
            nextFloor.value = (counter.value < nextFloor.value) ?
            counter.value.upNextFloor(up: isAboveSelectedList.value, down: isUnderSelectedList.value) :
            counter.value.downNextFloor(up: isAboveSelectedList.value, down: isUnderSelectedList.value);
          }
          "nextFloor: ${nextFloor.value}".debugPrint();
        }
      } catch (e) {
        "Error in floorCanceled: $e".debugPrint();
      }
    }

    // --- Door Control Logic ---
    // Door opening and closing operations
    // Close elevator doors with state management and movement continuation
    Future<void> doorsClosing() async {
      if (!context.mounted || isMoving.value || isEmergency.value || 
          isDoorState.value == closedState || isDoorState.value == closingState) return;
      
      try {
        isDoorState.value = closingState;
        "isDoorState: ${isDoorState.value}".debugPrint();
        
        await safeAsync(() async {
          await ttsManager.speakText(context.closeDoor(), true);
        });
        
        final timer = Timer(Duration(seconds: waitTime.value), () async {
          if (!context.mounted) return;
          
          if (!isMoving.value && !isEmergency.value && isDoorState.value == closingState) {
            isDoorState.value = closedState;
            "isDoorState: ${isDoorState.value}".debugPrint();
            
            if (counter.value < nextFloor.value) {
              await counterUp();
            } else if (counter.value > nextFloor.value) {
              await counterDown();
            } else {
              await safeAsync(() async {
                if (context.mounted) await ttsManager.speakText(context.pushNumber(), true);
              });
            }
          }
        });
        addTimer(timer);
      } catch (e) {
        "Error in doorsClosing: $e".debugPrint();
      }
    }

    // --- Operation Button Logic ---
    // Open, close, and alert button handling with state management
    // Handle open button press with door opening logic
    Future<void> pressedOpenAction(bool isOn) async {
      if (!context.mounted || isMoving.value) return;
      
      try {
        isPressedOperationButtons.value = [isOn, false, false];
        if (isOn) {
          await safeAsync(() async {
            await audioManager.playEffectSound(index: 0, asset: selectButton, volume: 1.0);
            await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
          });
          
          if (!isMoving.value && !isEmergency.value && 
              isDoorState.value != openedState && isDoorState.value != openingState) {
            
            final flashTimer = Timer(const Duration(milliseconds: flashTime), () async {
              if (!context.mounted) return;
              
              if (!isMoving.value && !isEmergency.value && 
                  isDoorState.value != openedState && isDoorState.value != openingState) {
                
                await safeAsync(() async {
                  if (context.mounted) await ttsManager.speakText(context.openDoor(), true);
                });
                
                isDoorState.value = openingState;
                "isDoorState: ${isDoorState.value}".debugPrint();
                
                final openTimer = Timer(Duration(seconds: waitTime.value), () async {
                  if (!context.mounted) return;
                  
                  if (!isMoving.value && !isEmergency.value && isDoorState.value == openingState) {
                    isDoorState.value = openedState;
                    "isDoorState: ${isDoorState.value}".debugPrint();
                  }
                });
                addTimer(openTimer);
              }
            });
            addTimer(flashTimer);
          }
        }
      } catch (e) {
        "Error in pressedOpenAction: $e".debugPrint();
      }
    }

    // Handle close button press with door closing logic
    Future<void> pressedCloseAction(bool isOn) async {
      if (!context.mounted || isMoving.value) return;
      
      try {
        isPressedOperationButtons.value = [false, isOn, false];
        if (isOn) {
          await safeAsync(() async {
            await audioManager.playEffectSound(index: 0, asset: selectButton, volume: 1.0);
            await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
          });
          
          if (!isMoving.value && !isEmergency.value && 
              isDoorState.value != closedState && isDoorState.value != closingState) {
            
            final flashTimer = Timer(const Duration(milliseconds: flashTime), () async {
              if (!context.mounted) return;
              await doorsClosing();
            });
            addTimer(flashTimer);
          }
        }
      } catch (e) {
        "Error in pressedCloseAction: $e".debugPrint();
      }
    }

    // Handle alert button press with emergency logic and return to first floor
    Future<void> pressedAlertAction(bool isOn, isLongPressed) async {
      if (!context.mounted) return;
      
      try {
        isPressedOperationButtons.value = [false, false, isOn];
        if (isOn && ((currentFloor.value - counter.value).abs() > 5) && ((nextFloor.value - counter.value).abs() > 5)) {
          await safeAsync(() async {
            await audioManager.playEffectSound(index: 0, asset: selectButton, volume: 1.0);
            await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
          });
          
          if (isLongPressed) {
            if (isMoving.value) isEmergency.value = true;
            if (isEmergency.value && isMoving.value) {
              await safeAsync(() async {
                await audioManager.playEffectSound(index: 0, asset: callSound, volume: 1.0);
              });
              
              final emergencyTimer = Timer(Duration(seconds: waitTime.value), () async {
                if (!context.mounted) return;
                
                await safeAsync(() async {
                  if (context.mounted) await ttsManager.speakText(context.emergency(), true);
                });
                
                nextFloor.value = counter.value;
                isMoving.value = false;
                isEmergency.value = true;
                counter.value.clearLowerFloor(isAboveSelectedList.value, isUnderSelectedList.value);
                counter.value.clearUpperFloor(isAboveSelectedList.value, isUnderSelectedList.value);
              });
              addTimer(emergencyTimer);
              
              final returnTimer = Timer(Duration(seconds: openTime.value), () async {
                if (!context.mounted) return;
                
                await safeAsync(() async {
                  if (context.mounted) await ttsManager.speakText(context.return1st(), true);
                });
              });
              addTimer(returnTimer);
              
              final firstFloorTimer = Timer(Duration(seconds: waitTime.value), () async {
                if (!context.mounted) return;
                
                if (counter.value != 1) {
                  nextFloor.value = 1;
                  "nextFloor: ${nextFloor.value}".debugPrint();
                  if (counter.value < nextFloor.value) {
                    await counterUp();
                  } else {
                    await counterDown();
                  }
                } else {
                  await safeAsync(() async {
                    if (context.mounted) await ttsManager.speakText(context.openDoor(), true);
                  });
                  isDoorState.value = openingState;
                  "isDoorState: ${isDoorState.value}".debugPrint();
                }
              });
              addTimer(firstFloorTimer);
            }
          }
        }
      } catch (e) {
        "Error in pressedAlertAction: $e".debugPrint();
      }
    }

    // --- Button Action Management ---
    // Dynamic button action list for operation buttons
    List<dynamic> pressedButtonAction(bool isOn, isLongPressed) => [
      (isOn && isLongPressed) ? () => pressedOpenAction(isOn): (_) => pressedOpenAction(isOn),
      (isOn && isLongPressed) ? () => pressedCloseAction(isOn): (_) => pressedCloseAction(isOn),
      (isOn && isLongPressed) ? () => pressedAlertAction(isOn, isLongPressed): (_) => pressedAlertAction(isOn, isLongPressed),
    ];
    
    // --- Door State Management ---
    // Automatic door state transitions and timing management
    useEffect(() {
      if (isDoorState.value == openingState) {
        final timer = Timer(Duration(seconds: waitTime.value), () {
          if (!context.mounted) return;
          
          isDoorState.value = openedState;
          "isDoorState: ${isDoorState.value}".debugPrint();
          
          if (!isMoving.value && !isEmergency.value && isDoorState.value == openedState) {
            final closeTimer = Timer(Duration(seconds: openTime.value), () async {
              if (!context.mounted) return;
              await doorsClosing();
            });
            addTimer(closeTimer);
          }
        });
        addTimer(timer);
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
                children: [...List.generate(3, (i) => GestureDetector(
                  onTapDown: pressedButtonAction(true, false)[i],
                  onTapUp: pressedButtonAction(false, false)[i],
                  onLongPress: pressedButtonAction(true, true)[i],
                  onLongPressEnd: pressedButtonAction(false, true)[i],
                  child: Container(
                    width: context.operationButtonSize(),
                    height: context.operationButtonSize(),
                    margin: EdgeInsets.only(
                      top: context.operationButtonMargin(),
                    ),
                    child: Image.asset(isShimada.operateBackGround(isPressedOperationButtons.value, buttonStyle)[i]),
                  )))..insert(2, SizedBox(width: context.operationButtonSize()))
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
}