import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../games/game_catalog.dart';
import '../screens/game_screen.dart';
import '../state/profile_controller.dart';
import '../theme/arcade_skin.dart';
import 'arcade_background.dart';

class GameCard extends StatelessWidget {
  const GameCard({super.key, required this.game});

  final GameInfo game;

  @override
  Widget build(BuildContext context) {
    final skin = ArcadeSkin.of(context);
    final unlocked = context.select<ProfileController, bool>(
      (p) => p.isUnlocked(game.id),
    );
    final best = context.select<ProfileController, int?>(
      (p) => p.highScore(game.id),
    );

    return GestureDetector(
      key: ValueKey('game-${game.id}'),
      onTap: () {
        final profile = context.read<ProfileController>();
        if (profile.hapticsOn) skin.tapHaptic();
        if (unlocked) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => GameScreen(game: game)),
          );
        } else {
          showUnlockSheet(context, game);
        }
      },
      child: SkinPanel(
        highlight: unlocked,
        padding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Opacity(
              opacity: unlocked ? 1 : 0.45,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(game.icon, style: const TextStyle(fontSize: 34)),
                  const Spacer(),
                  Text(
                    game.titleFor(skin.id),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: skin.text,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    best != null
                        ? 'Best $best'
                        : (game.players == 2 ? '2 players' : 'Solo'),
                    style: TextStyle(fontSize: 11, color: skin.mutedText),
                  ),
                ],
              ),
            ),
            if (!unlocked)
              Positioned(
                top: 0,
                right: 0,
                child: _CostChip(cost: game.unlockCost),
              ),
            if (unlocked && game.players == 2)
              Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  Icons.people_alt_rounded,
                  size: 18,
                  color: skin.accent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CostChip extends StatelessWidget {
  const _CostChip({required this.cost});

  final int cost;

  @override
  Widget build(BuildContext context) {
    final skin = ArcadeSkin.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: skin.accent,
        borderRadius: BorderRadius.circular(skin.cornerRadius == 0 ? 0 : 10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock, size: 12, color: Colors.black87),
          const SizedBox(width: 2),
          Text(
            '$cost',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showUnlockSheet(
  BuildContext context,
  GameInfo game,
) => showModalBottomSheet<void>(
  context: context,
  builder: (context) {
    final skin = ArcadeSkin.of(context);
    final profile = context.watch<ProfileController>();
    final affordable = profile.tokens >= game.unlockCost;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(game.icon, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              game.titleFor(skin.id),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              game.blurb,
              textAlign: TextAlign.center,
              style: TextStyle(color: skin.mutedText),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('unlock-button'),
                onPressed: affordable
                    ? () {
                        if (profile.unlockGame(game)) {
                          if (profile.hapticsOn) skin.impactHaptic();
                          Navigator.of(context).pop();
                        }
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    affordable
                        ? 'Unlock for ${game.unlockCost} ${skin.tokenIcon}'
                        : 'Need ${game.unlockCost - profile.tokens} more ${skin.tokenIcon}',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  },
);
