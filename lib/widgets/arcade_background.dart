import 'package:flutter/material.dart';

import '../theme/arcade_skin.dart';

/// Full-screen gradient backdrop in the active skin's colors.
class ArcadeBackground extends StatelessWidget {
  const ArcadeBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final skin = ArcadeSkin.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [skin.backgroundTop, skin.backgroundBottom],
        ),
      ),
      child: child,
    );
  }
}

/// Rounded (or square, for Pixel Dungeon) panel used for cards and badges.
class SkinPanel extends StatelessWidget {
  const SkinPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.highlight = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final skin = ArcadeSkin.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: skin.surface,
        borderRadius: skin.radius,
        border: Border.all(
          color: highlight
              ? skin.primary
              : skin.primary.withValues(alpha: 0.25),
          width: skin.id == SkinId.pixelDungeon ? 3 : 1.5,
        ),
        boxShadow: highlight ? skin.glowShadow : const [],
      ),
      child: child,
    );
  }
}
