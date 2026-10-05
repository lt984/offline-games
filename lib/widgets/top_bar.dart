import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../games/game_catalog.dart';
import '../state/profile_controller.dart';
import '../theme/arcade_skin.dart';
import '../theme/skins.dart';
import 'arcade_background.dart';

/// Hub header: title, token balance, theme toggle and offline progress bar.
class HubTopBar extends StatelessWidget {
  const HubTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final skin = ArcadeSkin.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pocket Arcade',
                      style: text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'World Tour',
                      style: text.labelLarge?.copyWith(color: skin.mutedText),
                    ),
                  ],
                ),
              ),
              const TokenBadge(),
              const SizedBox(width: 8),
              const ThemeToggleButton(),
            ],
          ),
          const SizedBox(height: 12),
          const OfflineProgressBar(),
        ],
      ),
    );
  }
}

class TokenBadge extends StatelessWidget {
  const TokenBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final skin = ArcadeSkin.of(context);
    final tokens = context.select<ProfileController, int>((p) => p.tokens);
    return SkinPanel(
      key: const ValueKey('token-badge'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      highlight: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(skin.tokenIcon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Text(
              '$tokens',
              key: ValueKey(tokens),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: skin.text,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tap: switch to the next skin instantly. Long press: open the skin picker.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final skin = ArcadeSkin.of(context);
    final profile = context.read<ProfileController>();
    return Tooltip(
      message: 'Switch theme (hold for all themes)',
      child: GestureDetector(
        onLongPress: () => showSkinPicker(context),
        child: Material(
          color: skin.primary,
          borderRadius: skin.radius,
          child: InkWell(
            key: const ValueKey('theme-toggle'),
            borderRadius: skin.radius,
            onTap: () {
              if (profile.hapticsOn) skin.tapHaptic();
              profile.cycleSkin();
            },
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(skin.skinIcon, style: const TextStyle(fontSize: 20)),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showSkinPicker(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  builder: (context) {
    final profile = context.watch<ProfileController>();
    final current = ArcadeSkin.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Themes', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final s in allSkins)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SkinOption(skin: s, selected: s.id == current.id),
              ),
            SwitchListTile(
              title: const Text('Vibration'),
              value: profile.hapticsOn,
              onChanged: profile.setHaptics,
            ),
          ],
        ),
      ),
    );
  },
);

class _SkinOption extends StatelessWidget {
  const _SkinOption({required this.skin, required this.selected});

  final ArcadeSkin skin;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    // Each option previews its own colors, not the active skin's.
    return Material(
      color: skin.surface,
      shape: RoundedRectangleBorder(
        borderRadius: skin.radius,
        side: BorderSide(
          color: selected ? skin.primary : Colors.transparent,
          width: 3,
        ),
      ),
      child: InkWell(
        borderRadius: skin.radius,
        onTap: () => context.read<ProfileController>().selectSkin(skin.id),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [skin.primary, skin.accent]),
                  borderRadius: skin.radius,
                ),
                child: Text(
                  skin.skinIcon,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skin.name,
                      style: TextStyle(
                        color: skin.text,
                        fontWeight: FontWeight.w700,
                        fontFamily: skin.fontFamily,
                      ),
                    ),
                    Text(
                      skin.tagline,
                      style: TextStyle(color: skin.mutedText, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (selected) Icon(Icons.check_circle, color: skin.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class OfflineProgressBar extends StatelessWidget {
  const OfflineProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    final skin = ArcadeSkin.of(context);
    final progress = context.select<ProfileController, double>(
      (p) => p.collectionProgress,
    );
    final unlocked = (progress * gameCatalog.length).round();
    return Row(
      children: [
        Icon(Icons.airplanemode_active, size: 16, color: skin.accent),
        const SizedBox(width: 4),
        Text(
          'Offline ready',
          style: TextStyle(color: skin.mutedText, fontSize: 12),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(skin.cornerRadius == 0 ? 0 : 8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: skin.primary,
              backgroundColor: skin.primary.withValues(alpha: 0.15),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$unlocked/${gameCatalog.length} games',
          style: TextStyle(
            color: skin.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
