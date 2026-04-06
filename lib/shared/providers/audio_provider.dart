import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/services/database.dart';

class PlayerState {
  final AudioTrack? currentTrack;
  final List<AudioTrack> queue;
  final int queueIndex;
  final bool isPlaying;
  final Duration duration;

  const PlayerState({
    this.currentTrack,
    this.queue = const [],
    this.queueIndex = 0,
    this.isPlaying = false,
    this.duration = Duration.zero,
  });

  PlayerState copyWith({
    AudioTrack? currentTrack,
    List<AudioTrack>? queue,
    int? queueIndex,
    bool? isPlaying,
    Duration? duration,
  }) {
    return PlayerState(
      currentTrack: currentTrack ?? this.currentTrack,
      queue: queue ?? this.queue,
      queueIndex: queueIndex ?? this.queueIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      duration: duration ?? this.duration,
    );
  }
}

class AudioNotifier extends StateNotifier<PlayerState> {
  final AudioPlayer _player = AudioPlayer();

  AudioNotifier() : super(const PlayerState()) {
    _player.playerStateStream.listen((playerState) {
      state = state.copyWith(isPlaying: playerState.playing);
    });
    _player.durationStream.listen((duration) {
      if (duration != null) {
        state = state.copyWith(duration: duration);
      }
    });
    _player.processingStateStream.listen((processingState) {
      if (processingState == ProcessingState.completed) {
        playNext();
      }
    });
  }

  Stream<Duration> get positionStream => _player.positionStream;

  Future<void> playTrack(AudioTrack track) async {
    state = state.copyWith(currentTrack: track);
    await _player.setFilePath(track.filePath);
    await _player.play();
    AppDatabase.instance.updateLastPlayed(track.id);
  }

  Future<void> playQueue(List<AudioTrack> tracks, {int startIndex = 0}) async {
    state = state.copyWith(queue: tracks, queueIndex: startIndex);
    if (tracks.isNotEmpty) {
      await playTrack(tracks[startIndex]);
    }
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> playNext() async {
    if (state.queue.isEmpty) return;
    final nextIndex = state.queueIndex + 1;
    if (nextIndex < state.queue.length) {
      state = state.copyWith(queueIndex: nextIndex);
      await playTrack(state.queue[nextIndex]);
    } else {
      await _player.stop();
      state = state.copyWith(isPlaying: false);
    }
  }

  Future<void> playPrevious() async {
    if (state.queue.isEmpty) return;
    final prevIndex = state.queueIndex - 1;
    if (prevIndex >= 0) {
      state = state.copyWith(queueIndex: prevIndex);
      await playTrack(state.queue[prevIndex]);
    } else {
      await _player.seek(Duration.zero);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

final audioProvider = StateNotifierProvider<AudioNotifier, PlayerState>((ref) {
  return AudioNotifier();
});
