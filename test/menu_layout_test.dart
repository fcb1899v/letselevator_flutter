// Draws the real menu at small screen sizes and fails on any overflow. The
// purchase tile made the grid taller than a 667 screen leaves; the grid now
// scales down to fit, and this is what keeps it that way.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:letselevator/l10n/app_localizations.dart';
import 'package:letselevator/menu.dart';

const _sizes = [Size(320, 568), Size(360, 640), Size(375, 667), Size(768, 1024)];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in _sizes) {
    testWidgets("the menu fits at ${size.width.toInt()}x${size.height.toInt()}",
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const MenuPage(isHome: true),
        ),
      ));
      // Let the tile and link images decode: before that the link logos are
      // zero high and the grid looks roomier than it is
      await tester.runAsync(() async {
        for (final e in find.byType(Image).evaluate()) {
          final image = (e.widget as Image).image;
          await precacheImage(image, e);
        }
      });
      await tester.pump();

      expect(tester.takeException(), isNull,
        reason: "the menu overflows at $size");
    });
  }
}
