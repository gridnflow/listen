import 'package:dio/dio.dart';
import 'package:webfeed_plus/webfeed_plus.dart';

class PodcastFeedResult {
  final String title;
  final String author;
  final String description;
  final String artworkUrl;
  final List<EpisodeData> episodes;

  const PodcastFeedResult({
    required this.title,
    required this.author,
    required this.description,
    required this.artworkUrl,
    required this.episodes,
  });
}

class EpisodeData {
  final String title;
  final String description;
  final String audioUrl;
  final String guid;
  final int durationMs;
  final DateTime? publishedAt;

  const EpisodeData({
    required this.title,
    required this.description,
    required this.audioUrl,
    required this.guid,
    required this.durationMs,
    this.publishedAt,
  });
}

class RssService {
  final Dio _dio;

  RssService(this._dio);

  Future<PodcastFeedResult> fetchFeed(String feedUrl) async {
    final response = await _dio.get(feedUrl);
    final feed = RssFeed.parse(response.data);

    final episodes = (feed.items ?? [])
        .where((item) => item.enclosure?.url != null)
        .map((item) => EpisodeData(
              title: item.title ?? 'Untitled',
              description: item.description ?? '',
              audioUrl: item.enclosure!.url!,
              guid: item.guid ?? item.enclosure!.url!,
              durationMs: _parseDuration(item.itunes?.duration),
              publishedAt: item.pubDate,
            ))
        .toList();

    return PodcastFeedResult(
      title: feed.title ?? '',
      author: feed.itunes?.author ?? feed.author ?? '',
      description: feed.description ?? '',
      artworkUrl: feed.itunes?.image?.href ?? feed.image?.url ?? '',
      episodes: episodes,
    );
  }

  int _parseDuration(Duration? duration) {
    if (duration == null) return 0;
    return duration.inMilliseconds;
  }
}
