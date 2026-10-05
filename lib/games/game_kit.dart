import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/profile_controller.dart';
import '../theme/arcade_skin.dart';
import 'game_catalog.dart';

/// Records a finished round: pays out tokens and keeps the best score.
/// Returns true when [score] is a new personal best. Versus games pass no
/// score; match history belongs to the progression work.
bool finishRound(
  BuildContext context,
  GameInfo game, {
  int? score,
  required int tokens,
}) {
  final profile = context.read<ProfileController>();
  profile.addTokens(tokens);
  final best = score != null && profile.submitScore(game.id, score);
  if (profile.hapticsOn) ArcadeSkin.of(context).impactHaptic();
  return best;
}

/// Plays the skin's light haptic if the player has vibration on.
void tapFeedback(BuildContext context) {
  if (context.read<ProfileController>().hapticsOn) {
    ArcadeSkin.of(context).tapHaptic();
  }
}

/// Plays the skin's heavy haptic if the player has vibration on.
void impactFeedback(BuildContext context) {
  if (context.read<ProfileController>().hapticsOn) {
    ArcadeSkin.of(context).impactHaptic();
  }
}

/// Back button, title and optional actions across the top of a game.
class GameHeader extends StatelessWidget {
  const GameHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final skin = ArcadeSkin.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
      child: Row(
        children: [
          BackButton(color: skin.text),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(color: skin.mutedText, fontSize: 12),
                  ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// Round-over card shown on top of a game.
class RoundOverCard extends StatelessWidget {
  const RoundOverCard({
    super.key,
    required this.title,
    required this.lines,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.quarterTurns = 0,
  });

  final String title;
  final List<String> lines;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// Rotates the card, so a two-player result can face the other player.
  final int quarterTurns;

  @override
  Widget build(BuildContext context) {
    final skin = ArcadeSkin.of(context);
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: RotatedBox(
          quarterTurns: quarterTurns,
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: skin.surface,
              borderRadius: skin.radius,
              border: Border.all(color: skin.primary, width: 2),
              boxShadow: skin.glowShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                for (final l in lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      l,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: skin.text, fontSize: 16),
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const ValueKey('round-primary'),
                  onPressed: onPrimary,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Text(primaryLabel),
                  ),
                ),
                if (secondaryLabel != null)
                  TextButton(
                    onPressed: onSecondary,
                    child: Text(
                      secondaryLabel!,
                      style: TextStyle(color: skin.mutedText),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
