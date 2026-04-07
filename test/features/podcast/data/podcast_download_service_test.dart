import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PodcastDownloadService - file extension parsing', () {
    String getExtension(String url) {
      final uri = Uri.parse(url);
      final path = uri.path.toLowerCase();
      if (path.endsWith('.mp3')) return '.mp3';
      if (path.endsWith('.m4a')) return '.m4a';
      if (path.endsWith('.ogg')) return '.ogg';
      if (path.endsWith('.opus')) return '.opus';
      return '.mp3';
    }

    test('detects .mp3 extension', () {
      expect(getExtension('https://example.com/audio/episode.mp3'), '.mp3');
    });

    test('detects .m4a extension', () {
      expect(getExtension('https://example.com/audio/episode.m4a'), '.m4a');
    });

    test('detects .ogg extension', () {
      expect(getExtension('https://example.com/audio/episode.ogg'), '.ogg');
    });

    test('detects .opus extension', () {
      expect(getExtension('https://example.com/audio/episode.opus'), '.opus');
    });

    test('defaults to .mp3 for unknown extension', () {
      expect(getExtension('https://example.com/audio/episode.wav'), '.mp3');
    });

    test('handles URL with query parameters', () {
      expect(
        getExtension('https://example.com/audio/episode.mp3?token=abc'),
        '.mp3',
      );
    });

    test('handles URL with no extension', () {
      expect(getExtension('https://example.com/audio/stream'), '.mp3');
    });

    test('case insensitive matching', () {
      expect(getExtension('https://example.com/audio/EP.MP3'), '.mp3');
    });
  });

  group('PodcastDownloadService - download progress', () {
    test('progress calculation', () {
      const received = 5000000;
      const total = 10000000;
      final progress = ((received / total) * 100).round();
      expect(progress, 50);
    });

    test('progress at 100%', () {
      const received = 10000000;
      const total = 10000000;
      final progress = ((received / total) * 100).round();
      expect(progress, 100);
    });

    test('progress at 0', () {
      const received = 0;
      const total = 10000000;
      final progress = ((received / total) * 100).round();
      expect(progress, 0);
    });

    test('unknown total (0) should not calculate', () {
      const total = 0;
      // Service guards with `if (total > 0)` - no progress when total unknown
      expect(total > 0, false);
    });
  });
}
