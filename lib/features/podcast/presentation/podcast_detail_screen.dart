import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/database.dart';
import '../../../shared/providers/audio_provider.dart';
import '../../../shared/providers/podcast_provider.dart';
import 'widgets/episode_list_tile.dart';

final _podcastProvider =
    FutureProvider.family<Podcast?, int>((ref, podcastId) async {
  final podcasts = await AppDatabase.instance.getAllPodcasts();
  return podcasts.where((p) => p.id == podcastId).firstOrNull;
});

class PodcastDetailScreen extends ConsumerWidget {
  final int podcastId;

  const PodcastDetailScreen({super.key, required this.podcastId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final podcastAsync = ref.watch(_podcastProvider(podcastId));
    final episodesAsync = ref.watch(podcastEpisodesProvider(podcastId));
    final downloading = ref.watch(downloadingEpisodesProvider);

    final podcast = podcastAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(podcast?.title ?? 'Podcast'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              if (podcast != null) {
                final count = await ref
                    .read(podcastActionsProvider)
                    .refreshPodcast(podcast.id, podcast.feedUrl);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$count new episodes')),
                  );
                }
              }
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'unsubscribe',
                child: Text('Unsubscribe'),
              ),
            ],
            onSelected: (value) async {
              if (value == 'unsubscribe') {
                await ref.read(podcastActionsProvider).unsubscribe(podcastId);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (podcast != null) _PodcastHeader(podcast: podcast),
          const Divider(height: 1),
          Expanded(
            child: episodesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (episodes) {
                if (episodes.isEmpty) {
                  return const Center(child: Text('No episodes yet'));
                }
                return ListView.builder(
                  itemCount: episodes.length,
                  itemBuilder: (context, index) {
                    final episode = episodes[index];
                    return EpisodeListTile(
                      episode: episode,
                      downloadProgress: downloading[episode.id],
                      onPlay: () {
                        ref.read(audioProvider.notifier).playEpisode(
                              episode,
                              artworkUrl: podcast?.artworkUrl,
                            );
                      },
                      onDownload: () {
                        ref
                            .read(downloadingEpisodesProvider.notifier)
                            .downloadEpisode(episode, podcastId);
                      },
                      onDeleteDownload: () {
                        ref
                            .read(downloadingEpisodesProvider.notifier)
                            .deleteDownload(episode.id);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PodcastHeader extends StatelessWidget {
  final Podcast podcast;

  const _PodcastHeader({required this.podcast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 80,
              height: 80,
              child: podcast.artworkUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: podcast.artworkUrl,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.podcasts, size: 40),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  podcast.title,
                  style: theme.textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  podcast.author,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
