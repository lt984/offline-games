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
- **Game screen** (`lib/screens/game_screen.dart`): placeholder page each
  mini-game will replace. It has a temporary "Claim demo tokens" button so the
  unlock flow can be tried before real rewards exist.

## Adding a mini-game

1. Build the game as a widget under `lib/games/<id>/`.
2. Route to it from `GameScreen` by `game.id`.
3. On a finished round call `ProfileController.submitScore` and `addTokens`.
4. Read colors, haptics and fonts from `ArcadeSkin.of(context)` so it re-skins
   for free.

## Fonts

VT323 (Pixel Dungeon) is under the SIL Open Font License; see
`assets/fonts/OFL-VT323.txt`.
