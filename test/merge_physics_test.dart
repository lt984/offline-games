import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_arcade/games/pancake_merge/merge_physics.dart';

void run(MergeWorld w, double seconds) {
  for (var t = 0.0; t < seconds; t += 1 / 120) {
    w.step(1 / 120);
  }
}

void main() {
  test('a dropped item falls and rests on the floor', () {
    final w = MergeWorld(random: Random(1));
    final b = w.drop(50)!;
    run(w, 2);
    expect(b.y, closeTo(MergeWorld.height - b.radius, 0.5));
    expect(b.vy.abs(), lessThan(5));
  });

  test('two identical items merge into the next tier and score', () {
    final w = MergeWorld(random: Random(1));
    w.spawn(2, 50, 100);
    w.spawn(2, 50, 80);
    run(w, 2);
    expect(w.bodies, hasLength(1));
    expect(w.bodies.single.tier, 3);
    expect(w.score, MergeWorld.pointsFor(3));
    expect(w.takeEvents(), hasLength(1));
  });

  test('different items stack without merging or overlapping much', () {
    final w = MergeWorld(random: Random(1));
    final low = w.spawn(4, 50, 120);
    final high = w.spawn(1, 50, 90);
    run(w, 3);
    expect(w.bodies, hasLength(2));
    final dist = sqrt(pow(low.x - high.x, 2) + pow(low.y - high.y, 2));
    expect(dist, greaterThan(low.radius + high.radius - 0.5));
  });

  test('two of the biggest item pop and leave the jar', () {
    final w = MergeWorld(random: Random(1));
    w.spawn(MergeWorld.maxTier, 30, 110);
    w.spawn(MergeWorld.maxTier, 70, 110);
    run(w, 3);
    expect(w.bodies, isEmpty);
    expect(w.score, greaterThan(0));
  });

  test('many random drops stay inside the jar and stay finite', () {
    final w = MergeWorld(random: Random(7));
    final rng = Random(3);
    for (var i = 0; i < 60 && !w.gameOver; i++) {
      w.drop(rng.nextDouble() * MergeWorld.width);
      run(w, 0.5);
    }
    for (final b in w.bodies) {
      expect(b.x.isFinite && b.y.isFinite, isTrue);
      expect(
        b.x,
        inInclusiveRange(b.radius - 0.5, MergeWorld.width - b.radius + 0.5),
      );
      expect(b.y, lessThanOrEqualTo(MergeWorld.height - b.radius + 0.5));
    }
    expect(w.merges, greaterThan(0));
  });

  test('a stack over the line for too long ends the game', () {
    final w = MergeWorld(random: Random(1));
    // Fill the jar with big items that can't merge with their neighbours.
    var tier = 6;
    for (var y = 120.0; y > 0; y -= 22) {
      for (var x = 20.0; x <= 80; x += 40) {
        w.spawn(tier, x, y);
        tier = tier == 6 ? 5 : 6;
      }
      tier = tier == 6 ? 5 : 6;
    }
    run(w, 5);
    expect(w.gameOver, isTrue);
    expect(w.drop(50), isNull);
  });
}
