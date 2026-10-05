import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_arcade/data/save_store.dart';
import 'package:pocket_arcade/games/game_catalog.dart';
import 'package:pocket_arcade/main.dart';
import 'package:pocket_arcade/state/profile_controller.dart';
import 'package:pocket_arcade/theme/arcade_skin.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProfileController> pumpHub(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final controller = ProfileController(await SaveStore.open(starterGameIds));
  await tester.pumpWidget(PocketArcadeApp(controller: controller));
  await tester.pumpAndSettle();
  return controller;
}

ArcadeSkin activeSkin(WidgetTester tester) =>
    ArcadeSkin.of(tester.element(find.byKey(const ValueKey('token-badge'))));

void main() {
  testWidgets('hub shows header, tabs and the first category', (tester) async {
    await pumpHub(tester);
    expect(find.text('Pocket Arcade'), findsOneWidget);
    for (final c in GameCategory.values) {
      expect(find.byKey(ValueKey('tab-${c.name}')), findsOneWidget);
    }
    expect(find.text('Boba Sort'), findsOneWidget);
    expect(find.text('5/20 games'), findsOneWidget);
  });

  testWidgets('tapping a category tab moves the carousel', (tester) async {
    await pumpHub(tester);
    await tester.tap(find.byKey(const ValueKey('tab-versus')));
    await tester.pumpAndSettle();
    expect(find.text('Cat Cake Hockey'), findsOneWidget);
  });

  testWidgets('theme toggle switches the whole app skin in one tap', (
    tester,
  ) async {
    final controller = await pumpHub(tester);
    expect(activeSkin(tester).id, SkinId.cozyKitty);

    await tester.tap(find.byKey(const ValueKey('theme-toggle')));
    await tester.pumpAndSettle();
    expect(controller.skin.id, SkinId.cyberNeon);
    expect(activeSkin(tester).id, SkinId.cyberNeon);
    expect(
      find.text('Plasma Sort'),
      findsOneWidget,
      reason: 'game titles re-theme too',
    );
  });

  testWidgets('earning tokens then unlocking a game updates the hub', (
    tester,
  ) async {
    final controller = await pumpHub(tester);

    await tester.tap(find.byKey(const ValueKey('game-boba_sort')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('demo-reward')));
    await tester.tap(find.byKey(const ValueKey('demo-reward')));
    await tester.pump();
    expect(controller.tokens, 50);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('game-memory_flip')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('unlock-button')));
    await tester.pumpAndSettle();
    expect(controller.isUnlocked('memory_flip'), isTrue);
    expect(controller.tokens, 0);
    expect(find.text('6/20 games'), findsOneWidget);
  });
}
