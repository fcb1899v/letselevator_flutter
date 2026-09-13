// Draws the real floor panel at small screen sizes and fails on any overflow.
// The arithmetic tests in floor_test.dart only check the estimate; this checks
// the widget, so putting Transform.scale back on the stop switch fails here.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevator/constant.dart';
import 'package:letselevator/l10n/app_localizations.dart';
import 'package:letselevator/settings.dart';

// Each size gets its own tree: reusing one reports only the first overflow
const _sizes = [
  Size(320, 568), Size(360, 640), Size(375, 667), Size(412, 915),
];

void main() {
  for (final size in _sizes) {
    testWidgets("the floor panel fits at ${size.width.toInt()}x${size.height.toInt()}",
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(builder: (context) => SettingsWidget(
            context: context,
            floorNumbers: initialFloorNumbers,
            floorStops: initialFloorStops,
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
        reason: "the floor panel overflows at $size");
    });
  }
}
