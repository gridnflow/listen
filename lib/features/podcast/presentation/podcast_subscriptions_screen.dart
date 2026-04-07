import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/podcast_provider.dart';
import 'widgets/podcast_card.dart';

class PodcastSubscriptionsScreen extends ConsumerWidget {
  const PodcastSubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final podcastsAsync = ref.watch(subscribedPodcastsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Podcasts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh all',
            onPressed: () async {
              await ref.read(podcastActionsProvider).refreshAllPodcasts();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feeds refreshed')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search podcasts',
            onPressed: () => context.go('/podcasts/search'),
          ),
        ],
      ),
      body: podcastsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (podcasts) {
          if (podcasts.isEmpty) {
            return const _EmptyPodcasts();
          }
          return ListView.builder(
            itemCount: podcasts.length,
            itemBuilder: (context, index) {
              final podcast = podcasts[index];
              return PodcastCard(
                podcast: podcast,
                onTap: () => context.go('/podcasts/${podcast.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyPodcasts extends StatelessWidget {
  const _EmptyPodcasts();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.podcasts,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No podcast subscriptions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the search icon to find podcasts',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
