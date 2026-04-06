import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listen/core/services/database.dart';

void main() {
  group('Database Schema - AudioTracks', () {
    test('companion accepts required fields only', () {
      final companion = AudioTracksCompanion.insert(
        title: 'Test',
        filePath: '/test.mp3',
      );
      expect(companion.title.value, 'Test');
      expect(companion.filePath.value, '/test.mp3');
    });

    test('companion accepts all optional fields', () {
      final companion = AudioTracksCompanion.insert(
        title: 'Test',
        filePath: '/test.mp3',
        artist: const Value('Artist'),
        durationMs: const Value(120000),
        fileSize: const Value(5000),
      );
      expect(companion.artist.value, 'Artist');
      expect(companion.durationMs.value, 120000);
      expect(companion.fileSize.value, 5000);
    });
  });

  group('Database Schema - Playlists', () {
    test('companion requires name', () {
      final companion = PlaylistsCompanion.insert(name: 'My Playlist');
      expect(companion.name.value, 'My Playlist');
    });
  });

  group('Database Schema - PlaylistTracks', () {
    test('companion requires all fields', () {
      final companion = PlaylistTracksCompanion.insert(
        playlistId: 1,
        trackId: 2,
        position: 0,
      );
      expect(companion.playlistId.value, 1);
      expect(companion.trackId.value, 2);
      expect(companion.position.value, 0);
    });
  });
}
