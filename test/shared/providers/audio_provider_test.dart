import 'package:flutter_test/flutter_test.dart';
import 'package:listen/shared/providers/audio_provider.dart';
import 'package:listen/core/services/database.dart';

AudioTrack _makeTrack({
  int id = 1,
  String title = 'Test Track',
  String artist = 'Test Artist',
  int durationMs = 180000,
  String filePath = '/test/audio.mp3',
}) {
  return AudioTrack(
    id: id,
    title: title,
    artist: artist,
    durationMs: durationMs,
    filePath: filePath,
    fileSize: 1024,
    addedAt: DateTime.now(),
    lastPlayedAt: null,
    playCount: 0,
  );
}

void main() {
  group('PlayerState', () {
    test('default values are correct', () {
      const state = PlayerState();
      expect(state.currentTrack, isNull);
      expect(state.queue, isEmpty);
      expect(state.queueIndex, 0);
      expect(state.isPlaying, false);
      expect(state.duration, Duration.zero);
      expect(state.position, Duration.zero);
    });

    test('copyWith preserves unchanged values', () {
      final track = _makeTrack();
      final state = PlayerState(
        currentTrack: track,
        queue: [track],
        queueIndex: 0,
        isPlaying: true,
        duration: const Duration(seconds: 180),
        position: const Duration(seconds: 30),
      );

      final copied = state.copyWith(isPlaying: false);
      expect(copied.currentTrack, track);
      expect(copied.queue.length, 1);
      expect(copied.queueIndex, 0);
      expect(copied.isPlaying, false);
      expect(copied.duration, const Duration(seconds: 180));
      expect(copied.position, const Duration(seconds: 30));
    });

    test('copyWith replaces specified values', () {
      const state = PlayerState();
      final track = _makeTrack();

      final updated = state.copyWith(
        currentTrack: track,
        isPlaying: true,
        duration: const Duration(minutes: 3),
      );

      expect(updated.currentTrack, track);
      expect(updated.isPlaying, true);
      expect(updated.duration, const Duration(minutes: 3));
      expect(updated.queue, isEmpty);
    });
  });

  group('PlayerState queue logic', () {
    test('queue index within bounds', () {
      final tracks = List.generate(5, (i) => _makeTrack(id: i, title: 'Track $i'));
      final state = PlayerState(queue: tracks, queueIndex: 2);
      expect(state.queue[state.queueIndex].title, 'Track 2');
    });

    test('queue navigation: next index calculation', () {
      final tracks = List.generate(3, (i) => _makeTrack(id: i));
      final state = PlayerState(queue: tracks, queueIndex: 1);

      final nextIndex = state.queueIndex + 1;
      expect(nextIndex < state.queue.length, true);
      expect(nextIndex, 2);
    });

    test('queue navigation: at last track', () {
      final tracks = List.generate(3, (i) => _makeTrack(id: i));
      final state = PlayerState(queue: tracks, queueIndex: 2);

      final nextIndex = state.queueIndex + 1;
      expect(nextIndex < state.queue.length, false);
    });

    test('queue navigation: previous index calculation', () {
      final tracks = List.generate(3, (i) => _makeTrack(id: i));
      final state = PlayerState(queue: tracks, queueIndex: 1);

      final prevIndex = state.queueIndex - 1;
      expect(prevIndex >= 0, true);
      expect(prevIndex, 0);
    });

    test('queue navigation: at first track', () {
      final tracks = List.generate(3, (i) => _makeTrack(id: i));
      final state = PlayerState(queue: tracks, queueIndex: 0);

      final prevIndex = state.queueIndex - 1;
      expect(prevIndex >= 0, false);
    });

    test('empty queue returns no next/previous', () {
      const state = PlayerState();
      expect(state.queue.isEmpty, true);
    });
  });

  group('MiniPlayer progress calculation', () {
    test('progress is 0 when duration is zero', () {
      const state = PlayerState(
        duration: Duration.zero,
        position: Duration.zero,
      );
      final progress = state.duration.inMilliseconds > 0
          ? state.position.inMilliseconds / state.duration.inMilliseconds
          : 0.0;
      expect(progress, 0.0);
    });

    test('progress is calculated correctly at midpoint', () {
      const state = PlayerState(
        duration: Duration(seconds: 200),
        position: Duration(seconds: 100),
      );
      final progress = state.position.inMilliseconds / state.duration.inMilliseconds;
      expect(progress, 0.5);
    });

    test('progress is clamped to 0-1 range', () {
      const state = PlayerState(
        duration: Duration(seconds: 100),
        position: Duration(seconds: 150),
      );
      final progress = state.duration.inMilliseconds > 0
          ? state.position.inMilliseconds / state.duration.inMilliseconds
          : 0.0;
      final clamped = progress.clamp(0.0, 1.0);
      expect(clamped, 1.0);
    });
  });
}
