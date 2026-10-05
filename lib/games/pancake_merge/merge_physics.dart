import 'dart:math';

/// One round item in the jar.
class MergeBody {
  MergeBody({
    required this.id,
    required this.tier,
    required this.x,
    required this.y,
    this.vx = 0,
    this.vy = 0,
  });

  final int id;
  final int tier;
  double x;
  double y;
  double vx;
  double vy;

  /// Seconds since the body entered the jar. New drops get a grace period
  /// before they can trigger the overflow line.
  double age = 0;

  double get radius => MergeWorld.radii[tier];
  double get mass => radius * radius;
}

/// A drop-and-merge jar (Suika-style) in world units: [width] wide and
/// [height] tall, y pointing down. Pure Dart so it can be tested and stepped
/// at a fixed rate independent of the frame rate.
class MergeWorld {
  MergeWorld({Random? random}) : _rng = random ?? Random();

  static const width = 100.0;
  static const height = 140.0;

  /// Items above this line for too long end the game.
  static const overflowLine = 26.0;
  static const dropY = 12.0;
  static const overflowGrace = 1.0;
  static const overflowLimit = 2.0;

  static const radii = [4.5, 6.0, 7.8, 9.8, 12.0, 14.5, 17.5, 21.0, 25.0];
  static int get maxTier => radii.length - 1;

  /// Only the small tiers are ever dropped.
  static const droppableTiers = 5;

  static const gravity = 260.0;
  static const _restitution = 0.15;
  static const _iterations = 4;

  final Random _rng;
  final List<MergeBody> bodies = [];
  int score = 0;
  int merges = 0;
  bool gameOver = false;

  /// Seconds an item has been over the line; drives the warning flash.
  double overflowTimer = 0;
  late int nextTier = _rollTier();
  int _nextId = 0;

  /// Merge events since the last [takeEvents] call, for effects and haptics.
  final List<({double x, double y, int tier})> _events = [];

  /// Weighted toward the smallest tiers.
  int _rollTier() =>
      min(_rng.nextInt(droppableTiers), _rng.nextInt(droppableTiers));

  static int pointsFor(int tier) => (tier + 1) * (tier + 2) ~/ 2;

  List<({double x, double y, int tier})> takeEvents() {
    final e = List.of(_events);
    _events.clear();
    return e;
  }

  /// Clamps a requested drop x so the next item fits inside the walls.
  double clampDropX(double x) {
    final r = radii[nextTier];
    return x.clamp(r, width - r);
  }

  /// Drops the queued item at [x] and rolls the next one.
  MergeBody? drop(double x) {
    if (gameOver) return null;
    final body = MergeBody(
      id: _nextId++,
      tier: nextTier,
      x: clampDropX(x),
      y: dropY,
    );
    bodies.add(body);
    nextTier = _rollTier();
    return body;
  }

  /// Adds a body directly; used by tests and the bomb booster preview.
  MergeBody spawn(int tier, double x, double y) {
    final body = MergeBody(id: _nextId++, tier: tier, x: x, y: y);
    bodies.add(body);
    return body;
  }

  void remove(MergeBody body) => bodies.remove(body);

  /// Topmost body under a world point, for the bomb booster.
  MergeBody? bodyAt(double x, double y) {
    for (final b in bodies.reversed) {
      final dx = b.x - x, dy = b.y - y;
      if (dx * dx + dy * dy <= b.radius * b.radius) return b;
    }
    return null;
  }

  void step(double dt) {
    if (gameOver) return;
    for (final b in bodies) {
      b.age += dt;
      b.vy += gravity * dt;
      b.vx *= 0.995;
      b.x += b.vx * dt;
      b.y += b.vy * dt;
    }
    for (var i = 0; i < _iterations; i++) {
      _resolveWalls();
      if (_resolvePairs()) i = 0;
    }
    // Walls win over pair pushes so nothing ends a step outside the jar.
    _resolveWalls();
    _checkOverflow(dt);
  }

  void _resolveWalls() {
    for (final b in bodies) {
      final r = b.radius;
      if (b.x < r) {
        b.x = r;
        if (b.vx < 0) b.vx = -b.vx * _restitution;
      } else if (b.x > width - r) {
        b.x = width - r;
        if (b.vx > 0) b.vx = -b.vx * _restitution;
      }
      if (b.y > height - r) {
        b.y = height - r;
        if (b.vy > 0) b.vy = -b.vy * _restitution;
        b.vx *= 0.98; // floor friction
      }
    }
  }

  /// Separates overlapping bodies and merges touching twins. Returns true if
  /// a merge happened, so the solver runs again on the new layout.
  bool _resolvePairs() {
    for (var i = 0; i < bodies.length; i++) {
      for (var j = i + 1; j < bodies.length; j++) {
        final a = bodies[i], b = bodies[j];
        var dx = b.x - a.x, dy = b.y - a.y;
        final minDist = a.radius + b.radius;
        final d2 = dx * dx + dy * dy;
        if (d2 >= minDist * minDist) continue;
        if (a.tier == b.tier) {
          _merge(a, b);
          return true;
        }
        var d = sqrt(d2);
        if (d < 1e-6) {
          dx = 0.01;
          dy = 0;
          d = 0.01;
        }
        final nx = dx / d, ny = dy / d;
        final overlap = minDist - d;
        final total = a.mass + b.mass;
        a.x -= nx * overlap * b.mass / total;
        a.y -= ny * overlap * b.mass / total;
        b.x += nx * overlap * a.mass / total;
        b.y += ny * overlap * a.mass / total;
        final rel = (b.vx - a.vx) * nx + (b.vy - a.vy) * ny;
        if (rel < 0) {
          final impulse = -(1 + _restitution) * rel / (1 / a.mass + 1 / b.mass);
          a.vx -= impulse * nx / a.mass;
          a.vy -= impulse * ny / a.mass;
          b.vx += impulse * nx / b.mass;
          b.vy += impulse * ny / b.mass;
        }
      }
    }
    return false;
  }

  void _merge(MergeBody a, MergeBody b) {
    bodies
      ..remove(a)
      ..remove(b);
    final x = (a.x + b.x) / 2, y = (a.y + b.y) / 2;
    merges++;
    if (a.tier == maxTier) {
      // Two of the biggest item pop for a jackpot and free up the jar.
      score += pointsFor(maxTier) * 4;
      _events.add((x: x, y: y, tier: maxTier + 1));
      return;
    }
    final tier = a.tier + 1;
    score += pointsFor(tier);
    final merged = MergeBody(
      id: _nextId++,
      tier: tier,
      x: x,
      y: y,
      vx: (a.vx + b.vx) / 2,
      vy: (a.vy + b.vy) / 2,
    )..age = overflowGrace;
    bodies.add(merged);
    _events.add((x: x, y: y, tier: tier));
  }

  void _checkOverflow(double dt) {
    final over = bodies.any(
      (b) => b.age > overflowGrace && b.y - b.radius < overflowLine,
    );
    overflowTimer = over ? overflowTimer + dt : 0;
    if (overflowTimer >= overflowLimit) gameOver = true;
  }
}
