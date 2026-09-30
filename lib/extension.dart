// ===== Extension methods for LETS ELEVATOR =====
// String, Context, Int, ListInt, ListString, Bool, ListBool, and ListDynamic extensions

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'audio_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constant.dart';
import 'l10n/app_localizations.dart' show AppLocalizations;

part 'l10n_extension.dart';
part 'size_extension.dart';

// ===== StringExt: string, SharedPreferences, image path, and style helpers =====
extension StringExt on String {

  // --- Debug Utilities ---
  // Provides debug printing functionality for development
  void debugPrint() {
    if (kDebugMode) print(this);
  }

  // --- SharedPreferences Helpers ---
  // Store and retrieve data from SharedPreferences, with debug logging
  void setSharedPrefString(SharedPreferences prefs, String value) {
    "Saved ${replaceAll("Key", "")}: $value".debugPrint();
    prefs.setString(this, value);
  }
  void setSharedPrefInt(SharedPreferences prefs, int value) {
    "Saved ${replaceAll("Key", "")}: $value".debugPrint();
    prefs.setInt(this, value);
  }
  void setSharedPrefBool(SharedPreferences prefs, bool value) {
    "Saved ${replaceAll("Key", "")}: $value".debugPrint();
    prefs.setBool(this, value);
  }
  void setSharedPrefListString(SharedPreferences prefs, List<String> value) {
    "Saved ${replaceAll("Key", "")}: $value".debugPrint();
    prefs.setStringList(this, value);
  }
  void setSharedPrefListInt(SharedPreferences prefs, List<int> value) {
    for (int i = 0; i < value.length; i++) {
      prefs.setInt("$this$i", value[i]);
    }
    "Saved ${replaceAll("Key", "")}: $value".debugPrint();
  }
  void setSharedPrefListBool(SharedPreferences prefs, List<bool> value) {
    for (int i = 0; i < value.length; i++) {
      prefs.setBool("$this$i", value[i]);
    }
    "Saved ${replaceAll("Key", "")}: $value".debugPrint();
  }
  String getSharedPrefString(SharedPreferences prefs, String defaultString) {
    String value = prefs.getString(this) ?? defaultString;
    "Get ${replaceAll("Key", "")}: $value".debugPrint();
    return value;
  }
  int getSharedPrefInt(SharedPreferences prefs, int defaultInt) {
    int value = prefs.getInt(this) ?? defaultInt;
    "Get ${replaceAll("Key", "")}: $value".debugPrint();
    return value;
  }
  bool getSharedPrefBool(SharedPreferences prefs, bool defaultBool) {
    bool value = prefs.getBool(this) ?? defaultBool;
    "Get ${replaceAll("Key", "")}: $value".debugPrint();
    return value;
  }
  List<String> getSharedPrefListString(SharedPreferences prefs, List<String> defaultList) {
    List<String> values = prefs.getStringList(this) ?? defaultList;
    "Get ${replaceAll("Key", "")}: $values".debugPrint();
    return values;
  }
  List<int> getSharedPrefListInt(SharedPreferences prefs, List<int> defaultList) {
    List<int> values = [];
    for (int i = 0; i < defaultList.length; i++) {
      int v = prefs.getInt("$this$i") ?? defaultList[i];
      values.add(v);
    }
    "Get ${replaceAll("Key", "")}: $values".debugPrint();
    return (values == []) ? defaultList: values;
  }
  List<bool> getSharedPrefListBool(SharedPreferences prefs, List<bool> defaultList) {
    List<bool> values = [];
    for (int i = 0; i < defaultList.length; i++) {
      bool v = prefs.getBool("$this$i") ?? defaultList[i];
      values.add(v);
    }
    "Get ${replaceAll("Key", "")}: $values".debugPrint();
    return (values == []) ? defaultList: values;
  }

  // --- Image Path Helpers ---
  // Methods for creating and managing image assets and file-based images
  String backGroundImage() => "$assetsCommon$this.png";

  // --- Button Shape Helpers ---
  // Methods for managing button shape configurations and indices
  int buttonShapeIndex() => buttonShapeList.contains(this) ? buttonShapeList.indexOf(this): 0;
}

