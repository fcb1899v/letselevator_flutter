// ===== CommonWidget: shared UI components =====
// Background, ad banner with menu button, floor button, loading overlay, purchase dialog

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
  /// isPremium: the banner is gone, so the row shrinks to the button and would
  /// otherwise sit under the system navigation. The button is the only way into
  /// the menu, so it is lifted clear of it
  Widget commonAdBanner({
    required String image,
    required void Function() onTap,
    required bool isPremium,
  }) => Column(children: [
    const Spacer(flex: 1),
    Padding(
      padding: EdgeInsets.only(
        bottom: isPremium ? MediaQuery.viewPaddingOf(context).bottom : 0,
      ),
    // The banner is taller than the button, so the row takes the banner height and
    // start pins the button to the top of it
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Expanded gives the banner the width left after the menu button, so the
        // ad size is derived from the layout instead of a hardcoded inset
        const Expanded(child: AdBannerWidget()),
        // Menu button. Horizontal padding only, so it stays off the banner and the
        // screen edge without undoing the top alignment above
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.operationButtonMargin()),
          child: GestureDetector(
            onTap: onTap,
            child: SizedBox(
              width: context.operationButtonSize(),
              height: context.operationButtonSize(),
              child: Image.asset(image),
            ),
          ),
        ),
      ]
    ),
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
        Text(number,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontFamily: "roboto"
          ),
        ),
      ],
    ),
  );

  // --- Feedback Components ---

  /// Report the outcome of a purchase or a restore. A silent purchase looks like
  /// a failed one, so every ending of the flow but a cancel comes through here
  void commonSnackBar(String text) {
    "commonSnackBar: $text".debugPrint();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      // Shrunk rather than wrapped: the text carries its own line breaks, and a
      // language that overruns should keep them instead of folding a third line
      content: FittedBox(fit: BoxFit.scaleDown,
        child: Text(text,
          style: TextStyle(
            color: blackColor,
            fontWeight: FontWeight.bold,
            fontFamily: context.font(),
            fontSize: context.settingsAlertDescFontSize(),
          ),
          textAlign: TextAlign.center,
        ),
      ),
      backgroundColor: lampColor,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.settingsLockFreeBorderRadius()),
      ),
      margin: EdgeInsets.all(context.settingsLockMargin()),
    ));
  }

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

