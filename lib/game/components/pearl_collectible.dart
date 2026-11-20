import 'dart:math';
import 'dart:ui' as ui;

import 'package:demo_runner/game/ocean_runner_game.dart';
// ignore: unused_import
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Glowing ocean pearl collectible that grants bonus points and triggers a
/// particle sparkle burst on pickup.
class PearlCollectible extends PositionComponent
    with HasGameReference<OceanRunnerGame> {
  PearlCollectible({required Vector2 position})
      : _baseY = position.y,
        super(
          position: position,
          size: Vector2.all(36),
          anchor: Anchor.center,
        );

  // ignore: unused_field
  final double _baseY;
  double _phase = 0;
  bool _collected = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _phase = (position.x * 0.05) % (pi * 2);
    // TODO (Stage 3): Add a passive CircleHitbox(radius: 15, position: Vector2.all(18), anchor: Anchor.center).
  }

  /// Marks this pearl as collected and triggers score, particles, and chime.
  void collect() {
    if (_collected) return;
    _collected = true;
    game.handlePearlCollected(position.clone());
    removeFromParent();
  }

  @override
  // ignore: unnecessary_overrides
  void update(double dt) {
    super.update(dt);
    // TODO (Stage 2): Scroll pearl left, bob vertically with _baseY & _phase,
    // and call removeFromParent() when off-screen.
  }

  @override
  void render(Canvas canvas) {
    final pulse = 1.0 + sin(_phase * 1.5) * 0.14;
    const center = Offset(18, 18);

    canvas.drawCircle(
      center,
      15 * pulse,
      Paint()..color = const Color(0x38FFD166),
    );

    canvas.drawCircle(
      center,
      10,
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(14.5, 14.5),
          12,
          const [
            Color(0xFFFFFFFF),
            Color(0xFFCAF0F8),
            Color(0xFF48CAE4),
          ],
          const [0.0, 0.55, 1.0],
        ),
    );

    canvas.drawCircle(
      center,
      10,
      Paint()
        ..color = const Color(0xAAFFE66D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.drawCircle(
      const Offset(14.5, 14.5),
      2.6,
      Paint()..color = const Color(0xEEFFFFFF),
    );
  }
}
