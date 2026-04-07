import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listen/core/services/database.dart';

void main() {
  group('Database Schema - Podcasts', () {
    test('companion requires title and feedUrl', () {
      final companion = PodcastsCompanion.insert(
        title: 'My Podcast',
        feedUrl: 'https://example.com/feed.xml',
      );
      expect(companion.title.value, 'My Podcast');
      expect(companion.feedUrl.value, 'https://example.com/feed.xml');
    });

    test('companion accepts optional fields', () {
      final companion = PodcastsCompanion.insert(
        title: 'My Podcast',
        feedUrl: 'https://example.com/feed.xml',
        author: const Value('Author'),
        description: const Value('Description'),
        artworkUrl: const Value('https://example.com/art.jpg'),
        autoDownload: const Value(true),
      );
      expect(companion.author.value, 'Author');
      expect(companion.description.value, 'Description');
      expect(companion.artworkUrl.value, 'https://example.com/art.jpg');
      expect(companion.autoDownload.value, true);
    });
  });

  group('Database Schema - Episodes', () {
    test('companion requires podcastId, title, audioUrl, guid', () {
      final companion = EpisodesCompanion.insert(
        podcastId: 1,
        title: 'Episode 1',
        audioUrl: 'https://example.com/ep1.mp3',
        guid: 'guid-1',
      );
      expect(companion.podcastId.value, 1);
      expect(companion.title.value, 'Episode 1');
      expect(companion.audioUrl.value, 'https://example.com/ep1.mp3');
      expect(companion.guid.value, 'guid-1');
    });

    test('companion accepts all optional fields', () {
      final companion = EpisodesCompanion.insert(
        podcastId: 1,
        title: 'Episode 1',
        audioUrl: 'https://example.com/ep1.mp3',
        guid: 'guid-1',
        description: const Value('A great episode'),
        durationMs: const Value(3600000),
        publishedAt: Value(DateTime(2026, 4, 1)),
      );
      expect(companion.description.value, 'A great episode');
      expect(companion.durationMs.value, 3600000);
      expect(companion.publishedAt.value, DateTime(2026, 4, 1));
    });
  });

  group('Database Schema Version', () {
    test('schema version is 2', () {
      expect(AppDatabase.instance.schemaVersion, 2);
    });
  });
}
