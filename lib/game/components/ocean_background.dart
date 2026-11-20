import 'dart:math';
// ignore: unused_import
import 'dart:ui' as ui;

import 'package:demo_runner/game/ocean_runner_game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Procedural deep-ocean backdrop with light rays, parallax reef silhouettes,
/// and rising ambient micro-bubbles.
class OceanBackground extends PositionComponent
    with HasGameReference<OceanRunnerGame> {
  OceanBackground() : super(priority: -10);

  // Pre-built starter fields for Stage 0:
  // ignore: unused_field, prefer_final_fields
  double _scrollDistance = 0;
  // ignore: unused_field, prefer_final_fields
  double _elapsedTime = 0;

  // ignore: unused_field
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
  // ignore: unnecessary_overrides
  void update(double dt) {
    super.update(dt);
    // TODO (Stage 0): Advance _elapsedTime, _scrollDistance, and rising _bubbles.
  }

  @override
  void render(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(rect, Paint()..color = const Color(0xFF031B36));

    // TODO (Stage 0): Replace flat background with Gulf Stream gradient,
    // _drawSunbeams(canvas), _drawParallaxRidge(...) layers, and _bubbles.
  }

  // ignore: unused_element
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

  // ignore: unused_element
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
