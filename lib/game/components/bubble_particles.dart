// Pre-imported for Stage 4 particle emitters:
// ignore: unused_import
import 'dart:math';

import 'package:flame/components.dart';
// ignore: unused_import
import 'package:flame/particles.dart';
// ignore: unused_import
import 'package:flutter/material.dart';

/// Factory helpers for Flame [ParticleSystemComponent] visual feedback.
class BubbleParticles {
  /// Cavitation bubble trail emitted behind the mini-sub on each thrust.
  static ParticleSystemComponent thrustBurst(Vector2 origin) {
    // TODO (Stage 4): Replace with Particle.generate(...) cavitation bubbles.
    return ParticleSystemComponent();
  }

  /// Radial golden-aqua sparkle burst when collecting a pearl.
  static ParticleSystemComponent pearlSparkle(Vector2 origin) {
    // TODO (Stage 4): Replace with Particle.generate(...) pearl sparkles.
    return ParticleSystemComponent();
  }

  /// Impact shockwave and bubble burst on obstacle collision.
  static ParticleSystemComponent crashExplosion(Vector2 origin) {
    // TODO (Stage 4): Replace with Particle.generate(...) crash burst.
    return ParticleSystemComponent();
  }
}
