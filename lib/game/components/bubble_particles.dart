import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

/// Factory helpers for Flame [ParticleSystemComponent] visual feedback.
class BubbleParticles {
  static final Random _rng = Random();

  /// Cavitation bubble trail emitted behind the mini-sub on each thrust.
  static ParticleSystemComponent thrustBurst(Vector2 origin) {
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: 10,
        lifespan: 0.45,
        generator: (index) {
          final speed = Vector2(
            -90 - _rng.nextDouble() * 80,
            (_rng.nextDouble() - 0.5) * 70 - 20,
          );
          final radius = 2.2 + _rng.nextDouble() * 3.4;
          return AcceleratedParticle(
            position: origin.clone(),
            speed: speed,
            acceleration: Vector2(0, -45),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final alpha = (1.0 - particle.progress).clamp(0.0, 1.0);
                final paint = Paint()
                  ..color = Color.fromRGBO(144, 224, 239, alpha * 0.85)
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 1.5;
                canvas.drawCircle(Offset.zero, radius * (1 + particle.progress * 0.4), paint);
              },
            ),
          );
        },
      ),
    );
  }

  /// Radial golden-aqua sparkle burst when collecting a pearl.
  static ParticleSystemComponent pearlSparkle(Vector2 origin) {
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: 18,
        lifespan: 0.55,
        generator: (index) {
          final angle = (index / 18) * pi * 2 + _rng.nextDouble() * 0.3;
          final magnitude = 60 + _rng.nextDouble() * 110;
          final speed = Vector2(cos(angle) * magnitude, sin(angle) * magnitude);
          final isGold = index.isEven;
          return AcceleratedParticle(
            position: origin.clone(),
            speed: speed,
            acceleration: -speed * 0.9,
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final alpha = (1.0 - particle.progress).clamp(0.0, 1.0);
                final color = isGold
                    ? Color.fromRGBO(255, 209, 102, alpha)
                    : Color.fromRGBO(144, 224, 239, alpha);
                canvas.drawCircle(
                  Offset.zero,
                  3.5 * (1.0 - particle.progress * 0.6),
                  Paint()..color = color,
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Impact shockwave and bubble burst on obstacle collision.
  static ParticleSystemComponent crashExplosion(Vector2 origin) {
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: 28,
        lifespan: 0.7,
        generator: (index) {
          final angle = _rng.nextDouble() * pi * 2;
          final magnitude = 70 + _rng.nextDouble() * 190;
          final speed = Vector2(cos(angle) * magnitude, sin(angle) * magnitude);
          final radius = 2.8 + _rng.nextDouble() * 4.5;
          return AcceleratedParticle(
            position: origin.clone(),
            speed: speed,
            acceleration: Vector2(0, 140),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final alpha = (1.0 - particle.progress).clamp(0.0, 1.0);
                final color = index % 3 == 0
                    ? Color.fromRGBO(255, 107, 107, alpha)
                    : Color.fromRGBO(255, 230, 109, alpha);
                canvas.drawCircle(
                  Offset.zero,
                  radius * (1.0 - particle.progress * 0.5),
                  Paint()..color = color,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
