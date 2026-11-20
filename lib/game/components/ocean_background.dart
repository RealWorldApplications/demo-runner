import 'dart:math';
import 'dart:ui' as ui;

import 'package:demo_runner/game/ocean_runner_game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Procedural deep-ocean backdrop with light rays, parallax reef silhouettes,
/// and rising ambient micro-bubbles.
class OceanBackground extends PositionComponent
    with HasGameReference<OceanRunnerGame> {
  OceanBackground() : super(priority: -10);

  double _scrollDistance = 0;
  double _elapsedTime = 0;

  final List<_AmbientBubble> _bubbles = List.generate(26, (index) {
    final rng = Random(index * 97 + 13);
    return _AmbientBubble(
      xRatio: rng.nextDouble(),
      yRatio: rng.nextDouble(),
      radius: 1.8 + rng.nextDouble() * 3.8,
      speedY: 18 + rng.nextDouble() * 32,
      driftPhase: rng.nextDouble() * pi * 2,
    );
  });

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsedTime += dt;
    _scrollDistance += game.currentScrollSpeed * dt;

    for (final bubble in _bubbles) {
      bubble.yRatio -= (bubble.speedY * dt) / max(size.y, 1.0);
      if (bubble.yRatio < -0.05) {
        bubble.yRatio = 1.05;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    // 1. Deep Gulf Stream vertical gradient
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, size.y),
        const [
          Color(0xFF06325C),
          Color(0xFF031B36),
          Color(0xFF010B18),
        ],
        const [0.0, 0.55, 1.0],
      );
    canvas.drawRect(rect, bgPaint);

    // 2. Shimmering surface sunbeams
    _drawSunbeams(canvas);

    // 3. Far parallax reef ridge (0.35x scroll speed)
    _drawParallaxRidge(
      canvas: canvas,
      offset: _scrollDistance * 0.35,
      baseHeight: size.y * 0.78,
      amplitude: 28,
      wavelength: 210,
      color: const Color(0xFF042442),
    );

    // 4. Near parallax seabed ridge (0.85x scroll speed)
    _drawParallaxRidge(
      canvas: canvas,
      offset: _scrollDistance * 0.85,
      baseHeight: size.y * 0.89,
      amplitude: 18,
      wavelength: 135,
      color: const Color(0xFF021428),
    );

    // 5. Rising ambient bubbles
    final bubbleFill = Paint()..color = const Color(0x2890E0EF);
    final bubbleStroke = Paint()
      ..color = const Color(0x45CAF0F8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final bubble in _bubbles) {
      final bx =
          (bubble.xRatio * size.x + sin(_elapsedTime * 1.6 + bubble.driftPhase) * 8) %
              size.x;
      final by = bubble.yRatio * size.y;
      canvas.drawCircle(Offset(bx, by), bubble.radius, bubbleFill);
      canvas.drawCircle(Offset(bx, by), bubble.radius, bubbleStroke);
    }
  }

  void _drawSunbeams(Canvas canvas) {
    for (var i = 0; i < 4; i++) {
      final sway = sin(_elapsedTime * 0.45 + i * 1.3) * 26;
      final topX = size.x * (0.14 + i * 0.24) + sway;
      final beamWidthTop = size.x * 0.06;
      final beamWidthBottom = size.x * 0.16;

      final path = Path()
        ..moveTo(topX, 0)
        ..lineTo(topX + beamWidthTop, 0)
        ..lineTo(topX + beamWidthBottom + 90, size.y * 0.88)
        ..lineTo(topX + 45, size.y * 0.88)
        ..close();

      final rayPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(topX, 0),
          Offset(topX + 60, size.y * 0.88),
          const [
            Color(0x2272EFDD),
            Color(0x0072EFDD),
          ],
        );

      canvas.drawPath(path, rayPaint);
    }
  }

  void _drawParallaxRidge({
    required Canvas canvas,
    required double offset,
    required double baseHeight,
    required double amplitude,
    required double wavelength,
    required Color color,
  }) {
    final path = Path()..moveTo(0, size.y);
    const step = 24.0;

    for (double x = 0; x <= size.x + step; x += step) {
      final worldX = x + offset;
      final wave =
          sin(worldX / wavelength) * amplitude +
          cos(worldX / (wavelength * 0.47)) * (amplitude * 0.45);
      path.lineTo(x, baseHeight + wave);
    }

    path
      ..lineTo(size.x + step, size.y)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }
}

class _AmbientBubble {
  _AmbientBubble({
    required this.xRatio,
    required this.yRatio,
    required this.radius,
    required this.speedY,
    required this.driftPhase,
  });

  final double xRatio;
  double yRatio;
  final double radius;
  final double speedY;
  final double driftPhase;
}
