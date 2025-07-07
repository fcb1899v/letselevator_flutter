// =============================
// CommonWidget: Shared UI Components
//
// This class provides common UI components used across the app including:
// 1. Background Components: Responsive background image handling
// 2. Ad Components: Ad banner with menu button integration
// 3. Button Components: Floor button with number overlay
// 4. Loading Components: Circular progress indicator overlay
// =============================

import 'package:flutter/material.dart';
import 'admob_banner.dart';
import 'constant.dart';
import 'extension.dart';

class CommonWidget {

  final BuildContext context;

  CommonWidget({
    required this.context,
  });

  // --- Background Components ---
  // Responsive background image with orientation handling
  Widget commonBackground({
    required double width,
    required String image
  }) => (width > context.height()) ? ClipRect(
    child: OverflowBox(
      alignment: Alignment.center,
      minWidth: 0,
      minHeight: 0,
      maxWidth: width,
      maxHeight: double.infinity,
      child: Image.asset(image,
        fit: BoxFit.fitWidth,
        width: width,
      ),
    ),
  ): SizedBox(
    width: width,
    height: context.height(),
    child: FittedBox(
      fit: BoxFit.fill,
      child: Image.asset(image),
    ),
  );

  // --- Ad Components ---
  // Ad banner with menu button integration
  Widget commonAdBanner({
    required String image,
    required void Function() onTap,
  }) => Column(children: [
    const Spacer(flex: 1),
    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const AdBannerWidget(),
        // Menu button with gesture handling
        GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: context.operationButtonSize(),
            height: context.operationButtonSize(),
            child: Image.asset(image),
          ),
        ),
      ]
    ),
  ]);

  // --- Button Components ---
  // Floor button with number overlay and styling
  Widget floorButtonImage({
    required String image,
    required double size,
    required String number,
    required double fontSize,
    required Color color,
    required double marginTop,
    required double marginBottom,
  }) => SizedBox(
    width: size,
    height: size,
    child: Stack(alignment: Alignment.center,
      children: [
        Image.asset(image),
        Container(
          margin: EdgeInsets.only(
            top: marginTop,
            bottom: marginBottom,
          ),
          child: Text(number,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              fontFamily: normalFont
            ),
          ),
        ),
      ],
    ),
  );

  // --- Loading Components ---
  // Circular progress indicator overlay
  Widget commonCircularProgressIndicator() => Container(
    alignment: Alignment.center,
    width: context.width(),
    height: context.height(),
    color: transpBlackColor,
    child: CircularProgressIndicator(
      color: lampColor,
      strokeWidth: context.circleStrokeWidth(),
    ),
  );

}

