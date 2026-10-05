import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../theme/arcade_skin.dart';
import '../../widgets/arcade_background.dart';
import '../game_catalog.dart';
import '../game_kit.dart';
import 'hockey_table.dart';

/// Two players face each other across one phone laid flat. Each drags the
/// paddle on their own half; first to five goals wins.
class AirHockeyScreen extends StatefulWidget {
  const AirHockeyScreen({super.key, required this.game, this.table});

  final GameInfo game;

  /// Injected by tests.
  final HockeyTable? table;

  static const matchReward = 10;

  @override
  State<AirHockeyScreen> createState() => _AirHockeyScreenState();
}

class _AirHockeyScreenState extends State<AirHockeyScreen>
    with SingleTickerProviderStateMixin {
  static const _dt = 1 / 240;

  late final HockeyTable _table = widget.table ?? HockeyTable();
  late final Ticker _ticker;
  final _repaint = ValueNotifier(0);
  final _pointers = <int, HockeyPlayer>{};
  Duration _last = Duration.zero;
  double _accumulator = 0;
  double _wallBuzzCooldown = 0;
  bool _paid = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  void _tick(Duration now) {
    final elapsed = ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.1);
    _last = now;
    _accumulator += elapsed;
    _wallBuzzCooldown -= elapsed;
    while (_accumulator >= _dt) {
      _table.step(_dt);
      _accumulator -= _dt;
    }
    var scored = false;
    for (final e in _table.takeEvents()) {
      switch (e) {
        case HockeyEvent.goalOne || HockeyEvent.goalTwo:
          scored = true;
          impactFeedback(context);
        case HockeyEvent.wall || HockeyEvent.paddle:
          if (_wallBuzzCooldown <= 0) {
            tapFeedback(context);
            _wallBuzzCooldown = 0.08;
          }
      }
    }
    if (scored) {
      if (_table.winner != null && !_paid) {
        _paid = true;
        finishRound(context, widget.game, tokens: AirHockeyScreen.matchReward);
      }
      setState(() {});
    }
    _repaint.value++;
  }

  void _rematch() {
    setState(() {
      _table.reset();
      _pointers.clear();
      _paid = false;
    });
  }

  void _onPointer(PointerEvent e, double scale) {
    final world = e.localPosition / scale;
    final player = _pointers.putIfAbsent(
      e.pointer,
      () => world.dy > HockeyTable.height / 2
          ? HockeyPlayer.one
          : HockeyPlayer.two,
    );
    _table.setTarget(player, world.dx, world.dy);
  }

  @override
  Widget build(BuildContext context) {
    final skin = ArcadeSkin.of(context);
    final winner = _table.winner;
    return Scaffold(
      body: ArcadeBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _PlayerBar(
                    player: HockeyPlayer.two,
                    score: _table.scoreTwo,
                    color: skin.accent,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: HockeyTable.width / HockeyTable.height,
                          child: LayoutBuilder(
                            builder: (context, box) {
                              final scale = box.maxWidth / HockeyTable.width;
                              return Listener(
                                key: const ValueKey('hockey-table'),
                                behavior: HitTestBehavior.opaque,
                                onPointerDown: (e) => _onPointer(e, scale),
                                onPointerMove: (e) => _onPointer(e, scale),
                                onPointerUp: (e) => _pointers.remove(e.pointer),
                                onPointerCancel: (e) =>
                                    _pointers.remove(e.pointer),
                                child: CustomPaint(
                                  painter: _TablePainter(
                                    table: _table,
                                    skin: skin,
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
                  _PlayerBar(
                    player: HockeyPlayer.one,
                    score: _table.scoreOne,
                    color: skin.primary,
                    leading: BackButton(color: skin.text),
                  ),
                ],
              ),
              if (winner != null)
                RoundOverCard(
                  // Turn the card to face whoever won.
                  quarterTurns: winner == HockeyPlayer.two ? 2 : 0,
                  title: winner == HockeyPlayer.one
                      ? 'Player 1 wins!'
                      : 'Player 2 wins!',
                  lines: [
                    '${_table.scoreOne} : ${_table.scoreTwo}',
                    '+${AirHockeyScreen.matchReward} ${skin.tokenIcon}',
                  ],
                  primaryLabel: 'Rematch',
                  onPrimary: _rematch,
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

/// Score strip for one player. Player 2's is upside down so it reads
/// correctly from across the table.
class _PlayerBar extends StatelessWidget {
  const _PlayerBar({
    required this.player,
    required this.score,
    required this.color,
    this.leading,
  });

  final HockeyPlayer player;
  final int score;
  final Color color;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final skin = ArcadeSkin.of(context);
    final label = player == HockeyPlayer.one ? 'PLAYER 1' : 'PLAYER 2';
    return RotatedBox(
      quarterTurns: player == HockeyPlayer.two ? 2 : 0,
      child: Padding(
        padding: EdgeInsets.fromLTRB(leading == null ? 20 : 4, 8, 20, 8),
        child: Row(
          children: [
            ?leading,
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const Spacer(),
            for (var i = 0; i < HockeyTable.winningScore; i++)
              Container(
                margin: const EdgeInsets.only(left: 4),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: i < score ? color : Colors.transparent,
                  border: Border.all(color: color, width: 2),
                  shape: skin.cornerRadius == 0
                      ? BoxShape.rectangle
                      : BoxShape.circle,
                ),
              ),
            const SizedBox(width: 12),
            Text(
              '$score',
              key: ValueKey('score-${player.name}'),
              style: TextStyle(
                color: skin.text,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TablePainter extends CustomPainter {
  _TablePainter({
    required this.table,
    required this.skin,
    required super.repaint,
  });

  final HockeyTable table;
  final ArcadeSkin skin;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / HockeyTable.width;
    final rect = Offset.zero & size;
    final corner = Radius.circular(skin.cornerRadius);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = skin.mutedText.withValues(alpha: 0.5);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, corner),
      Paint()..color = skin.surface.withValues(alpha: 0.85),
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      line,
    );
    canvas.drawCircle(size.center(Offset.zero), 16 * s, line);

    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = skin.id == SkinId.pixelDungeon ? 5 : 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(1), corner),
      rim..color = skin.mutedText,
    );

    // Goal mouths in each player's color.
    final mouth = HockeyTable.goalWidth * s;
    final left = (size.width - mouth) / 2;
    final goalPaint = Paint()
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(left, 1),
      Offset(left + mouth, 1),
      goalPaint..color = skin.accent,
    );
    canvas.drawLine(
      Offset(left, size.height - 1),
      Offset(left + mouth, size.height - 1),
      goalPaint..color = skin.primary,
    );

    _disc(canvas, table.paddleOne, s, skin.primary, paddle: true);
    _disc(canvas, table.paddleTwo, s, skin.accent, paddle: true);
    _disc(canvas, table.puck, s, skin.text, paddle: false);

    if (table.serving && table.winner == null) {
      _label(canvas, size, 'Ready', table.puck.y * s + 14 * s, s);
    }
  }

  void _disc(
    Canvas canvas,
    Disc d,
    double s,
    Color color, {
    required bool paddle,
  }) {
    final c = Offset(d.x * s, d.y * s);
    final r = d.radius * s;
    if (skin.glow > 0) {
      canvas.drawCircle(
        c,
        r + 2,
        Paint()
          ..color = color.withValues(alpha: 0.7)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, skin.glow / 2),
      );
    }
    final fill = Paint()..color = color;
    if (skin.cornerRadius == 0) {
      canvas.drawRect(Rect.fromCircle(center: c, radius: r * 0.9), fill);
    } else {
      canvas.drawCircle(c, r, fill);
    }
    if (paddle) {
      canvas.drawCircle(
        c,
        r * 0.45,
        Paint()..color = Colors.white.withValues(alpha: 0.35),
      );
    }
  }

  void _label(Canvas canvas, Size size, String text, double y, double s) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: skin.mutedText,
          fontSize: 5 * s,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, y));
  }

  @override
  bool shouldRepaint(_TablePainter old) =>
      old.skin != skin || old.table != table;
}
