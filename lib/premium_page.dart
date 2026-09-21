// PremiumPage: the full-screen purchase page every entry point opens.
// It names no feature: one icon per premiumTabList entry, so a new feature needs no edit here.

import 'package:flutter/material.dart';
import 'common_widget.dart';
import 'constant.dart';
import 'extension.dart';

// Every string uses the platform font, since context.font() gives Korean a display face.
// That breaks the one-plain-font rule; the PREMIUM board keeps letsgo, its own alphabet.
class PremiumPage extends StatelessWidget {
  const PremiumPage({
    super.key,
    required this.price,
    required this.onBuy,
    required this.onRestore,
  });

  final String price;
  final Future<void> Function() onBuy;
  final Future<void> Function() onRestore;

  @override
  Widget build(BuildContext context) {
    final common = CommonWidget(context: context);
    return Scaffold(
      // Transparent, so the banner the page below paints shows through
      backgroundColor: transpColor,
      body: Column(children: [
        Expanded(child: Stack(children: [
        // The settings screen's own metal, darkened.
        // Its centre highlight is the same luminance as the white body text and swallows it.
        common.commonBackground(
          width: context.width(),
          image: backgroundStyleList[0].backGroundImage(),
        ),
        Container(color: transpBlackColor),
        SafeArea(
          child: Column(children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () => context.popPage(),
                icon: Icon(Icons.close,
                  color: whiteColor,
                  size: context.premiumCloseSize(),
                ),
              ),
            ),
            // Centred in what the close button leaves, and scaled down where it does not fit (iPad landscape).
            // A scroll view keeps Buy and Restore below the fold there.
            Expanded(child: Center(
              child: FittedBox(fit: BoxFit.scaleDown,
                child: SizedBox(width: context.width(),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Identity
            _sign(context),
            SizedBox(height: context.premiumGapInner()),
            Text(context.premiumTitle(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: whiteColor,
                fontSize: context.premiumNameFontSize(),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: context.premiumGapBlock()),
            // What you get
            _plate(context),
            SizedBox(height: context.premiumGapInner()),
            Text(context.premiumUnlockAll(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: whiteColor,
                fontSize: context.premiumBodyFontSize(),
              ),
            ),
            SizedBox(height: context.premiumGapInner()),
            _tabIcons(context),
            SizedBox(height: context.premiumGapBlock()),
            // Action
            Text(context.premiumOneTime(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: whiteColor,
                fontSize: context.premiumNoteFontSize(),
              ),
            ),
            SizedBox(height: context.premiumGapInner()),
            _buyButton(context),
            SizedBox(height: context.premiumGapInner()),
            TextButton(
              onPressed: onRestore,
              child: Text(context.premiumRestore(),
                style: TextStyle(
                  color: whiteColor,
                  fontSize: context.premiumRestoreFontSize(),
                  decoration: TextDecoration.underline,
                  decorationColor: whiteColor,
                  ),
              ),
            ),
                ]),
              )),
            )),
          ]),
        ),
        ])),
        // The ad keeps showing while the page is open: it is what the purchase removes.
        // Always this tall, not admobHeight(), which clips the top on a short screen
        SizedBox(height: inlineBannerMaxHeight.toDouble()),
      ]),
    );
  }

  /// The indicator board, squared off and unframed like the floor display.
  /// letsgodigital is that display's own alphabet
  Widget _sign(BuildContext context) => Container(
    width: context.premiumContentWidth(),
    height: context.premiumSignHeight(),
    alignment: Alignment.center,
    color: darkBlackColor,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text("PREMIUM",
        style: TextStyle(
          color: lampColor,
          fontSize: context.premiumSignFontSize(),
          fontFamily: "letsgo",
        ),
      ),
    ),
  );

  /// The headline benefit, in a framed plate. No icon: the words carry it
  Widget _plate(BuildContext context) => Container(
    width: context.premiumContentWidth(),
    padding: EdgeInsets.symmetric(vertical: context.premiumPlatePadding()),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: darkBlackColor,
      borderRadius: BorderRadius.circular(context.premiumPlateRadius()),
      border: Border.all(color: grayColor, width: context.premiumBorderWidth()),
    ),
    child: Text(context.premiumNoAds(),
      textAlign: TextAlign.center,
      style: TextStyle(
        color: whiteColor,
        fontSize: context.premiumPlateFontSize(),
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  /// One icon per settings tab the unlock opens. Reading premiumTabList rather
  /// than a hand-written list is what keeps this page correct over time
  Widget _tabIcons(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: premiumTabList.map((tab) => Padding(
      padding: EdgeInsets.symmetric(horizontal: context.premiumIconMargin()),
      child: Image.asset("$assetsSettings${tab}SettingsPressed.png",
        width: context.premiumIconSize(),
        height: context.premiumIconSize(),
      ),
    )).toList(),
  );

  /// The only amber frame on the page, so the eye lands on it last and stays
  Widget _buyButton(BuildContext context) => GestureDetector(
    onTap: onBuy,
    child: Container(
      width: context.premiumContentWidth(),
      height: context.premiumBuyHeight(),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: darkBlackColor,
        borderRadius: BorderRadius.circular(context.premiumBuyRadius()),
        border: Border.all(color: lampColor, width: context.premiumBuyBorderWidth()),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_open,
            color: lampColor,
            size: context.premiumBuyFontSize(),
          ),
          SizedBox(width: context.premiumIconMargin()),
          Text(context.premiumBuy(price),
            style: TextStyle(
              color: lampColor,
              fontSize: context.premiumBuyFontSize(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}
