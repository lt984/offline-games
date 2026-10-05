import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_arcade/data/player_profile.dart';
import 'package:pocket_arcade/data/save_store.dart';
import 'package:pocket_arcade/games/game_catalog.dart';
import 'package:pocket_arcade/state/profile_controller.dart';
import 'package:pocket_arcade/theme/arcade_skin.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProfileController> freshController([
  Map<String, Object> prefs = const {},
]) async {
  SharedPreferences.setMockInitialValues(prefs);
  return ProfileController(await SaveStore.open(starterGameIds));
}

void main() {
  test('catalog has 20 games split 6/5/5/4 with 5 starters', () {
    expect(gameCatalog, hasLength(20));
    expect(gamesIn(GameCategory.brain), hasLength(6));
    expect(gamesIn(GameCategory.skill), hasLength(5));
    expect(gamesIn(GameCategory.action), hasLength(5));
    expect(gamesIn(GameCategory.versus), hasLength(4));
    expect(starterGameIds, hasLength(5));
    expect(
      gameCatalog.map((g) => g.id).toSet(),
      hasLength(20),
      reason: 'ids are unique',
    );
    for (final g in gameCatalog.where((g) => !g.starter)) {
      expect(g.unlockCost, greaterThan(0), reason: '${g.id} needs a price');
    }
  });

  test('a new player starts with starters unlocked and zero tokens', () async {
    final c = await freshController();
    expect(c.tokens, 0);
    expect(c.skin.id, SkinId.cozyKitty);
    expect(c.isUnlocked('pancake_merge'), isTrue);
    expect(c.isUnlocked('memory_flip'), isFalse);
    expect(c.collectionProgress, closeTo(5 / 20, 1e-9));
  });

  test('tokens, unlocks, skin and scores survive a restart', () async {
    final c = await freshController();
    c.addTokens(120);
    expect(c.unlockGame(gameById('memory_flip')!), isTrue);
    c.cycleSkin();
    c.submitScore('boba_sort', 42);
    await Future<void>.delayed(Duration.zero);

    final reopened = ProfileController(await SaveStore.open(starterGameIds));
    expect(reopened.tokens, 70);
    expect(reopened.isUnlocked('memory_flip'), isTrue);
    expect(reopened.skin.id, SkinId.cyberNeon);
    expect(reopened.highScore('boba_sort'), 42);
  });

  test('spending more than the balance is refused', () async {
    final c = await freshController();
    c.addTokens(10);
    expect(c.spendTokens(11), isFalse);
    expect(c.unlockGame(gameById('tile_match')!), isFalse);
    expect(c.tokens, 10);
    expect(c.spendTokens(10), isTrue);
    expect(c.tokens, 0);
  });

  test('theme toggle cycles through all three skins', () async {
    final c = await freshController();
    final seen = <SkinId>[];
    for (var i = 0; i < 3; i++) {
      c.cycleSkin();
      seen.add(c.skin.id);
    }
    expect(seen, [SkinId.cyberNeon, SkinId.pixelDungeon, SkinId.cozyKitty]);
  });

  test('only higher scores replace a personal best', () async {
    final c = await freshController();
    expect(c.submitScore('air_hockey', 5), isTrue);
    expect(c.submitScore('air_hockey', 3), isFalse);
    expect(c.highScore('air_hockey'), 5);
  });

  test('a corrupt save falls back to a fresh profile', () async {
    final c = await freshController({'pocket_arcade.profile': '{not json'});
    expect(c.tokens, 0);
    expect(c.isUnlocked('boba_sort'), isTrue);
  });

  test('a partial or hostile save is repaired field by field', () {
    final p = PlayerProfile.fromJson(
      jsonDecode(
        '{"tokens": -5, "skin": "nope", "unlockedGames": ["stack_tower", 7]}',
      ) as Map<String, Object?>,
      starterGameIds,
    );
    expect(p.tokens, 0);
    expect(p.skin, SkinId.cozyKitty);
    expect(p.unlockedGames, containsAll([...starterGameIds, 'stack_tower']));
    expect(p.hapticsOn, isTrue);
  });
}
