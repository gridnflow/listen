import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../../core/services/database.dart';
import 'package:drift/drift.dart';

class YoutubeSearchResult {
  final String videoId;
  final String title;
  final String channelName;
  final String? thumbnailUrl;
  final Duration? duration;

  YoutubeSearchResult({
    required this.videoId,
    required this.title,
    required this.channelName,
    this.thumbnailUrl,
    this.duration,
  });
}

class YoutubeService {
  final _yt = YoutubeExplode();

  Future<List<YoutubeSearchResult>> search(String query) async {
    final results = await _yt.search.search(query);
    return results.whereType<SearchVideo>().map((v) {
      return YoutubeSearchResult(
        videoId: v.id.value,
        title: v.title,
        channelName: v.author,
        thumbnailUrl: v.thumbnails.isNotEmpty
            ? v.thumbnails.first.url.toString()
            : null,
        duration: _parseDuration(v.duration),
      );
    }).toList();
  }

  /// Downloads audio and saves to library. Calls [onProgress] with 0.0–1.0.
  Future<void> downloadAudio(
    YoutubeSearchResult result, {
    required void Function(double) onProgress,
  }) async {
    final manifest =
        await _yt.videos.streamsClient.getManifest(result.videoId);
    final streamInfo = manifest.audioOnly.withHighestBitrate();

    final dir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${dir.path}/youtube_downloads');
    if (!await downloadsDir.exists()) await downloadsDir.create(recursive: true);

    // Sanitize filename
    final safeName = result.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final filePath = '${downloadsDir.path}/$safeName.mp3';

    final stream = _yt.videos.streamsClient.get(streamInfo);
    final file = File(filePath);
    final sink = file.openWrite();

    final totalBytes = streamInfo.size.totalBytes;
    int received = 0;

    await for (final chunk in stream) {
      sink.add(chunk);
      received += chunk.length;
      onProgress(totalBytes > 0 ? received / totalBytes : 0);
    }
    await sink.flush();
    await sink.close();

    // Get duration
    int durationMs = result.duration?.inMilliseconds ?? 0;
    if (durationMs == 0) {
      try {
        final player = AudioPlayer();
        final d = await player.setFilePath(filePath);
        durationMs = d?.inMilliseconds ?? 0;
        await player.dispose();
      } catch (_) {}
    }

    // Save to library
    final existing = await AppDatabase.instance.findTrackByPath(filePath);
    if (existing == null) {
      await AppDatabase.instance.insertTrack(
        AudioTracksCompanion.insert(
          title: result.title,
          artist: Value(result.channelName),
          filePath: filePath,
          durationMs: Value(durationMs),
          fileSize: Value(await file.length()),
        ),
      );
    }
  }

  Duration? _parseDuration(dynamic value) {
    if (value == null) return null;
    if (value is Duration) return value;
    if (value is String) {
      final parts = value.split(':').map(int.tryParse).toList();
      if (parts.length == 2) {
        return Duration(minutes: parts[0] ?? 0, seconds: parts[1] ?? 0);
      } else if (parts.length == 3) {
        return Duration(hours: parts[0] ?? 0, minutes: parts[1] ?? 0, seconds: parts[2] ?? 0);
      }
    }
    return null;
  }

  void dispose() => _yt.close();
}
