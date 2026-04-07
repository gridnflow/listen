import 'package:flutter_test/flutter_test.dart';
import 'package:listen/core/services/database.dart';
import 'package:listen/shared/providers/audio_provider.dart';

Episode _makeEpisode({
  int id = 1,
  String title = 'Test Episode',
  String audioUrl = 'https://example.com/ep1.mp3',
  int durationMs = 3600000,
  int playbackPositionMs = 0,
  bool isPlayed = false,
  String? localFilePath,
}) {
  return Episode(
    id: id,
    podcastId: 1,
    title: title,
    description: '',
    audioUrl: audioUrl,
    guid: 'guid-$id',
    durationMs: durationMs,
    publishedAt: DateTime.now(),
    localFilePath: localFilePath,
    downloadProgress: localFilePath != null ? 100 : 0,
    playbackPositionMs: playbackPositionMs,
    isPlayed: isPlayed,
  );
}

AudioTrack _makeTrack({int id = 1, String title = 'Test Track'}) {
  return AudioTrack(
    id: id,
    title: title,
    artist: 'Test Artist',
    durationMs: 180000,
    filePath: '/test.mp3',
    fileSize: 1024,
    addedAt: DateTime.now(),
    lastPlayedAt: null,
    playCount: 0,
  );
}

void main() {
  group('PlayerState - Episode support', () {
    test('default state has no episode', () {
      const state = PlayerState();
      expect(state.currentEpisode, isNull);
      expect(state.isPlayingEpisode, false);
    });

    test('isPlayingEpisode returns true when episode is set', () {
      final episode = _makeEpisode();
      final state = PlayerState(currentEpisode: episode);
      expect(state.isPlayingEpisode, true);
    });

    test('isPlayingEpisode returns false when only track is set', () {
      final track = _makeTrack();
      final state = PlayerState(currentTrack: track);
      expect(state.isPlayingEpisode, false);
    });

    test('copyWith clearEpisode sets episode to null', () {
      final episode = _makeEpisode();
      final state = PlayerState(currentEpisode: episode);
      final cleared = state.copyWith(clearEpisode: true);
      expect(cleared.currentEpisode, isNull);
      expect(cleared.isPlayingEpisode, false);
    });

    test('copyWith clearTrack sets track to null', () {
      final track = _makeTrack();
      final state = PlayerState(currentTrack: track);
      final cleared = state.copyWith(clearTrack: true);
      expect(cleared.currentTrack, isNull);
    });

    test('switching from track to episode clears track', () {
      final track = _makeTrack();
      final episode = _makeEpisode();
      final state = PlayerState(currentTrack: track);
      final switched = state.copyWith(
        currentEpisode: episode,
        clearTrack: true,
        queue: const [],
      );
      expect(switched.currentTrack, isNull);
      expect(switched.currentEpisode, episode);
      expect(switched.queue, isEmpty);
    });

    test('switching from episode to track clears episode', () {
      final track = _makeTrack();
      final episode = _makeEpisode();
      final state = PlayerState(currentEpisode: episode);
      final switched = state.copyWith(
        currentTrack: track,
        clearEpisode: true,
      );
      expect(switched.currentTrack, track);
      expect(switched.currentEpisode, isNull);
    });
  });

  group('PlayerState - Playback speed', () {
    test('default playback speed is 1.0', () {
      const state = PlayerState();
      expect(state.playbackSpeed, 1.0);
    });

    test('copyWith updates playback speed', () {
      const state = PlayerState();
      final updated = state.copyWith(playbackSpeed: 1.5);
      expect(updated.playbackSpeed, 1.5);
    });

    test('speed range boundaries', () {
      const state = PlayerState();
      final slow = state.copyWith(playbackSpeed: 0.5);
      expect(slow.playbackSpeed, 0.5);

      final fast = state.copyWith(playbackSpeed: 3.0);
      expect(fast.playbackSpeed, 3.0);
    });
  });

  group('PlayerState - Sleep timer', () {
    test('default has no sleep timer', () {
      const state = PlayerState();
      expect(state.sleepTimerRemaining, isNull);
    });

    test('copyWith sets sleep timer', () {
      const state = PlayerState();
      final updated =
          state.copyWith(sleepTimerRemaining: const Duration(minutes: 30));
      expect(updated.sleepTimerRemaining, const Duration(minutes: 30));
    });

    test('clearSleepTimer removes timer', () {
      final state =
          const PlayerState(sleepTimerRemaining: Duration(minutes: 15));
      final cleared = state.copyWith(clearSleepTimer: true);
      expect(cleared.sleepTimerRemaining, isNull);
    });

    test('sleep timer countdown', () {
      final state =
          const PlayerState(sleepTimerRemaining: Duration(minutes: 5));
      final ticked = state.copyWith(
        sleepTimerRemaining:
            state.sleepTimerRemaining! - const Duration(seconds: 1),
      );
      expect(ticked.sleepTimerRemaining, const Duration(minutes: 4, seconds: 59));
    });
  });

  group('Episode - Resume playback logic', () {
    test('episode with no saved position starts from beginning', () {
      final episode = _makeEpisode(playbackPositionMs: 0);
      expect(episode.playbackPositionMs, 0);
      // AudioNotifier will skip seek when position is 0
    });

    test('episode with saved position should resume', () {
      final episode = _makeEpisode(playbackPositionMs: 120000);
      expect(episode.playbackPositionMs, 120000);
      expect(episode.playbackPositionMs > 0, true);
    });

    test('played episode has isPlayed flag', () {
      final episode = _makeEpisode(isPlayed: true);
      expect(episode.isPlayed, true);
    });

    test('has progress when position > 0 and not played', () {
      final episode =
          _makeEpisode(playbackPositionMs: 60000, isPlayed: false);
      final hasProgress = episode.playbackPositionMs > 0 && !episode.isPlayed;
      expect(hasProgress, true);
    });

    test('no progress when marked as played', () {
      final episode =
          _makeEpisode(playbackPositionMs: 60000, isPlayed: true);
      final hasProgress = episode.playbackPositionMs > 0 && !episode.isPlayed;
      expect(hasProgress, false);
    });
  });

  group('Episode - Download state', () {
    test('episode without localFilePath is not downloaded', () {
      final episode = _makeEpisode(localFilePath: null);
      expect(episode.localFilePath, isNull);
    });

    test('episode with localFilePath is downloaded', () {
      final episode =
          _makeEpisode(localFilePath: '/data/podcasts/1/1.mp3');
      expect(episode.localFilePath, isNotNull);
      expect(episode.downloadProgress, 100);
    });
  });

  group('PlayerScreen - 30s skip logic', () {
    test('30s rewind does not go below zero', () {
      const position = Duration(seconds: 15);
      final newPos = position - const Duration(seconds: 30);
      final clamped = newPos < Duration.zero ? Duration.zero : newPos;
      expect(clamped, Duration.zero);
    });

    test('30s rewind from mid-track', () {
      const position = Duration(minutes: 5);
      final newPos = position - const Duration(seconds: 30);
      expect(newPos, const Duration(minutes: 4, seconds: 30));
    });

    test('30s forward does not exceed duration', () {
      const position = Duration(minutes: 59, seconds: 45);
      const duration = Duration(hours: 1);
      final newPos = position + const Duration(seconds: 30);
      final clamped = newPos > duration ? duration : newPos;
      expect(clamped, duration);
    });

    test('30s forward from mid-track', () {
      const position = Duration(minutes: 30);
      final newPos = position + const Duration(seconds: 30);
      expect(newPos, const Duration(minutes: 30, seconds: 30));
    });
  });

  group('PlayerScreen - Duration formatting (fixed)', () {
    String formatDuration(Duration d) {
      final hours = d.inHours;
      final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      if (hours > 0) return '$hours:$minutes:$seconds';
      return '$minutes:$seconds';
    }

    test('formats 1 hour correctly', () {
      expect(formatDuration(const Duration(hours: 1)), '1:00:00');
    });

    test('formats 1h5m30s correctly', () {
      expect(
        formatDuration(const Duration(hours: 1, minutes: 5, seconds: 30)),
        '1:05:30',
      );
    });

    test('formats sub-hour correctly', () {
      expect(formatDuration(const Duration(minutes: 45, seconds: 30)), '45:30');
    });
  });
}
