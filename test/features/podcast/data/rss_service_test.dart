import 'package:flutter_test/flutter_test.dart';
import 'package:listen/features/podcast/data/rss_service.dart';

void main() {
  group('EpisodeData', () {
    test('creates with required fields', () {
      const ep = EpisodeData(
        title: 'Episode 1',
        description: 'Description',
        audioUrl: 'https://example.com/ep1.mp3',
        guid: 'guid-1',
        durationMs: 3600000,
      );
      expect(ep.title, 'Episode 1');
      expect(ep.audioUrl, 'https://example.com/ep1.mp3');
      expect(ep.durationMs, 3600000);
      expect(ep.publishedAt, isNull);
    });

    test('creates with publishedAt', () {
      final date = DateTime(2026, 4, 1);
      final ep = EpisodeData(
        title: 'Episode 1',
        description: '',
        audioUrl: 'https://example.com/ep1.mp3',
        guid: 'guid-1',
        durationMs: 0,
        publishedAt: date,
      );
      expect(ep.publishedAt, date);
    });
  });

  group('PodcastFeedResult', () {
    test('creates with all fields', () {
      const feed = PodcastFeedResult(
        title: 'My Podcast',
        author: 'Author',
        description: 'A great podcast',
        artworkUrl: 'https://example.com/art.jpg',
        episodes: [],
      );
      expect(feed.title, 'My Podcast');
      expect(feed.episodes, isEmpty);
    });

    test('feed can contain episodes', () {
      const feed = PodcastFeedResult(
        title: 'My Podcast',
        author: 'Author',
        description: '',
        artworkUrl: '',
        episodes: [
          EpisodeData(
            title: 'Ep 1',
            description: '',
            audioUrl: 'https://example.com/1.mp3',
            guid: 'g1',
            durationMs: 1800000,
          ),
          EpisodeData(
            title: 'Ep 2',
            description: '',
            audioUrl: 'https://example.com/2.mp3',
            guid: 'g2',
            durationMs: 2400000,
          ),
        ],
      );
      expect(feed.episodes.length, 2);
      expect(feed.episodes[0].title, 'Ep 1');
      expect(feed.episodes[1].guid, 'g2');
    });
  });
}
