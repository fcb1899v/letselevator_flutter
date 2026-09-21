// How wide the stop / bypass label may be before FittedBox shrinks it.
// A word that fits in one language can be halved in another; measured with the app's own font.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevator/constant.dart';
import 'package:letselevator/l10n/app_localizations.dart';

Future<void> _loadFonts() async {
  const families = {
    "roboto": "assets/fonts/Roboto-Bold.ttf",
    "notoJP": "assets/fonts/NotoSansJP-Bold.ttf",
    "notoSC": "assets/fonts/NotoSansSC-Bold.ttf",
    "bmDohyeon": "assets/fonts/bm-dohyeon.regular.ttf",
  };
  for (final entry in families.entries) {
    final loader = FontLoader(entry.key)..addFont(rootBundle.load(entry.value));
    await loader.load();
  }
}

// iPhone SE is the shortest screen iOS 17 still runs on
const _w = 375.0, _h = 667.0;

double _width(String text, double fontSize, String family) {
  final painter = TextPainter(
    text: TextSpan(text: text,
      style: TextStyle(fontSize: fontSize, fontFamily: family)),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout();
  return painter.width;
}

void main() {
  // rootBundle needs the binding before any font can be loaded
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadFonts);

  testWidgets("the stop / restricted labels fit the cell", (tester) async {
    final cell = floorCellWidth(_w, _h);
    final fontSize = _h * floorStopLabelFactor;
    // The shipped labels, read from the arb files so a translation change cannot make this stale.
    // FittedBox shrinks anything wider.
    const fonts = {"ja": "notoJP", "en": "roboto", "ko": "bmDohyeon",
                   "zh": "notoSC", "es": "roboto", "fr": "roboto"};
    for (final lang in ["ja", "en", "ko", "zh", "es", "fr"]) {
      final l10n = await AppLocalizations.delegate.load(Locale(lang));
      for (final entry in {"stop": l10n.stop, "bypass": l10n.bypass}.entries) {
        final px = _width(entry.value, fontSize, fonts[lang]!);
        expect(px, lessThanOrEqualTo(cell),
          reason: "$lang ${entry.key} \"${entry.value}\" is ${px.toStringAsFixed(1)}px "
            "in a ${cell.toStringAsFixed(1)}px cell, so FittedBox shrinks it");
        // ignore: avoid_print
        print("  $lang ${entry.key.padRight(7)} ${entry.value.padRight(12)} "
          "${px.toStringAsFixed(1)}px");
      }
    }
  });
}
