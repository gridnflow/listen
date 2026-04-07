import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/database.dart';

class PodcastCard extends StatelessWidget {
  final Podcast podcast;
  final VoidCallback onTap;

  const PodcastCard({
    super.key,
    required this.podcast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 56,
          height: 56,
          child: podcast.artworkUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: podcast.artworkUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, url) => _placeholder(context),
                  errorWidget: (_, url, error) => _placeholder(context),
                )
              : _placeholder(context),
        ),
      ),
      title: Text(
        podcast.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        podcast.author,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.podcasts, size: 28),
    );
  }
}
