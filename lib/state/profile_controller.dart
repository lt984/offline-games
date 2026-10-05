import 'package:flutter/foundation.dart';

import '../data/player_profile.dart';
import '../data/save_store.dart';
import '../games/game_catalog.dart';
import '../theme/arcade_skin.dart';
import '../theme/skins.dart';

/// Single source of truth for tokens, skin and unlocks. Every change is
/// written to the local save immediately.
class ProfileController extends ChangeNotifier {
  ProfileController(this._store) : _profile = _store.load();

  final SaveStore _store;
  PlayerProfile _profile;

  PlayerProfile get profile => _profile;
  int get tokens => _profile.tokens;
  ArcadeSkin get skin => skinFor(_profile.skin);
  bool get hapticsOn => _profile.hapticsOn;

  bool isUnlocked(String gameId) => _profile.unlockedGames.contains(gameId);

  /// Share of the 20 games the player has unlocked, for the progress bar.
  double get collectionProgress =>
      _profile.unlockedGames.where((id) => gameById(id) != null).length /
      gameCatalog.length;

  int? highScore(String gameId) => _profile.highScores[gameId];

  void selectSkin(SkinId id) {
    if (id == _profile.skin || !_profile.ownedSkins.contains(id)) return;
    _update(_profile.copyWith(skin: id));
  }

  /// One-tap skin switch: moves to the next owned skin in toggle order.
  void cycleSkin() {
    final owned = allSkins
        .where((s) => _profile.ownedSkins.contains(s.id))
        .toList();
    final i = owned.indexWhere((s) => s.id == _profile.skin);
    selectSkin(owned[(i + 1) % owned.length].id);
  }

  void setHaptics(bool on) => _update(_profile.copyWith(hapticsOn: on));

  void addTokens(int amount) {
    if (amount <= 0) return;
    _update(_profile.copyWith(tokens: _profile.tokens + amount));
  }

  /// Returns false and changes nothing if the balance is too low.
  bool spendTokens(int amount) {
    if (amount < 0 || amount > _profile.tokens) return false;
    _update(_profile.copyWith(tokens: _profile.tokens - amount));
    return true;
  }

  bool unlockGame(GameInfo game) {
    if (isUnlocked(game.id) || game.unlockCost > _profile.tokens) return false;
    _update(
      _profile.copyWith(
        tokens: _profile.tokens - game.unlockCost,
        unlockedGames: {..._profile.unlockedGames, game.id},
      ),
    );
    return true;
  }

  /// Records a score and returns true when it beats the previous best.
  bool submitScore(String gameId, int score) {
    final best = _profile.highScores[gameId];
    if (best != null && best >= score) return false;
    _update(
      _profile.copyWith(highScores: {..._profile.highScores, gameId: score}),
    );
    return true;
  }

  void _update(PlayerProfile next) {
    _profile = next;
    notifyListeners();
    _store.save(next);
  }
}
