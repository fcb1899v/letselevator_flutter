import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'many_buttons_extension.dart';
import 'constant.dart';

Widget real1000ButtonsTitle(BuildContext context, double width, String realTitleImage) =>
    Container(
      height: width.startHeight(),
      padding: EdgeInsets.all(width.startPadding() * 0.5),
      child: Image(image: AssetImage(realTitleImage)),
    );

Widget challengeStartText(BuildContext context, double width, int number, bool flag) =>
    Container(
      width: width.startWidth(),
      height: width.startHeight(),
      padding: EdgeInsets.only(
        top: width.startPadding() * (flag ? 1.1: 0.4),
        left: width.startPadding() * (flag ? 2: 1),
        right: width.startPadding() * (flag ? 1.5: 1),
        bottom: width.startPadding() * (flag ? 0.5: 0),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!flag) FittedBox(
            fit: BoxFit.fitWidth,
            child: Text(AppLocalizations.of(context)!.challenge,
              style: const TextStyle(
                fontSize: 100,
                fontWeight: FontWeight.bold,
                color: whiteColor,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.fitHeight,
            child: Text(number.startButtonText(context, flag),
              style: TextStyle(
                fontFamily: (flag) ? numberFont: null,
                fontSize: 80,
                fontWeight: (flag) ? FontWeight.normal: FontWeight.bold,
                color: whiteColor,
              ),
            ),
          ),
        ],
      ),
    );

ButtonStyle challengeStartStyle(double width, int number, bool flag) =>
    ButtonStyle(
      backgroundColor: MaterialStateProperty.all(number.startButtonColor(flag)),
      shape: MaterialStateProperty.all(RoundedRectangleBorder(
        side: BorderSide(color: whiteColor, width: width.startBorderWidth()),
        borderRadius: BorderRadius.circular(width.startCornerRadius()),
      )),
      padding: MaterialStateProperty.all(EdgeInsets.zero),
      minimumSize: MaterialStateProperty.all(Size.zero),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

Widget countDisplay(double width, int counter) {
  return Container(
    width: width.startHeight() * 2.2,
    height: width.startHeight(),
    color: darkBlackColor,
    padding: EdgeInsets.only(
      top: width.startHeight() * 0.11,
      left: width.startHeight() * 0.20,
      right: width.startHeight() * 0.12,
    ),
    child: FittedBox(
      fit: BoxFit.fitWidth,
      child: Text(counter.countNumber(),
        style: const TextStyle(
          color: lampColor,
          fontFamily: numberFont,
          fontSize: 50,
        ),
      ),
    ),
  );
}

Widget eachButtonImage(int i, int j, double height, String image) =>
    Container(
      width: height.buttonWidth(i, j),
      height: height.buttonHeight(),
      padding: EdgeInsets.all(height.paddingSize()),
      alignment: Alignment.center,
      child: Image(image: AssetImage(image)),
    );

Widget largeButtonImage(double hR, double vR, double height, String image) =>
    Container(
      width: height.largeButtonWidth(hR),
      height: height.largeButtonHeight(vR),
      padding: EdgeInsets.all(height.paddingSize()),
      alignment: Alignment.center,
      child: Image(
          image: AssetImage(image)
      ),
    );

Widget countNumber(double width, double height, int i) =>
    Stack(
    alignment: Alignment.center,
    children: [
      SizedBox(
        width: width,
        height: height,
      ),
      SizedBox(
        width: width * 0.4,
        height: width * 0.4,
        child: const FittedBox(
          fit: BoxFit.fitWidth,
          child: Image(image: AssetImage(beforeCountImage)),
        ),
      ),
      Text("$i",
        style: GoogleFonts.roboto(
          color: whiteColor,
          fontSize: width * 0.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    ]
  );

Text finishChallengeText(String text, double fontSize) =>
    Text(text,
      style: TextStyle(
        color: whiteColor,
        fontWeight: FontWeight.bold,
        fontSize: fontSize,
      )
    );

Text finishChallengeScore(int counter) =>
    Text(counter.countNumber(),
      style: const TextStyle(
        color: lampColor,
        fontFamily: "teleIndicators",
        fontSize: 120,
      ),
    );

Text return1000Buttons(String text) =>
    Text(text,
      style: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    );

