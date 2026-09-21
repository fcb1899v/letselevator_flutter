// constant.dart pins CupertinoSwitch's natural size and the floor cell sizes from it.
// This checks the pin still matches Flutter; floor_panel_layout_test.dart draws the panel.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevator/constant.dart';

void main() {
  testWidgets("CupertinoSwitch still lays out at the pinned size", (tester) async {
    await tester.pumpWidget(CupertinoApp(
      home: Center(child: CupertinoSwitch(value: true, onChanged: (_) {})),
    ));
    expect(tester.getSize(find.byType(CupertinoSwitch)), cupertinoSwitchSize);
  });
}
