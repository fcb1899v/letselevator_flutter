// ===== FloorManager: floor configuration and settings persistence =====
// Saves floor numbers and stop flags with validation, plus generic string/int settings

import 'package:shared_preferences/shared_preferences.dart';
import 'constant.dart';
import 'extension.dart';

class FloorManager {

  // --- Floor Number Management ---
  // Save floor number after validating range and uniqueness
  Future<List<int>> saveFloorNumber({
    required List<int> currentList,
    required int newValue,
    required int newIndex,
  }) async {
    // The picker only offers the gap between the neighbouring buttons, so the
    // same gap is the only thing accepted here. Nothing else has to move
    if (!isInFloorGap(currentList, newIndex, newValue)) return currentList;
    final newList = List<int>.from(currentList)..[newIndex] = newValue;
    final prefs = await SharedPreferences.getInstance();
    "newNumber: $newValue".debugPrint();
    "numbersKey".setSharedPrefListInt(prefs, newList);
    return newList;
  }

  // --- Floor Stop Management ---
  // Save floor stop flag for elevator operation
  Future<List<bool>> saveFloorStops({
    required List<bool> currentList,
    required bool newValue,
    required int newIndex,
  }) async {
    if (!newValue && isOnlyStop(currentList, newIndex)) return currentList;
    final prefs = await SharedPreferences.getInstance();
    final newList = List<bool>.from(currentList);
    newList[newIndex] = newValue;
    "newStop: $newValue".debugPrint();
    "stopsKey".setSharedPrefListBool(prefs, newList);
    return newList;
  }

  // --- Settings Persistence ---
  // Save string settings only when the value changes
  Future<String> changeSettingsStringValue({
    required String key,
    required String current,
    required String next,
  }) async {
    if (next != current) {
      final prefs = await SharedPreferences.getInstance();
      key.setSharedPrefString(prefs, next);
      return next;
    } else {
      return current;
    }
  }

  // Generic integer settings management with change detection
  // Saves integer settings only when value changes
  Future<int> changeSettingsIntValue({
    required String key,
    required int current,
    required int next,
  }) async {
    if (next != current) {
      final prefs = await SharedPreferences.getInstance();
      key.setSharedPrefInt(prefs, next);
      return next;
    } else {
      return current;
    }
  }
}