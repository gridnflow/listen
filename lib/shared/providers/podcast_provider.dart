import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/database.dart';
import '../../features/podcast/data/podcast_api_service.dart';
import '../../features/podcast/data/podcast_download_service.dart';
import '../../features/podcast/data/rss_service.dart';

// --- Service providers ---

final _dioProvider = Provider((ref) => Dio());

final podcastApiServiceProvider = Provider((ref) {
  return PodcastApiService(ref.watch(_dioProvider));
});

final rssServiceProvider = Provider((ref) {
  return RssService(ref.watch(_dioProvider));
});

final podcastDownloadServiceProvider = Provider((ref) {
  return PodcastDownloadService(ref.watch(_dioProvider));
});

// --- Data providers ---

final subscribedPodcastsProvider = StreamProvider<List<Podcast>>((ref) {
  return AppDatabase.instance.watchSubscribedPodcasts();
});

final podcastSearchProvider =
    FutureProvider.family<List<PodcastSearchResult>, String>((ref, query) {
  return ref.read(podcastApiServiceProvider).search(query);
});

final podcastEpisodesProvider =
    StreamProvider.family<List<Episode>, int>((ref, podcastId) {
  return AppDatabase.instance.watchEpisodes(podcastId);
});

// --- Download state ---

class DownloadNotifier extends StateNotifier<Map<int, int>> {
  final Ref _ref;

  DownloadNotifier(this._ref) : super({});

  Future<void> downloadEpisode(Episode episode, int podcastId) async {
    if (state.containsKey(episode.id)) return; // Already downloading

    state = {...state, episode.id: 0};

    try {
      await _ref.read(podcastDownloadServiceProvider).downloadEpisode(
            podcastId: podcastId,
            episodeId: episode.id,
            audioUrl: episode.audioUrl,
            onProgress: (progress) {
              state = {...state, episode.id: progress};
              AppDatabase.instance
                  .updateEpisodeDownloadProgress(episode.id, progress);
            },
          );
    } catch (e) {
      // Reset on failure
      await AppDatabase.instance
          .updateEpisodeDownloadProgress(episode.id, 0);
    } finally {
      state = Map.from(state)..remove(episode.id);
    }
  }

  Future<void> deleteDownload(int episodeId) async {
    await _ref.read(podcastDownloadServiceProvider).deleteDownload(episodeId);
  }
}

final downloadingEpisodesProvider =
    StateNotifierProvider<DownloadNotifier, Map<int, int>>((ref) {
  return DownloadNotifier(ref);
});

// --- Podcast actions ---

class PodcastActions {
  final Ref _ref;

  PodcastActions(this._ref);

  Future<Podcast> subscribe(PodcastSearchResult result) async {
    // Check if already subscribed
    final existing =
        await AppDatabase.instance.findPodcastByFeedUrl(result.feedUrl);
    if (existing != null) return existing;

    // Insert podcast
    final podcast = await AppDatabase.instance.insertPodcast(
      PodcastsCompanion.insert(
        title: result.title,
        author: Value(result.author),
        feedUrl: result.feedUrl,
        artworkUrl: Value(result.artworkUrl),
      ),
    );

    // Fetch and store episodes
    await refreshPodcast(podcast.id, result.feedUrl);

    return podcast;
  }

  Future<void> unsubscribe(int podcastId) async {
    await AppDatabase.instance.deletePodcast(podcastId);
  }

  Future<int> refreshPodcast(int podcastId, String feedUrl) async {
    final rss = _ref.read(rssServiceProvider);
    final feed = await rss.fetchFeed(feedUrl);
    int newCount = 0;

    for (final ep in feed.episodes) {
      final existing =
          await AppDatabase.instance.findEpisodeByGuid(podcastId, ep.guid);
      if (existing != null) continue;

      await AppDatabase.instance.insertEpisode(
        EpisodesCompanion.insert(
          podcastId: podcastId,
          title: ep.title,
          description: Value(ep.description),
          audioUrl: ep.audioUrl,
          guid: ep.guid,
          durationMs: Value(ep.durationMs),
          publishedAt: Value(ep.publishedAt),
        ),
      );
      newCount++;
    }

    await AppDatabase.instance.updatePodcastLastChecked(podcastId);
    return newCount;
  }

  Future<void> refreshAllPodcasts() async {
    final podcasts = await AppDatabase.instance.getAllPodcasts();
    for (final podcast in podcasts) {
      await refreshPodcast(podcast.id, podcast.feedUrl);
    }
  }
}

final podcastActionsProvider = Provider((ref) => PodcastActions(ref));
