import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/audio_provider.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(audioProvider);
    final track = playerState.currentTrack;
    final episode = playerState.currentEpisode;

    if (track == null && episode == null) return const SizedBox.shrink();

    final title = track?.title ?? episode?.title ?? '';
    final subtitle = track?.artist ?? '';
    final isEpisode = episode != null;

    final theme = Theme.of(context);
    final progressPercent = playerState.duration.inMilliseconds > 0
        ? playerState.position.inMilliseconds /
            playerState.duration.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTap: () => context.push('/player'),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant,
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: progressPercent.clamp(0.0, 1.0),
              minHeight: 2,
              backgroundColor: Colors.transparent,
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      isEpisode ? Icons.podcasts : Icons.music_note,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      playerState.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 28,
                    ),
                    onPressed: () =>
                        ref.read(audioProvider.notifier).togglePlayPause(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, size: 24),
                    onPressed: () =>
                        ref.read(audioProvider.notifier).playNext(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
