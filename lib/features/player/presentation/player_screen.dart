import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/audio_provider.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(audioProvider);
    final title = playerState.currentTrack?.title ?? 'No track';
    final subtitle = playerState.currentTrack?.artist ?? '';
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Now Playing',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6C63FF).withAlpha(18),
              Colors.transparent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.center,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(),
                // Album art
                Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF4A3FA8).withAlpha(200),
                        const Color(0xFF1A1560).withAlpha(240),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withAlpha(60),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.music_note_rounded,
                    size: 80,
                    color: Colors.white.withAlpha(120),
                  ),
                ),
                const Spacer(),
                // Title & artist
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (playerState.sleepTimerRemaining != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Sleep in ${_formatDuration(playerState.sleepTimerRemaining!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                // Seek bar
                StreamBuilder<Duration>(
                  stream: ref.read(audioProvider.notifier).positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration = playerState.duration;
                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            activeTrackColor: theme.colorScheme.primary,
                            inactiveTrackColor:
                                theme.colorScheme.onSurface.withAlpha(30),
                            thumbColor: theme.colorScheme.primary,
                            overlayColor:
                                theme.colorScheme.primary.withAlpha(30),
                          ),
                          child: Slider(
                            value: duration.inMilliseconds > 0
                                ? (position.inMilliseconds /
                                        duration.inMilliseconds)
                                    .clamp(0.0, 1.0)
                                : 0,
                            onChanged: (value) {
                              ref.read(audioProvider.notifier).seek(
                                    Duration(
                                      milliseconds:
                                          (value * duration.inMilliseconds)
                                              .round(),
                                    ),
                                  );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 40,
                      icon: const Icon(Icons.skip_previous_rounded),
                      onPressed: () =>
                          ref.read(audioProvider.notifier).playPrevious(),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(80, 80),
                        shape: const CircleBorder(),
                      ),
                      onPressed: () =>
                          ref.read(audioProvider.notifier).togglePlayPause(),
                      child: Icon(
                        playerState.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 38,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      iconSize: 40,
                      icon: const Icon(Icons.skip_next_rounded),
                      onPressed: () =>
                          ref.read(audioProvider.notifier).playNext(),
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
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

    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Sleep Timer',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
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
            ...options.map(
              (opt) => ListTile(
                title: Text(opt.$1),
                onTap: () {
                  ref.read(audioProvider.notifier).startSleepTimer(opt.$2);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) return '$hours:$minutes:$seconds';
    return '$minutes:$seconds';
  }
}
