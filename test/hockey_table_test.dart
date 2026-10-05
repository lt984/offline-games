import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_arcade/games/air_hockey/hockey_table.dart';

void run(HockeyTable t, double seconds) {
  for (var s = 0.0; s < seconds; s += 1 / 240) {
    t.step(1 / 240);
  }
}

void main() {
  test('paddles stay on their own half and inside the walls', () {
    final t = HockeyTable();
    t.setTarget(HockeyPlayer.one, -50, 10);
    t.setTarget(HockeyPlayer.two, 500, 160);
    run(t, 1);
    expect(t.paddleOne.x, t.paddleOne.radius);
    expect(t.paddleOne.y, HockeyTable.height / 2 + t.paddleOne.radius);
    expect(t.paddleTwo.x, HockeyTable.width - t.paddleTwo.radius);
    expect(t.paddleTwo.y, HockeyTable.height / 2 - t.paddleTwo.radius);
  });

  test('the puck waits for the serve, then a paddle strike sends it away', () {
    final t = HockeyTable();
    expect(t.serving, isTrue);
    run(t, HockeyTable.serveDelay + 0.05);
    expect(t.serving, isFalse);
    // Swing player 1's paddle up through the resting puck.
    t.paddleOne
      ..x = 50
      ..y = 110;
    t.setTarget(HockeyPlayer.one, 50, 86);
    run(t, 0.1);
    expect(t.puck.vy, lessThan(-20), reason: 'puck heads toward player 2');
    expect(t.takeEvents(), contains(HockeyEvent.paddle));
  });

  test('a puck through the top mouth is a goal for player 1', () {
    final t = HockeyTable();
    run(t, HockeyTable.serveDelay + 0.05);
    t.paddleTwo.x = 90; // keep the goalie out of the way
    t.puck
      ..x = 50
      ..y = 30
      ..vy = -200;
    run(t, 0.5);
    expect(t.scoreOne, 1);
    expect(t.scoreTwo, 0);
    expect(t.takeEvents(), contains(HockeyEvent.goalOne));
    expect(t.serving, isTrue);
    expect(t.puck.y, greaterThan(0), reason: 'puck is reset onto the table');
  });

  test('the puck bounces off the end wall outside the goal mouth', () {
    final t = HockeyTable();
    run(t, HockeyTable.serveDelay + 0.05);
    t.puck
      ..x = 10
      ..y = 150
      ..vy = 150;
    run(t, 0.3);
    expect(t.scoreTwo, 0);
    expect(t.puck.vy, lessThan(0));
  });

  test('first to five wins and the table freezes until reset', () {
    final t = HockeyTable();
    for (var i = 0; i < HockeyTable.winningScore; i++) {
      run(t, HockeyTable.serveDelay + 0.05);
      t.puck
        ..x = 50
        ..y = 140
        ..vx = 0
        ..vy = 200;
      t.paddleOne.x = 10; // keep the paddle out of the way
      run(t, 0.5);
    }
    expect(t.scoreTwo, HockeyTable.winningScore);
    expect(t.winner, HockeyPlayer.two);
    t.reset();
    expect(t.winner, isNull);
    expect(t.scoreTwo, 0);
  });
}
