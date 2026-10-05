import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../games/game_catalog.dart';
import '../state/profile_controller.dart';
import '../theme/arcade_skin.dart';
import '../widgets/arcade_background.dart';

/// Landing page for a mini-game. The games themselves plug in here as they
/// are built; until then this shows the rules and a temporary token reward so
/// the economy can be tried end to end.
class GameScreen extends StatelessWidget {
  const GameScreen({super.key, required this.game});

  final GameInfo game;

  /// Temporary stand-in for real end-of-round rewards.
  static const demoReward = 25;

  @override
  Widget build(BuildContext context) {
    final skin = ArcadeSkin.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: ArcadeBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: BackButton(color: skin.text),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(game.icon, style: const TextStyle(fontSize: 80)),
                      const SizedBox(height: 12),
                      Text(
                        game.titleFor(skin.id),
                        textAlign: TextAlign.center,
                        style: text.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${game.category.icon} ${game.category.label}',
                        style: TextStyle(color: skin.mutedText),
                      ),
                      const SizedBox(height: 16),
                      SkinPanel(
                        child: Text(
                          game.blurb,
                          textAlign: TextAlign.center,
                          style: text.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'This game is in the workshop.',
                        style: TextStyle(color: skin.mutedText),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: const ValueKey('demo-reward'),
                        onPressed: () {
                          final profile = context.read<ProfileController>();
                          profile.addTokens(demoReward);
                          if (profile.hapticsOn) skin.impactHaptic();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '+$demoReward ${skin.tokenIcon} (demo reward)',
                              ),
                            ),
                          );
                        },
                        icon: Text(skin.tokenIcon),
                        label: const Text('Claim demo tokens'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
