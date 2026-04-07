import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/database.dart';

class TrackListTile extends StatelessWidget {
  final AudioTrack track;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const TrackListTile({
    super.key,
    required this.track,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.music_note),
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        track.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: SizedBox(
        width: onDelete != null ? 96 : 48,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.youtube_searched_for),
              tooltip: 'Search on YouTube',
              onPressed: () => _searchYoutube(track.title, track.artist),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context),
              ),
          ],
        ),
      ),
      onTap: onTap,
    );
  }

  Future<void> _searchYoutube(String title, String artist) async {
    final query = Uri.encodeQueryComponent('$title $artist');
    final url = Uri.parse('https://www.youtube.com/results?search_query=$query');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete track'),
        content: Text('Remove "${track.title}" from your library?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
