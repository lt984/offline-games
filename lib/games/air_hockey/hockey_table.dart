import 'dart:math';

/// Player 1 sits at the bottom of the screen, player 2 at the top.
enum HockeyPlayer { one, two }

enum HockeyEvent { wall, paddle, goalOne, goalTwo }

class Disc {
  Disc(this.x, this.y, this.radius);

  double x;
  double y;
  double vx = 0;
  double vy = 0;
  final double radius;
}

/// Air hockey rules and physics in world units, y pointing down. Player 1
/// defends the bottom goal and player 2 the top one.
class HockeyTable {
  static const width = 100.0;
  static const height = 170.0;
  static const goalWidth = 36.0;
  static const winningScore = 5;
  static const maxPuckSpeed = 230.0;
  static const maxPaddleSpeed = 450.0;
  static const serveDelay = 0.8;

  final puck = Disc(width / 2, height / 2, 5);
  final paddleOne = Disc(width / 2, height * 0.85, 9);
  final paddleTwo = Disc(width / 2, height * 0.15, 9);

  int scoreOne = 0;
  int scoreTwo = 0;
  double _serveTimer = serveDelay;
  final _targets = <HockeyPlayer, Point<double>>{};
  final List<HockeyEvent> _events = [];

  HockeyPlayer? get winner => scoreOne >= winningScore
      ? HockeyPlayer.one
      : scoreTwo >= winningScore
      ? HockeyPlayer.two
      : null;

  bool get serving => _serveTimer > 0;

  Disc paddleOf(HockeyPlayer p) =>
      p == HockeyPlayer.one ? paddleOne : paddleTwo;

  /// Where a player's finger is. The paddle chases it at a capped speed and
  /// never leaves that player's half.
  void setTarget(HockeyPlayer p, double x, double y) =>
      _targets[p] = Point(x, y);

  List<HockeyEvent> takeEvents() {
    final e = List.of(_events);
    _events.clear();
    return e;
  }

  void step(double dt) {
    if (winner != null) return;
    for (final p in HockeyPlayer.values) {
      _movePaddle(p, dt);
    }
    if (_serveTimer > 0) {
      _serveTimer -= dt;
      return;
    }
    puck.vx *= pow(0.75, dt);
    puck.vy *= pow(0.75, dt);
    puck.x += puck.vx * dt;
    puck.y += puck.vy * dt;
    _collideWalls();
    _collidePaddle(paddleOne);
    _collidePaddle(paddleTwo);
    _capSpeed();
  }

  void _movePaddle(HockeyPlayer p, double dt) {
    final paddle = paddleOf(p);
    final target = _targets[p];
    if (target == null) {
      paddle
        ..vx = 0
        ..vy = 0;
      return;
    }
    final r = paddle.radius;
    final (minY, maxY) = p == HockeyPlayer.one
        ? (height / 2 + r, height - r)
        : (r, height / 2 - r);
    final tx = target.x.clamp(r, width - r);
    final ty = target.y.clamp(minY, maxY);
    var dx = tx - paddle.x, dy = ty - paddle.y;
    final dist = sqrt(dx * dx + dy * dy);
    final maxStep = maxPaddleSpeed * dt;
    if (dist > maxStep) {
      dx *= maxStep / dist;
      dy *= maxStep / dist;
    }
    paddle
      ..x += dx
      ..y += dy
      ..vx = dx / dt
      ..vy = dy / dt;
  }

  void _collideWalls() {
    final r = puck.radius;
    if (puck.x < r || puck.x > width - r) {
      puck.x = puck.x.clamp(r, width - r);
      puck.vx = -puck.vx * 0.9;
      _events.add(HockeyEvent.wall);
    }
    final inMouth = (puck.x - width / 2).abs() < goalWidth / 2 - r * 0.5;
    if (puck.y < r) {
      if (inMouth) {
        if (puck.y < -r) _goal(HockeyPlayer.one);
      } else {
        puck.y = r;
        puck.vy = -puck.vy * 0.9;
        _events.add(HockeyEvent.wall);
      }
    } else if (puck.y > height - r) {
      if (inMouth) {
        if (puck.y > height + r) _goal(HockeyPlayer.two);
      } else {
        puck.y = height - r;
        puck.vy = -puck.vy * 0.9;
        _events.add(HockeyEvent.wall);
      }
    }
  }

  void _collidePaddle(Disc paddle) {
    final dx = puck.x - paddle.x, dy = puck.y - paddle.y;
    final minDist = puck.radius + paddle.radius;
    final d2 = dx * dx + dy * dy;
    if (d2 >= minDist * minDist) return;
    final d = max(sqrt(d2), 1e-6);
    final nx = dx / d, ny = dy / d;
    puck.x = paddle.x + nx * minDist;
    puck.y = paddle.y + ny * minDist;
    final rel = (puck.vx - paddle.vx) * nx + (puck.vy - paddle.vy) * ny;
    if (rel < 0) {
      // The paddle is effectively infinitely heavy.
      puck.vx -= 1.9 * rel * nx;
      puck.vy -= 1.9 * rel * ny;
      _events.add(HockeyEvent.paddle);
    }
  }

  void _capSpeed() {
    final speed = sqrt(puck.vx * puck.vx + puck.vy * puck.vy);
    if (speed > maxPuckSpeed) {
      puck.vx *= maxPuckSpeed / speed;
      puck.vy *= maxPuckSpeed / speed;
    }
  }

  void _goal(HockeyPlayer scorer) {
    if (scorer == HockeyPlayer.one) {
      scoreOne++;
      _events.add(HockeyEvent.goalOne);
    } else {
      scoreTwo++;
      _events.add(HockeyEvent.goalTwo);
    }
    // The player who conceded gets the puck on their side.
    puck
      ..x = width / 2
      ..y = scorer == HockeyPlayer.one ? height * 0.35 : height * 0.65
      ..vx = 0
      ..vy = 0;
    _serveTimer = serveDelay;
  }

  void reset() {
    scoreOne = 0;
    scoreTwo = 0;
    puck
      ..x = width / 2
      ..y = height / 2
      ..vx = 0
      ..vy = 0;
    paddleOne
      ..x = width / 2
      ..y = height * 0.85;
    paddleTwo
      ..x = width / 2
      ..y = height * 0.15;
    _targets.clear();
    _events.clear();
    _serveTimer = serveDelay;
  }
}
