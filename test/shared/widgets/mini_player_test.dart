import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listen/core/services/database.dart';
import 'package:listen/shared/providers/audio_provider.dart';
import 'package:listen/shared/widgets/mini_player.dart';

AudioTrack _makeTrack({
  String title = 'Test Song',
  String artist = 'Test Artist',
}) {
  return AudioTrack(
    id: 1,
    title: title,
    artist: artist,
    durationMs: 180000,
    filePath: '/test.mp3',
    fileSize: 1024,
    addedAt: DateTime.now(),
    lastPlayedAt: null,
    playCount: 0,
  );
}

class FakeAudioNotifier extends StateNotifier<PlayerState>
    implements AudioNotifier {
  FakeAudioNotifier(super.state);

  @override
  Future<void> playTrack(AudioTrack track) async {}
  @override
  Future<void> playQueue(List<AudioTrack> tracks, {int startIndex = 0}) async {}
  @override
  Future<void> togglePlayPause() async {
    state = state.copyWith(isPlaying: !state.isPlaying);
  }

  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> stop() async {
    state = const PlayerState();
  }
  @override
  Future<void> playNext() async {}
  @override
  Future<void> playPrevious() async {}
  @override
  Stream<Duration> get positionStream => const Stream.empty();
}

Widget _buildTestWidget(PlayerState initialState) {
  final notifier = FakeAudioNotifier(initialState);
  return ProviderScope(
    overrides: [
      audioProvider.overrideWith((ref) => notifier),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: Column(
          children: [MiniPlayer()],
        ),
      ),
    ),
  );
}

void main() {
  group('MiniPlayer', () {
    testWidgets('is hidden when no track is playing', (tester) async {
      await tester.pumpWidget(_buildTestWidget(const PlayerState()));
      await tester.pump();

      // SizedBox.shrink should be rendered
      expect(find.byType(GestureDetector), findsNothing);
      expect(find.text('Test Song'), findsNothing);
    });

    testWidgets('shows track info when a track is set', (tester) async {
      final track = _makeTrack(title: 'My Song', artist: 'My Artist');
      await tester.pumpWidget(_buildTestWidget(
        PlayerState(currentTrack: track),
      ));
      await tester.pump();

      expect(find.text('My Song'), findsOneWidget);
      expect(find.text('My Artist'), findsOneWidget);
    });

    testWidgets('shows play icon when paused', (tester) async {
      final track = _makeTrack();
      await tester.pumpWidget(_buildTestWidget(
        PlayerState(currentTrack: track, isPlaying: false),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsNothing);
    });

    testWidgets('shows pause icon when playing', (tester) async {
      final track = _makeTrack();
      await tester.pumpWidget(_buildTestWidget(
        PlayerState(currentTrack: track, isPlaying: true),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    });

    testWidgets('shows skip next button', (tester) async {
      final track = _makeTrack();
      await tester.pumpWidget(_buildTestWidget(
        PlayerState(currentTrack: track),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
    });

    testWidgets('shows progress indicator', (tester) async {
      final track = _makeTrack();
      await tester.pumpWidget(_buildTestWidget(
        PlayerState(
          currentTrack: track,
          duration: const Duration(seconds: 200),
          position: const Duration(seconds: 100),
        ),
      ));
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
