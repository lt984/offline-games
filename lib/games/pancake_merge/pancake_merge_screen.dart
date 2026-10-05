import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../theme/arcade_skin.dart';
import '../../widgets/arcade_background.dart';
import '../game_catalog.dart';
import '../game_kit.dart';
import 'merge_physics.dart';

/// Look of each merge tier, smallest first, per skin.
const _tierLooks = <SkinId, List<(String, Color)>>{
  SkinId.cozyKitty: [
    ('🍬', Color(0xFFFFCDD2)),
    ('🍪', Color(0xFFFFE0B2)),
    ('🧁', Color(0xFFF8BBD0)),
    ('🍩', Color(0xFFFFCC80)),
    ('🧇', Color(0xFFFFE082)),
    ('🥞', Color(0xFFFFD54F)),
    ('🎂', Color(0xFFF48FB1)),
    ('🐱', Color(0xFFFFB74D)),
    ('😻', Color(0xFFF06292)),
  ],
  SkinId.cyberNeon: [
    ('✨', Color(0xFF3A3A6A)),
    ('🪨', Color(0xFF5A5A7A)),
    ('☄️', Color(0xFF7A4AA8)),
    ('🌑', Color(0xFF4A4A8A)),
    ('🌍', Color(0xFF1E6FD9)),
    ('🔴', Color(0xFFD94A2E)),
    ('🪐', Color(0xFFE0A050)),
    ('🌞', Color(0xFFFFC21A)),
    ('🌌', Color(0xFF8A2BE2)),
  ],
  SkinId.pixelDungeon: [
    ('🦠', Color(0xFF5CB83C)),
    ('💧', Color(0xFF3C7ED8)),
    ('🍄', Color(0xFFD83C3C)),
    ('🧪', Color(0xFF9B4CC8)),
    ('💎', Color(0xFF3CC8C0)),
    ('🛡️', Color(0xFF8B8B9B)),
    ('👑', Color(0xFFE8B53A)),
    ('🐉', Color(0xFF2E8B57)),
    ('🏰', Color(0xFF8B5A2B)),
  ],
};

class PancakeMergeScreen extends StatefulWidget {
  const PancakeMergeScreen({super.key, required this.game, this.world});

  final GameInfo game;

  /// Injected by tests for a seeded, controllable jar.
  final MergeWorld? world;

  @override
  State<PancakeMergeScreen> createState() => _PancakeMergeScreenState();
}

