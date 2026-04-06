import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/database.dart';
import '../../../shared/providers/audio_provider.dart';
import '../../../shared/widgets/track_list_tile.dart';

final playlistTracksProvider =
    FutureProvider.family<List<AudioTrack>, int>((ref, playlistId) {
  return AppDatabase.instance.getPlaylistTracks(playlistId);
});

final playlistNameProvider =
    FutureProvider.family<String, int>((ref, playlistId) async {
  final playlists = await AppDatabase.instance.getAllPlaylists();
  final playlist = playlists.where((p) => p.id == playlistId).firstOrNull;
  return playlist?.name ?? 'Playlist';
});

class PlaylistDetailScreen extends ConsumerWidget {
  final int playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(playlistTracksProvider(playlistId));
    final nameAsync = ref.watch(playlistNameProvider(playlistId));

    return Scaffold(
      appBar: AppBar(
        title: Text(nameAsync.valueOrNull ?? 'Playlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add tracks',
            onPressed: () => _showAddTracksDialog(context, ref),
          ),
        ],
      ),
      body: tracksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tracks) {
          if (tracks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_off_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tracks in this playlist',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add tracks from your library',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              return TrackListTile(
                track: track,
                onTap: () {
                  ref
                      .read(audioProvider.notifier)
                      .playQueue(tracks, startIndex: index);
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showAddTracksDialog(BuildContext context, WidgetRef ref) async {
    final allTracks = await AppDatabase.instance.getAllTracks();
    if (!context.mounted) return;

    if (allTracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tracks in library. Import some first.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Add tracks',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: allTracks.length,
                itemBuilder: (context, index) {
                  final track = allTracks[index];
                  return ListTile(
                    leading: const Icon(Icons.music_note),
                    title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () async {
                        final added = await AppDatabase.instance
                            .addTrackToPlaylist(playlistId, track.id);
                        ref.invalidate(playlistTracksProvider(playlistId));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(added
                                  ? 'Added "${track.title}"'
                                  : '"${track.title}" already in playlist'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
