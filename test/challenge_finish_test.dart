// The 30 s challenge finish: a new best saves and shows the score achieved, not the one the
// page was built with. No Game Center: what is checked is the value handed to the provider.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:letselevator/buttons.dart';
import 'package:letselevator/constant.dart';
import 'package:letselevator/games_manager.dart';
import 'package:letselevator/l10n/app_localizations.dart';
import 'package:letselevator/main.dart';

// The banner asks UMP for consent; with no plugin that is a MissingPluginException, which
// the SDK does not catch. Answer "no ads" instead; only the method name is read
const umpChannel = "plugins.flutter.io/google_mobile_ads/ump";
void mockUmp(WidgetTester tester) {
  tester.binding.defaultBinaryMessenger.setMockMessageHandler(umpChannel, (message) async {
    final name = const StandardMessageCodec().readValue(ReadBuffer(message!)) as String;
    final reply = name.endsWith("canRequestAds") || name.endsWith("isConsentFormAvailable")
      ? false : null;
    return const StandardMethodCodec().encodeSuccessEnvelope(reply);
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMessageHandler(umpChannel, null));
}

// The result screen names its fonts. Under the test font, whose glyphs are a full em
// wide, its BEST row overflows; with these it fits (challenge_start_label_test.dart)
Future<void> loadFonts() async {
  const families = {
    "roboto": "assets/fonts/Roboto-Bold.ttf",
    "lcd": "assets/fonts/5x8_lcd_hd44780u_a02.ttf",
  };
  for (final entry in families.entries) {
    await (FontLoader(entry.key)..addFont(rootBundle.load(entry.value))).load();
  }
}

Future<void> pumpButtons(WidgetTester tester) async {
  mockUmp(tester);
  resetGamesSignIn();
  // Pixel-class screen, so the page lays out as on the emulator
  tester.view.physicalSize = const Size(1280, 2856);
  tester.view.devicePixelRatio = 2.8;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const ButtonsPage(),
    ),
  ));
  // Sign-in answers at once, but the button images decode in real time and their
  // continuations only run on a pump. One frame first: initState starts after it
  await tester.pump();
  for (int i = 0; i < 5 || (i < 30 && find.byType(CircularProgressIndicator).evaluate().isNotEmpty); i++) {
    await letRealIoFinish(tester);
  }
  expect(find.byType(CircularProgressIndicator), findsNothing, reason: "initState finished");
}

// A real wait, then a pump to run the continuations it queued
Future<void> letRealIoFinish(WidgetTester tester) async {
  await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
  await tester.pump();
}

// Top-left buttons of panel 1: off image of (row, col) is 1/1_{row+1}_{col+1}.png
Finder panel1Button(int row, int col) =>
    find.image(AssetImage("${assetsReal1000Off}1/1_${row + 1}_${col + 1}.png"));

// The buttons also take a double tap, so a single tap is delivered after the
// double-tap window closes
Future<void> tapButton(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 400));
}

// Aim at the tappable box, not the label inside it
Finder startButton() =>
    find.ancestor(of: find.text("START"), matching: find.byType(GestureDetector)).first;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);

  testWidgets("a new best saves the achieved score, not the stale best", (tester) async {
    // The page is built with a best of 0 (the provider default) and then loads
    // 1 from prefs; the stale closure value is 0, the current best is 1
    SharedPreferences.setMockInitialValues({'bestScore': 1});
    await pumpButtons(tester);
    final container = ProviderScope.containerOf(tester.element(find.byType(ButtonsPage)));
    expect(container.read(bestScoreProvider), 1, reason: "prefs value loaded");

    await tester.tap(startButton());
    // 3 s pre-countdown, then the run
    await tester.pump(const Duration(milliseconds: 3100));
    await tapButton(tester, panel1Button(0, 0));
    await tapButton(tester, panel1Button(1, 0));
    await tapButton(tester, panel1Button(2, 0));
    expect(find.text("0003"), findsOneWidget, reason: "counter shows the 3 taps");

    // 30 s of ticks plus the finishing tick, then the async finish work
    await tester.pump(const Duration(seconds: 32));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text("BACK"), findsOneWidget, reason: "the result screen is up");
    expect(container.read(bestScoreProvider), 3);
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < 15 && prefs.getInt('bestScore') != 3; i++) {
      await letRealIoFinish(tester);
    }
    expect(prefs.getInt('bestScore'), 3, reason: "the saved best is the achieved score");
    // Signed out in tests, so the submission fails and the run stays pending
    for (int i = 0; i < 15 && ChallengeRun.read(prefs) == null; i++) {
      await letRealIoFinish(tester);
    }
    final pending = ChallengeRun.read(prefs);
    expect(pending?.score, 3);
    expect(pending?.submitted, isFalse);
  });

  testWidgets("a score below the best leaves the best alone", (tester) async {
    SharedPreferences.setMockInitialValues({'bestScore': 5});
    await pumpButtons(tester);
    await tester.tap(startButton());
    await tester.pump(const Duration(milliseconds: 3100));
    await tapButton(tester, panel1Button(0, 0));
    await tester.pump(const Duration(seconds: 32));
    await tester.pump(const Duration(seconds: 2));

    final container = ProviderScope.containerOf(tester.element(find.byType(ButtonsPage)));
    expect(container.read(bestScoreProvider), 5);
    expect((await SharedPreferences.getInstance()).getInt('bestScore'), 5);
  });

  testWidgets("leaving the page stops the timer", (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpButtons(tester);
    await tester.tap(startButton());
    await tester.pump(const Duration(milliseconds: 3100));
    // Replace the page mid-run; a leaked timer would touch disposed notifiers
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    tester.takeException(); // anything from the frames so far is not the timer
    await tester.pump(const Duration(seconds: 40));
    expect(tester.takeException(), isNull);
  });
}
