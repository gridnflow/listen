import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/audio_provider.dart';
import '../../../shared/providers/library_provider.dart';
import '../../../shared/widgets/track_list_tile.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(allTracksProvider);
    final libraryState = ref.watch(libraryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: tracksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tracks) => CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 110,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Library',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6C63FF).withAlpha(38),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.youtube_searched_for),
                  tooltip: 'Download from YouTube',
                  onPressed: () => context.push('/library/youtube'),
                ),
                IconButton(
                  icon: libraryState.isScanning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.phone_android),
                  tooltip: 'Scan device audio',
                  onPressed: libraryState.isScanning
                      ? null
                      : () async {
                          final count = await ref
                              .read(libraryProvider.notifier)
                              .scanDeviceAudio();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Found $count new tracks')),
                            );
                          }
                        },
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Import files',
                  onPressed: () =>
                      ref.read(libraryProvider.notifier).importFiles(),
                ),
              ],
            ),
            if (tracks.isEmpty)
              const SliverFillRemaining(child: _EmptyLibrary())
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Text(
                    '${tracks.length} ${tracks.length == 1 ? 'track' : 'tracks'}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final track = tracks[index];
                    return TrackListTile(
                      track: track,
                      onTap: () => ref
                          .read(audioProvider.notifier)
                          .playQueue(tracks, startIndex: index),
                      onDelete: () =>
                          ref.read(libraryProvider.notifier).deleteTrack(track),
                    );
                  },
                  childCount: tracks.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_music_outlined,
            size: 72,
            color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
          ),
          const SizedBox(height: 20),
          Text(
            'Your library is empty',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the phone icon to scan device audio\nor + to import files',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
