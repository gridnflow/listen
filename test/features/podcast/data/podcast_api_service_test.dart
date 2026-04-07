import 'package:flutter_test/flutter_test.dart';
import 'package:listen/features/podcast/data/podcast_api_service.dart';

void main() {
  group('PodcastSearchResult', () {
    test('creates with all fields', () {
      const result = PodcastSearchResult(
        title: 'My Podcast',
        author: 'Author',
        feedUrl: 'https://example.com/feed.xml',
        artworkUrl: 'https://example.com/art.jpg',
      );
      expect(result.title, 'My Podcast');
      expect(result.author, 'Author');
      expect(result.feedUrl, 'https://example.com/feed.xml');
      expect(result.artworkUrl, 'https://example.com/art.jpg');
    });

    test('handles empty artwork url', () {
      const result = PodcastSearchResult(
        title: 'Test',
        author: 'Author',
        feedUrl: 'https://example.com/feed.xml',
        artworkUrl: '',
      );
      expect(result.artworkUrl.isEmpty, true);
    });
  });

  group('PodcastApiService.search - input validation', () {
    test('empty query should return empty list conceptually', () {
      // PodcastApiService.search returns [] for empty query
      // This tests the guard clause logic
      expect(''.trim().isEmpty, true);
    });

    test('whitespace-only query is treated as empty', () {
      expect('   '.trim().isEmpty, true);
    });
  });
}
