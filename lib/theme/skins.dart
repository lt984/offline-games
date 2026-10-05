import 'package:flutter/material.dart';

import 'arcade_skin.dart';

const cozyKittySkin = ArcadeSkin(
  id: SkinId.cozyKitty,
  name: 'Cozy Kitty Bakery',
  tagline: 'Relaxing, cozy, cute',
  brightness: Brightness.light,
  backgroundTop: Color(0xFFFFE4EC),
  backgroundBottom: Color(0xFFFFF6E8),
  surface: Color(0xFFFFFFFF),
  primary: Color(0xFFF27BA0),
  accent: Color(0xFFFFB86B),
  text: Color(0xFF5A3D4A),
  mutedText: Color(0xFF9C7F8B),
  cornerRadius: 24,
  glow: 0,
  fontFamily: null,
  tokenIcon: '🐟',
  skinIcon: '🐱',
  hapticStyle: HapticStyle.soft,
  audioPack: 'acoustic_purr',
);

const cyberNeonSkin = ArcadeSkin(
  id: SkinId.cyberNeon,
  name: 'Cyberpunk Neon',
  tagline: 'Cool, retro-futuristic, high-energy',
  brightness: Brightness.dark,
  backgroundTop: Color(0xFF0B0221),
  backgroundBottom: Color(0xFF1A0B3D),
  surface: Color(0xFF16112E),
  primary: Color(0xFF00F0FF),
  accent: Color(0xFFFF2BD6),
  text: Color(0xFFE8F9FF),
  mutedText: Color(0xFF8A86B5),
  cornerRadius: 6,
  glow: 14,
  fontFamily: null,
  tokenIcon: '💠',
  skinIcon: '🌃',
  hapticStyle: HapticStyle.crisp,
  audioPack: 'synthwave',
);

const pixelDungeonSkin = ArcadeSkin(
  id: SkinId.pixelDungeon,
  name: 'Pixel Dungeon',
  tagline: 'Adventurous, nostalgic, arcade-like',
  brightness: Brightness.dark,
  backgroundTop: Color(0xFF1E1A2E),
  backgroundBottom: Color(0xFF2E2433),
  surface: Color(0xFF3A2F45),
  primary: Color(0xFFE8B53A),
  accent: Color(0xFF6CC24A),
  text: Color(0xFFF4E9D0),
  mutedText: Color(0xFFB3A48A),
  cornerRadius: 0,
  glow: 0,
  fontFamily: 'VT323',
  tokenIcon: '🪙',
  skinIcon: '🗡️',
  hapticStyle: HapticStyle.chunky,
  audioPack: 'chiptune',
);

/// All skins in toggle order. The theme button cycles through this list.
const allSkins = [cozyKittySkin, cyberNeonSkin, pixelDungeonSkin];

ArcadeSkin skinFor(SkinId id) => allSkins.firstWhere((s) => s.id == id);
