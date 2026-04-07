import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/database.dart';

class EpisodeListTile extends StatelessWidget {
  final Episode episode;
  final int? downloadProgress; // null = not downloading
  final VoidCallback onPlay;
  final VoidCallback onDownload;
  final VoidCallback? onDeleteDownload;

  const EpisodeListTile({
    super.key,
    required this.episode,
    this.downloadProgress,
    required this.onPlay,
    required this.onDownload,
    this.onDeleteDownload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDownloaded = episode.localFilePath != null;
    final isDownloading = downloadProgress != null;
    final hasProgress = episode.playbackPositionMs > 0 && !episode.isPlayed;

    return ListTile(
      title: Text(
        episode.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: episode.isPlayed
              ? theme.colorScheme.onSurfaceVariant
              : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              if (episode.publishedAt != null)
                Text(
                  DateFormat.yMMMd().format(episode.publishedAt!),
                  style: theme.textTheme.bodySmall,
                ),
              if (episode.durationMs > 0) ...[
                const Text(' · '),
                Text(
                  _formatDuration(Duration(milliseconds: episode.durationMs)),
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (isDownloaded) ...[
                const SizedBox(width: 4),
                Icon(Icons.download_done,
                    size: 14, color: theme.colorScheme.primary),
              ],
            ],
          ),
          if (hasProgress) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: episode.durationMs > 0
                  ? episode.playbackPositionMs / episode.durationMs
                  : 0,
              minHeight: 2,
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isDownloading)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                value: downloadProgress! / 100,
                strokeWidth: 2,
              ),
            )
          else if (isDownloaded)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onDeleteDownload,
            )
          else
            IconButton(
              icon: const Icon(Icons.download_outlined, size: 20),
              onPressed: onDownload,
            ),
          IconButton(
            icon: const Icon(Icons.youtube_searched_for),
            tooltip: 'Search on YouTube',
            onPressed: () => _searchYoutube(episode.title),
          ),
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }

  Future<void> _searchYoutube(String title) async {
    final query = Uri.encodeQueryComponent(title);
    final url = Uri.parse('https://www.youtube.com/results?search_query=$query');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) return '$hours:$minutes:$seconds';
    return '$minutes:$seconds';
  }
}
