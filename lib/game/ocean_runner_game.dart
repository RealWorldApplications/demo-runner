import 'dart:math';

import 'package:demo_runner/game/audio_synth.dart';
// Pre-imported for Stage 4 particle effects:
// ignore: unused_import
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

/// Starter Flame game shell for **Gulf Stream Mini-Sub** with guided
/// `TODO (Stage X)` checkpoints matching `WORKSHOP_GUIDE.md`.
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

  // Pre-built starter fields for Stage 2 & Stage 4:
  // ignore: unused_field
  final Random _rng = Random();
  double elapsedRunTime = 0.0;
  // ignore: unused_field
  double _spawnTimer = 0.0;
  // ignore: unused_field
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
    // TODO (Stage 4): Add BubbleParticles.thrustBurst(...) and OceanAudio.instance.playSwim();
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
    // TODO (Stage 4): Add BubbleParticles.pearlSparkle(worldPos) and OceanAudio.instance.playPearl();
  }

  /// Ends the run with screen shake, explosion particles, crash sound, and overlay.
  void handlePlayerCrash(Vector2 worldPos) {
    if (state != GameState.playing) return;
    state = GameState.gameOver;

    if (scoreNotifier.value > highScoreNotifier.value) {
      highScoreNotifier.value = scoreNotifier.value;
    }

    // TODO (Stage 4): Trigger _shakeTime = 0.35, BubbleParticles.crashExplosion(worldPos),
    // and OceanAudio.instance.playCrash();
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
  // ignore: unnecessary_overrides
  void update(double dt) {
    super.update(dt);
    // TODO (Stage 2): Advance elapsedRunTime, decrement _spawnTimer, and call _spawnWave().
    // TODO (Stage 4): Decrement _shakeTime toward 0.0.
  }

  // ignore: unused_element
  void _spawnWave() {
    // TODO (Stage 2): Spawn coral spires, jellyfish, and companion pearls.
  }

  @override
  // ignore: unnecessary_overrides
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    // TODO (Stage 1): Call triggerPlayerThrust() when playing, or startGame() in menu.
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent) {
      // TODO (Stage 1): Handle Space / ArrowUp / W to thrust or startGame().

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
