// ===== PremiumPage: the full-screen purchase page =====
// Replaces the CupertinoAlertDialog every entry point used to open. The button
// is pressed by people asking "what is this?", and a three-line alert sells
// them nothing (08_Designer/ui/2026-09-11_premium_purchase_page.md).
//
// The page never names an individual feature. It draws one icon per entry in
// premiumTabList, which is the settings tabs that hold something the unlock
// opens, so adding a feature inside a tab leaves this file and its six
// translations untouched. The number tab joined the list when its floors
// gained locks, so there are three icons.

import 'package:flutter/material.dart';
import 'common_widget.dart';
import 'constant.dart';
import 'extension.dart';

// Every string here uses the platform font. context.font() hands Korean a
// display face (bmDohyeon) that does not match the rest of the page, and the
// owner asked for one plain font across all six. The PREMIUM board keeps
// letsgo: that is the floor display's own alphabet, not body text.
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
        // The settings screen's own metal, darkened: its centre highlight is
        // the same luminance as the white body text and swallows it
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
            // Centred in what the close button leaves. The scroll view never
            // scrolls on a phone; it is there so an unusually short screen
            // shows the page instead of an overflow stripe
            Expanded(child: Center(
              child: SingleChildScrollView(
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
              ),
            )),
          ]),
        ),
        ])),
        // The ad goes on showing while the page is open: it is the thing the
        // purchase removes, and it keeps earning until it does. The banner is
        // always this tall, not admobHeight(): the latter covers the top of it
        // on a short screen
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
