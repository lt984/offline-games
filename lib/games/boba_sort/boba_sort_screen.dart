import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/profile_controller.dart';
import '../../theme/arcade_skin.dart';
import '../../widgets/arcade_background.dart';
import '../game_catalog.dart';
import '../game_kit.dart';
import 'boba_sort_logic.dart';

/// Liquid colors per skin, one per puzzle color.
const _palettes = <SkinId, List<Color>>{
  SkinId.cozyKitty: [
    Color(0xFFF48FB1),
    Color(0xFF90CAF9),
    Color(0xFFA5D6A7),
    Color(0xFFFFE082),
    Color(0xFFCE93D8),
    Color(0xFFFFAB91),
    Color(0xFF80DEEA),
    Color(0xFF8D6E63),
    Color(0xFFB0BEC5),
  ],
  SkinId.cyberNeon: [
    Color(0xFF00F0FF),
    Color(0xFFFF2BD6),
    Color(0xFF39FF14),
    Color(0xFFFFF01F),
    Color(0xFF8A2BE2),
    Color(0xFFFF6B00),
    Color(0xFF0066FF),
    Color(0xFFFF0040),
    Color(0xFFFFFFFF),
  ],
  SkinId.pixelDungeon: [
    Color(0xFFD83C3C),
    Color(0xFF3C7ED8),
    Color(0xFF5CB83C),
    Color(0xFFE8B53A),
    Color(0xFF9B4CC8),
    Color(0xFFE07A2E),
    Color(0xFF3CC8C0),
    Color(0xFF8B5A2B),
    Color(0xFFD8D8D8),
  ],
};

class BobaSortScreen extends StatefulWidget {
  const BobaSortScreen({super.key, required this.game});

  final GameInfo game;

  @override
  State<BobaSortScreen> createState() => _BobaSortScreenState();
}

class _BobaSortScreenState extends State<BobaSortScreen> {
  late int _level;
  late BobaSortPuzzle _puzzle;
  int? _selected;
  int? _reward;

  @override
  void initState() {
    super.initState();
    // Best score is the highest level cleared, so resume at the next one.
    _startLevel(
      (context.read<ProfileController>().highScore(widget.game.id) ?? 0) + 1,
    );
  }

  void _startLevel(int level) {
    _level = level;
    _puzzle = BobaSortPuzzle.forLevel(level);
    _selected = null;
    _reward = null;
  }

  void _tapTube(int i) {
    if (_reward != null) return;
    setState(() {
      final from = _selected;
      if (from == null) {
        if (_puzzle.tubes[i].isNotEmpty) {
          _selected = i;
          tapFeedback(context);
        }
        return;
      }
      _selected = null;
      if (from == i) return;
      if (_puzzle.pour(from, i)) {
        tapFeedback(context);
        if (_puzzle.isSolved) {
          _reward = 5 + _level;
          finishRound(context, widget.game, score: _level, tokens: _reward!);
        }
      } else if (_puzzle.tubes[i].isNotEmpty) {
        // An invalid pour onto a non-empty tube selects that tube instead.
        _selected = i;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final skin = ArcadeSkin.of(context);
    final palette = _palettes[skin.id]!;
    final tubes = _puzzle.tubes;
    return Scaffold(
      body: ArcadeBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  GameHeader(
                    title: widget.game.titleFor(skin.id),
                    subtitle: 'Level $_level · ${_puzzle.moves} moves',
                    actions: [
                      IconButton(
                        key: const ValueKey('boba-undo'),
                        tooltip: 'Undo',
                        color: skin.text,
                        onPressed: _puzzle.canUndo && _reward == null
                            ? () => setState(() {
                                _puzzle.undo();
                                _selected = null;
                              })
                            : null,
                        icon: const Icon(Icons.undo_rounded),
                      ),
                      IconButton(
                        tooltip: 'Restart level',
                        color: skin.text,
                        onPressed: () => setState(() => _startLevel(_level)),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Tap a tube, then tap where to pour. No timer, unlimited undos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: skin.mutedText, fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 14,
                          runSpacing: 28,
                          children: [
                            for (var i = 0; i < tubes.length; i++)
                              _Tube(
                                key: ValueKey('tube-$i'),
                                layers: tubes[i],
                                capacity: _puzzle.capacity,
                                palette: palette,
                                selected: _selected == i,
                                onTap: () => _tapTube(i),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_reward != null)
                RoundOverCard(
                  title: 'Level $_level cleared!',
                  lines: [
                    '${_puzzle.moves} moves',
                    '+$_reward ${skin.tokenIcon}',
                  ],
                  primaryLabel: 'Next level',
                  onPrimary: () => setState(() => _startLevel(_level + 1)),
                  secondaryLabel: 'Back to arcade',
                  onSecondary: () => Navigator.of(context).pop(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tube extends StatelessWidget {
  const _Tube({
    super.key,
    required this.layers,
    required this.capacity,
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final List<int> layers;
  final int capacity;
  final List<Color> palette;
  final bool selected;
  final VoidCallback onTap;

  static const _layerHeight = 30.0;
  static const _width = 46.0;

  @override
  Widget build(BuildContext context) {
    final skin = ArcadeSkin.of(context);
    final round = skin.cornerRadius == 0 ? 0.0 : _width / 2;
    final complete =
        layers.length == capacity && layers.every((c) => c == layers.first);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 150),
        offset: Offset(0, selected ? -0.12 : 0),
        child: Container(
          width: _width,
          height:
              _layerHeight * capacity + 20, // padding plus the thickest border
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
          decoration: BoxDecoration(
            color: skin.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(round),
              top: const Radius.circular(4),
            ),
            border: Border.all(
              color: selected || complete
                  ? skin.primary
                  : skin.mutedText.withValues(alpha: 0.6),
              width: selected ? 3 : 2,
            ),
            boxShadow: selected ? skin.glowShadow : const [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(round)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (final c in layers.reversed)
                  Container(
                    height: _layerHeight - 2,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: palette[c],
                      borderRadius: BorderRadius.circular(
                        skin.cornerRadius == 0 ? 0 : 8,
                      ),
                      boxShadow: skin.glow > 0
                          ? [
                              BoxShadow(
                                color: palette[c].withValues(alpha: 0.7),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                    child: skin.id == SkinId.cozyKitty ? const _Pearls() : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Little tapioca pearls drawn on the Cozy Kitty layers.
class _Pearls extends StatelessWidget {
  const _Pearls();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      for (var i = 0; i < 3; i++)
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
        ),
    ],
  );
}