// ===== ContextExt: BuildContext utilities, localization, UI helpers =====
extension ContextExt on BuildContext {
  // --- Navigation & UI Basics ---
  // Core navigation and UI utility methods for screen management and responsive design
  void pushFadeReplacement(Widget page, {Duration duration = const Duration(milliseconds: 500)}) {
    AudioManager().playEffectSound(asset: changeModeSound, volume: 1.0);
    Navigator.pushReplacement(this, PageRouteBuilder(
      pageBuilder: (_, animation, _) => page,
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      transitionDuration: duration,
    ));
  }
  void pushNoBack(Widget page) => Navigator.pushAndRemoveUntil(this,
      MaterialPageRoute(builder: (_) => page),
      (route) => false
    );
  /// Push over the current screen, keeping it underneath. Not opaque: the ad
  /// banner the screen below draws stays visible through the strip the page
  /// leaves at the bottom
  void pushPage(Widget page) {
    Navigator.push(this, PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, animation, _) => page,
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 300),
    ));
  }
  void popPage() => Navigator.pop(this);
}


extension IntExt on int {

  // --- Settings UI ---
  // Selected number indicator for settings buttons
  String selected(int i) => (this == i) ? "Pressed": "";
  String settingsButton(int i) => "$assetsSettings${settingsItemList[i]}Settings${selected(i)}.png";
  // Operation button style assets for different button types
  String openButton() => "${assetsButton}open${this + 1}.png";
  String closeButton() => "${assetsButton}close${this + 1}.png";
  String alertButton() => "${assetsButton}phone${this + 1}.png";
  String pressedOpenButton() => "${assetsButton}open${this + 1}Pressed.png";
  String pressedCloseButton() => "${assetsButton}close${this + 1}Pressed.png";
  String pressedAlertButton() => "${assetsButton}phone${this + 1}Pressed.png";

  // --- Matrix Utilities ---
  // List index calculation for 2D matrix operations
  int listNum(int row, int col) => this * row + col;

