// The floor panel in all six languages, with the app's own fonts loaded. The
// default test font draws every glyph a full em wide, which exaggerates Latin
// labels and hides nothing; the real fonts give the widths a device would.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevator/constant.dart';
import 'package:letselevator/l10n/app_localizations.dart';
import 'package:letselevator/settings.dart';

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
const _size = Size(375, 667);

void main() {
  setUpAll(_loadFonts);

  for (final lang in ["en", "es", "fr", "ja", "ko", "zh"]) {
    testWidgets("the floor panel fits in $lang at 375x667", (tester) async {
      tester.view.physicalSize = _size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Every stop switched off, so every cell shows the longer Bypass label
      final allBypass = List<bool>.generate(initialFloorStops.length,
        (i) => i == oneFloorIndex);

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale(lang),
        home: Scaffold(
          body: Builder(builder: (context) => SettingsWidget(
            context: context,
            floorNumbers: initialFloorNumbers,
            floorStops: allBypass,
            buttonStyle: initialButtonStyle,
            buttonShape: initialButtonShape,
            backgroundStyle: initialBackgroundStyle,
            isPremium: false,
          ).settingsButtonNumberWidget(
            isButtonOn: List.generate(4, (_) => List.filled(4, false)),
            floorLockList: initialFloorLock,
            changeButtonNumber: (_, _) {},
            changeFloorStopFlag: (_, _, _) {},
            showRewardAdAlertDialog: (_) {},
            onBuy: () {},
          )),
        ),
      ));
      await tester.pump();

      expect(tester.takeException(), isNull,
        reason: "the floor panel overflows in $lang at $_size");
    });
  }
}
