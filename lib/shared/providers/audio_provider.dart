import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/services/database.dart';

class PlayerState {
  final AudioTrack? currentTrack;
  final Episode? currentEpisode;
  final List<AudioTrack> queue;
  final int queueIndex;
  final bool isPlaying;
  final Duration duration;
  final Duration position;
  final double playbackSpeed;
  final Duration? sleepTimerRemaining;

  const PlayerState({
    this.currentTrack,
    this.currentEpisode,
    this.queue = const [],
    this.queueIndex = 0,
    this.isPlaying = false,
    this.duration = Duration.zero,
    this.position = Duration.zero,
    this.playbackSpeed = 1.0,
    this.sleepTimerRemaining,
  });

  bool get isPlayingEpisode => currentEpisode != null;

  PlayerState copyWith({
    AudioTrack? currentTrack,
    Episode? currentEpisode,
    List<AudioTrack>? queue,
    int? queueIndex,
    bool? isPlaying,
    Duration? duration,
    Duration? position,
    double? playbackSpeed,
    Duration? sleepTimerRemaining,
    bool clearEpisode = false,
    bool clearTrack = false,
    bool clearSleepTimer = false,
  }) {
    return PlayerState(
      currentTrack: clearTrack ? null : (currentTrack ?? this.currentTrack),
      currentEpisode:
          clearEpisode ? null : (currentEpisode ?? this.currentEpisode),
      queue: queue ?? this.queue,
      queueIndex: queueIndex ?? this.queueIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
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

  Future<void> setEpisode(Episode episode, {String? artworkUrl}) async {
    if (episode.localFilePath != null) {
      await _player.setFilePath(episode.localFilePath!);
    } else {
      await _player.setUrl(episode.audioUrl);
    }
    mediaItem.add(MediaItem(
      id: episode.audioUrl,
      title: episode.title,
      artUri: artworkUrl != null ? Uri.tryParse(artworkUrl) : null,
      duration: Duration(milliseconds: episode.durationMs),
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
  Timer? _positionSaver;

  AudioNotifier(this._handler) : super(const PlayerState()) {
    _handler.player.playerStateStream.listen((playerState) {
      state = state.copyWith(isPlaying: playerState.playing);
    });
    _handler.player.durationStream.listen((duration) {
      if (duration != null) {
        state = state.copyWith(duration: duration);
      }
    });
    _handler.player.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });
    _handler.onTrackCompleted = playNext;
    _handler.onSkipToPrevious = playPrevious;

    // Save episode playback position every 5 seconds
    _positionSaver = Timer.periodic(const Duration(seconds: 5), (_) {
      _saveEpisodePosition();
    });
  }

  Stream<Duration> get positionStream => _handler.player.positionStream;

  // --- Track playback ---

  Future<void> playTrack(AudioTrack track) async {
    await _saveEpisodePosition();
    state = state.copyWith(
      currentTrack: track,
      clearEpisode: true,
    );
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

  // --- Episode playback ---

  Future<void> playEpisode(Episode episode, {String? artworkUrl}) async {
    await _saveEpisodePosition();
    state = state.copyWith(
      currentEpisode: episode,
      clearTrack: true,
      queue: const [],
    );
    await _handler.setEpisode(episode, artworkUrl: artworkUrl);

    // Resume from saved position
    if (episode.playbackPositionMs > 0) {
      await _handler.seek(Duration(milliseconds: episode.playbackPositionMs));
    }

    await _handler.play();
  }

  // --- Common controls ---

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
    await _saveEpisodePosition();
    await _handler.stop();
    state = const PlayerState();
  }

  Future<void> playNext() async {
    if (state.isPlayingEpisode) {
      // For episodes, mark as played and stop
      if (state.currentEpisode != null) {
        await AppDatabase.instance.markEpisodePlayed(state.currentEpisode!.id);
      }
      await _handler.stop();
      state = state.copyWith(isPlaying: false);
      return;
    }
    if (state.queue.isEmpty) return;
    final nextIndex = state.queueIndex + 1;
    if (nextIndex < state.queue.length) {
      state = state.copyWith(queueIndex: nextIndex);
      await playTrack(state.queue[nextIndex]);
    } else {
      await _handler.stop();
      state = state.copyWith(isPlaying: false);
    }
  }

  Future<void> playPrevious() async {
    if (state.isPlayingEpisode) {
      await _handler.seek(Duration.zero);
      return;
    }
    if (state.queue.isEmpty) return;
    final prevIndex = state.queueIndex - 1;
    if (prevIndex >= 0) {
      state = state.copyWith(queueIndex: prevIndex);
      await playTrack(state.queue[prevIndex]);
    } else {
      await _handler.seek(Duration.zero);
    }
  }

  // --- Playback speed ---

  Future<void> setPlaybackSpeed(double speed) async {
    await _handler.player.setSpeed(speed);
    state = state.copyWith(playbackSpeed: speed);
  }

  // --- Sleep timer ---

  void startSleepTimer(Duration duration) {
    cancelSleepTimer();
    state = state.copyWith(sleepTimerRemaining: duration);

    _sleepTimer = Timer(duration, () async {
      await _handler.pause();
      state = state.copyWith(clearSleepTimer: true);
    });

    // Update countdown every second
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

  // --- Episode position saving ---

  Future<void> _saveEpisodePosition() async {
    if (state.currentEpisode != null && state.position.inMilliseconds > 0) {
      await AppDatabase.instance.updateEpisodePlaybackPosition(
        state.currentEpisode!.id,
        state.position.inMilliseconds,
      );
    }
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _sleepCountdown?.cancel();
    _positionSaver?.cancel();
    _saveEpisodePosition();
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
