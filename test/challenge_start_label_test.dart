// Measures the 1000 Buttons Start and countdown labels in their fixed box with the
// bundled fonts, for every locale on three screens. Fails on overflow or a wrapped line.
// The default test font draws every glyph a full em wide, so it cannot judge this.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevator/buttons.dart';
import 'package:letselevator/l10n/app_localizations.dart';

// Logical sizes: iPhone SE, the Pixel-class emulator (1280x2856 @2.8), iPad Air 11" portrait
const _screens = {
  "iphone-se": Size(375, 667),
  "pixel": Size(1280 / 2.8, 2856 / 2.8),
  "ipad-air-11": Size(820, 1180),
};

Future<void> _loadFonts() async {
  const families = {
    "roboto": "assets/fonts/Roboto-Bold.ttf",
    "notoJP": "assets/fonts/NotoSansJP-Bold.ttf",
    "notoSC": "assets/fonts/NotoSansSC-Bold.ttf",
    "bmDohyeon": "assets/fonts/bm-dohyeon.regular.ttf",
    "lcd": "assets/fonts/5x8_lcd_hd44780u_a02.ttf",
  };
  for (final entry in families.entries) {
    final loader = FontLoader(entry.key)..addFont(rootBundle.load(entry.value));
    await loader.load();
  }
}

Future<Rect> _pumpBox(WidgetTester tester, Size size, Locale locale,
    Widget Function(ButtonsWidget buttons) box) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    // Stands in for the platform font, as in ipad_layout_test.dart
    theme: ThemeData(fontFamily: "roboto", fontFamilyFallback: const ["notoJP", "notoSC", "bmDohyeon"]),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: Scaffold(body: Center(child: Builder(builder: (context) =>
      KeyedSubtree(key: const Key("box"), child: box(ButtonsWidget(context: context)))))),
  ));
  await tester.pump();
  return tester.getRect(find.byKey(const Key("box")));
}

// One line tall is the height of the same text laid out with no width limit
double _oneLineHeight(RenderParagraph p) {
  final painter = TextPainter(text: p.text, textDirection: TextDirection.ltr, textScaler: p.textScaler)..layout();
  final h = painter.height;
  painter.dispose();
  return h;
}

void _expectLabelFits(WidgetTester tester, String label, Rect inner, String tag) {
  final finder = find.text(label);
  expect(finder, findsOneWidget, reason: "$tag: '$label' drawn");
  final p = tester.renderObject<RenderParagraph>(finder);
  final rect = tester.getRect(finder);
  final scale = rect.height / p.size.height;
  // ignore: avoid_print
  print("$tag '$label': natural ${p.getMaxIntrinsicWidth(double.infinity).toStringAsFixed(1)}"
    "x${_oneLineHeight(p).toStringAsFixed(1)}, drawn ${rect.width.toStringAsFixed(1)}"
    "x${rect.height.toStringAsFixed(1)} at (${rect.left.toStringAsFixed(1)}, ${rect.top.toStringAsFixed(1)}) (scale ${scale.toStringAsFixed(2)}), "
    "inner ${inner.width.toStringAsFixed(1)}x${inner.height.toStringAsFixed(1)}");
  expect(p.size.height, lessThan(_oneLineHeight(p) * 1.5), reason: "$tag: '$label' wrapped");
  expect(inner.inflate(0.5).contains(rect.topLeft) && inner.inflate(0.5).contains(rect.bottomRight), isTrue,
    reason: "$tag: '$label' $rect outside $inner");
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadFonts);

  for (final screen in _screens.entries) {
    for (final locale in AppLocalizations.supportedLocales) {
      testWidgets("start label: ${screen.key} ${locale.languageCode}", (tester) async {
        final box = await _pumpBox(tester, screen.value, locale, (b) => b.challengeStartButton());
        final overflow = tester.takeException();
        final l10n = AppLocalizations.of(tester.element(find.byKey(const Key("box"))))!;
        // The box minus its border; the top padding only moves the column down
        final border = tester.renderObject<RenderDecoratedBox>(find.descendant(
          of: find.byKey(const Key("box")), matching: find.byType(DecoratedBox)).first);
        final width = ((border.decoration as BoxDecoration).border as Border).top.width;
        final inner = box.deflate(width);
        final tag = "${screen.key} ${locale.languageCode}";
        _expectLabelFits(tester, l10n.challenge, inner, tag);
        _expectLabelFits(tester, l10n.start, inner, tag);
        expect(overflow, isNull, reason: "overflow");
      });
    }

    for (final seconds in [30, 9, 0]) {
      testWidgets("countdown: ${screen.key} $seconds", (tester) async {
        final box = await _pumpBox(tester, screen.value, const Locale('en'), (b) => b.challengeCountdown(seconds));
        expect(tester.takeException(), isNull, reason: "overflow");
        final label = find.byType(Text);
        final p = tester.renderObject<RenderParagraph>(label);
        final rect = tester.getRect(label);
        // ignore: avoid_print
        print("${screen.key} countdown '${p.text.toPlainText()}': natural "
          "${p.getMaxIntrinsicWidth(double.infinity).toStringAsFixed(1)}x${_oneLineHeight(p).toStringAsFixed(1)}, "
          "drawn ${rect.width.toStringAsFixed(1)}x${rect.height.toStringAsFixed(1)}, box ${box.width.toStringAsFixed(1)}x${box.height.toStringAsFixed(1)}");
        expect(p.size.height, lessThan(_oneLineHeight(p) * 1.5), reason: "wrapped");
        expect(box.contains(rect.topLeft) && box.inflate(0.5).contains(rect.bottomRight), isTrue, reason: "$rect outside $box");
      });
    }

    // The result screen's BEST row: challenge_finish_test.dart reaches it under the test font
    for (final locale in AppLocalizations.supportedLocales) {
      testWidgets("best row: ${screen.key} ${locale.languageCode}", (tester) async {
        final row = await _pumpBox(tester, screen.value, locale, (b) => b.resultBestScore(1000));
        final overflow = tester.takeException();
        final natural = tester.renderObject<RenderFlex>(find.byType(Row)).getMaxIntrinsicWidth(double.infinity);
        // ignore: avoid_print
        print("${screen.key} ${locale.languageCode} best row: natural ${natural.toStringAsFixed(1)}"
          ", drawn ${row.width.toStringAsFixed(1)}, screen ${screen.value.width.toStringAsFixed(1)}");
        expect(natural, lessThanOrEqualTo(screen.value.width));
        expect(overflow, isNull, reason: "overflow");
      });
    }
  }
}
