import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'player_profile.dart';

/// Local-only persistence for the player profile. Nothing here touches the
/// network; saves live in the platform's app preferences store.
class SaveStore {
  SaveStore(this._prefs, this._starterGames);

  static const _key = 'pocket_arcade.profile';

  final SharedPreferences _prefs;
  final Set<String> _starterGames;

  static Future<SaveStore> open(Set<String> starterGames) async =>
      SaveStore(await SharedPreferences.getInstance(), starterGames);

  PlayerProfile load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return PlayerProfile.fresh(_starterGames);
    try {
      final json = jsonDecode(raw);
      if (json is Map<String, Object?>) {
        return PlayerProfile.fromJson(json, _starterGames);
      }
    } on FormatException {
      // Corrupt save: start fresh rather than crash.
    }
    return PlayerProfile.fresh(_starterGames);
  }

  Future<void> save(PlayerProfile profile) =>
      _prefs.setString(_key, jsonEncode(profile.toJson()));

  Future<void> reset() => _prefs.remove(_key);
}
