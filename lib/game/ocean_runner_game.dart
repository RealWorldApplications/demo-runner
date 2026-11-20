import 'dart:math';

import 'package:demo_runner/game/audio_synth.dart';
import 'package:demo_runner/game/components/bubble_particles.dart';
import 'package:demo_runner/game/components/minisub_player.dart';
import 'package:demo_runner/game/components/ocean_background.dart';
import 'package:demo_runner/game/components/obstacle_component.dart';
import 'package:demo_runner/game/components/pearl_collectible.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum GameState { menu, playing, gameOver }

/// Main Flame game loop for **Gulf Stream Mini-Sub**, combining procedural
/// canvas rendering, collision detection, particles, and Flutter HUD overlays.
class OceanRunnerGame extends FlameGame
    with TapCallbacks, KeyboardEvents, HasCollisionDetection {
  static const String menuOverlay = 'MenuOverlay';
  static const String hudOverlay = 'HudOverlay';
  static const String gameOverOverlay = 'GameOverOverlay';

  static const double baseScrollSpeed = 210.0;

  GameState state = GameState.menu;

  final ValueNotifier<int> scoreNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> pearlsNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> highScoreNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> debugModeNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> mutedNotifier = ValueNotifier<bool>(false);

  late final MiniSubPlayer player;

  final Random _rng = Random();
  double elapsedRunTime = 0.0;
  double _spawnTimer = 0.0;
  double _shakeTime = 0.0;

  double get currentScrollSpeed => state == GameState.playing
      ? baseScrollSpeed + (elapsedRunTime * 10.0).clamp(0.0, 220.0)
      : 90.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await OceanAudio.instance.init();
    await add(OceanBackground());
    player = MiniSubPlayer();
    await add(player);
  }

  /// Starts or restarts an ocean run from the beginning.
  void startGame() {
    for (final obstacle in children.whereType<ObstacleComponent>().toList()) {
      obstacle.removeFromParent();
    }
    for (final pearl in children.whereType<PearlCollectible>().toList()) {
      pearl.removeFromParent();
    }

    scoreNotifier.value = 0;
    pearlsNotifier.value = 0;
    elapsedRunTime = 0.0;
    _spawnTimer = 0.6;
    _shakeTime = 0.0;

    player.reset();
    state = GameState.playing;

    overlays.remove(menuOverlay);
    overlays.remove(gameOverOverlay);
    if (!overlays.isActive(hudOverlay)) {
      overlays.add(hudOverlay);
    }

    triggerPlayerThrust();
  }

  /// Triggers an upward thrust, cavitation bubble burst, and swim sound.
  void triggerPlayerThrust() {
    if (state != GameState.playing) return;
    player.thrust();
    final emitterOrigin = Vector2(
      player.position.x - 36,
      player.position.y + 4,
    );
    add(BubbleParticles.thrustBurst(emitterOrigin));
    OceanAudio.instance.playSwim();
  }

  /// Awards 1 point when the player clears an obstacle.
  void incrementObstacleScore() {
    if (state != GameState.playing) return;
    scoreNotifier.value += 1;
    if (scoreNotifier.value > highScoreNotifier.value) {
      highScoreNotifier.value = scoreNotifier.value;
    }
  }

  /// Awards 5 bonus points and triggers sparkle particles + chime on pearl pickup.
  void handlePearlCollected(Vector2 worldPos) {
    if (state != GameState.playing) return;
    pearlsNotifier.value += 1;
    scoreNotifier.value += 5;
    if (scoreNotifier.value > highScoreNotifier.value) {
      highScoreNotifier.value = scoreNotifier.value;
    }
    add(BubbleParticles.pearlSparkle(worldPos));
    OceanAudio.instance.playPearl();
  }

  /// Ends the run with screen shake, explosion particles, crash sound, and overlay.
  void handlePlayerCrash(Vector2 worldPos) {
    if (state != GameState.playing) return;
    state = GameState.gameOver;
    _shakeTime = 0.35;

    if (scoreNotifier.value > highScoreNotifier.value) {
      highScoreNotifier.value = scoreNotifier.value;
    }

    add(BubbleParticles.crashExplosion(worldPos));
    OceanAudio.instance.playCrash();
    overlays.add(gameOverOverlay);
  }

  /// Toggles Flame's hitbox debug overlay live across the game tree (`D` key).
  void toggleDebugHitboxes() {
    final next = !debugModeNotifier.value;
    debugModeNotifier.value = next;
    debugMode = next;
    for (final component in descendants()) {
      component.debugMode = next;
    }
  }

  /// Toggles synthesized ocean audio mute (`M` key).
  void toggleMute() {
    mutedNotifier.value = OceanAudio.instance.toggleMute();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_shakeTime > 0) {
      _shakeTime = max(0.0, _shakeTime - dt);
    }

    if (state != GameState.playing) return;

    elapsedRunTime += dt;
    _spawnTimer -= dt;

    if (_spawnTimer <= 0) {
      _spawnWave();
      final minInterval = max(0.85, 1.65 - elapsedRunTime * 0.014);
      _spawnTimer = minInterval + _rng.nextDouble() * 0.55;
    }
  }

  @override
  void render(Canvas canvas) {
    if (_shakeTime > 0) {
      final intensity = (_shakeTime / 0.35) * 9.0;
      final dx = (_rng.nextDouble() * 2 - 1) * intensity;
      final dy = (_rng.nextDouble() * 2 - 1) * intensity;
      canvas.save();
      canvas.translate(dx, dy);
      super.render(canvas);
      canvas.restore();
      return;
    }
    super.render(canvas);
  }

  void _spawnWave() {
    if (size.x <= 0 || size.y <= 0) return;

    final spawnX = size.x + 60.0;
    final roll = _rng.nextDouble();

    if (roll < 0.52) {
      // Coral spire from seafloor or ceiling + optional pearl in safe lane
      final fromTop = _rng.nextBool();
      final maxSpireHeight = max(90.0, size.y * 0.44);
      final height = 90.0 + _rng.nextDouble() * (maxSpireHeight - 90.0);
      final obstacleY = fromTop ? 0.0 : size.y - height;

      final spire = ObstacleComponent(
        type: ObstacleType.coralSpire,
        position: Vector2(spawnX, obstacleY),
        fromTop: fromTop,
        height: height,
      )..debugMode = debugModeNotifier.value;
      add(spire);

      if (_rng.nextDouble() < 0.65) {
        final pearlY = fromTop
            ? min(size.y - 60.0, height + 75.0 + _rng.nextDouble() * 60.0)
            : max(60.0, obstacleY - 75.0 - _rng.nextDouble() * 60.0);
        final pearl = PearlCollectible(
          position: Vector2(spawnX + 24, pearlY),
        )..debugMode = debugModeNotifier.value;
        add(pearl);
      }
    } else {
      // Drifting bioluminescent jellyfish + occasional companion pearl
      final minY = 64.0;
      final maxY = max(minY + 10, size.y - 132.0);
      final jellyY = minY + _rng.nextDouble() * (maxY - minY);

      final jellyfish = ObstacleComponent(
        type: ObstacleType.jellyfish,
        position: Vector2(spawnX, jellyY),
      )..debugMode = debugModeNotifier.value;
      add(jellyfish);

      if (_rng.nextDouble() < 0.55) {
        final pearlY = jellyY > size.y * 0.5
            ? max(64.0, jellyY - 85.0)
            : min(size.y - 64.0, jellyY + 130.0);
        final pearl = PearlCollectible(
          position: Vector2(spawnX + 95, pearlY),
        )..debugMode = debugModeNotifier.value;
        add(pearl);
      }
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (state == GameState.playing) {
      triggerPlayerThrust();
    } else if (state == GameState.menu) {
      startGame();
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.keyW) {
        if (state == GameState.playing) {
          triggerPlayerThrust();
        } else {
          startGame();
        }
        return KeyEventResult.handled;
      }

      if (event.logicalKey == LogicalKeyboardKey.keyD) {
        toggleDebugHitboxes();
        return KeyEventResult.handled;
      }

      if (event.logicalKey == LogicalKeyboardKey.keyM) {
        toggleMute();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  void onRemove() {
    scoreNotifier.dispose();
    pearlsNotifier.dispose();
    highScoreNotifier.dispose();
    debugModeNotifier.dispose();
    mutedNotifier.dispose();
    super.onRemove();
  }
}
