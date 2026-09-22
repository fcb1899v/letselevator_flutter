// A basement is announced through soundFloor in every language.
// The es/fr ordinal tables read a positive number only, so a negative one is read as the wrong floor.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevator/extension.dart';
import 'package:letselevator/l10n/app_localizations.dart';

Future<String> _spoken(WidgetTester tester, String lang, int floor) async {
  late BuildContext captured;
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: Locale(lang),
    home: Builder(builder: (context) {
      captured = context;
      return const SizedBox();
    }),
  ));
  await tester.pump();
  return captured.soundFloor(floor);
}

void main() {
  testWidgets("es and fr read a basement by its absolute value", (tester) async {
    expect(await _spoken(tester, "es", -7), contains("séptimo"));
    expect(await _spoken(tester, "es", -12), contains("duodécimo"));
    expect(await _spoken(tester, "fr", -7), contains("septième"));
    expect(await _spoken(tester, "fr", -12), contains("douzième"));
    // The wrong table entry is the twenties: 28th for B12, 23rd for B7
    for (final lang in ["es", "fr"]) {
      for (final floor in [-1, -2, -7, -12]) {
        final text = await _spoken(tester, lang, floor);
        expect(text, isNot(contains(lang == "es" ? "vigésimo" : "vingtième")), reason: "$lang B${-floor}");
      }
    }
  });

  testWidgets("en, ja, ko and zh name the basement with the right number", (tester) async {
    expect(await _spoken(tester, "en", -12), contains("12th"));
    expect(await _spoken(tester, "en", -7), contains("7th"));
    for (final lang in ["ja", "ko", "zh"]) {
      expect(await _spoken(tester, lang, -12), contains("12"), reason: lang);
      expect(await _spoken(tester, lang, -7), contains("7"), reason: lang);
    }
  });
}
