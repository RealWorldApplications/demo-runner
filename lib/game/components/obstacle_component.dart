import 'dart:math';
import 'dart:ui' as ui;

import 'package:demo_runner/game/ocean_runner_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum ObstacleType { jellyfish, coralSpire }

/// Procedural ocean hazard rendered either as a drifting bioluminescent
/// jellyfish or a jagged coral spire anchored to the ceiling or seafloor.
class ObstacleComponent extends PositionComponent
    with HasGameReference<OceanRunnerGame> {
  ObstacleComponent({
    required this.type,
    required Vector2 position,
    this.fromTop = false,
    double? height,
  }) : super(
          position: position,
          size: type == ObstacleType.jellyfish
              ? Vector2(54, 68)
              : Vector2(48, height ?? 150),
        ) {
    _baseY = position.y;
  }

  final ObstacleType type;
  final bool fromTop;

  late final double _baseY;
  double _phase = 0;
  bool _passed = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _phase = (position.x * 0.03) % (pi * 2);

    if (type == ObstacleType.jellyfish) {
      add(
        CircleHitbox(
          radius: 21,
          position: Vector2(27, 25),
          anchor: Anchor.center,
          collisionType: CollisionType.passive,
        ),
      );
    } else {
      add(
        RectangleHitbox(
          size: Vector2(32, max(24.0, size.y - 14)),
          position: Vector2(8, fromTop ? 0 : 14),
          collisionType: CollisionType.passive,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) return;

    _phase += dt * 3.0;
    position.x -= game.currentScrollSpeed * dt;

    if (type == ObstacleType.jellyfish) {
      final maxTop = max(36.0, game.size.y - size.y - 36.0);
      position.y = (_baseY + sin(_phase) * 26).clamp(36.0, maxTop);
    }

    if (!_passed && position.x + size.x < game.player.position.x) {
      _passed = true;
      game.incrementObstacleScore();
    }

    if (position.x < -size.x - 40) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (type == ObstacleType.jellyfish) {
      _renderJellyfish(canvas);
    } else {
      _renderCoralSpire(canvas);
    }
  }

  void _renderJellyfish(Canvas canvas) {
    // Soft bioluminescent aura
    canvas.drawCircle(
      const Offset(27, 24),
      26,
      Paint()..color = const Color(0x28FF4D8D),
    );

    // Undulating tentacles
    final tentaclePaint = Paint()
      ..color = const Color(0xCCFF85B3)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 4; i++) {
      final startX = 15.0 + i * 8.0;
      final sway = sin(_phase + i * 0.9) * 5.0;
      final tentacle = Path()
        ..moveTo(startX, 34)
        ..quadraticBezierTo(startX + sway, 48, startX - sway * 0.6, 63);
      canvas.drawPath(tentacle, tentaclePaint);
    }

    // Bell dome
    final domePath = Path()
      ..moveTo(6, 33)
      ..quadraticBezierTo(6, 4, 27, 4)
      ..quadraticBezierTo(48, 4, 48, 33)
      ..quadraticBezierTo(27, 38, 6, 33)
      ..close();

    canvas.drawPath(
      domePath,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(27, 4),
          const Offset(27, 36),
          const [Color(0xEEFF4D8D), Color(0xBB7209B7)],
        ),
    );

    // Highlight spots
    final spotPaint = Paint()..color = const Color(0x99FFE5EC);
    canvas.drawCircle(const Offset(20, 17), 3.2, spotPaint);
    canvas.drawCircle(const Offset(31, 14), 2.2, spotPaint);
  }

  void _renderCoralSpire(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final path = Path();

    if (fromTop) {
      path
        ..moveTo(0, 0)
        ..lineTo(w, 0)
        ..lineTo(w * 0.84, h * 0.42)
        ..lineTo(w * 0.62, h * 0.92)
        ..lineTo(w * 0.48, h)
        ..lineTo(w * 0.32, h * 0.86)
        ..lineTo(w * 0.14, h * 0.46)
        ..close();
    } else {
      path
        ..moveTo(0, h)
        ..lineTo(w * 0.14, h * 0.54)
        ..lineTo(w * 0.34, h * 0.12)
        ..lineTo(w * 0.50, 0)
        ..lineTo(w * 0.68, h * 0.16)
        ..lineTo(w * 0.86, h * 0.58)
        ..lineTo(w, h)
        ..close();
    }

    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, fromTop ? 0 : h),
          Offset(0, fromTop ? h : 0),
          const [Color(0xFF0F766E), Color(0xFFF97316)],
        ),
    );

    // Bioluminescent coral polyps
    final polypPaint = Paint()..color = const Color(0xCCFFE66D);
    canvas.drawCircle(
      Offset(w * 0.44, fromTop ? h * 0.62 : h * 0.38),
      3.5,
      polypPaint,
    );
    canvas.drawCircle(
      Offset(w * 0.60, fromTop ? h * 0.34 : h * 0.66),
      2.6,
      polypPaint,
    );
  }
}
