import 'dart:math';

/// Rules for Boba Sort: tubes hold stacked color layers (bottom first). Pour
/// the top run of one tube onto an empty tube or a matching top color until
/// every tube is empty or full of one color.
class BobaSortPuzzle {
  BobaSortPuzzle(List<List<int>> tubes, {this.capacity = 4})
    : _tubes = [
        for (final t in tubes) [...t],
      ];

  final int capacity;
  final List<List<int>> _tubes;
  final List<List<List<int>>> _history = [];
  int moves = 0;

  List<List<int>> get tubes => [for (final t in _tubes) List.unmodifiable(t)];
  int get tubeCount => _tubes.length;
  bool get canUndo => _history.isNotEmpty;

  bool get isSolved => _tubes.every(
    (t) => t.isEmpty || (t.length == capacity && t.every((c) => c == t.first)),
  );

  /// How many layers would move from [from] to [to]; zero if the pour is not
  /// allowed.
  int pourAmount(int from, int to) {
    if (from == to) return 0;
    final src = _tubes[from];
    final dst = _tubes[to];
    if (src.isEmpty || dst.length >= capacity) return 0;
    final color = src.last;
    if (dst.isNotEmpty && dst.last != color) return 0;
    var run = 0;
    for (var i = src.length - 1; i >= 0 && src[i] == color; i--) {
      run++;
    }
    return min(run, capacity - dst.length);
  }

  bool pour(int from, int to) {
    final n = pourAmount(from, to);
    if (n == 0) return false;
    _history.add(tubes.map((t) => [...t]).toList());
    for (var i = 0; i < n; i++) {
      _tubes[to].add(_tubes[from].removeLast());
    }
    moves++;
    return true;
  }

  bool undo() {
    if (_history.isEmpty) return false;
    final prev = _history.removeLast();
    for (var i = 0; i < _tubes.length; i++) {
      _tubes[i]
        ..clear()
        ..addAll(prev[i]);
    }
    moves++;
    return true;
  }

  /// Builds a guaranteed-solvable puzzle for [level] (1-based). The same
  /// level always produces the same puzzle.
  factory BobaSortPuzzle.forLevel(int level, {int capacity = 4}) {
    final colors = levelColors(level);
    final rng = Random(level * 7919);
    while (true) {
      final layers = [
        for (var c = 0; c < colors; c++) ...List.filled(capacity, c),
      ]..shuffle(rng);
      final tubes = [
        for (var t = 0; t < colors; t++)
          layers.sublist(t * capacity, (t + 1) * capacity),
        <int>[],
        <int>[],
      ];
      final puzzle = BobaSortPuzzle(tubes, capacity: capacity);
      if (!puzzle.isSolved && puzzle.isSolvable()) return puzzle;
    }
  }

  /// Number of colors at a level: starts at 3, adds one every two levels, and
  /// tops out at the palette size.
  static int levelColors(int level) => min(3 + (level - 1) ~/ 2, maxColors);

  static const maxColors = 9;

  /// Depth-first search over pour moves with a visited set. Bounded so a
  /// pathological shuffle can't stall level generation.
  bool isSolvable({int budget = 200000}) {
    final seen = <String>{};
    var steps = 0;
    bool search(BobaSortPuzzle p) {
      if (p.isSolved) return true;
      if (++steps > budget) return false;
      final key = p._canonicalKey();
      if (!seen.add(key)) return false;
      for (var a = 0; a < p.tubeCount; a++) {
        for (var b = 0; b < p.tubeCount; b++) {
          if (p.pourAmount(a, b) == 0) continue;
          // Moving a whole uniform tube into an empty one changes nothing.
          if (p._tubes[b].isEmpty &&
              p._tubes[a].every((c) => c == p._tubes[a].first)) {
            continue;
          }
          final next = BobaSortPuzzle(p._tubes, capacity: p.capacity)
            ..pour(a, b);
          if (search(next)) return true;
        }
      }
      return false;
    }

    return search(this);
  }

  /// Tube order doesn't matter for solvability, so sort tubes for the key.
  String _canonicalKey() =>
      (_tubes.map((t) => t.join(',')).toList()..sort()).join('|');
}
