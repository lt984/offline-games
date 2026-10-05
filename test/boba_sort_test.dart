import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_arcade/games/boba_sort/boba_sort_logic.dart';

void main() {
  test('pour moves the top run onto a matching color or empty tube', () {
    final p = BobaSortPuzzle([
      [0, 1, 1],
      [2, 1],
      <int>[],
    ]);
    expect(p.pourAmount(0, 1), 2);
    expect(p.pour(0, 1), isTrue);
    expect(p.tubes[0], [0]);
    expect(p.tubes[1], [2, 1, 1, 1]);
    expect(p.pour(0, 1), isFalse, reason: 'destination is full');
    expect(p.pour(1, 0), isFalse, reason: 'top colors differ');
    expect(p.pour(0, 2), isTrue, reason: 'anything pours into an empty tube');
    expect(p.moves, 2);
  });

  test('undo restores the previous layout', () {
    final p = BobaSortPuzzle([
      [0, 1],
      [1],
      <int>[],
    ]);
    p.pour(0, 1);
    expect(p.undo(), isTrue);
    expect(p.tubes, [
      [0, 1],
      [1],
      <int>[],
    ]);
    expect(p.canUndo, isFalse);
  });

  test('solved means every tube is empty or full of one color', () {
    expect(
      BobaSortPuzzle([
        [0, 0, 0, 0],
        <int>[],
      ]).isSolved,
      isTrue,
    );
    expect(
      BobaSortPuzzle([
        [0, 0, 0],
        [0],
      ]).isSolved,
      isFalse,
    );
  });

  test('levels are deterministic, unsolved at start and solvable', () {
    final sw = Stopwatch()..start();
    for (var level = 1; level <= 20; level++) {
      final a = BobaSortPuzzle.forLevel(level);
      final b = BobaSortPuzzle.forLevel(level);
      expect(a.tubes, b.tubes);
      expect(a.isSolved, isFalse);
      expect(a.isSolvable(), isTrue);
      expect(a.tubeCount, BobaSortPuzzle.levelColors(level) + 2);
    }
    // ignore: avoid_print
    print('generated 20 levels in ${sw.elapsedMilliseconds} ms');
  });
}
