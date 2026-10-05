# Pocket Arcade: World Tour

Offline mini-game collection for phones and tablets, built with Flutter so one
codebase ships to iOS and Android. Everything runs with no network: saves are
local, and fonts are bundled.

## Run it

```sh
flutter pub get
flutter run            # on a connected phone or emulator
flutter test           # unit and widget tests
```

Built and tested with Flutter 3.47.6 (Dart 3.13).

## What's here (foundation and hub)

- **Hub screen** (`lib/screens/hub_screen.dart`): header with token balance,
  theme toggle and an offline progress bar, four category tabs, and a swipeable
  carousel with one page per category (6 / 5 / 5 / 4 games).
- **Skin engine** (`lib/theme/`): Cozy Kitty Bakery, Cyberpunk Neon and Pixel
  Dungeon. A skin sets colors, corner shape, glow, font, token icon, haptic
  strength and audio pack id. Tap the theme button to cycle; hold it for the
  picker and the vibration switch. Widgets read the active skin with
  `ArcadeSkin.of(context)`. Some games re-title per skin
  (Pancake Merge becomes Planet Merge in Neon).
- **Game catalog** (`lib/games/game_catalog.dart`): all 20 slots. Five
  starters are free (Boba Sort, Pancake Merge, Dodge Storm, Neon Air Hockey,
  Tap Duel); the other 15 unlock with tokens. Only the three spotlight games
  have designed rules; the rest are placeholder names for the content roadmap.
- **Local saves and tokens** (`lib/data/`, `lib/state/profile_controller.dart`):
  one versioned JSON profile in the platform preferences store holding tokens,
  skin, owned skins, unlocked games, personal bests and the haptics setting.
  Every change saves immediately. Damaged or partial saves are repaired field
  by field instead of crashing.
- **Game screen** (`lib/screens/game_screen.dart`): opens the playable
  games by id. Games not built yet show their rules and a temporary "Claim
  demo tokens" button so the unlock flow can be tried.

## Playable games

- **Boba Sort** (`lib/games/boba_sort/`): pour puzzle with endless levels.
  Starts at 3 colors and adds one every two levels, up to 9. Every level is
  generated from its number and checked solvable by a search before you see
  it. Unlimited undo, no timer. Pays 5 + level tokens; the hub shows your best
  level and the game resumes after it.
- **Pancake Merge** (`lib/games/pancake_merge/`): drop-and-merge jar with a
  fixed-step physics sim. Drag to aim, release to drop. Two of the same item
  merge into the next of nine tiers; two of the biggest pop for a jackpot.
  Anything over the dashed line for two seconds ends the run. Earn a bomb
  every 300 points and tap an item to blast it. Pays score / 40 tokens.
- **Neon Air Hockey** (`lib/games/air_hockey/`): two players, one phone laid
  flat. Each player drags the paddle on their half (multi-touch). Player 2's
  score strip is upside down so it reads from across the table. First to 5
  wins; the result card turns to face the winner. Pays 10 tokens a match.

Every game re-skins: liquid colors, merge items (sweets, planets, dungeon
loot), paddle shapes, glow and haptic strength all come from the active skin.

## Adding a mini-game

1. Put the rules in a plain Dart class under `lib/games/<id>/` so they can be
   unit tested, and the screen next to it.
2. Register the screen in `playableGames` in `lib/screens/game_screen.dart`.
3. On a finished round call `finishRound` from `lib/games/game_kit.dart`.
4. Read colors, haptics and fonts from `ArcadeSkin.of(context)` so it re-skins
   for free.

## Fonts

VT323 (Pixel Dungeon) is under the SIL Open Font License; see
`assets/fonts/OFL-VT323.txt`.
