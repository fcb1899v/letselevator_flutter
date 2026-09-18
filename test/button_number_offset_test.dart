// The number on a floor button is centred on the shape's visual centre, not on
// the bounding box. Star, heart and cat carry a per-shape offset in
// floorButtonNumberOffset; dropping the margin from floorButtonImage made
// every shape draw the number in the geometric centre, which this catches.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letselevator/common_widget.dart';
import 'package:letselevator/constant.dart';
import 'package:letselevator/extension.dart';

// Draw one button and report how far the number sits from the button centre.
// Positive is downwards
Future<double> _numberOffset(WidgetTester tester, String shape) async {
  late double size;
  late double offset;

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Center(
        child: Builder(builder: (context) {
          size = context.floorButtonSize();
          offset = context.floorButtonNumberOffsetOf(shape);
          return CommonWidget(context: context).floorButtonImage(
            image: "assets/images/button/${shape}1.png",
            size: size,
            number: "9",
            fontSize: context.buttonNumberFontSize(),
            color: Colors.white,
            numberOffset: offset,
          );
        }),
      ),
    ),
  ));
  await tester.pump();

  final button = tester.getCenter(find.byType(SizedBox).first);
  final number = tester.getCenter(find.text("9"));
  // Reported as a fraction of the button, the same unit as floorButtonNumberOffset
  return (number.dy - button.dy) / size;
}

void main() {
  testWidgets("a shape with no offset keeps the number in the centre",
      (tester) async {
    expect(await _numberOffset(tester, "circle"), moreOrLessEquals(0, epsilon: 0.01));
  });

  testWidgets("star, heart and cat move the number by their measured offset",
      (tester) async {
    for (final shape in ["star", "heart", "cat"]) {
      expect(await _numberOffset(tester, shape),
        moreOrLessEquals(floorButtonNumberOffset[shape.buttonShapeIndex()], epsilon: 0.002),
        reason: "$shape lands off its shape's visual centre");
    }
  });
}