  // --- Floor Sound Generation ---
  // English ordinal number generation for floor announcements
  String enRankNumber() =>
      (abs() % 10 == 1 && abs() ~/ 10 != 1) ? "${abs()}st ":
      (abs() % 10 == 2 && abs() ~/ 10 != 1) ? "${abs()}nd ":
      (abs() % 10 == 3 && abs() ~/ 10 != 1) ? "${abs()}rd ":
      "${abs()}th ";
  // Spanish ordinal number generation for floor announcements
  String esRankNumber() => //1~199
  (this == 0) ? '':
  (this == 1) ? 'primer ' :
  (this == 2) ? 'segundo ' :
  (this == 3) ? 'tercer ' :
  (this == 4) ? 'cuarto ' :
  (this == 5) ? 'quinto ' :
  (this == 6) ? 'sexto ' :
  (this == 7) ? 'séptimo ' :
  (this == 8) ? 'octavo ' :
  (this == 9) ? 'noveno ' :
  (this == 10) ? 'décimo ' :
  (this == 11) ? 'undécimo ' :
  (this == 12) ? 'duodécimo ' :
  (this == 13) ? 'decimotercero ' :
  (this == 14) ? 'decimocuarto ' :
  (this == 15) ? 'decimoquinto ' :
  (this == 16) ? 'decimosexto ' :
  (this == 17) ? 'decimoséptimo ' :
  (this == 18) ? 'decimoctavo ' :
  (this == 19) ? 'decimonoveno ' :
  (this == 20) ? 'vigésimo ':
  (this < 100) ? esRankNumberOver20():
  esRankNumberOver100();
  String esRankNumberOver20() =>
      (this < 100) ? "${
          (this < 30) ? 'vigésimo ':
          (this < 40) ? 'trigésimo ':
          (this < 50) ? 'cuadragésimo ':
          (this < 60) ? 'quincuagésimo ':
          (this < 70) ? 'sexagésimo ':
          (this < 80) ? 'septuagésimo ':
          (this < 90) ? 'octogésimo ':
          'nonagésimo '
      } ${(this % 10).esRankNumber()} ":
      esRankNumberOver100();
  String esRankNumberOver100() =>
      'centésimo ${(this % 100).esRankNumberOver20()} ';
  // French ordinal number generation for floor announcements
  String frRankNumber() => //1~199
    (this == 0) ? '':
    (this == 1) ? 'premier ' :
    (this == 2) ? 'deuxième ' :
    (this == 3) ? 'troisième ' :
    (this == 4) ? 'quatrième ' :
    (this == 5) ? 'cinquième ' :
    (this == 6) ? 'sixième ' :
    (this == 7) ? 'septième ' :
    (this == 8) ? 'huitième ' :
    (this == 9) ? 'neuvième ' :
    (this == 10) ? 'dixième ' :
    (this == 11) ? 'onzième ' :
    (this == 12) ? 'douzième ' :
    (this == 13) ? 'treizième ' :
    (this == 14) ? 'quatorzième ' :
    (this == 15) ? 'quinzième ' :
    (this == 16) ? 'seizième ' :
    (this == 17) ? 'dix-septième ' :
    (this == 18) ? 'dix-huitième ' :
    (this == 19) ? 'dix-neuvième ' :
    (this == 20) ? 'vingtième ':
    (this < 100) ? frRankNumberOver20():
    frRankNumberOver100();
  String frRankNumberOver20() =>
    (this < 100) ? "${
      (this < 30) ? 'vingtième ':
      (this < 40) ? 'trentième ':
      (this < 50) ? 'quarantième ':
      (this < 60) ? 'cinquantième ':
      (this < 70) ? 'soixantième ':
      (this < 80) ? 'soixante-dixième ':
      (this < 90) ? 'quatre-vingtième ':
      'quatre-vingt-dixième '
    } ${(this % 10).frRankNumber()} ":
    frRankNumberOver100();
  String frRankNumberOver100() =>
    'centième ${(this % 100).frRankNumberOver20()} ';

  // --- Display Logic ---
  // Current floor counter display with special symbols
  String displayNumber(bool isTop) =>
      isTop ? "R":
      (this == 0) ? "G":
      (this < 0) ? "B${abs()}":
      "$this";
  // Floor number header display for elevator display panel
  String displayNumberHeader(bool isTop) =>
      isTop ? "R":
      (this == 0) ? "G":
      (this < 0) ? "B":
      " ";
  // Direction arrow image selection based on movement and destination
  String arrowImage(bool isMoving, int nextFloor, int buttonStyle) =>
      (isMoving && this < nextFloor) ? "${assetsCommon}up${buttonStyle + 1}.png":
      (isMoving && this > nextFloor) ? "${assetsCommon}down${buttonStyle + 1}.png":
      transpImage;

  // --- Elevator Movement Logic ---
  // Speed calculation based on distance and operation count
  int elevatorSpeed(int count, int nextFloor) {
    int l = (this - nextFloor).abs();
    return (count < 2 || l < 2) ? 2000:
    (count < 5 || l < 5) ? 1000:
    (count < 10 || l < 10) ? 500:
    (count < 20 || l < 20) ? 250: 100;
  }

  // --- Button State Management ---
  // Floor button number display with special symbols
  String buttonNumber(bool isTop) =>
      isTop ? "R":
      (this == 0) ? "G":
      (this < 0) ? "B${abs()}":
      "$this";

  // Button selection state checking for up/down direction lists
  bool isSelected({
    required List<bool> up,
    required List<bool> down
  }) => (this > 0) ? up[this]: down[this * (-1)];
  // Floor button background image selection based on selection state
  String floorButtonBackgroundImage({
    required bool shimada,
    required int row,
    required int col,
    required List<bool> up,
    required List<bool> down,
    required int style,
    required String shape,
  }) => shimada ? isSelected(up: up, down: down).shimadaButtonImage(row, col):
                  isSelected(up: up, down: down).numberBackground(style,shape);
  // Floor button number color selection based on selection state
  Color floorButtonNumberColor({
    required List<bool> up,
    required List<bool> down,
    required int style,
    required String shape,
  }) => (style != 0) ? blackColor:
    isSelected(up: up, down: down).floorButtonNumberColor(shape);

  // --- Floor Selection Management ---
  // Clear all floors above current position
  void clearUpperFloor(List<bool> isAboveSelectedList, isUnderSelectedList) {
    for (int j = max; j > this - 1; j--) {
      if (j > 0) isAboveSelectedList[j] = false;
      if (j < 0) isUnderSelectedList[j * (-1)] = false;
    }
  }
  // Clear all floors below current position
  void clearLowerFloor(List<bool> isAboveSelectedList, isUnderSelectedList) {
    for (int j = min; j < this + 1; j++) {
      if (j > 0) isAboveSelectedList[j] = false;
      if (j < 0) isUnderSelectedList[j * (-1)] = false;
    }
  }

  // --- Floor Range Generation ---
  // Generate ascending floor list from current to target
  List<int> upFromToNumber(int nextFloor) {
    List<int> floorList = [];
    for (int i = this + 1; i < nextFloor + 1; i++) {
      floorList.add(i);
    }
    return floorList;
  }
  // Generate descending floor list from current to target
  List<int> downFromToNumber(int nextFloor) {
    List<int> floorList = [];
    for (int i = this - 1; i > nextFloor - 1; i--) {
      floorList.add(i);
    }
    return floorList;
  }

  // --- Next Floor Calculation ---
  // Calculate next floor when moving upward
  int upNextFloor({
    required List<bool> up,
    required List<bool> down,
  }) {
    int nextFloor = max;
    for (int k = this + 1; k < max + 1; k++) {
      bool isSelected = k.isSelected(up: up, down: down);
      if (k < nextFloor && isSelected) nextFloor = k;
    }
    if (nextFloor == max) {
      bool isMaxSelected = max.isSelected(up: up, down: down);
      if (isMaxSelected) {
        nextFloor = max;
      } else {
        nextFloor = min;
        bool isMinSelected = min.isSelected(up: up, down: down);
        for (int k = min; k < this; k++) {
          bool isSelected = k.isSelected(up: up, down: down);
          if (k > nextFloor && isSelected) nextFloor = k;
        }
        if (isMinSelected) nextFloor = min;
      }
    }
    bool allFalse = true;
    for (int k = 0; k < up.length; k++) {
      if (up[k]) allFalse = false;
    }
    for (int k = 0; k < down.length; k++) {
      if (down[k]) allFalse = false;
    }
    if (allFalse) nextFloor = this;
    return nextFloor;
  }
  // Calculate next floor when moving downward
  int downNextFloor({
    required List<bool> up,
    required List<bool> down,
  }) {
    int nextFloor = min;
    for (int k = min; k < this; k++) {
      bool isSelected = k.isSelected(up: up, down: down);
      if (k > nextFloor && isSelected) nextFloor = k;
    }
    if (nextFloor == min) {
      bool isMinSelected = min.isSelected(up: up, down: down);
      if (isMinSelected) {
        nextFloor = min;
      } else {
        nextFloor = max;
        bool isMaxSelected = max.isSelected(up: up, down: down);
        for (int k = max; k > this; k--) {
          bool isSelected = k.isSelected(up: up, down: down);
          if (k < nextFloor && isSelected) nextFloor = k;
        }
        if (isMaxSelected) nextFloor = max;
      }
    }
    bool allFalse = true;
    for (int k = 0; k < up.length; k++) {
      if (up[k]) allFalse = false;
    }
    for (int k = 0; k < down.length; k++) {
      if (down[k]) allFalse = false;
    }
    if (allFalse) nextFloor = this;
    return nextFloor;
  }

  // --- Button State Control ---
  // Set button as selected (true)
  void trueSelected({
    required List<bool> up,
    required List<bool> down,
  }) {
    if (this > 0) up[this] = true;
    if (this < 0) down[this * (-1)] = true;
  }

  // Set button as unselected (false)
  void falseSelected({
    required List<bool> up,
    required List<bool> down,
  }) {
    if (this > 0) up[this] = false;
    if (this < 0) down[this * (-1)] = false;
  }
  // Check if this is the only selected button
  bool onlyTrue({
    required List<bool> up,
    required List<bool> down,
  }) {
    bool listFlag = false;
    if (isSelected(up: up, down: down)) listFlag = true;
    if (this > 0) {
      for (int k = 0; k < up.length; k++) {
        if (k != this && up[k]) listFlag = false;
      }
      for (int k = 0; k < down.length; k++) {
        if (down[k]) listFlag = false;
      }
    }
    if (this < 0) {
      for (int k = 0; k < down.length; k++) {
        if (k != this * (-1) && down[k]) listFlag = false;
      }
      for (int k = 0; k < up.length; k++) {
        if (up[k]) listFlag = false;
      }
    }
    return listFlag;
  }

  // --- 1000 Button Challenge Layout ---
  // Transparent button positions for special layout effects
  bool isTranspButton(int i, j) =>
      //panel 2
      (this == 1 && i == 2 && j == 7) ? true:
      //panel 4
      (this == 3 && i == 9 && j == 3) ? true:
      false;
  // Missing button positions for realistic elevator panel layouts
  bool isNotHaveButton(int i, j) =>
      // panel 1
      (this == 0 && i == 0 && j == 2) ? true:
      (this == 0 && i == 0 && j == 4) ? true:
      (this == 0 && i == 0 && j == 10) ? true:
      (this == 0 && i == 1 && j == 1) ? true:
      (this == 0 && i == 1 && j == 2) ? true:
      (this == 0 && i == 1 && j == 9) ? true:
      (this == 0 && i == 1 && j == 10) ? true:
      (this == 0 && i == 2 && j == 6) ? true:
      (this == 0 && i == 2 && j == 9) ? true:
      (this == 0 && i == 2 && j == 10) ? true:
      (this == 0 && i == 5 && j == 4) ? true:
      (this == 0 && i == 5 && j == 5) ? true:
      (this == 0 && i == 6 && j == 5) ? true:
      (this == 0 && i == 7 && j == 3) ? true:
      (this == 0 && i == 7 && j == 8) ? true:
      (this == 0 && i == 8 && j == 7) ? true:
      (this == 0 && i == 8 && j == 9) ? true:
      (this == 0 && i == 9 && j == 5) ? true:
      (this == 0 && i == 10 && j == 1) ? true:
      // panel 2
      (this == 1 && i == 0 && j == 0) ? true:
      (this == 1 && i == 0 && j == 3) ? true:
      (this == 1 && i == 0 && j == 4) ? true:
      (this == 1 && i == 0 && j == 6) ? true:
      (this == 1 && i == 1 && j == 0) ? true:
      (this == 1 && i == 1 && j == 9) ? true:
      (this == 1 && i == 2 && j == 2) ? true:
      (this == 1 && i == 3 && j == 2) ? true:
      (this == 1 && i == 7 && j == 1) ? true:
      (this == 1 && i == 7 && j == 4) ? true:
      (this == 1 && i == 8 && j == 1) ? true:
      (this == 1 && i == 8 && j == 3) ? true:
      (this == 1 && i == 8 && j == 4) ? true:
      (this == 1 && i == 8 && j == 7) ? true:
      // panel 3
      (this == 2 && i == 0 && j == 0) ? true:
      (this == 2 && i == 1 && j == 7) ? true:
      (this == 2 && i == 1 && j == 8) ? true:
      (this == 2 && i == 1 && j == 9) ? true:
      (this == 2 && i == 2 && j == 6) ? true:
      (this == 2 && i == 3 && j == 0) ? true:
      (this == 2 && i == 4 && j == 5) ? true:
      (this == 2 && i == 4 && j == 6) ? true:
      (this == 2 && i == 5 && j == 10) ? true:
      (this == 2 && i == 7 && j == 9) ? true:
      (this == 2 && i == 8 && j == 7) ? true:
      (this == 2 && i == 9 && j == 5) ? true:
      (this == 2 && i == 10 && j == 1) ? true:
      (this == 2 && i == 10 && j == 4) ? true:
      // panel 4
      (this == 3 && i == 0 && j == 5) ? true:
      (this == 3 && i == 1 && j == 4) ? true:
      (this == 3 && i == 1 && j == 5) ? true:
      (this == 3 && i == 1 && j == 8) ? true:
      (this == 3 && i == 2 && j == 10) ? true:
      (this == 3 && i == 3 && j == 2) ? true:
      (this == 3 && i == 3 && j == 3) ? true:
      (this == 3 && i == 6 && j == 5) ? true:
      (this == 3 && i == 7 && j == 3) ? true:
      (this == 3 && i == 7 && j == 6) ? true:
      (this == 3 && i == 7 && j == 10) ? true:
      (this == 3 && i == 8 && j == 2) ? true:
      (this == 3 && i == 8 && j == 4) ? true:
      (this == 3 && i == 10 && j == 4) ? true:
      (this == 3 && i == 10 && j == 5) ? true:
      // panel 5
      (this == 4 && i == 0 && j == 3) ? true:
      (this == 4 && i == 0 && j == 5) ? true:
      (this == 4 && i == 0 && j == 6) ? true:
      (this == 4 && i == 0 && j == 8) ? true:
      (this == 4 && i == 0 && j == 9) ? true:
      (this == 4 && i == 1 && j == 8) ? true:
      (this == 4 && i == 2 && j == 6) ? true:
      (this == 4 && i == 3 && j == 1) ? true:
      (this == 4 && i == 3 && j == 4) ? true:
      (this == 4 && i == 3 && j == 9) ? true:
      (this == 4 && i == 5 && j == 8) ? true:
      (this == 4 && i == 6 && j == 1) ? true:
      (this == 4 && i == 6 && j == 9) ? true:
      (this == 4 && i == 7 && j == 7) ? true:
      (this == 4 && i == 8 && j == 7) ? true:
      (this == 4 && i == 8 && j == 9) ? true:
      (this == 4 && i == 9 && j == 7) ? true:
      (this == 4 && i == 9 && j == 8) ? true:
      (this == 4 && i == 10 && j == 3) ? true:
      (this == 4 && i == 10 && j == 8) ? true:
      // panel 6
      (this == 5 && i == 0 && j == 7) ? true:
      (this == 5 && i == 1 && j == 6) ? true:
      (this == 5 && i == 1 && j == 9) ? true:
      (this == 5 && i == 2 && j == 5) ? true:
      (this == 5 && i == 3 && j == 0) ? true:
      (this == 5 && i == 3 && j == 4) ? true:
      (this == 5 && i == 3 && j == 5) ? true:
      (this == 5 && i == 4 && j == 0) ? true:
      (this == 5 && i == 4 && j == 3) ? true:
      (this == 5 && i == 4 && j == 5) ? true:
      (this == 5 && i == 4 && j == 7) ? true:
      (this == 5 && i == 5 && j == 2) ? true:
      (this == 5 && i == 5 && j == 4) ? true:
      (this == 5 && i == 5 && j == 8) ? true:
      (this == 5 && i == 6 && j == 1) ? true:
      (this == 5 && i == 6 && j == 4) ? true:
      (this == 5 && i == 6 && j == 9) ? true:
      (this == 5 && i == 7 && j == 6) ? true:
      (this == 5 && i == 8 && j == 0) ? true:
      (this == 5 && i == 8 && j == 3) ? true:
      (this == 5 && i == 8 && j == 7) ? true:
      (this == 5 && i == 8 && j == 9) ? true:
      (this == 5 && i == 9 && j == 1) ? true:
      (this == 5 && i == 9 && j == 2) ? true:
      (this == 5 && i == 9 && j == 7) ? true:
      (this == 5 && i == 9 && j == 10) ? true:
      (this == 5 && i == 10 && j == 7) ? true:
      // panel 7
      (this == 6 && i == 0 && j == 2) ? true:
      (this == 6 && i == 1 && j == 9) ? true:
      (this == 6 && i == 2 && j == 1) ? true:
      (this == 6 && i == 2 && j == 2) ? true:
      (this == 6 && i == 2 && j == 10) ? true:
      (this == 6 && i == 3 && j == 2) ? true:
      (this == 6 && i == 3 && j == 6) ? true:
      (this == 6 && i == 3 && j == 7) ? true:
      (this == 6 && i == 4 && j == 1) ? true:
      (this == 6 && i == 6 && j == 8) ? true:
      (this == 6 && i == 7 && j == 10) ? true:
      (this == 6 && i == 10 && j == 0) ? true:
      // panel 8
      (this == 7 && i == 1 && j == 3) ? true:
      (this == 7 && i == 2 && j == 6) ? true:
      (this == 7 && i == 2 && j == 8) ? true:
      (this == 7 && i == 3 && j == 3) ? true:
      (this == 7 && i == 5 && j == 0) ? true:
      (this == 7 && i == 5 && j == 7) ? true:
      (this == 7 && i == 7 && j == 2) ? true:
      (this == 7 && i == 7 && j == 7) ? true:
      (this == 7 && i == 7 && j == 10) ? true:
      (this == 7 && i == 8 && j == 0) ? true:
      (this == 7 && i == 8 && j == 7) ? true:
      (this == 7 && i == 9 && j == 4) ? true:
      (this == 7 && i == 10 && j == 2) ? true:
      (this == 7 && i == 10 && j == 4) ? true:
      // panel 8
      (this == 8 && i == 0 && j == 4) ? true:
      (this == 8 && i == 0 && j == 9) ? true:
      (this == 8 && i == 1 && j == 1) ? true:
      (this == 8 && i == 1 && j == 2) ? true:
      (this == 8 && i == 2 && j == 3) ? true:
      (this == 8 && i == 2 && j == 9) ? true:
      (this == 8 && i == 3 && j == 4) ? true:
      (this == 8 && i == 3 && j == 5) ? true:
      (this == 8 && i == 3 && j == 7) ? true:
      (this == 8 && i == 3 && j == 8) ? true:
      (this == 8 && i == 5 && j == 3) ? true:
      (this == 8 && i == 5 && j == 4) ? true:
      (this == 8 && i == 5 && j == 6) ? true:
      (this == 8 && i == 5 && j == 8) ? true:
      (this == 8 && i == 6 && j == 7) ? true:
      (this == 8 && i == 6 && j == 10) ? true:
      (this == 8 && i == 7 && j == 9) ? true:
      (this == 8 && i == 8 && j == 2) ? true:
      (this == 8 && i == 8 && j == 8) ? true:
      (this == 8 && i == 9 && j == 5) ? true:
      (this == 8 && i == 10 && j == 8) ? true:
      // Other
      false;
  // Button width scaling factors for different panel layouts
  double buttonWidthFactor(int i, j) =>
      //panel 1
      (this == 0 && i == 1 && j == 8) ? 3:
      (this == 0 && i == 5 && j == 2) ? 3:
      (this == 0 && i == 8 && j == 10) ? 2:
      //panel 2
      (this == 1 && i == 2 && j == 6) ? 2:
      (this == 1 && i == 2 && j == 7) ? 2:
      (this == 1 && i == 5 && j == 1) ? 3:
      (this == 1 && i == 7 && j == 9) ? 3:
      //panel 3
      (this == 2 && i == 4 && j == 2) ? 1.5:
      (this == 2 && i == 5 && j == 2) ? 1.5:
      (this == 2 && i == 6 && j == 6) ? 3:
      //panel 4
      (this == 3 && i == 2 && j == 2) ? 3:
      //panel 5
      (this == 4 && i == 1 && j == 5) ? 2:
      (this == 4 && i == 1 && j == 9) ? 2:
      (this == 4 && i == 5 && j == 2) ? 2:
      (this == 4 && i == 6 && j == 6) ? 1.5:
      (this == 4 && i == 7 && j == 6) ? 1.5:
      //panel 6
      (this == 5 && i == 3 && j == 8) ? 3:
      (this == 5 && i == 7 && j == 1) ? 2:
      //panel 7
      (this == 6 && i == 3 && j == 3) ? 3:
      (this == 6 && i == 7 && j == 1) ? 2:
      (this == 6 && i == 7 && j == 8) ? 3:
      //panel 8
      (this == 7 && i == 6 && j == 5) ? 3:
      //panel 9
      (this == 8 && i == 1 && j == 6) ? 4:
      (this == 8 && i == 2 && j == 1) ? 4:
      (this == 8 && i == 7 && j == 3) ? 3:
      1;

  // --- Challenge Mode Utilities ---
  // Zero-padded number display for score counters
  String countNumber() =>
      (this > 999) ? "$this":
      (this > 99) ? "0$this":
      (this > 9) ? "00$this":
      "000$this";
  // Countdown timer number formatting
  String countDownNumber() =>
      (this > 9) ? "$this": (this < 0 || this > 99) ? "00": "0$this";
  // Start button color coding based on challenge state
  Color startButtonColor() =>
      (this == 0) ? redColor:
      (this % 2 == 1) ? blackColor:
      (this < 10) ? yellowColor:
      greenColor;

  // --- List Generation Utilities ---
  // Generate 3D list filled with false values
  List<List<List<bool>>> listListAllFalse(int rowMax, int columnMax) =>
      List.generate(this, (_) => List.generate(rowMax, (_) => List.generate(columnMax, (_) => false)));
  // Generate 3D list filled with true values
  List<List<List<bool>>> listListAllTrue(int rowMax, int columnMax) =>
      List.generate(this, (_) => List.generate(rowMax, (_) => List.generate(columnMax, (_) => true)));
}

