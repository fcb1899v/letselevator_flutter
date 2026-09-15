// Draws the purchase surfaces at iPad Air 11-inch logical size, both orientations,
// and fails on any overflow. iPadOS ignores the portrait lock while multitasking is on.
// The bundled fonts are loaded: the default test font draws every glyph a full em wide.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:letselevator/constant.dart';
import 'package:letselevator/l10n/app_localizations.dart';
import 'package:letselevator/menu.dart';
import 'package:letselevator/plan_provider.dart';
import 'package:letselevator/premium_page.dart';
import 'package:letselevator/purchase_manager.dart';
import 'package:letselevator/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _sizes = {"portrait": Size(820, 1180), "landscape": Size(1180, 820)};

Future<void> _loadFonts() async {
  const families = {
    "roboto": "assets/fonts/Roboto-Bold.ttf",
    "notoJP": "assets/fonts/NotoSansJP-Bold.ttf",
    "notoSC": "assets/fonts/NotoSansSC-Bold.ttf",
    "bmDohyeon": "assets/fonts/bm-dohyeon.regular.ttf",
    "letsgo": "assets/fonts/letsgodigital.ttf",
  };
  for (final entry in families.entries) {
    final loader = FontLoader(entry.key)..addFont(rootBundle.load(entry.value));
    await loader.load();
  }
}

Future<void> _pump(WidgetTester tester, Size size, Locale locale, String price, Widget home) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  PurchaseManager.priceSource = () async => price.isEmpty ? null : price;
  addTearDown(PurchaseManager.resetPrice);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      planProvider.overrideWith(() => PlanNotifier(PlanState(priceString: price))),
    ],
    child: MaterialApp(
      // Stands in for the platform font, which tests cannot load. Bold is the wider cut
      theme: ThemeData(fontFamily: "roboto", fontFamilyFallback: const ["notoJP", "notoSC", "bmDohyeon"]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: home,
    ),
  ));
  // Decode images so their real heights take part in the layout
  await tester.runAsync(() async {
    for (final e in find.byType(Image).evaluate()) {
      await precacheImage((e.widget as Image).image, e);
    }
  });
  await tester.pump(const Duration(seconds: 5));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadFonts);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // The settings page's ads ask UMP first: the update fails and ads may not load.
    // Its arguments use a private codec, so only the method name is read
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      "plugins.flutter.io/google_mobile_ads/ump", (message) async {
        final method = const StandardMessageCodec().readValue(ReadBuffer(message!));
        return (method == "ConsentInformation#canRequestAds")
          ? const StandardMethodCodec().encodeSuccessEnvelope(false)
          : const StandardMethodCodec().encodeErrorEnvelope(code: "0", message: "no UMP in tests");
      },
    );
  });

  // The purchase page is also checked on the shortest iPhone, since it scales down to fit
  for (final entry in {..._sizes, "iphone-se": const Size(375, 667)}.entries) {
    final size = entry.value;
    // What the page leaves above the banner space it reserves at the bottom
    final visibleBottom = size.height - inlineBannerMaxHeight;
    // Priced only: menu.dart and settings.dart show a snackbar instead of opening it without one
    const price = "\$3.99";
    for (final locale in AppLocalizations.supportedLocales) {
      testWidgets("premium page: ${entry.key} ${locale.languageCode} price='$price'", (tester) async {
        await _pump(tester, size, locale, price,
          PremiumPage(price: price, onBuy: () async {}, onRestore: () async {}));
        expect(tester.takeException(), isNull);
        // Buy and Restore are on screen as the page opens, with no scrolling
        final buy = tester.getRect(find.byIcon(Icons.lock_open));
        expect(buy.top >= 0 && buy.bottom <= visibleBottom, isTrue, reason: "buy off screen: $buy");
        final restore = tester.getRect(find.text(
          AppLocalizations.of(tester.element(find.byType(PremiumPage)))!.premiumRestore));
        expect(restore.top >= 0 && restore.bottom <= visibleBottom, isTrue, reason: "restore off screen: $restore");
      });
    }
  }

  for (final entry in _sizes.entries) {
    final size = entry.value;

    for (final price in ["\$3.99", ""]) {
      testWidgets("menu: ${entry.key} price='$price'", (tester) async {
        await _pump(tester, size, const Locale('en'), price, const MenuPage(isHome: true));
        expect(tester.takeException(), isNull);
        expect(find.image(const AssetImage(purchaseButton)), price.isEmpty ? findsNothing : findsOneWidget);
      });
    }

    for (final tab in [0, 1, 2]) {
      testWidgets("settings tab $tab: ${entry.key}", (tester) async {
        await _pump(tester, size, const Locale('en'), "\$3.99", SettingsPage(initialTab: tab));
        expect(tester.takeException(), isNull);
        // Control: the lock screens were drawn, not a loading page
        expect(find.byIcon(CupertinoIcons.lock_fill), findsWidgets);
      });
    }
  }
}
