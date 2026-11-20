import 'package:demo_runner/game/ocean_runner_game.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const OceanRunnerApp());
}

/// Root Flutter widget mounting Flame's [GameWidget] alongside reactive
/// Material UI overlays for the Start Menu, HUD, and Game Over screen.
class OceanRunnerApp extends StatefulWidget {
  const OceanRunnerApp({super.key});

  @override
  State<OceanRunnerApp> createState() => _OceanRunnerAppState();
}

class _OceanRunnerAppState extends State<OceanRunnerApp> {
  final FocusNode _gameFocusNode = FocusNode();

  @override
  void dispose() {
    _gameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gulf Stream Mini-Sub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00B4D8),
          brightness: Brightness.dark,
        ),
      ),
      home: Scaffold(
        body: GameWidget<OceanRunnerGame>.controlled(
          focusNode: _gameFocusNode,
          autofocus: true,
          gameFactory: OceanRunnerGame.new,
          initialActiveOverlays: const [OceanRunnerGame.menuOverlay],
          overlayBuilderMap: {
            OceanRunnerGame.menuOverlay: (context, game) => _MenuOverlay(
              game: game,
              onStartPressed: () {
                game.startGame();
                _gameFocusNode.requestFocus();
              },
            ),
            OceanRunnerGame.hudOverlay: (context, game) => _HudOverlay(
              game: game,
              onFocusGame: _gameFocusNode.requestFocus,
            ),
            OceanRunnerGame.gameOverOverlay: (context, game) =>
                _GameOverOverlay(
                  game: game,
                  onRestartPressed: () {
                    game.startGame();
                    _gameFocusNode.requestFocus();
                  },
                ),
          },
        ),
      ),
    );
  }
}

class _MenuOverlay extends StatelessWidget {
  const _MenuOverlay({
    required this.game,
    required this.onStartPressed,
  });

  final OceanRunnerGame game;
  final VoidCallback onStartPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            decoration: BoxDecoration(
              color: const Color(0xD9031528),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x6648CAE4), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x88000000),
                  blurRadius: 30,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x2848CAE4),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0x5548CAE4)),
                  ),
                  child: const Text(
                    'GDG TAMPA BAY • FLUTTER & FLAME',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Color(0xFF90E0EF),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'GULF STREAM MINI-SUB',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    color: Color(0xFFFFD166),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Navigate the deep reef, dodge bioluminescent jellyfish, and collect glowing pearls.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFFCBD5E1),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x55062544),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Column(
                    children: [
                      _ControlRow(
                        icon: Icons.touch_app,
                        label: 'Tap, Click, or SPACE / W / ↑ to Thrust',
                      ),
                      SizedBox(height: 8),
                      _ControlRow(
                        icon: Icons.grid_on,
                        label: 'Press D to toggle Flame Hitbox Debug',
                      ),
                      SizedBox(height: 8),
                      _ControlRow(
                        icon: Icons.volume_up,
                        label: 'Press M to mute synthesized audio',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onStartPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD166),
                      foregroundColor: const Color(0xFF041426),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 26),
                    label: const Text(
                      'DIVE IN',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlRow extends StatelessWidget {
  const _ControlRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF48CAE4)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFFE2E8F0)),
          ),
        ),
      ],
    );
  }
}

class _HudOverlay extends StatelessWidget {
  const _HudOverlay({
    required this.game,
    required this.onFocusGame,
  });

  final OceanRunnerGame game;
  final VoidCallback onFocusGame;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: game.scoreNotifier,
                  builder: (context, score, _) => _HudPill(
                    icon: Icons.speed_rounded,
                    label: 'SCORE',
                    value: '$score',
                    accent: const Color(0xFF48CAE4),
                  ),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: game.pearlsNotifier,
                  builder: (context, pearls, _) => _HudPill(
                    icon: Icons.lens_blur_rounded,
                    label: 'PEARLS',
                    value: '$pearls',
                    accent: const Color(0xFFFFD166),
                  ),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: game.highScoreNotifier,
                  builder: (context, best, _) => _HudPill(
                    icon: Icons.emoji_events_rounded,
                    label: 'BEST',
                    value: '$best',
                    accent: const Color(0xFF72EFDD),
                  ),
                ),
              ],
            ),
            const Spacer(),
            ValueListenableBuilder<bool>(
              valueListenable: game.debugModeNotifier,
              builder: (context, isDebug, _) => IconButton.filledTonal(
                tooltip: 'Toggle Hitbox Debug (D)',
                onPressed: () {
                  game.toggleDebugHitboxes();
                  onFocusGame();
                },
                style: IconButton.styleFrom(
                  backgroundColor: isDebug
                      ? const Color(0xCCFF4D8D)
                      : const Color(0xAA04182E),
                ),
                icon: Icon(
                  Icons.bug_report_rounded,
                  color: isDebug ? Colors.white : const Color(0xFF90E0EF),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<bool>(
              valueListenable: game.mutedNotifier,
              builder: (context, isMuted, _) => IconButton.filledTonal(
                tooltip: 'Toggle Sound (M)',
                onPressed: () {
                  game.toggleMute();
                  onFocusGame();
                },
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xAA04182E),
                ),
                icon: Icon(
                  isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: isMuted
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFFFFD166),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HudPill extends StatelessWidget {
  const _HudPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xBB031528),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 6),
          Text(
            '$label ',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.game,
    required this.onRestartPressed,
  });

  final OceanRunnerGame game;
  final VoidCallback onRestartPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xE0041426),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x77FF6B6B), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.waves_rounded,
                  size: 40,
                  color: Color(0xFFFF6B6B),
                ),
                const SizedBox(height: 10),
                const Text(
                  'HULL BREACH!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: Color(0xFFFF6B6B),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatColumn(
                      label: 'SCORE',
                      value: '${game.scoreNotifier.value}',
                      color: const Color(0xFF48CAE4),
                    ),
                    _StatColumn(
                      label: 'PEARLS',
                      value: '${game.pearlsNotifier.value}',
                      color: const Color(0xFFFFD166),
                    ),
                    _StatColumn(
                      label: 'BEST',
                      value: '${game.highScoreNotifier.value}',
                      color: const Color(0xFF72EFDD),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onRestartPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF48CAE4),
                      foregroundColor: const Color(0xFF041426),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text(
                      'DIVE AGAIN',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}
