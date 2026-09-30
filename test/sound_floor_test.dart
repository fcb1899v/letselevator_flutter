// What the arrival announcement actually says, per language.
// es and fr must not skip floor(): without it they speak a bare ordinal nothing on screen shows.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevator/extension.dart';
import 'package:letselevator/l10n/app_localizations.dart';

/// The announcement for [floor] as the app would speak it in [lang]
Future<String> _spoken(WidgetTester tester, String lang, int floor, {bool isTop = false}) async {
  late String said;
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: Locale(lang),
    home: Builder(builder: (context) {
      said = context.soundFloor(floor, isTop);
      return const SizedBox.shrink();
    }),
  ));
  return said;
}

void main() {
  testWidgets("the arrival names the floor in every language", (tester) async {
    // Above ground: the noun has to be there, or the ordinal dangles
    const nouns = {
      "ja": "階", "en": "floor", "ko": "층", "zh": "层",
      "es": "piso", "fr": "étage",
    };
    for (final entry in nouns.entries) {
      final said = await _spoken(tester, entry.key, 3);
      expect(said, contains(entry.value),
        reason: "${entry.key} arrival says \"$said\", with no \"${entry.value}\"");
    }
  });

  testWidgets("the basement keeps its own noun, not the floor noun", (tester) async {
    // Sótano / Sous-sol already mean "basement floor", so adding piso / étage after them would be wrong.
    // The floor noun must not reach the basement branch.
    expect(await _spoken(tester, "es", -2), contains("ótano"));
    expect(await _spoken(tester, "es", -2), isNot(contains("piso")));
    expect(await _spoken(tester, "fr", -2), contains("ous-sol"));
    expect(await _spoken(tester, "fr", -2), isNot(contains("étage")));
  });

  testWidgets("the ground floor is named, not numbered", (tester) async {
    // France and Spain count the floor above the ground one as the first
    expect(await _spoken(tester, "fr", 0), contains("Rez-de-chaussée"));
    expect(await _spoken(tester, "es", 0), contains("Planta baja"));
  });

  testWidgets("a top floor below 163 is still named as the rooftop", (tester) async {
    // The top button can be renumbered below the structural 163F, so the
    // rooftop announcement must key off isTop, not the floor number itself.
    expect(await _spoken(tester, "en", 120, isTop: true), contains("top floor"));
    expect(await _spoken(tester, "en", 120, isTop: false), isNot(contains("top floor")));
  });
}
