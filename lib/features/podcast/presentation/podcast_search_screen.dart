import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/podcast_provider.dart';
import '../data/podcast_api_service.dart';

final _searchQueryProvider = StateProvider<String>((ref) => '');

class PodcastSearchScreen extends ConsumerStatefulWidget {
  const PodcastSearchScreen({super.key});

  @override
  ConsumerState<PodcastSearchScreen> createState() =>
      _PodcastSearchScreenState();
}

class _PodcastSearchScreenState extends ConsumerState<PodcastSearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(_searchQueryProvider);
    final resultsAsync =
        query.isNotEmpty ? ref.watch(podcastSearchProvider(query)) : null;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search podcasts...',
            border: InputBorder.none,
          ),
          onSubmitted: (value) {
            ref.read(_searchQueryProvider.notifier).state = value.trim();
          },
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                ref.read(_searchQueryProvider.notifier).state = '';
              },
            ),
        ],
      ),
      body: resultsAsync == null
          ? const Center(
              child: Text('Enter a search term to find podcasts'),
            )
          : resultsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (results) {
                if (results.isEmpty) {
                  return const Center(child: Text('No results found'));
                }
                return ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final result = results[index];
                    return _SearchResultTile(result: result);
                  },
                );
              },
            ),
    );
  }
}

class _SearchResultTile extends ConsumerWidget {
  final PodcastSearchResult result;

  const _SearchResultTile({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 56,
          height: 56,
          child: result.artworkUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: result.artworkUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, url) => _placeholder(context),
                  errorWidget: (_, url, error) => _placeholder(context),
                )
              : _placeholder(context),
        ),
      ),
      title: Text(
        result.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        result.author,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: _SubscribeButton(feedUrl: result.feedUrl, result: result),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.podcasts, size: 28),
    );
  }
}

class _SubscribeButton extends ConsumerStatefulWidget {
  final String feedUrl;
  final PodcastSearchResult result;

  const _SubscribeButton({required this.feedUrl, required this.result});

  @override
  ConsumerState<_SubscribeButton> createState() => _SubscribeButtonState();
}

class _SubscribeButtonState extends ConsumerState<_SubscribeButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final podcastsAsync = ref.watch(subscribedPodcastsProvider);
    final isSubscribed = podcastsAsync.valueOrNull
            ?.any((p) => p.feedUrl == widget.feedUrl) ??
        false;

    if (isSubscribed) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }

    if (_loading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return IconButton(
      icon: const Icon(Icons.add_circle_outline),
      onPressed: () async {
        setState(() => _loading = true);
        final messenger = ScaffoldMessenger.of(context);
        try {
          await ref.read(podcastActionsProvider).subscribe(widget.result);
          if (mounted) {
            messenger.showSnackBar(
              SnackBar(content: Text('Subscribed to "${widget.result.title}"')),
            );
          }
        } catch (e) {
          if (mounted) {
            messenger.showSnackBar(
              SnackBar(content: Text('Failed to subscribe: $e')),
            );
          }
        } finally {
          if (mounted) setState(() => _loading = false);
        }
      },
    );
  }
}
