// Floor panel rules: the picker range, the save guard, and the stop toggles.
// These are pure functions in constant.dart / extension.dart, so they are
// checked exhaustively rather than through the widgets that call them.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:letselevator/floor_manager.dart';
import 'package:letselevator/constant.dart';
import 'package:letselevator/extension.dart';

/// Every button that is not 1F, as the (row, col) the widgets pass around
List<List<int>> selectableCells() {
  final cells = <List<int>>[];
  for (int row = 0; row < reversedButtonIndex.length; row++) {
    for (int col = 0; col < reversedButtonIndex[row].length; col++) {
      if (!isNotSelectFloor(row, col)) cells.add([row, col]);
    }
  }
  return cells;
}

void expectValidPanel(List<int> list, String reason) {
  expect(list.length, initialFloorNumbers.length, reason: reason);
  expect(list[oneFloorIndex], 1, reason: reason);
  expect(list.contains(0), isFalse, reason: reason);
  expect(list.first >= min && list.last <= max, isTrue, reason: reason);
  for (int i = 1; i < list.length; i++) {
    expect(list[i] > list[i - 1], isTrue, reason: "$reason: not ascending at $i");
  }
}

void main() {
  test("the initial panel obeys every rule", () {
    expectValidPanel(initialFloorNumbers, "initial");
  });

  test("every offered floor is accepted and keeps the panel valid", () {
    for (final cell in selectableCells()) {
      final row = cell[0], col = cell[1];
      final list = List<int>.from(initialFloorNumbers);
      final first = list.selectFirstFloor(row, col);
      final last = list.selectLastFloor(row, col);
      expect(last >= first, isTrue, reason: "empty range at $cell");
      for (int i = 0; i < list.selectDiffFloor(row, col); i++) {
        final value = list.selectedFloor(i, row, col);
        final index = reversedButtonIndex[row][col];
        expect(isInFloorGap(list, index, value), isTrue,
          reason: "offered $value at $cell but the save refuses it");
        expectValidPanel(
          List<int>.from(list)..[index] = value, "picked $value at $cell");
      }
    }
  });

  test("a value meant for another button is refused", () {
    // The picker reports an index, not a floor, so a stale selection used to
    // reach the save and push the panel past max
    final list = List<int>.from(initialFloorNumbers);
    for (final cell in selectableCells()) {
      final row = cell[0], col = cell[1];
      final index = reversedButtonIndex[row][col];
      final offered = <int>{
        for (int i = 0; i < list.selectDiffFloor(row, col); i++)
          list.selectedFloor(i, row, col),
      };
      for (int value = min - 2; value <= max + 2; value++) {
        expect(isInFloorGap(list, index, value), offered.contains(value),
          reason: "$value at $cell: the save and the picker disagree");
      }
    }
    expect(isInFloorGap(list, list.length - 1, max + 1), isFalse);
    expect(isInFloorGap(list, 0, min - 1), isFalse);
    expect(isInFloorGap(list, oneFloorIndex, 2), isFalse);
    expect(isInFloorGap(list, oneFloorIndex - 1, 0), isFalse);
    expect(isInFloorGap(list, oneFloorIndex + 1, 1), isFalse);
  });

  test("a broken saved panel is repaired, and only the broken part", () {
    // A valid panel is left alone
    expect(normalizedFloorNumbers(initialFloorNumbers), initialFloorNumbers);
    // A list of the wrong length has nothing to repair
    expect(normalizedFloorNumbers([1, 2]), initialFloorNumbers);

    // 1F is put back and the buttons around it are pushed clear of it
    final noOneFloor = List<int>.from(initialFloorNumbers)..[oneFloorIndex] = 0;
    expectValidPanel(normalizedFloorNumbers(noOneFloor), "1F was 0");

    // The old basement picker let each button be set on its own
    final tangled = List<int>.from(initialFloorNumbers);
    for (int i = 0; i < oneFloorIndex; i++) {
      tangled[i] = -1;
    }
    final repaired = normalizedFloorNumbers(tangled);
    expectValidPanel(repaired, "duplicated basement");
    // Above ground was fine, so it is untouched
    for (int i = oneFloorIndex + 1; i < repaired.length; i++) {
      expect(repaired[i], initialFloorNumbers[i], reason: "moved a good floor at $i");
    }

    // Repair that runs off the end has nothing sensible left to keep
    final over = List<int>.from(initialFloorNumbers)..[initialFloorNumbers.length - 1] = max + 5;
    expect(normalizedFloorNumbers(over), initialFloorNumbers);
    final unordered = List<int>.from(initialFloorNumbers)..[oneFloorIndex + 1] = max;
    expect(normalizedFloorNumbers(unordered), initialFloorNumbers);

    // Whatever comes in, what comes out is a panel the pickers can work with
    for (final broken in [
      List<int>.generate(initialFloorNumbers.length, (_) => 0),
      List<int>.generate(initialFloorNumbers.length, (i) => -i),
      List<int>.generate(initialFloorNumbers.length, (_) => 1),
    ]) {
      final out = normalizedFloorNumbers(broken);
      expectValidPanel(out, "repaired $broken");
    }
  });

  test("each side of 1F keeps at least one stop", () {
    // Exhaustive over every panel state and every toggle it allows
    final n = initialFloorStops.length;
    bool sidesOk(List<bool> s) =>
      s.sublist(0, oneFloorIndex).contains(true) &&
      s.sublist(oneFloorIndex + 1).contains(true);
    for (int m = 0; m < (1 << n); m++) {
      final stops = List<bool>.generate(n, (i) => (m >> i) & 1 == 1)..[oneFloorIndex] = true;
      if (!sidesOk(stops)) continue;
      for (int i = 0; i < n; i++) {
        if (i == oneFloorIndex) continue;
        for (final value in [true, false]) {
          if (!value && isOnlyStop(stops, i)) continue;  // the switch is disabled
          expect(sidesOk(List<bool>.from(stops)..[i] = value), isTrue,
            reason: "setting $i to $value emptied a side");
        }
      }
    }
  });

  test("a saved state with an empty side is repaired", () {
    final none = List<bool>.generate(initialFloorStops.length, (_) => false);
    final fixed = normalizedFloorStops(none);
    expect(fixed[oneFloorIndex], isTrue);
    expect(fixed.sublist(0, oneFloorIndex).contains(true), isTrue);
    expect(fixed.sublist(oneFloorIndex + 1).contains(true), isTrue);
    expect(normalizedFloorStops([true, false]).length, initialFloorStops.length);
  });
  group("persistence", () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });

    Future<Set<String>> savedKeys(String prefix) async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getKeys().where((k) => k.startsWith(prefix)).toSet();
    }

    test("a floor outside the gap is neither returned nor written", () async {
      final manager = FloorManager();
      final before = List<int>.from(initialFloorNumbers);
      for (final attempt in [
        [before.length - 1, max + 1],     // past the top of the building
        [0, min - 1],                     // past the bottom
        [oneFloorIndex, 2],               // 1F never moves
        [oneFloorIndex - 1, 0],           // floor 0 does not exist
        [oneFloorIndex + 1, before[oneFloorIndex + 2]],  // onto its neighbour
      ]) {
        final after = await manager.saveFloorNumber(
          currentList: before, newIndex: attempt[0], newValue: attempt[1]);
        expect(after, before, reason: "accepted ${attempt[1]} at ${attempt[0]}");
      }
      expect(await savedKeys("numbersKey"), isEmpty);
    });

    test("a floor inside the gap is returned and written", () async {
      final manager = FloorManager();
      final before = List<int>.from(initialFloorNumbers);
      final index = before.length - 1;
      // A value the panel does not already hold, so saving the old list fails
      final moved = before[index] - 1;
      expect(moved, isNot(before[index]));
      final after = await manager.saveFloorNumber(
        currentList: before, newIndex: index, newValue: moved);
      expect(after[index], moved);
      expectValidPanel(after, "saved the top floor");

      // What reached storage, not just which keys exist
      final prefs = await SharedPreferences.getInstance();
      final stored = List<int>.generate(before.length,
        (i) => prefs.getInt("numbersKey$i") ?? 0);
      expect(stored, after);
      expect(stored, isNot(before));
    });

    test("the last stop on a side is neither returned nor written", () async {
      final manager = FloorManager();
      final before = List<bool>.generate(initialFloorStops.length,
        (i) => i == oneFloorIndex || i == oneFloorIndex - 1 || i == oneFloorIndex + 1);
      for (final index in [oneFloorIndex - 1, oneFloorIndex + 1]) {
        final after = await manager.saveFloorStops(
          currentList: before, newIndex: index, newValue: false);
        expect(after, before, reason: "emptied a side at $index");
      }
      expect(await savedKeys("stopsKey"), isEmpty);
    });

    test("a stop that is not the last one is written", () async {
      final manager = FloorManager();
      final before = List<bool>.generate(initialFloorStops.length, (_) => true);
      final after = await manager.saveFloorStops(
        currentList: before, newIndex: oneFloorIndex + 1, newValue: false);
      expect(after[oneFloorIndex + 1], isFalse);
      expect(await savedKeys("stopsKey"), isNotEmpty);
    });
  });

  group("background migration", () {
    final allLocked = List<bool>.generate(initialButtonLock.length, (i) => initialButtonLock[i]);
    final noneLocked = List<bool>.generate(initialButtonLock.length, (_) => false);

    test("a user who had every background under the old rule keeps them", () {
      expect(hadBulkUnlock(
        savedBestScore: unlockAllBestScore, shapeLocks: allLocked), isTrue);
      expect(hadBulkUnlock(
        savedBestScore: unlockAllBestScore + 50, shapeLocks: allLocked), isTrue);
      // The shapes answer it on their own
      expect(hadBulkUnlock(
        savedBestScore: 0, shapeLocks: noneLocked), isTrue);
    });

    test("a user who did not qualify does not", () {
      expect(hadBulkUnlock(
        savedBestScore: unlockAllBestScore - 1, shapeLocks: allLocked), isFalse);
      expect(hadBulkUnlock(
        savedBestScore: 0, shapeLocks: allLocked), isFalse);
      // One shape still locked is not "every shape"
      final oneLocked = List<bool>.generate(initialButtonLock.length,
        (i) => i == initialButtonLock.length - 1);
      expect(hadBulkUnlock(
        savedBestScore: 0, shapeLocks: oneLocked), isFalse);
    });
  });

  group("floor migration", () {
    test("a fresh install gets nothing back", () {
      final grants = floorMigrationGrants(
        hadPanel: false,
        savedNumbers: preLockFloorNumbers,
        savedStops: initialFloorStops,
      );
      expect(grants.contains(true), isFalse);
      // Even if its panel already differs, which it does: the basement moved
      final fresh = floorMigrationGrants(
        hadPanel: false,
        savedNumbers: initialFloorNumbers,
        savedStops: initialFloorStops,
      );
      expect(fresh.contains(true), isFalse);
    });

    test("an untouched old panel gets nothing back", () {
      final grants = floorMigrationGrants(
        hadPanel: true,
        savedNumbers: preLockFloorNumbers,
        savedStops: initialFloorStops,
      );
      expect(grants.contains(true), isFalse);
    });

    test("only the buttons the user had moved come back", () {
      final moved = List<int>.from(preLockFloorNumbers)..[13] = 50;
      final grants = floorMigrationGrants(
        hadPanel: true,
        savedNumbers: moved,
        savedStops: initialFloorStops,
      );
      expect(grants[13], isTrue);
      for (int i = 0; i < grants.length; i++) {
        if (i != 13) expect(grants[i], isFalse, reason: "gave back $i too");
      }
    });

    test("a flipped stop switch counts as touched", () {
      final flipped = List<bool>.from(initialFloorStops)..[2] = !initialFloorStops[2];
      final grants = floorMigrationGrants(
        hadPanel: true,
        savedNumbers: preLockFloorNumbers,
        savedStops: flipped,
      );
      expect(grants[2], isTrue);
    });

    test("a button that was never locked is never granted", () {
      // index 3 is B1, free from the start
      final moved = List<int>.from(preLockFloorNumbers)..[3] = -3;
      final grants = floorMigrationGrants(
        hadPanel: true,
        savedNumbers: moved,
        savedStops: initialFloorStops,
      );
      expect(grants[3], isFalse);
    });
  });

  group("floor unlock order", () {
    test("the first of each side is offered first", () {
      final locks = List<bool>.from(initialFloorLock);
      // 8F above ground, B2 below. Nothing else carries the button
      expect(nextFloorToUnlock(locks, 11), 11);
      expect(nextFloorToUnlock(locks, 15), 11);
      expect(nextFloorToUnlock(locks, 2), 2);
      expect(nextFloorToUnlock(locks, 0), 2);
    });

    test("each side moves on only when its own is opened", () {
      final locks = List<bool>.from(initialFloorLock)..[11] = false;
      expect(nextFloorToUnlock(locks, 12), 12, reason: "above ground did not advance");
      expect(nextFloorToUnlock(locks, 2), 2, reason: "the basement moved with it");
    });

    test("a finished side offers nothing", () {
      final locks = List<bool>.from(initialFloorLock);
      for (final i in [2, 1, 0]) {
        locks[i] = false;
      }
      expect(nextFloorToUnlock(locks, 0), isNull);
      expect(nextFloorToUnlock(locks, 11), 11, reason: "above ground was finished too");
    });

    test("a button that was never locked has no place in the order", () {
      final locks = List<bool>.from(initialFloorLock);
      for (final i in [3, 4, 5, 10]) {
        expect(nextFloorToUnlock(locks, i), isNull, reason: "index $i answered");
      }
    });

    test("the order opens one at a time, to the end", () {
      final locks = List<bool>.from(initialFloorLock);
      final opened = <int>[];
      for (int step = 0; step < 20; step++) {
        final next = nextFloorToUnlock(locks, 11) ?? nextFloorToUnlock(locks, 2);
        if (next == null) break;
        opened.add(next);
        locks[next] = false;
      }
      expect(opened, [11, 12, 13, 14, 15, 2, 1, 0]);
    });
  });

  group("shimada assets", () {
    // The 1000Mode folder holds one artwork per floor. initialFloorNumbers moved
    // its basement to B1/B2/B4/B6, and B6 has no artwork, so the shimada panel
    // has to be pinned to the files that exist
    test("every shimada button image is on disk", () {
      for (int row = 0; row < 4; row++) {
        for (int col = 0; col < 4; col++) {
          for (final pressed in [true, false]) {
            final path = pressed.shimadaButtonImage(row, col);
            expect(File(path).existsSync(), isTrue, reason: "missing $path");
          }
        }
      }
    });

    test("the shimada panel is a valid panel of its own", () {
      expect(shimadaFloorNumbers.length, initialFloorNumbers.length);
      expectValidPanel(shimadaFloorNumbers, "shimada");
    });
  });

  group("free designs", () {
    test("the first row of backgrounds is free and the rest are locked", () {
      expect(initialBackgroundLock.length, backgroundStyleList.length);
      for (int i = 0; i < initialBackgroundLock.length; i++) {
        expect(initialBackgroundLock[i], i >= freeBackgroundCount,
          reason: "background $i");
      }
      // The grid is two wide, so "free" has to be a whole row or it looks odd
      expect(freeBackgroundCount, 2);
      expect(initialBackgroundLock.where((l) => !l).length, freeBackgroundCount);
    });

    test("the locked floors are exactly the ones in the unlock orders", () {
      final ordered = floorUnlockOrders.expand((o) => o).toSet();
      for (int i = 0; i < initialFloorLock.length; i++) {
        expect(initialFloorLock[i], ordered.contains(i), reason: "floor $i");
      }
      // 1F and the buttons beside it stay free, or a new install cannot move at all
      expect(ordered.contains(oneFloorIndex), isFalse);
      expect(ordered.contains(oneFloorIndex - 1), isFalse);
      expect(ordered.contains(oneFloorIndex + 1), isFalse);
    });
  });

  group("lock plate geometry", () {
    // Screens from the narrowest phone still supported to a tall foldable
    const screens = [
      [320.0, 568.0], [360.0, 640.0], [360.0, 800.0], [360.0, 840.0],
      [360.0, 900.0], [360.0, 936.0], [360.0, 1000.0], [375.0, 667.0],
      [390.0, 844.0], [412.0, 915.0], [430.0, 932.0], [600.0, 960.0],
      [768.0, 1024.0], [834.0, 1194.0], [1024.0, 768.0],
      // Past every ratio the formula changes behaviour at: 2.319, 2.367, 2.841
      [360.0, 1024.0], [360.0, 1100.0], [360.0, 1200.0], [360.0, 1440.0],
    ];

    test("four plates fit on a row with a gap left over", () {
      for (final s in screens) {
        final w = s[0], h = s[1];
        final used = floorLockPlateWidth(w, h) * 4;
        expect(used <= w, isTrue, reason: "four plates overflow ${w}x$h");
        // Butted up against each other reads as one block, not four buttons
        expect(used <= w * 0.95, isTrue, reason: "no gap left at ${w}x$h");
      }
    });

    test("the documented ratios are what the constants actually produce", () {
      // These two numbers are in 2026-09-12_lets_unlock_one_at_a_time.md. Pinned
      // here because the tests below re-derive their expectations from the same
      // constants, so a changed constant would otherwise move the goalposts
      expect(1 / (lockPlatesPerRow * lockPlateHeightFactor),
        closeTo(2.319, 0.001), reason: "where the width cap starts");
      expect(1 / (lockPlatesPerRow
          * (lockPillWidthFactor + lockPillPaddingFactor * 2)),
        closeTo(2.367, 0.001), reason: "where the pill starts shrinking");
    });

    test("the cell still holds the floor button it is drawn around", () {
      // settingsButtonSize() is height * 0.07. Above 21:9 no phone exists, so
      // the shape only has to hold together up to there
      for (final s in screens) {
        final w = s[0], h = s[1];
        if (h / w > 2.5) continue;
        expect(lockPillWidth(w, h) >= h * 0.07, isTrue,
          reason: "the floor button sticks out of its cell at ${w}x$h");
      }
    });

    test("the plate is never narrower than the cell it covers", () {
      for (final s in screens) {
        final w = s[0], h = s[1];
        final plate = floorLockPlateWidth(w, h);
        // The cell inside is lockPillWidth too, so this is what stops the plate
        // from being shrunk past the floor button it is supposed to hide
        expect(lockPillWidth(w, h) <= plate + 0.001, isTrue,
          reason: "the cell sticks out of the plate at ${w}x$h");
        expect(lockPillWidth(w, h) >= plate * 0.5, isTrue,
          reason: "the plate is mostly padding at ${w}x$h");
      }
    });

    test("the pill and its padding always fit the plate", () {
      for (final s in screens) {
        final w = s[0], h = s[1];
        final needed = lockPillWidth(w, h) + h * lockPillPaddingFactor * 2;
        expect(needed <= floorLockPlateWidth(w, h) + 0.001, isTrue,
          reason: "the pill is squeezed out at ${w}x$h");
        expect(lockPillWidth(w, h) > 0, isTrue, reason: "no pill at ${w}x$h");
      }
    });

    test("the pill keeps its full width until the cap takes over", () {
      // 2.367 is where the width cap starts eating into the pill
      for (final s in screens) {
        final w = s[0], h = s[1];
        final full = (h / w) <= 1 / (lockPlatesPerRow
          * (lockPillWidthFactor + lockPillPaddingFactor * 2));
        expect(lockPillWidth(w, h) == h * lockPillWidthFactor, full,
          reason: "${w}x$h (h/w ${(h / w).toStringAsFixed(3)})");
      }
    });

    test("the plate grows with the height, then stops at the cap", () {
      const w = 360.0;
      final cap = w / lockPlatesPerRow;
      var previous = 0.0;
      for (double h = 640; h <= 1200; h += 4) {
        final plate = floorLockPlateWidth(w, h);
        expect(plate >= previous - 0.001, isTrue, reason: "shrank at ${w}x$h");
        expect(plate <= cap + 0.001, isTrue, reason: "past the cap at ${w}x$h");
        previous = plate;
      }
      // The cap is reached, or the test proves nothing about it
      expect(floorLockPlateWidth(w, 1200), closeTo(cap, 0.001));
    });
  });

  group("floor cell height", () {
    // 568 is the shortest screen the app still gets asked to draw on
    const heights = [568.0, 640.0, 667.0, 740.0, 800.0, 844.0, 915.0, 1000.0];

    test("the cell clears what it has to hold", () {
      for (final h in heights) {
        expect(floorCellHeight(h) >= floorCellContentHeight(h), isTrue,
          reason: "the cell overflows at height $h "
            "(needs ${floorCellContentHeight(h).toStringAsFixed(1)}, "
            "has ${floorCellHeight(h).toStringAsFixed(1)})");
      }
    });

    test("the sum counts every part of the cell", () {
      // Dropping a term makes the cell look roomier than it is, which is how
      // the 6.3px overflow got in
      const h = 667.0;
      expect(floorCellContentHeight(h) > h * floorButtonFactor
        + cupertinoSwitchSize.height * h * floorStopSwitchScaleFactor, isTrue,
        reason: "the label and the margin are missing from the sum");
      expect(floorCellContentHeight(h) - h * floorButtonFactor
        >= cupertinoSwitchSize.height * h * floorStopSwitchScaleFactor, isTrue,
        reason: "the switch is missing from the sum");
      expect(floorCellContentHeight(h)
        - cupertinoSwitchSize.height * h * floorStopSwitchScaleFactor
        - h * floorButtonFactor >= h * floorStopLabelFactor, isTrue,
        reason: "the Stop label is missing from the sum");
    });

    test("the cell fits inside the plate drawn over it", () {
      for (final s in [
        [360.0, 800.0], [375.0, 667.0], [412.0, 915.0],
        [360.0, 1024.0], [360.0, 1200.0], [360.0, 1440.0],
      ]) {
        final w = s[0], h = s[1];
        expect(floorCellWidth(w, h) <= floorLockPlateWidth(w, h) + 0.001, isTrue,
          reason: "the cell is wider than its lock plate at ${w}x$h");
      }
    });
  });
}
