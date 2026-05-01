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

class CancellationToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}

class YoutubeService {
  final _yt = YoutubeExplode();
  VideoSearchList? _lastPage;

  Future<List<YoutubeSearchResult>> search(String query) async {
    final page = await _yt.search.search(query);
    _lastPage = page;
    return _mapResults(page);
  }

  Future<List<YoutubeSearchResult>> loadMore() async {
    if (_lastPage == null) return [];
    final next = await _lastPage!.nextPage();
    if (next == null) return [];
    _lastPage = next;
    return _mapResults(next);
  }

  List<YoutubeSearchResult> _mapResults(VideoSearchList page) {
    return page.map((v) {
      return YoutubeSearchResult(
        videoId: v.id.value,
        title: v.title,
        channelName: v.author,
        thumbnailUrl: v.thumbnails.mediumResUrl,
        duration: v.duration,
      );
    }).toList();
  }

  /// Downloads audio and saves to library. Calls [onProgress] with 0.0–1.0.
  /// Throws [CancelledException] if [cancellationToken] is cancelled mid-download.
  Future<void> downloadAudio(
    YoutubeSearchResult result, {
    required void Function(double) onProgress,
    CancellationToken? cancellationToken,
  }) async {
    final manifest =
        await _yt.videos.streamsClient.getManifest(result.videoId);
    final streamInfo = manifest.audioOnly.withHighestBitrate();

    final dir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${dir.path}/youtube_downloads');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    final safeName = result.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final filePath = '${downloadsDir.path}/$safeName.m4a';

    // Skip re-download if already in library
    final existing = await AppDatabase.instance.findTrackByPath(filePath);
    if (existing != null) return;

    final file = File(filePath);
    final sink = file.openWrite();
    final totalBytes = streamInfo.size.totalBytes;
    int received = 0;

    try {
      await for (final chunk in _yt.videos.streamsClient.get(streamInfo)) {
        if (cancellationToken?.isCancelled == true) {
          throw const CancelledException();
        }
        sink.add(chunk);
        received += chunk.length;
        onProgress(totalBytes > 0 ? received / totalBytes : 0);
      }
      await sink.flush();
    } catch (_) {
      await sink.close();
      if (await file.exists()) await file.delete();
      rethrow;
    }
    await sink.close();

    int durationMs = result.duration?.inMilliseconds ?? 0;
    if (durationMs == 0) {
      final player = AudioPlayer();
      try {
        final d = await player.setFilePath(filePath);
        durationMs = d?.inMilliseconds ?? 0;
      } catch (_) {
        // duration is optional — proceed without it
      } finally {
        await player.dispose();
      }
    }

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

  void dispose() => _yt.close();
}

class CancelledException implements Exception {
  const CancelledException();

  @override
  String toString() => 'Download cancelled';
}