class _PancakeMergeScreenState extends State<PancakeMergeScreen>
    with SingleTickerProviderStateMixin {
  static const _dt = 1 / 120;
  static const _dropCooldown = 0.45;
  static const _pointsPerBomb = 300;

  late MergeWorld _world;
  late final Ticker _ticker;
  final _repaint = ValueNotifier(0);
  Duration _last = Duration.zero;
  double _accumulator = 0;
  double _cooldown = 0;
  double _aimX = MergeWorld.width / 2;
  int _bombs = 0;
  int _bombsEarned = 0;
  bool _bombArmed = false;
  int? _reward;

  @override
  void initState() {
    super.initState();
    _world = widget.world ?? MergeWorld();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  void _restart() {
    setState(() {
      _world = MergeWorld();
      _bombs = 0;
      _bombsEarned = 0;
      _bombArmed = false;
      _reward = null;
      _cooldown = 0;
    });
  }

  void _tick(Duration now) {
    // Cap the catch-up so a paused app doesn't fast-forward the jar.
    final elapsed = ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.1);
    _last = now;
    if (_reward != null) return;
    _accumulator += elapsed;
    _cooldown = (_cooldown - elapsed).clamp(0, _dropCooldown);
    final scoreBefore = _world.score;
    while (_accumulator >= _dt) {
      _world.step(_dt);
      _accumulator -= _dt;
    }
    if (_world.takeEvents().isNotEmpty) impactFeedback(context);
    final earned = _world.score ~/ _pointsPerBomb;
    final newBombs = earned - _bombsEarned;
    if (newBombs > 0) {
      _bombs += newBombs;
      _bombsEarned = earned;
    }
    if (_world.gameOver) {
      final tokens = (_world.score ~/ 40).clamp(1, 60);
      setState(() => _reward = tokens);
      finishRound(context, widget.game, score: _world.score, tokens: tokens);
    } else if (_world.score != scoreBefore || newBombs > 0) {
      setState(() {});
    }
    _repaint.value++;
  }

  void _drop() {
    if (_cooldown > 0 || _reward != null) return;
    _world.drop(_aimX);
    _cooldown = _dropCooldown;
    tapFeedback(context);
    setState(() {});
  }

  void _useBomb(Offset worldPoint) {
    final target = _world.bodyAt(worldPoint.dx, worldPoint.dy);
    if (target == null) return;
    setState(() {
      _world.remove(target);
      _bombs--;
      _bombArmed = false;
    });
    impactFeedback(context);
  }

  @override
  Widget build(BuildContext context) {
    final skin = ArcadeSkin.of(context);
    final looks = _tierLooks[skin.id]!;
    final next = looks[_world.nextTier];
    return Scaffold(
      body: ArcadeBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  GameHeader(
                    title: widget.game.titleFor(skin.id),
                    subtitle: 'Merge twins. Keep the stack under the line.',
                    actions: [
                      _ScoreChip(label: 'Score', value: '${_world.score}'),
                      const SizedBox(width: 6),
                      _ScoreChip(label: 'Next', value: next.$1),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: MergeWorld.width / MergeWorld.height,
                          child: LayoutBuilder(
                            builder: (context, box) {
                              final scale = box.maxWidth / MergeWorld.width;
                              Offset toWorld(Offset p) => p / scale;
                              return GestureDetector(
                                key: const ValueKey('merge-jar'),
                                behavior: HitTestBehavior.opaque,
                                onPanDown: (d) {
                                  if (!_bombArmed) {
                                    _aimX = _world.clampDropX(
                                      toWorld(d.localPosition).dx,
                                    );
                                  }
                                },
                                onPanUpdate: (d) {
                                  if (!_bombArmed) {
                                    _aimX = _world.clampDropX(
                                      toWorld(d.localPosition).dx,
                                    );
                                  }
                                },
                                onPanEnd: (_) {
                                  if (!_bombArmed) _drop();
                                },
                                onTapUp: (d) {
                                  if (_bombArmed) {
                                    _useBomb(toWorld(d.localPosition));
                                  } else {
                                    _aimX = _world.clampDropX(
                                      toWorld(d.localPosition).dx,
                                    );
                                    _drop();
                                  }
                                },
                                child: CustomPaint(
                                  painter: _JarPainter(
                                    world: _world,
                                    skin: skin,
                                    looks: looks,
                                    aimX: () => _aimX,
                                    showAim: () =>
                                        _cooldown == 0 && !_bombArmed,
                                    repaint: _repaint,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FilledButton.icon(
                      key: const ValueKey('merge-bomb'),
                      onPressed: _bombs > 0 && _reward == null
                          ? () => setState(() => _bombArmed = !_bombArmed)
                          : null,
                      icon: const Text('💣'),
                      label: Text(
                        _bombArmed
                            ? 'Tap an item to blast it'
                            : _bombs > 0
                            ? 'Bomb x$_bombs'
                            : 'Bomb at every $_pointsPerBomb points',
                      ),
                    ),
                  ),
                ],
              ),
              if (_reward != null)
                RoundOverCard(
                  title: 'Jar overflowed!',
                  lines: [
                    'Score ${_world.score}',
                    '${_world.merges} merges',
                    '+$_reward ${skin.tokenIcon}',
                  ],
                  primaryLabel: 'Play again',
                  onPrimary: _restart,
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

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final skin = ArcadeSkin.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: skin.surface,
        borderRadius: skin.radius,
        border: Border.all(color: skin.primary.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: skin.mutedText)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w900, color: skin.text),
          ),
        ],
      ),
    );
  }
}

class _JarPainter extends CustomPainter {
  _JarPainter({
    required this.world,
    required this.skin,
    required this.looks,
    required this.aimX,
    required this.showAim,
    required super.repaint,
  });

  final MergeWorld world;
  final ArcadeSkin skin;
  final List<(String, Color)> looks;
  final double Function() aimX;
  final bool Function() showAim;
  final Map<(int, double), TextPainter> _emoji = {};

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / MergeWorld.width;
    final jar = Offset.zero & size;
    final radius = Radius.circular(skin.cornerRadius);

    canvas.drawRRect(
      RRect.fromRectAndRadius(jar, radius),
      Paint()..color = skin.surface.withValues(alpha: 0.55),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(jar.deflate(1), radius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = skin.id == SkinId.pixelDungeon ? 4 : 2.5
        ..color = skin.primary,
    );

    // Overflow line, flashing red while something sits above it.
    final danger = world.overflowTimer > 0;
    final lineY = MergeWorld.overflowLine * s;
    final linePaint = Paint()
      ..color = danger
          ? const Color(0xFFFF3B3B)
          : skin.mutedText.withValues(alpha: 0.6)
      ..strokeWidth = danger ? 3 : 1.5;
    for (var x = 0.0; x < size.width; x += 12) {
      canvas.drawLine(Offset(x, lineY), Offset(x + 6, lineY), linePaint);
    }

    if (showAim()) {
      final x = aimX() * s;
      canvas.drawLine(
        Offset(x, MergeWorld.dropY * s),
        Offset(x, size.height),
        Paint()
          ..color = skin.primary.withValues(alpha: 0.25)
          ..strokeWidth = 2,
      );
      _drawBody(canvas, Offset(x, MergeWorld.dropY * s), world.nextTier, s);
    }

    for (final b in world.bodies) {
      _drawBody(canvas, Offset(b.x * s, b.y * s), b.tier, s);
    }
  }

  void _drawBody(Canvas canvas, Offset c, int tier, double s) {
    final r = MergeWorld.radii[tier] * s;
    final (emoji, color) = looks[tier];
    if (skin.glow > 0) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = color.withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    if (skin.cornerRadius == 0) {
      canvas.drawRect(
        Rect.fromCircle(center: c, radius: r * 0.92),
        Paint()..color = color,
      );
    } else {
      canvas.drawCircle(c, r, Paint()..color = color);
    }
    final tp = _emoji.putIfAbsent((tier, s), () {
      return TextPainter(
        text: TextSpan(
          text: emoji,
          style: TextStyle(fontSize: r * 1.15),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_JarPainter old) => old.skin != skin || old.world != world;
}
