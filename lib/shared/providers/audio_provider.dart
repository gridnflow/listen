import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/services/database.dart';

class PlayerState {
  final AudioTrack? currentTrack;
  final List<AudioTrack> queue;
  final int queueIndex;
  final bool isPlaying;
  final Duration duration;
  final Duration position;
  final Duration? sleepTimerRemaining;

  const PlayerState({
    this.currentTrack,
    this.queue = const [],
    this.queueIndex = 0,
    this.isPlaying = false,
    this.duration = Duration.zero,
    this.position = Duration.zero,
    this.sleepTimerRemaining,
  });

  PlayerState copyWith({
    AudioTrack? currentTrack,
    List<AudioTrack>? queue,
    int? queueIndex,
    bool? isPlaying,
    Duration? duration,
    Duration? position,
    Duration? sleepTimerRemaining,
    bool clearTrack = false,
    bool clearSleepTimer = false,
  }) {
    return PlayerState(
      currentTrack: clearTrack ? null : (currentTrack ?? this.currentTrack),
      queue: queue ?? this.queue,
      queueIndex: queueIndex ?? this.queueIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      sleepTimerRemaining: clearSleepTimer
          ? null
          : (sleepTimerRemaining ?? this.sleepTimerRemaining),
    );
  }
}

class ListenAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  ListenAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState);
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _onTrackCompleted?.call();
      }
    });
  }

  AudioPlayer get player => _player;
  void Function()? _onTrackCompleted;
  void Function()? _onSkipToPrevious;

  set onTrackCompleted(void Function()? callback) {
    _onTrackCompleted = callback;
  }

  set onSkipToPrevious(void Function()? callback) {
    _onSkipToPrevious = callback;
  }

  Future<void> setTrack(AudioTrack track) async {
    await _player.setFilePath(track.filePath);
    mediaItem.add(MediaItem(
      id: track.filePath,
      title: track.title,
      artist: track.artist,
      duration: Duration(milliseconds: track.durationMs),
    ));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    _onTrackCompleted?.call();
  }

  @override
  Future<void> skipToPrevious() async {
    _onSkipToPrevious?.call();
  }

  void _broadcastState(PlaybackEvent event) {
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    ));
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}

class AudioNotifier extends StateNotifier<PlayerState> {
  final ListenAudioHandler _handler;
  Timer? _sleepTimer;
  Timer? _sleepCountdown;
  late final List<StreamSubscription<dynamic>> _subscriptions;

  AudioNotifier(this._handler) : super(const PlayerState()) {
    _subscriptions = [
      _handler.player.playerStateStream.listen((playerState) {
        state = state.copyWith(isPlaying: playerState.playing);
      }),
      _handler.player.durationStream.listen((duration) {
        if (duration != null) {
          state = state.copyWith(duration: duration);
        }
      }),
      _handler.player.positionStream.listen((position) {
        state = state.copyWith(position: position);
      }),
    ];
    _handler.onTrackCompleted = playNext;
    _handler.onSkipToPrevious = playPrevious;
  }

  Stream<Duration> get positionStream => _handler.player.positionStream;

  Future<void> playTrack(AudioTrack track) async {
    state = state.copyWith(currentTrack: track);
    await _handler.setTrack(track);
    await _handler.play();
    AppDatabase.instance.updateLastPlayed(track.id);
  }

  Future<void> playQueue(List<AudioTrack> tracks, {int startIndex = 0}) async {
    state = state.copyWith(queue: tracks, queueIndex: startIndex);
    if (tracks.isNotEmpty) {
      await playTrack(tracks[startIndex]);
    }
  }

  Future<void> togglePlayPause() async {
    if (_handler.player.playing) {
      await _handler.pause();
    } else {
      await _handler.play();
    }
  }

  Future<void> seek(Duration position) async {
    await _handler.seek(position);
  }

  Future<void> stop() async {
    await _handler.stop();
    state = const PlayerState();
  }

  Future<void> playNext() async {
    if (state.queue.isEmpty) return;
    final nextIndex = state.queueIndex + 1;
    if (nextIndex < state.queue.length) {
      state = state.copyWith(queueIndex: nextIndex);
      await playTrack(state.queue[nextIndex]);
    } else {
      await _handler.stop();
      state = state.copyWith(isPlaying: false, clearTrack: true);
    }
  }

  Future<void> playPrevious() async {
    if (state.queue.isEmpty) return;
    final prevIndex = state.queueIndex - 1;
    if (prevIndex >= 0) {
      state = state.copyWith(queueIndex: prevIndex);
      await playTrack(state.queue[prevIndex]);
    } else {
      await _handler.seek(Duration.zero);
    }
  }

  void startSleepTimer(Duration duration) {
    cancelSleepTimer();
    state = state.copyWith(sleepTimerRemaining: duration);

    _sleepTimer = Timer(duration, () async {
      await _handler.pause();
      state = state.copyWith(clearSleepTimer: true);
    });

    _sleepCountdown = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = state.sleepTimerRemaining;
      if (remaining != null && remaining.inSeconds > 0) {
        state = state.copyWith(
          sleepTimerRemaining: remaining - const Duration(seconds: 1),
        );
      }
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepCountdown?.cancel();
    _sleepTimer = null;
    _sleepCountdown = null;
    state = state.copyWith(clearSleepTimer: true);
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _sleepCountdown?.cancel();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _handler.dispose();
    super.dispose();
  }
}

final audioHandlerProvider = Provider<ListenAudioHandler>((ref) {
  throw UnimplementedError('Must be overridden in main.dart');
});

final audioProvider =
    StateNotifierProvider<AudioNotifier, PlayerState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return AudioNotifier(handler);
});