extension BoolExt on bool {

  // --- Button State Management ---
  // Pressed state suffix for asset file names
  String pressed() => this ? 'Pressed': '';
  // Button background image selection based on style, shape, and pressed state
  String numberBackground(int buttonStyle, String buttonShape) => "$assetsButton$buttonShape${buttonStyle + 1}${pressed()}.png";
  // Button number color selection based on pressed state
  Color numberColor(int i) => this ? numberColorList[i]: whiteColor;
  // Floor button number color based on button shape and pressed state
  Color floorButtonNumberColor(String buttonShape) => numberColor(buttonShape.buttonShapeIndex());
  // Shimada button image selection for 1000 button challenge
  String shimadaButtonImage(int row, int col) =>
      '$assets1000${this ? "p": ""}${shimadaFloorNumbers.toReversedMatrix(4)[row][col].buttonNumber(shimadaFloorNumbers.toReversedMatrix(4)[row][col] == max)}.png';

  // --- Menu Navigation ---
  // Mode change button selection based on current Shimada state
  String modeChangeButton(bool isShimada) => (this && !isShimada) ? modeShimadaButton: modeNormalButton;
  // Challenge mode button selection based on games sign-in status
  String modeChallengeButton(bool isGamesSignIn) => (!this && isGamesSignIn) ? rankingButton: mode1000Button;

