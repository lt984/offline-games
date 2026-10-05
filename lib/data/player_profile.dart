import '../theme/arcade_skin.dart';

/// Everything the player has earned, saved locally as one JSON document.
class PlayerProfile {
  const PlayerProfile({
    required this.tokens,
    required this.skin,
    required this.ownedSkins,
    required this.unlockedGames,
    required this.highScores,
    required this.hapticsOn,
  });

  /// Bump when the JSON shape changes and add a migration in [fromJson].
  static const schemaVersion = 1;

  factory PlayerProfile.fresh(Set<String> starterGames) => PlayerProfile(
    tokens: 0,
    skin: SkinId.cozyKitty,
    // The three launch skins are free; later skins are bought with tokens.
    ownedSkins: SkinId.values.toSet(),
    unlockedGames: starterGames,
    highScores: const {},
    hapticsOn: true,
  );

  final int tokens;
  final SkinId skin;
  final Set<SkinId> ownedSkins;
  final Set<String> unlockedGames;
  final Map<String, int> highScores;
  final bool hapticsOn;

  PlayerProfile copyWith({
    int? tokens,
    SkinId? skin,
    Set<SkinId>? ownedSkins,
    Set<String>? unlockedGames,
    Map<String, int>? highScores,
    bool? hapticsOn,
  }) => PlayerProfile(
    tokens: tokens ?? this.tokens,
    skin: skin ?? this.skin,
    ownedSkins: ownedSkins ?? this.ownedSkins,
    unlockedGames: unlockedGames ?? this.unlockedGames,
    highScores: highScores ?? this.highScores,
    hapticsOn: hapticsOn ?? this.hapticsOn,
  );

  Map<String, Object?> toJson() => {
    'v': schemaVersion,
    'tokens': tokens,
    'skin': skin.key,
    'ownedSkins': [for (final s in ownedSkins) s.key],
    'unlockedGames': unlockedGames.toList()..sort(),
    'highScores': highScores,
    'hapticsOn': hapticsOn,
  };

  /// Reads a saved profile. Missing or malformed fields fall back to the fresh
  /// defaults so a damaged save never blocks the app from starting. Starter
  /// games are always merged in, so games added as starters in an update
  /// appear for existing players too.
  factory PlayerProfile.fromJson(
    Map<String, Object?> json,
    Set<String> starterGames,
  ) {
    final fresh = PlayerProfile.fresh(starterGames);
    final owned = (json['ownedSkins'] as List?)
        ?.whereType<String>()
        .map(SkinId.fromKey)
        .toSet();
    final unlocked = (json['unlockedGames'] as List?)
        ?.whereType<String>()
        .toSet();
    final scores = (json['highScores'] as Map?)?.map(
      (k, v) => MapEntry('$k', v is num ? v.toInt() : 0),
    );
    final tokens = json['tokens'];
    return PlayerProfile(
      tokens: tokens is num && tokens >= 0 ? tokens.toInt() : fresh.tokens,
      skin: SkinId.fromKey(json['skin'] as String?),
      ownedSkins: {...fresh.ownedSkins, ...?owned},
      unlockedGames: {...starterGames, ...?unlocked},
      highScores: scores ?? fresh.highScores,
      hapticsOn: json['hapticsOn'] is bool
          ? json['hapticsOn'] as bool
          : fresh.hapticsOn,
    );
  }
}
