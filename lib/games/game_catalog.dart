import '../theme/arcade_skin.dart';

enum GameCategory {
  brain('Brain & Puzzle', 'Brain', '🧠'),
  skill('Skill & Physics', 'Skill', '🎯'),
  action('Action & Reflex', 'Action', '⚡'),
  versus('2-Player Local', '2-Player', '⚔️');

  const GameCategory(this.label, this.shortLabel, this.icon);
  final String label;

  /// Fits the hub's tab strip on the narrowest phones.
  final String shortLabel;
  final String icon;
}

/// One mini-game slot in the hub. `id` is saved to disk, so never change it.
class GameInfo {
  const GameInfo({
    required this.id,
    required this.title,
    required this.category,
    required this.icon,
    required this.blurb,
    this.players = 1,
    this.starter = false,
    this.unlockCost = 0,
    this.skinTitles = const {},
    this.bestLabel = 'Best',
  });

  final String id;
  final String title;
  final GameCategory category;
  final String icon;
  final String blurb;
  final int players;

  /// Starter games are playable from the first launch.
  final bool starter;

  /// Arcade Tokens needed to unlock a non-starter game.
  final int unlockCost;

  /// Some games re-theme their name per skin (Pancake Merge becomes Planet
  /// Merge in Cyberpunk Neon).
  final Map<SkinId, String> skinTitles;

  /// Prefix for the personal best on the hub card.
  final String bestLabel;

  String titleFor(SkinId skin) => skinTitles[skin] ?? title;
}

/// The full 20-game lineup. Five starters are free; the other 15 unlock with
/// tokens. Only the three spotlight games have designed rules so far; the
/// rest are placeholders for the content roadmap.
const gameCatalog = <GameInfo>[
  // Brain & Puzzle (6)
  GameInfo(
    id: 'boba_sort',
    title: 'Boba Sort',
    category: GameCategory.brain,
    icon: '🧋',
    blurb: 'Pour colors between tubes until every tube is one color.',
    starter: true,
    bestLabel: 'Level',
    skinTitles: {
      SkinId.pixelDungeon: 'Potion Sort',
      SkinId.cyberNeon: 'Plasma Sort',
    },
  ),
  GameInfo(
    id: 'memory_flip',
    title: 'Memory Flip',
    category: GameCategory.brain,
    icon: '🃏',
    blurb: 'Flip cards and find every pair.',
    unlockCost: 50,
  ),
  GameInfo(
    id: 'number_slide',
    title: 'Number Slide',
    category: GameCategory.brain,
    icon: '🔢',
    blurb: 'Slide and merge tiles to reach the big number.',
    unlockCost: 75,
  ),
  GameInfo(
    id: 'pipe_connect',
    title: 'Pipe Connect',
    category: GameCategory.brain,
    icon: '🧩',
    blurb: 'Rotate pipes to link the flow.',
    unlockCost: 100,
  ),
  GameInfo(
    id: 'word_hunt',
    title: 'Word Hunt',
    category: GameCategory.brain,
    icon: '🔤',
    blurb: 'Find hidden words in a letter grid.',
    unlockCost: 125,
  ),
  GameInfo(
    id: 'tile_match',
    title: 'Tile Match',
    category: GameCategory.brain,
    icon: '🀄',
    blurb: 'Clear the board three tiles at a time.',
    unlockCost: 150,
  ),

  // Skill & Physics (5)
  GameInfo(
    id: 'pancake_merge',
    title: 'Pancake Merge',
    category: GameCategory.skill,
    icon: '🥞',
    blurb: 'Drop and merge matching items without overflowing the line.',
    starter: true,
    skinTitles: {
      SkinId.cyberNeon: 'Planet Merge',
      SkinId.pixelDungeon: 'Slime Merge',
    },
  ),
  GameInfo(
    id: 'stack_tower',
    title: 'Stack Tower',
    category: GameCategory.skill,
    icon: '🏗️',
    blurb: 'Stack sliding blocks as high as you can.',
    unlockCost: 50,
  ),
  GameInfo(
    id: 'bounce_shot',
    title: 'Bounce Shot',
    category: GameCategory.skill,
    icon: '🏀',
    blurb: 'Bank shots off the walls into the target.',
    unlockCost: 75,
  ),
  GameInfo(
    id: 'mini_golf',
    title: 'Mini Golf',
    category: GameCategory.skill,
    icon: '⛳',
    blurb: 'Flick to putt through tiny courses.',
    unlockCost: 100,
  ),
  GameInfo(
    id: 'rope_cut',
    title: 'Rope Cut',
    category: GameCategory.skill,
    icon: '✂️',
    blurb: 'Cut ropes to swing the treat home.',
    unlockCost: 125,
  ),

  // Action & Reflex (5)
  GameInfo(
    id: 'dodge_storm',
    title: 'Dodge Storm',
    category: GameCategory.action,
    icon: '🌧️',
    blurb: 'Weave through falling hazards.',
    starter: true,
  ),
  GameInfo(
    id: 'dash_runner',
    title: 'Dash Runner',
    category: GameCategory.action,
    icon: '🏃',
    blurb: 'Jump and slide through an endless run.',
    unlockCost: 50,
  ),
  GameInfo(
    id: 'tap_rhythm',
    title: 'Tap Rhythm',
    category: GameCategory.action,
    icon: '🥁',
    blurb: 'Tap to the beat.',
    unlockCost: 75,
  ),
  GameInfo(
    id: 'whack_pop',
    title: 'Whack Pop',
    category: GameCategory.action,
    icon: '🔨',
    blurb: 'Bop whatever pops up, fast.',
    unlockCost: 100,
  ),
  GameInfo(
    id: 'snake_trail',
    title: 'Snake Trail',
    category: GameCategory.action,
    icon: '🐍',
    blurb: 'Grow your trail without biting it.',
    unlockCost: 125,
  ),

  // 2-Player Local (4)
  GameInfo(
    id: 'air_hockey',
    title: 'Neon Air Hockey',
    category: GameCategory.versus,
    icon: '🏒',
    blurb: 'First to 5 goals wins. Face each other across one screen.',
    players: 2,
    starter: true,
    skinTitles: {
      SkinId.cozyKitty: 'Cat Cake Hockey',
      SkinId.pixelDungeon: 'Shield Hockey',
    },
  ),
  GameInfo(
    id: 'tap_duel',
    title: 'Tap Duel',
    category: GameCategory.versus,
    icon: '🤠',
    blurb: 'Wait for the signal, then tap first.',
    players: 2,
    starter: true,
  ),
  GameInfo(
    id: 'tug_of_war',
    title: 'Tug of War',
    category: GameCategory.versus,
    icon: '🪢',
    blurb: 'Out-tap your rival to pull the rope.',
    players: 2,
    unlockCost: 75,
  ),
  GameInfo(
    id: 'four_in_row',
    title: 'Four in a Row',
    category: GameCategory.versus,
    icon: '🔴',
    blurb: 'Drop pieces and connect four first.',
    players: 2,
    unlockCost: 100,
  ),
];

List<GameInfo> gamesIn(GameCategory category) =>
    gameCatalog.where((g) => g.category == category).toList();

GameInfo? gameById(String id) {
  for (final g in gameCatalog) {
    if (g.id == id) return g;
  }
  return null;
}

Set<String> get starterGameIds => {
  for (final g in gameCatalog)
    if (g.starter) g.id,
};
