import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/audio_provider.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(audioProvider);
    final isEpisode = playerState.isPlayingEpisode;
    final title =
        playerState.currentTrack?.title ?? playerState.currentEpisode?.title ?? 'No track';
    final subtitle = playerState.currentTrack?.artist ?? '';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(isEpisode ? 'Now Playing - Podcast' : 'Now Playing'),
        actions: [
          if (isEpisode)
            IconButton(
              icon: const Icon(Icons.speed),
              tooltip: 'Playback speed',
              onPressed: () => _showSpeedSheet(context, ref),
            ),
          IconButton(
            icon: Icon(
              playerState.sleepTimerRemaining != null
                  ? Icons.timer
                  : Icons.timer_outlined,
            ),
            tooltip: 'Sleep timer',
            onPressed: () => _showSleepTimerSheet(context, ref),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(),
            // Album art placeholder
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isEpisode ? Icons.podcasts : Icons.music_note,
                size: 80,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            // Track info
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            if (playerState.sleepTimerRemaining != null) ...[
              const SizedBox(height: 4),
              Text(
                'Sleep in ${_formatDuration(playerState.sleepTimerRemaining!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
            if (isEpisode && playerState.playbackSpeed != 1.0) ...[
              const SizedBox(height: 4),
              Text(
                '${playerState.playbackSpeed}x',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
            const SizedBox(height: 24),
            // Progress bar
            StreamBuilder<Duration>(
              stream: ref.read(audioProvider.notifier).positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = playerState.duration;
                return Column(
                  children: [
                    Slider(
                      value: duration.inMilliseconds > 0
                          ? (position.inMilliseconds / duration.inMilliseconds)
                              .clamp(0.0, 1.0)
                          : 0,
                      onChanged: (value) {
                        ref.read(audioProvider.notifier).seek(
                              Duration(
                                milliseconds:
                                    (value * duration.inMilliseconds).round(),
                              ),
                            );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(position)),
                          Text(_formatDuration(duration)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isEpisode)
                  // 30s rewind for podcasts
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.replay_30),
                    onPressed: () {
                      final newPos = playerState.position -
                          const Duration(seconds: 30);
                      ref.read(audioProvider.notifier).seek(
                            newPos < Duration.zero
                                ? Duration.zero
                                : newPos,
                          );
                    },
                  )
                else
                  IconButton(
                    iconSize: 36,
                    icon: const Icon(Icons.skip_previous),
                    onPressed: () =>
                        ref.read(audioProvider.notifier).playPrevious(),
                  ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(72, 72),
                    shape: const CircleBorder(),
                  ),
                  icon: Icon(
                    playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 36,
                  ),
                  label: const SizedBox.shrink(),
                  onPressed: () =>
                      ref.read(audioProvider.notifier).togglePlayPause(),
                ),
                const SizedBox(width: 16),
                if (isEpisode)
                  // 30s forward for podcasts
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.forward_30),
                    onPressed: () {
                      final newPos = playerState.position +
                          const Duration(seconds: 30);
                      ref.read(audioProvider.notifier).seek(
                            newPos > playerState.duration
                                ? playerState.duration
                                : newPos,
                          );
                    },
                  )
                else
                  IconButton(
                    iconSize: 36,
                    icon: const Icon(Icons.skip_next),
                    onPressed: () =>
                        ref.read(audioProvider.notifier).playNext(),
                  ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  void _showSpeedSheet(BuildContext context, WidgetRef ref) {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0];
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Playback Speed',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ...speeds.map((speed) {
              final current = ref.read(audioProvider).playbackSpeed;
              return ListTile(
                title: Text('${speed}x'),
                trailing:
                    speed == current ? const Icon(Icons.check) : null,
                onTap: () {
                  ref.read(audioProvider.notifier).setPlaybackSpeed(speed);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showSleepTimerSheet(BuildContext context, WidgetRef ref) {
    final hasTimer = ref.read(audioProvider).sleepTimerRemaining != null;
    final options = [
      ('5 minutes', const Duration(minutes: 5)),
      ('10 minutes', const Duration(minutes: 10)),
      ('15 minutes', const Duration(minutes: 15)),
      ('30 minutes', const Duration(minutes: 30)),
      ('45 minutes', const Duration(minutes: 45)),
      ('1 hour', const Duration(hours: 1)),
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Sleep Timer',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            if (hasTimer)
              ListTile(
                leading: const Icon(Icons.timer_off),
                title: const Text('Cancel timer'),
                onTap: () {
                  ref.read(audioProvider.notifier).cancelSleepTimer();
                  Navigator.pop(context);
                },
              ),
            ...options.map((opt) => ListTile(
                  title: Text(opt.$1),
                  onTap: () {
                    ref.read(audioProvider.notifier).startSleepTimer(opt.$2);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
