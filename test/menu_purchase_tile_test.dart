// The purchase tile is drawn only from a real store price, and appears as soon as one arrives.
// No pumpAndSettle: the spinner animates while initState's real IO is pending.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:letselevator/constant.dart';
import 'package:letselevator/l10n/app_localizations.dart';
import 'package:letselevator/menu.dart';
import 'package:letselevator/plan_provider.dart';
import 'package:letselevator/purchase_manager.dart';

Future<void> pumpMenu(WidgetTester tester, String price) async {
  tester.view.physicalSize = const Size(768, 1024);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      planProvider.overrideWith(() => PlanNotifier(PlanState(priceString: price))),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const MenuPage(isHome: true),
    ),
  ));
  // Well past any fetch the menu could start; the answers above do not depend on it
  await tester.pump(const Duration(seconds: 5));
}

final purchaseTile = find.image(const AssetImage(purchaseButton));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(PurchaseManager.resetPrice);
  tearDown(PurchaseManager.resetPrice);

  testWidgets("no price: no purchase tile", (tester) async {
    PurchaseManager.priceSource = () async => null;
    await pumpMenu(tester, "");
    expect(purchaseTile, findsNothing);
    // Control: the menu itself was drawn
    expect(find.image(const AssetImage(settingsButton)), findsOneWidget);
  });

  testWidgets("price: the purchase tile is drawn", (tester) async {
    PurchaseManager.priceSource = () async => "¥500";
    await pumpMenu(tester, "500");
    expect(purchaseTile, findsOneWidget);
  });

  testWidgets("a price arriving while the menu is open brings the tile in", (tester) async {
    // The store has not answered yet, and never does during this test
    PurchaseManager.priceSource = () => Completer<String?>().future;
    await pumpMenu(tester, "");
    expect(purchaseTile, findsNothing);
    // The home screen's prefetch lands, as HomePage delivers it
    ProviderScope.containerOf(tester.element(find.byType(MenuPage)))
      .read(planProvider.notifier).setPrice("¥500");
    await tester.pump(const Duration(seconds: 5));
    expect(purchaseTile, findsOneWidget);
  });
}
