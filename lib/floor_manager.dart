import 'package:shared_preferences/shared_preferences.dart';
import 'constant.dart';
import 'extension.dart';

class FloorManager {

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

  Future<List<bool>> saveFloorStops({
    required List<bool> currentList,
    required bool newValue,
    required int newIndex,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final newList = List<bool>.from(currentList);
    newList[newIndex] = newValue;
    "newNumber: $newValue".debugPrint();
    "stopsKey".setSharedPrefListBool(prefs, newList);
    return newList;
  }

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