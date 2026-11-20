# Presenter & Live-Coding Guide: Dive into Game Development with Flutter & Flame

**Event:** GDG Tampa Bay Virtual Meetup  
**Title:** *Dive into Game Development: Building 2D Web Games with Flutter & Flame*  
**Project:** **Gulf Stream Mini-Sub** (`demo_runner`)  
**Duration:** 60 Minutes (6 runnable checkpoints)

---

## 1. Presenter Pre-Flight Checklist

1. **Clone / open the repo on the `main` (`starter`) branch:**
   ```bash
   git checkout main
   flutter pub get
   flutter run -d chrome
   ```
2. **Keep `completed` handy** in a second terminal or IDE window in case you want to show the finished experience first (`git checkout completed`) or diff a step.
3. **Show the end state for 60 seconds first:** Before live-coding on `main`, run `completed` in Chrome so attendees know what they are building—fly through a couple of jellyfish, collect a pearl, press **`D`** to flash Flame's debug hitboxes, and crash to show screen-shake + Game Over overlay. Then switch back to `main` (`git checkout main`) and Hot Restart (`Shift+R`).
4. **Hot Reload vs. Hot Restart reminder for attendees:**
   - Editing `render(Canvas)` or `update(double dt)` works with **Hot Reload (`r`)**.
   - Editing `onLoad()` (adding new components or hitboxes) requires **Hot Restart (`Shift + R`)** because `onLoad()` runs once when a component mounts.

---

## 2. Live-Coding Run of Show (60 Minutes)

| Time | Stage | Meetup Agenda Topic | File(s) Edited |
| :--- | :--- | :--- | :--- |
| **0:00 – 0:08** | **Stage 0** | The Flame Game Loop & Procedural Canvas | `ocean_background.dart`, `ocean_runner_game.dart` |
| **0:08 – 0:20** | **Stage 1** | Mini-Sub Sprite Animation & Single-Touch Controls | `minisub_player.dart`, `ocean_runner_game.dart` |
| **0:20 – 0:32** | **Stage 2** | Component-Based Architecture (Obstacles & Pearls) | `obstacle_component.dart`, `pearl_collectible.dart`, `ocean_runner_game.dart` |
| **0:32 – 0:42** | **Stage 3** | Collision Detection & Flutter Overlays | `minisub_player.dart`, `obstacle_component.dart`, `pearl_collectible.dart`, `ocean_runner_game.dart` |
| **0:42 – 0:52** | **Stage 4** | Dynamic Visuals (Particles) & Zero-Asset Audio | `bubble_particles.dart`, `ocean_runner_game.dart` |
| **0:52 – 1:00** | **Stage 5** | Web Optimization, Viewports & Deployment | Walkthrough & Q&A |

---

## Stage 0 (0:00 – 0:08): The Flame Game Loop & Procedural Ocean Canvas

### What to Say to the Audience
- *"Flutter already uses Skia/Impeller to paint 60–120 FPS widgets onto a Canvas. Flame simply gives us a dedicated game loop (`update(dt)` + `render(canvas)`) wrapped inside a normal Flutter widget: `GameWidget`."*
- Explain `dt` (**delta time**, seconds since the previous frame): multiplying speeds by `dt` ensures the game moves at the exact same speed on a 60 Hz laptop, a 120 Hz ProMotion tablet, or a throttled browser tab.
- Walk through `lib/main.dart` briefly to show `GameWidget<OceanRunnerGame>.controlled` and how `FlameGame` mounts inside `Scaffold`.
- Open `lib/game/components/ocean_background.dart` and look for **`TODO (Stage 0)`**.

### Live Code — `lib/game/components/ocean_background.dart`
Implement scrolling distance in `update(double dt)` and the deep-ocean gradient + sunbeams + parallax ridges in `render(Canvas canvas)`:

```dart
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
```

### Live Code — `lib/game/ocean_runner_game.dart` (`onLoad`)
Mount `OceanBackground()` inside `onLoad()`:
```dart
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await OceanAudio.instance.init();
    await add(OceanBackground());
    player = MiniSubPlayer();
    await add(player);
  }
```

### Checkpoint 0 Verification
Run **Hot Restart (`Shift+R`)**. Chrome shows the animated Gulf Stream gradient, swaying sunbeams, scrolling seabed silhouettes, rising bubbles, and the **GULF STREAM MINI-SUB** start overlay.

---

## Stage 1 (0:08 – 0:20): Mini-Sub Player, Procedural Sprite Animation & Touch Physics

### What to Say to the Audience
- *"Usually 2D tutorials stall while everyone downloads sprite sheets and edits `pubspec.yaml` asset paths. Here, `MiniSubSprites.createAnimation()` uses Flutter's `ui.PictureRecorder` to paint 4 propeller frames onto an offscreen canvas at startup and wraps them into a real Flame `SpriteAnimation`."*
- Explain single-touch runner physics:
  - Constant downward gravity (`velocityY += gravity * dt`).
  - Tap / Space applies an upward impulse (`velocityY = thrustImpulse`).
  - Pitch rotation (`angle`) maps vertical velocity so the sub noses up when climbing and pitches down when diving.

