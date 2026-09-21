// Runs before every test file.
// There is no Game Center or Play Games in tests, so sign-in answers "signed out" without DNS or a plugin.

import 'dart:async';
import 'package:letselevator/games_manager.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  nativeGamesSignIn = () async => false;
  await testMain();
}
