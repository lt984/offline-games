import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_arcade/data/save_store.dart';
import 'package:pocket_arcade/games/air_hockey/air_hockey_screen.dart';
import 'package:pocket_arcade/games/air_hockey/hockey_table.dart';
import 'package:pocket_arcade/games/boba_sort/boba_sort_logic.dart';
import 'package:pocket_arcade/games/game_catalog.dart';
import 'package:pocket_arcade/games/pancake_merge/merge_physics.dart';
import 'package:pocket_arcade/games/pancake_merge/pancake_merge_screen.dart';
import 'package:pocket_arcade/main.dart';
import 'package:pocket_arcade/state/profile_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProfileController> pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final controller = ProfileController(await SaveStore.open(starterGameIds));
  await tester.pumpWidget(PocketArcadeApp(controller: controller));
  await tester.pumpAndSettle();
  return controller;
}

/// Pushes a game screen directly, so tests can inject a seeded world.
Future<void> pushGame(WidgetTester tester, Widget screen) async {
  final nav = tester.state<NavigatorState>(find.byType(Navigator));
  nav.push(MaterialPageRoute<void>(builder: (_) => screen));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('Boba Sort opens from the hub and pours on two taps', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('game-boba_sort')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Level 1'), findsOneWidget);

    final level = BobaSortPuzzle.forLevel(1);
    final empty = level.tubes.indexWhere((t) => t.isEmpty);
    await tester.tap(find.byKey(const ValueKey('tube-0')));
    await tester.pump();
    await tester.tap(find.byKey(ValueKey('tube-$empty')));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 moves'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('boba-undo')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('2 moves'),
      findsOneWidget,
      reason: 'undo counts as a move',
    );
  });

  testWidgets('Boba Sort resumes after the best cleared level', (tester) async {
    final controller = await pumpApp(tester);
    controller.submitScore('boba_sort', 4);
    await tester.pumpAndSettle();
    expect(
      find.text('Level 4'),
      findsOneWidget,
      reason: 'hub card shows best level',
    );
    await tester.tap(find.byKey(const ValueKey('game-boba_sort')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Level 5'), findsOneWidget);
  });

  testWidgets('Pancake Merge drops on tap and ends with a payout', (
    tester,
  ) async {
    final controller = await pumpApp(tester);
    final world = MergeWorld(random: Random(1));
    await pushGame(
      tester,
      PancakeMergeScreen(game: gameById('pancake_merge')!, world: world),
    );

    await tester.tap(find.byKey(const ValueKey('merge-jar')));
    await tester.pump(const Duration(milliseconds: 16));
    expect(world.bodies, hasLength(1));

    // Force an overflow and let the game notice.
    world.gameOver = true;
    world.score = 400;
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('Jar overflowed!'), findsOneWidget);
    expect(controller.tokens, 10);
    expect(controller.highScore('pancake_merge'), 400);

    await tester.tap(find.byKey(const ValueKey('round-primary')));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('Jar overflowed!'), findsNothing);
  });

  testWidgets('Air Hockey paddles follow each player\'s finger', (
    tester,
  ) async {
    await pumpApp(tester);
    final table = HockeyTable();
    await pushGame(
      tester,
      AirHockeyScreen(game: gameById('air_hockey')!, table: table),
    );

    final rect = tester.getRect(find.byKey(const ValueKey('hockey-table')));
    final p1 = await tester.startGesture(
      rect.bottomLeft + const Offset(40, -60),
      pointer: 1,
    );
    final p2 = await tester.startGesture(
      rect.topRight + const Offset(-40, 60),
      pointer: 2,
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(table.paddleOne.x, lessThan(30));
    expect(table.paddleOne.y, greaterThan(HockeyTable.height / 2));
    expect(table.paddleTwo.x, greaterThan(70));
    expect(table.paddleTwo.y, lessThan(HockeyTable.height / 2));
    await p1.up();
    await p2.up();
  });

  testWidgets('Air Hockey match end pays tokens once and offers a rematch', (
    tester,
  ) async {
    final controller = await pumpApp(tester);
    final table = HockeyTable()..scoreOne = HockeyTable.winningScore - 1;
    await pushGame(
      tester,
      AirHockeyScreen(game: gameById('air_hockey')!, table: table),
    );

    // Wait out the serve, then send the puck into player 2's goal.
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    table.paddleTwo.x = 90; // keep the goalie out of the way
    table.puck
      ..x = 50
      ..y = 30
      ..vx = 0
      ..vy = -200;
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text('Player 1 wins!'), findsOneWidget);
    expect(controller.tokens, AirHockeyScreen.matchReward);

    await tester.tap(find.byKey(const ValueKey('round-primary')));
    await tester.pump(const Duration(milliseconds: 16));
    expect(table.scoreOne, 0);
    expect(
      context(tester).read<ProfileController>().tokens,
      AirHockeyScreen.matchReward,
    );
  });
}

BuildContext context(WidgetTester tester) =>
    tester.element(find.byType(AirHockeyScreen));