  // --- Shimada Mode Styling ---
  // Button channel background selection
  String buttonChanBackGround() => (this) ? pressedButtonChan: buttonChan;
  // Open button background with Shimada or standard styling
  String openBackGround(bool isPressed, int buttonStyle) => (this) ?
      ((isPressed) ? pressedShimadaOpen: shimadaOpen):
      ((isPressed) ? buttonStyle.pressedOpenButton(): buttonStyle.openButton());
  // Close button background with Shimada or standard styling
  String closeBackGround(bool isPressed, int buttonStyle) => (this) ?
      ((isPressed) ? pressedShimadaClose: shimadaClose):
      ((isPressed) ? buttonStyle.pressedCloseButton(): buttonStyle.closeButton());
  // Phone/alert button background with Shimada or standard styling
  String phoneBackGround(bool isPressed, int buttonStyle) => (this) ?
      ((isPressed) ? pressedShimadaAlert: shimadaAlert):
      ((isPressed) ?  buttonStyle.pressedAlertButton(): buttonStyle.alertButton());

  // Operation button background list for all three buttons
  List<String> operateBackGround(List<bool> isPressedList, int buttonStyle) => [
    openBackGround(isPressedList[0], buttonStyle),
    closeBackGround(isPressedList[1], buttonStyle),
    phoneBackGround(isPressedList[2], buttonStyle)
  ];

