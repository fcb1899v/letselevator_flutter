// What the arrival announcement actually says, per language. es and fr must not skip
// floor(): without it they speak a bare ordinal, which nothing on screen would show.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevator/extension.dart';
import 'package:letselevator/l10n/app_localizations.dart';

/// The announcement for [floor] as the app would speak it in [lang]
Future<String> _spoken(WidgetTester tester, String lang, int floor) async {
  late String said;
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: Locale(lang),
    home: Builder(builder: (context) {
      said = context.soundFloor(floor);
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
    // Sótano / Sous-sol already mean "basement floor"; adding piso / étage
    // after them would be wrong, so the floor noun must not reach the basement branch
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
}
