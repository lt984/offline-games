import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Stable ids for every visual skin. The string `key` is what gets saved, so
/// never rename an existing key.
enum SkinId {
  cozyKitty('cozy_kitty'),
  cyberNeon('cyber_neon'),
  pixelDungeon('pixel_dungeon');

  const SkinId(this.key);
  final String key;

  static SkinId fromKey(String? key) => SkinId.values.firstWhere(
    (s) => s.key == key,
    orElse: () => SkinId.cozyKitty,
  );
}

/// How strongly a skin vibrates on taps and impacts.
enum HapticStyle { soft, crisp, chunky }

/// Everything a skin changes: colors, shapes, fonts, icons, haptics and the
/// audio pack id. Registered as a [ThemeExtension] so any widget can read the
/// active skin with `ArcadeSkin.of(context)`.
@immutable
class ArcadeSkin extends ThemeExtension<ArcadeSkin> {
  const ArcadeSkin({
    required this.id,
    required this.name,
    required this.tagline,
    required this.brightness,
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.surface,
    required this.primary,
    required this.accent,
    required this.text,
    required this.mutedText,
    required this.cornerRadius,
    required this.glow,
    required this.fontFamily,
    required this.tokenIcon,
    required this.skinIcon,
    required this.hapticStyle,
    required this.audioPack,
  });

  final SkinId id;
  final String name;
  final String tagline;
  final Brightness brightness;
  final Color backgroundTop;
  final Color backgroundBottom;
  final Color surface;
  final Color primary;
  final Color accent;
  final Color text;
  final Color mutedText;
  final double cornerRadius;

  /// Neon-style outer glow on cards and buttons. Zero disables it.
  final double glow;

  /// Null uses the platform default font. Fonts are bundled or system fonts
  /// only, never downloaded, so the app stays fully offline.
  final String? fontFamily;
  final String tokenIcon;
  final String skinIcon;
  final HapticStyle hapticStyle;

  /// Id of the music and sound-effect pack. Audio assets arrive with the
  /// mini-games; the hub only records which pack a skin uses.
  final String audioPack;

  static ArcadeSkin of(BuildContext context) =>
      Theme.of(context).extension<ArcadeSkin>()!;

  BorderRadius get radius => BorderRadius.circular(cornerRadius);

  List<BoxShadow> get glowShadow => glow == 0
      ? const []
      : [BoxShadow(color: primary.withValues(alpha: 0.55), blurRadius: glow)];

  /// Fires the skin's haptic for a light UI tap.
  Future<void> tapHaptic() => switch (hapticStyle) {
    HapticStyle.soft => HapticFeedback.selectionClick(),
    HapticStyle.crisp => HapticFeedback.lightImpact(),
    HapticStyle.chunky => HapticFeedback.mediumImpact(),
  };

  /// Fires the skin's haptic for a big moment (goal, merge, unlock).
  Future<void> impactHaptic() => switch (hapticStyle) {
    HapticStyle.soft => HapticFeedback.lightImpact(),
    HapticStyle.crisp => HapticFeedback.heavyImpact(),
    HapticStyle.chunky => HapticFeedback.heavyImpact(),
  };

  ThemeData toThemeData() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      secondary: accent,
      surface: surface,
      onSurface: text,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: backgroundBottom,
    );
    return base.copyWith(
      extensions: [this],
      textTheme: base.textTheme.apply(bodyColor: text, displayColor: text),
      cardTheme: CardThemeData(
        color: surface,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(cornerRadius),
          ),
        ),
      ),
    );
  }

  @override
  ArcadeSkin copyWith() => this;

  /// Colors blend during the theme switch animation; everything else flips at
  /// the halfway point.
  @override
  ArcadeSkin lerp(ArcadeSkin? other, double t) {
    if (other == null) return this;
    final pick = t < 0.5 ? this : other;
    return ArcadeSkin(
      id: pick.id,
      name: pick.name,
      tagline: pick.tagline,
      brightness: pick.brightness,
      backgroundTop: Color.lerp(backgroundTop, other.backgroundTop, t)!,
      backgroundBottom: Color.lerp(
        backgroundBottom,
        other.backgroundBottom,
        t,
      )!,
      surface: Color.lerp(surface, other.surface, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      text: Color.lerp(text, other.text, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      cornerRadius: cornerRadius + (other.cornerRadius - cornerRadius) * t,
      glow: glow + (other.glow - glow) * t,
      fontFamily: pick.fontFamily,
      tokenIcon: pick.tokenIcon,
      skinIcon: pick.skinIcon,
      hapticStyle: pick.hapticStyle,
      audioPack: pick.audioPack,
    );
  }
}