  // --- Menu Interaction ---
  // Menu button press handling with audio and vibration feedback
  Future<bool> pressedMenu() async {
    await AudioManager().playEffectSound(asset: selectSound, volume: 0.8);
    await Vibration.vibrate(duration: vibTime, amplitude: vibAmp);
    return !this;
  }
  
}

extension ListListListBoolExt on List<List<List<bool>>> {

  // --- 1000 Button Challenge Image Selection ---
  // Dynamic button image selection for challenge mode based on button state and position
  String buttonImage(int p, i, j) =>
      // Large Buttons => Transparent
      (p.isTranspButton(i, j)) ? transpImage:
      // Missing Buttons => Random image selection
      (p.isNotHaveButton(i, j) && this[p][i][j]) ? "${assetsRealOn}xp${(19 * i + 13 * j) % 184 + 1}.png":
      (p.isNotHaveButton(i, j)) ? "${assetsRealOff}x${(19 * i + 13 * j) % 184 + 1}.png":
      // Standard Buttons => State-based image selection
      (this[p][i][j]) ? "${assetsReal1000On}p${p + 1}/p${p + 1}_${i + 1}_${j + 1}.png":
      "$assetsReal1000Off${p + 1}/${p + 1}_${i + 1}_${j + 1}.png";
}