### Live Code — `lib/game/components/minisub_player.dart`
Fill in **`TODO (Stage 1)`** in `thrust()` and `update(double dt)`:

```dart
  void thrust() {
    velocityY = thrustImpulse;
  }
```

```dart
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

    velocityY += gravity * dt;
    position.y += velocityY * dt;

    final maxY = max(48.0, game.size.y - 48.0);
    if (position.y <= 48.0) {
      position.y = 48.0;
      if (velocityY < 0) velocityY = 0;
    } else if (position.y >= maxY) {
      position.y = maxY;
      if (velocityY > 0) velocityY = 0;
    }

    angle = (velocityY / 650.0).clamp(-0.42, 0.52);
  }
```

### Live Code — `lib/game/ocean_runner_game.dart` (Input Callbacks)
Fill in **`TODO (Stage 1)`** in `onTapDown`, `onKeyEvent`, and `triggerPlayerThrust`:

```dart
  void triggerPlayerThrust() {
    if (state != GameState.playing) return;
    player.thrust();
  }
```

```dart
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
```

### Checkpoint 1 Verification
Hot Restart (`Shift+R`), click **DIVE IN**, and tap/click or press `Space`. The animated yellow Mini-Sub tilts up on thrust and sinks smoothly under gravity!

---

## Stage 2 (0:20 – 0:32): Component-Based Architecture — Obstacles & Pearls

### What to Say to the Audience
- *"Flame uses a Component Tree just like Flutter's Widget Tree. Every jellyfish, coral spire, and pearl is a self-contained `PositionComponent` responsible for updating its own position, drawing itself, and cleaning itself up with `removeFromParent()` once it leaves the screen."*
- Point out progressive difficulty: `currentScrollSpeed` ramps gently with `elapsedRunTime`, while `_spawnTimer` shrinks the spawn interval.

### Live Code — `lib/game/components/obstacle_component.dart`
Fill in **`TODO (Stage 2)`** in `update(double dt)`:
```dart
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
```

### Live Code — `lib/game/components/pearl_collectible.dart`
Fill in **`TODO (Stage 2)`** in `update(double dt)`:
```dart
  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) return;

    _phase += dt * 4.0;
    position.x -= game.currentScrollSpeed * dt;
    position.y = _baseY + sin(_phase) * 12;

    if (position.x < -50) {
      removeFromParent();
    }
  }
```

### Live Code — `lib/game/ocean_runner_game.dart` (Wave Spawner)
Fill in **`TODO (Stage 2)`** in `update(double dt)` and `_spawnWave()`:
```dart
    if (state != GameState.playing) return;

    elapsedRunTime += dt;
    _spawnTimer -= dt;

    if (_spawnTimer <= 0) {
      _spawnWave();
      final minInterval = max(0.85, 1.65 - elapsedRunTime * 0.014);
      _spawnTimer = minInterval + _rng.nextDouble() * 0.55;
    }
```

```dart
  void _spawnWave() {
    if (size.x <= 0 || size.y <= 0) return;

    final spawnX = size.x + 60.0;
    final roll = _rng.nextDouble();

    if (roll < 0.52) {
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
```

### Checkpoint 2 Verification
Hot Reload (`r`), click **DIVE IN**. Bioluminescent jellyfish, coral spires, and pearls scroll smoothly from right to left, and your **SCORE** ticks up as you pass obstacles!

---

## Stage 3 (0:32 – 0:42): Collision Detection & Flutter Overlays

### What to Say to the Audience
- *"Notice the sub passes right through obstacles right now—let's turn on Flame's collision system!"*
- Explain **3 key Flame collision patterns**:
  1. Mix `HasCollisionDetection` onto `OceanRunnerGame`.
  2. Attach a forgiving `CircleHitbox` to `MiniSubPlayer` (smaller than the visual hull feels *fairer* to players!) and `CollisionType.passive` hitboxes to obstacles/pearls so obstacles don't waste CPU colliding with each other.
  3. Mix `CollisionCallbacks` onto `MiniSubPlayer` and react in `onCollisionStart`.
- Show how Flutter's `overlayBuilderMap` + `ValueNotifier<int>` keeps the UI declarative without calling `setState` at 60 FPS!

### Live Code — Hitboxes (`minisub_player.dart`, `obstacle_component.dart`, `pearl_collectible.dart`)
1. In `MiniSubPlayer.onLoad()` (`lib/game/components/minisub_player.dart`):
```dart
    add(
      CircleHitbox(
        radius: 19,
        position: Vector2(46, 26),
        anchor: Anchor.center,
      ),
    );
```
2. In `MiniSubPlayer.onCollisionStart(...)`:
```dart
  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (game.state != GameState.playing) return;

    if (other is ObstacleComponent) {
      game.handlePlayerCrash(position.clone());
    } else if (other is PearlCollectible) {
      other.collect();
    }
  }
```
3. In `ObstacleComponent.onLoad()` (`lib/game/components/obstacle_component.dart`):
```dart
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
```
4. In `PearlCollectible.onLoad()` (`lib/game/components/pearl_collectible.dart`):
```dart
    add(
      CircleHitbox(
        radius: 15,
        position: Vector2.all(18),
        anchor: Anchor.center,
        collisionType: CollisionType.passive,
      ),
    );
```

