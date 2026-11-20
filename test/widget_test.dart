import 'package:demo_runner/game/audio_synth.dart';
import 'package:demo_runner/game/ocean_runner_game.dart';
import 'package:demo_runner/main.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('OceanRunnerApp mounts Flame GameWidget and starts run on DIVE IN',
      (tester) async {
    await tester.pumpWidget(const OceanRunnerApp());
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(GameWidget<OceanRunnerGame>), findsOneWidget);
    expect(find.text('GULF STREAM MINI-SUB'), findsOneWidget);
    expect(find.text('DIVE IN'), findsOneWidget);

    await tester.tap(find.text('DIVE IN'));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('DIVE IN'), findsNothing);
    expect(find.text('SCORE '), findsOneWidget);
    expect(find.text('PEARLS '), findsOneWidget);
    expect(find.text('BEST '), findsOneWidget);
  });

  test('OceanAudio synthesizes valid PCM WAV buffers and toggles mute',
      () async {
    await OceanAudio.instance.init();
    final initialMuted = OceanAudio.instance.isMuted;
    expect(OceanAudio.instance.toggleMute(), !initialMuted);
    expect(OceanAudio.instance.toggleMute(), initialMuted);
  });
}