extension ListBoolExt on List<bool> {

  // --- Operation Button Image Management ---
  // Operation button image list generation for elevator control buttons
  List<String> operationButtonImage(int buttonStyle) => [
    false.openBackGround(this[0], buttonStyle),
    false.closeBackGround(this[1], buttonStyle),
    false.phoneBackGround(this[2], buttonStyle),
  ];

  // Update pressed lamp state; returns new list (index: 0=open, 1=close, 2=alert)
  List<bool> setOperationButtonLamp(bool isOn, int i) => [
    (i == 0) ? isOn: this[0],
    (i == 1) ? isOn: this[1],
    (i == 2) ? isOn: this[2],
  ];
}

extension ListDynamicExt<T> on List<T> {

  // --- Matrix Transformation Utilities ---
  // Convert list to 2D matrix with specified column count
  List<List<T>> toMatrix(int n) =>
      [for (var i = 0; i < length; i += n) sublist(i, (i + n <= length) ? i + n : length)];

  // Convert list to reversed 2D matrix for special layout requirements
  List<List<T>> toReversedMatrix(int n) {
    final chunks = <List<T>>[];
    for (int i = 0; i < length; i += n) {
      final end = (i + n).clamp(0, length);
      final chunk = (i == 0) ? sublist(i, end).reversed.toList(): sublist(i, end);
      chunks.add(chunk);
    }
    // "chunks: ${chunks.reversed.toList()}".debugPrint();
    return chunks.reversed.toList();
  }
}

extension ListInt on List<int> {

  /// A button sits between its neighbours, except the two ends. The bottom one
  /// runs down to min, and the top one up to max; their other limit comes from
  /// how many buttons have to fit on the far side of the fixed 1F
  /// The picker stops at the neighbouring buttons, so no other floor has to move
  int selectFirstFloor(int row, int col) {
    final i = reversedButtonIndex[row][col];
    // this[i - 1] is never -1 unless i is 1F, which cannot be selected.
    // So the result never lands on the floor 0 that does not exist.
    if (i == 0) return min;
    return this[i - 1] + 1;
  }
  int selectLastFloor(int row, int col) {
    final i = reversedButtonIndex[row][col];
    if (i == floorButtonCount - 1) return max;
    final last = this[i + 1] - 1;
    return (last == 0) ? -1 : last;
  }
  // Calculate floor range difference for button configuration
  int selectDiffFloor(int row, int col) =>
      selectLastFloor(row, col) - selectFirstFloor(row, col) + 1;
  // Calculate selected floor number based on index and position
  int selectedFloor(int index, int row, int col) =>
      index + selectFirstFloor(row, col);
}
