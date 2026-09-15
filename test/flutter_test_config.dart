// Runs before every test file. There is no Game Center or Play Games in tests, so the
// sign-in answers "signed out" at once instead of a real DNS lookup and plugin call.

import 'dart:async';
import 'package:letselevator/games_manager.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  nativeGamesSignIn = () async => false;
  await testMain();
}
