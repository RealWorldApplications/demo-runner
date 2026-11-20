import 'dart:math';
import 'dart:ui' as ui;

// Pre-imported for Stage 3 collision detection:
// ignore: unused_import
import 'package:demo_runner/game/components/obstacle_component.dart';
// ignore: unused_import
import 'package:demo_runner/game/components/pearl_collectible.dart';
import 'package:demo_runner/game/ocean_runner_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Builds a 4-frame procedural [SpriteAnimation] for the yellow Mini-Submarine
/// onto an offscreen [Canvas] so attendees learn Flame sprite animation without
/// needing external image assets.
class MiniSubSprites {
  static Future<SpriteAnimation> createAnimation() async {
    const width = 96;
    const height = 56;
    const frameCount = 4;

    final frames = <Sprite>[];
    for (var i = 0; i < frameCount; i++) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      _paintFrame(canvas, i);
      final picture = recorder.endRecording();
      final image = await picture.toImage(width, height);
      frames.add(Sprite(image));
    }

    return SpriteAnimation.spriteList(frames, stepTime: 0.08);
  }

  static void _paintFrame(Canvas canvas, int frameIndex) {
    // 1. Forward translucent headlight beam
    final beamPath = Path()
      ..moveTo(74, 29)
      ..lineTo(96, 17)
      ..lineTo(96, 43)
      ..close();
    canvas.drawPath(
      beamPath,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(74, 30),
          const Offset(96, 30),
          const [Color(0x66FFE66D), Color(0x00FFE66D)],
        ),
    );

    // 2. Animated stern thruster glow
    final glowRadius = 5.5 + (frameIndex % 2) * 2.2;
    canvas.drawCircle(
      const Offset(10, 30),
      glowRadius,
      Paint()..color = const Color(0x6648CAE4),
    );

    // 3. Animated stern propeller blades
    final bladeSpread = [8.5, 4.0, 1.5, 4.0][frameIndex];
    final propPaint = Paint()
      ..color = const Color(0xFF90E0EF)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(12, 30 - bladeSpread),
      Offset(12, 30 + bladeSpread),
      propPaint,
    );
    canvas.drawRect(
      const Rect.fromLTWH(12, 27, 6, 6),
      Paint()..color = const Color(0xFF475569),
    );

    // 4. Conning tower & periscope
    final towerRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(34, 8, 22, 13),
      const Radius.circular(5),
    );
    canvas.drawRRect(towerRect, Paint()..color = const Color(0xFFF59E0B));

    final periscopePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final periscope = Path()
      ..moveTo(45, 9)
      ..lineTo(45, 3)
      ..lineTo(52, 3);
    canvas.drawPath(periscope, periscopePaint);

    // 5. Yellow pressure hull
    final hullRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(17, 16, 60, 28),
      const Radius.circular(14),
    );
    canvas.drawRRect(
      hullRect,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(17, 16),
          const Offset(17, 44),
          const [Color(0xFFFFD166), Color(0xFFF59E0B)],
        ),
    );

    // Dark navy trim stripe
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(19, 28, 42, 4.5),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF0F172A),
    );

    // 6. Glowing cyan cockpit porthole dome
    canvas.drawCircle(
      const Offset(63, 29),
      9.5,
      Paint()..color = const Color(0xFF0F172A),
    );
    canvas.drawCircle(
      const Offset(63, 29),
      7.5,
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(61, 26),
          8,
          const [Color(0xFFE0FBFC), Color(0xFF00B4D8)],
        ),
    );
    canvas.drawCircle(
      const Offset(60.5, 26.5),
      2.2,
      Paint()..color = const Color(0xDDFFFFFF),
    );

    // 7. Side porthole rivets
    final rivetPaint = Paint()..color = const Color(0xFF00B4D8);
    canvas.drawCircle(const Offset(31, 23), 3.2, rivetPaint);
    canvas.drawCircle(const Offset(42, 23), 3.2, rivetPaint);
  }
}

/// The player-controlled Mini-Submarine with single-touch buoyancy physics and
/// hitbox collision callbacks.
class MiniSubPlayer extends SpriteAnimationComponent
    with HasGameReference<OceanRunnerGame>, CollisionCallbacks {
  MiniSubPlayer()
      : super(
          size: Vector2(88, 52),
          anchor: Anchor.center,
        );

  static const double gravity = 820.0;
  static const double thrustImpulse = -320.0;

  double velocityY = 0.0;
  double _idleTime = 0.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    animation = await MiniSubSprites.createAnimation();
    // TODO (Stage 3): Add a CircleHitbox(radius: 19, position: Vector2(46, 26), anchor: Anchor.center).
    reset();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x > 0 && size.y > 0) {
      position.x = size.x * 0.22;
      position.y = position.y == 0
          ? size.y * 0.5
          : position.y.clamp(48.0, max(48.0, size.y - 48.0));
    }
  }

  /// Applies an upward hydro-thrust impulse.
  void thrust() {
    // TODO (Stage 1): Set velocityY = thrustImpulse;
  }

  /// Resets submarine position, velocity, and pitch for a fresh run.
  void reset() {
    final safeHeight = max(game.size.y, 120.0);
    position = Vector2(max(game.size.x * 0.22, 84.0), safeHeight * 0.5);
    velocityY = 0.0;
    angle = 0.0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (game.state == GameState.menu) {
      _idleTime += dt;
      final safeHeight = max(game.size.y, 120.0);
      position.y = safeHeight * 0.5 + sin(_idleTime * 2.5) * 10;
      angle = sin(_idleTime * 2.5) * 0.05;
      return;
    }

    if (game.state != GameState.playing) {
      return;
    }

    // TODO (Stage 1): Apply gravity to velocityY, move position.y,
    // clamp to [48, game.size.y - 48], and update pitch angle.
  }

  @override
  // ignore: unnecessary_overrides
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    // TODO (Stage 3): Handle ObstacleComponent crash and PearlCollectible pickup.
  }
}
