import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'common_widget.dart';
import 'extension.dart';
import 'constant.dart';
import 'games_manager.dart';
import 'main.dart';
import 'menu.dart';
import 'sound_manager.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final isGamesSignIn = ref.watch(gamesSignInProvider);
    final isShimada = ref.watch(isShimadaProvider);
    final isMenu = ref.watch(isMenuProvider);
    final floorNumbers = ref.watch(floorNumbersProvider);
    final floorStops = ref.watch(floorStopsProvider);
    final buttonShape = ref.watch(buttonShapeProvider);
    final buttonStyle = ref.watch(buttonStyleProvider);
    final backgroundStyle = ref.watch(backgroundStyleProvider);

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

    //Manager
    final ttsManager = useMemoized(() => TtsManager(context: context));
    final audioManager = useMemoized(() => AudioManager());

    //Class
    final common = CommonWidget(context: context);
    final home = HomeWidget(
        context: context,
        floorNumbers: floorNumbers,
        floorStops: floorStops,
        buttonStyle: buttonStyle,
        buttonShape: buttonShape
    );

    initState() async {
      isLoadingData.value = true;
      try {
        await ttsManager.initTts();
        ref.read(gamesSignInProvider.notifier).state = await gamesSignIn(isGamesSignIn);
        ref.read(bestScoreProvider.notifier).state = await getBestScore(isGamesSignIn);
        isLoadingData.value = false;
      } catch (e) {
        "Error: $e".debugPrint();
        isLoadingData.value = false;
      }
    }

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await initState();
      });
      return null;
    }, []);

    useEffect(() {
      if (lifecycle == AppLifecycleState.inactive || lifecycle == AppLifecycleState.paused) {
        if (context.mounted) {
          audioManager.stopAll();
          ttsManager.stopTts();
        }
      }
      return null;
    }, [lifecycle]);

    ///Going up floor
    counterUp() async {
      ttsManager.speakText(context.upFloor(), true);
      int count = 0;
      isMoving.value = true;
      if (isDoorState.value != closedState) isDoorState.value = closedState;
      await Future.delayed(Duration(seconds: waitTime.value)).then((_) {
        Future.forEach(counter.value.upFromToNumber(nextFloor.value), (int i) async {
          await Future.delayed(Duration(milliseconds: i.elevatorSpeed(count, nextFloor.value))).then((_) async {
            if (isMoving.value) count++;
            if (isMoving.value && counter.value < nextFloor.value && nextFloor.value < max + 1) counter.value = counter.value + 1;
            if (counter.value == 0) counter.value = 1;
            if (isMoving.value && (counter.value == nextFloor.value || counter.value == max)) {
              if (context.mounted) ttsManager.speakText(context.openingSound(counter.value, isShimada), true);
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
        });
      });
    }

    ///Going down floor
    counterDown() async {
      ttsManager.speakText(context.downFloor(), true);
      int count = 0;
      isMoving.value = true;
      if (isDoorState.value != closedState) isDoorState.value = closedState;
      await Future.delayed(Duration(seconds: waitTime.value)).then((_) {
        Future.forEach(counter.value.downFromToNumber(nextFloor.value), (int i) async {
          await Future.delayed(Duration(milliseconds: i.elevatorSpeed(count, nextFloor.value))).then((_) async {
            if (isMoving.value) count++;
            if (isMoving.value && min - 1 < nextFloor.value && nextFloor.value < counter.value) counter.value = counter.value - 1;
            if (counter.value == 0) counter.value = -1;
            if (isMoving.value && (counter.value == nextFloor.value || counter.value == min)) {
              if (context.mounted) ttsManager.speakText(context.openingSound(counter.value, isShimada), true);
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
        });
      });
    }

    ///Select floor button
    floorSelected(int i, bool selectFlag) async {
      if (!isEmergency.value) {
        if (i == counter.value) {
          if (!isMoving.value && i == nextFloor.value) ttsManager.speakText(context.pushNumber(), true);
        } else if (!selectFlag) {
          ttsManager.speakText(context.notStop(), true);
        } else if (!i.isSelected(up: isAboveSelectedList.value, down: isUnderSelectedList.value)) {
          await audioManager.playEffectSound(index: 0, asset: selectButton, volume: 1.0);
          await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
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

    ///Deselect floor button
    floorCanceled(int i) async {
      if (i.isSelected(up: isAboveSelectedList.value, down: isUnderSelectedList.value) && i != nextFloor.value) {
        await audioManager.playEffectSound(index: 0, asset: cancelButton, volume: 1.0);
        await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
        i.falseSelected(up: isAboveSelectedList.value, down: isUnderSelectedList.value);
        if (i == nextFloor.value) {
          nextFloor.value = (counter.value < nextFloor.value) ?
          counter.value.upNextFloor(up: isAboveSelectedList.value, down: isUnderSelectedList.value) :
          counter.value.downNextFloor(up: isAboveSelectedList.value, down: isUnderSelectedList.value);
        }
        "nextFloor: ${nextFloor.value}".debugPrint();
      }
    }


    ///Close door
    doorsClosing() async {
      if (!isMoving.value && !isEmergency.value && isDoorState.value != closedState && isDoorState.value != closingState) {
        isDoorState.value = closingState;
        "isDoorState: ${isDoorState.value}".debugPrint();
        await ttsManager.speakText(context.closeDoor(), true);
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

    ///Pressed open button action
    pressedOpenAction(bool isOn) async {
      if (!isMoving.value) {
        isPressedOperationButtons.value = [isOn, false, false];
        if (isOn) {
          await audioManager.playEffectSound(index: 0, asset: selectButton, volume: 1.0);
          await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
          if (!isMoving.value && !isEmergency.value && isDoorState.value != openedState && isDoorState.value != openingState) {
            Future.delayed(const Duration(milliseconds: flashTime)).then((_) async {
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
            });
          }
        }
      } else {
        isPressedOperationButtons.value = [false, false, false];
      }
    }

    ///Pressed close button action
    pressedCloseAction(bool isOn) async {
      if (!isMoving.value) {
        isPressedOperationButtons.value = [false, isOn, false];
        if (isOn) {
          await audioManager.playEffectSound(index: 0, asset: selectButton, volume: 1.0);
          await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
          if (!isMoving.value && !isEmergency.value && isDoorState.value != closedState && isDoorState.value != closingState) {
            Future.delayed(const Duration(milliseconds: flashTime)).then((_) => doorsClosing());
          }
        }
      } else {
        isPressedOperationButtons.value = [false, false, false];
      }
    }

    ///Long pressed alert button action
    pressedAlertAction(bool isOn, isLongPressed) async {
      isPressedOperationButtons.value = [false, false, isOn];
      if (isOn && ((currentFloor.value - counter.value).abs() > 5) && ((nextFloor.value - counter.value).abs() > 5)) {
        await audioManager.playEffectSound(index: 0, asset: selectButton, volume: 1.0);
        await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
        if (isLongPressed) {
          if (isMoving.value) isEmergency.value = true;
          if (isEmergency.value && isMoving.value) {
            await audioManager.playEffectSound(index: 0, asset: callSound, volume: 1.0);
            await Future.delayed(Duration(seconds: waitTime.value)).then((_) {
              if (context.mounted) ttsManager.speakText(context.emergency(), true);
              nextFloor.value = counter.value;
              isMoving.value = false;
              isEmergency.value = true;
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
        }
      }
    }

    ///Button action list
    List<dynamic> pressedButtonAction(bool isOn, isLongPressed) => [
      (isOn && isLongPressed) ? () => pressedOpenAction(isOn): (_) => pressedOpenAction(isOn),
      (isOn && isLongPressed) ? () => pressedCloseAction(isOn): (_) => pressedCloseAction(isOn),
      (isOn && isLongPressed) ? () => pressedAlertAction(isOn, isLongPressed): (_) => pressedAlertAction(isOn, isLongPressed),
    ];
    
    ///Action after changing door state
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

    return Scaffold(
      backgroundColor: blackColor,
      body: Stack(alignment: Alignment.center,
        children: [
          common.commonBackground(
            width: context.widthResponsible(),
            image: backgroundStyle.backGroundImage(),
          ),
          Container(
            alignment: Alignment.center,
            width: context.displayWidth(),
            height: context.height(),
            child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              ///Display
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
              ///Operation Buttons (Open, Close, Alert)
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
              ///Floor Buttons
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
              SizedBox(height: context.admobHeight()),
            ]),
          ),
          ///Menu
          if (isMenu) const MenuPage(isHome: true),
          ///AdBanner
          common.commonAdBanner(
            image: isMenu.buttonChanBackGround(),
            onTap: () async => ref.read(isMenuProvider.notifier).state = await isMenu.pressedMenu()
          ),
          ///Progress Indicator
          if (isLoadingData.value) common.commonCircularProgressIndicator(),
        ]
      ),
    );
  }
}

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

  ///Display
  //Display arrow
  Widget displayArrow(String image) => Container(
    width: context.displayArrowWidth(),
    height: context.displayArrowHeight(),
    margin: EdgeInsets.only(
      top: context.displayMargin(),
      left: context.displayMargin(),
    ),
    child: Image.asset(image),
  );

  //Display floor number
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

  //Shimada logo
  Widget displayShimadaLogo() => Container(
    margin: EdgeInsets.only(top: context.shimadaLogoTopMargin()),
    child: Image.asset(shimadaImage,
      height: context.shimadaLogoHeight(),
      color: transpDarkColor,
      colorBlendMode: BlendMode.darken,
    )
  );
}