### Checkpoint 3 Verification
Hot Restart (`Shift+R`). Start a dive, then **press `D`** (or click the bug icon in the top right) to display Flame's live hitbox outlines! Collect a pearl to see `PEARLS` + `SCORE (+5)` update instantly in the Flutter HUD, then touch a jellyfish or spire to trigger the **HULL BREACH!** Game Over overlay.

---

## Stage 4 (0:42 – 0:52): Dynamic Visuals (Particles) & Zero-Asset Audio

### What to Say to the Audience
- *"Right now the game works, but it doesn't feel alive yet. Game feel—often called 'juice'—comes from immediate visual and audio feedback."*
- Show `lib/game/components/bubble_particles.dart`: `ParticleSystemComponent` wraps `Particle.generate`, `AcceleratedParticle` (velocity + gravity/drag), and `ComputedParticle` (alpha fade over `particle.progress`).
- Briefly open `lib/game/audio_synth.dart` to show the presenter magic trick: synthesizing 16-bit mono PCM WAV headers + sine sweeps into a `Uint8List` and playing them with `BytesSource(..., mimeType: 'audio/wav')`—zero external `.mp3` or `.wav` files!

### Live Code — `lib/game/components/bubble_particles.dart`
Fill in **`TODO (Stage 4)`** for `thrustBurst`, `pearlSparkle`, and `crashExplosion` (already templated with `ParticleSystemComponent` stubs in `main`—see the full implementation in the `completed` branch or paste below):

```dart
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
                canvas.drawCircle(
                  Offset.zero,
                  radius * (1 + particle.progress * 0.4),
                  paint,
                );
              },
            ),
          );
        },
      ),
    );
  }
```

### Live Code — `lib/game/ocean_runner_game.dart` (Particles, Screen Shake & Sound)
Update `triggerPlayerThrust`, `handlePearlCollected`, `handlePlayerCrash`, and `render`:

```dart
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
```

And in `render(Canvas canvas)`:
```dart
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
```

### Checkpoint 4 Verification
Hot Reload (`r`), dive in, and test:
- Every tap spawns cavitation bubble rings + plays the hydro-thruster pulse.
- Grabbing a pearl triggers a golden-aqua radial burst + D5→A5 chime.
- Hitting a coral spire shakes the screen, bursts debris particles, and plays the underwater hull thud.

---

## Stage 5 (0:52 – 1:00): Web Optimization & Production Deployment

Walk through these 5 web performance takeaways with your audience:

1. **Minimal Bundle Overhead (Procedural Canvas + In-Memory Audio)**  
   No sprite sheets, texture atlases, or `.mp3`/`.wav` assets to download over slow cellular connections. Initial page load stays lean.
2. **Strict Component Lifecycle Cleanup (`removeFromParent()`)**  
   Every off-screen obstacle, off-screen pearl, and finished `ParticleSystemComponent` automatically removes itself from the Flame tree so memory and frame times stay flat even after 10+ minutes of play.
3. **Broadphase Collision Pruning (`CollisionType.passive`)**  
   Setting obstacles and pearls to `CollisionType.passive` ensures Flame only tests collisions against active hitboxes (`MiniSubPlayer`), avoiding unnecessary $O(n^2)$ obstacle-vs-obstacle intersection checks.
4. **Responsive Web & Tablet Viewports**  
   - Our game adapts fluidly to `game.size` across mobile, tablet, and widescreen desktop browsers using percentage anchors (`size.x * 0.22`) and `SafeArea` Flutter overlays.
   - Tip for pixel-art or fixed-aspect games: Flame also provides `CameraComponent.withFixedResolution(width: 960, height: 540)` when you want locked virtual coordinates inside a `World`.
5. **Deploying Smoothly to the Web**
   ```bash
   # Build with WebAssembly (WASM) for fast startup & 60+ FPS compute
   flutter build web --wasm

   # Or standard JS release build
   flutter build web --release
   ```
   Host the resulting `build/web` directory statically on **Firebase Hosting**, **Cloudflare Pages**, or **GitHub Pages**.

---

## 3. Presenter Troubleshooting FAQ

- **No sound in Chrome until first click?**  
  Browser autoplay policies block Web Audio before a user gesture. Clicking **DIVE IN** unlocks browser audio immediately—and `OceanAudio` safely ignores pre-gesture errors.
- **Spacebar doesn't thrust right after clicking "DIVE IN"?**  
  `lib/main.dart` passes a shared `FocusNode` (`_gameFocusNode`) into `GameWidget` and calls `_gameFocusNode.requestFocus()` whenever an overlay button is clicked so keyboard controls stay locked onto Flame.
- **Hot Reload didn't add my new hitbox?**  
  `onLoad()` only executes when a component mounts. Use **Hot Restart (`Shift+R`)** in the Flutter terminal after modifying `onLoad()`.
