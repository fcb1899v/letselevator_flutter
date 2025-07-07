// =============================
// FloorManager: Floor Configuration and Settings Management
//
// This class manages floor-related data persistence and settings changes including:
// 1. Floor Number Management: Save and validate floor number configurations
// 2. Floor Stop Management: Save floor stop flag configurations
// 3. Settings Persistence: Generic string and integer settings management
// 4. Data Validation: Input validation for floor numbers and settings
// =============================

import 'package:shared_preferences/shared_preferences.dart';
import 'constant.dart';
import 'extension.dart';

class FloorManager {

  // --- Floor Number Management ---
  // Save floor number with validation and persistence
  // Validates floor number range and uniqueness before saving
  Future<List<int>> saveFloorNumber({
    required List<int> currentList,
    required int newValue,
    required int newIndex,
  }) async {
    if (!currentList.contains(newValue) && newValue != 0 && min <= newValue && newValue <= max) {
      final prefs = await SharedPreferences.getInstance();
      final newList = List<int>.from(currentList);
      newList[newIndex] = newValue;
      "newNumber: $newValue".debugPrint();
      "numbersKey".setSharedPrefListInt(prefs, newList);
      return newList;
    } else {
      return currentList;
    }
  }

  // --- Floor Stop Management ---
  // Save floor stop flag with persistence
  // Updates floor stop configuration for elevator operation
  Future<List<bool>> saveFloorStops({
    required List<bool> currentList,
    required bool newValue,
    required int newIndex,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final newList = List<bool>.from(currentList);
    newList[newIndex] = newValue;
    "newStop: $newValue".debugPrint();
    "stopsKey".setSharedPrefListBool(prefs, newList);
    return newList;
  }

  // --- Settings Persistence ---
  // Generic string settings management with change detection
  // Saves string settings only when value changes
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