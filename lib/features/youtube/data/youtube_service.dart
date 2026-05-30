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

  Future<void> downloadAudio(
    YoutubeSearchResult result, {
    required void Function(double) onProgress,
    CancellationToken? cancellationToken,
  }) async {
    // ignore: avoid_print
    print('[YT] getManifest start: ${result.videoId}');
    final manifest = await _yt.videos.streamsClient
        .getManifest(result.videoId)
        .timeout(const Duration(seconds: 30));
    // ignore: avoid_print
    print('[YT] getManifest done, streams: ${manifest.audioOnly.length}');

    final streamInfo = manifest.audioOnly.withHighestBitrate();
    // ignore: avoid_print
    print('[YT] streamInfo: ${streamInfo.codec.mimeType} ${streamInfo.size.totalBytes} bytes');

    final dir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${dir.path}/youtube_downloads');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    final safeName = result.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final ext = streamInfo.codec.mimeType.contains('webm') ? 'webm' : 'm4a';
    final filePath = '${downloadsDir.path}/$safeName.$ext';

    final existing = await AppDatabase.instance.findTrackByPath(filePath);
    if (existing != null) return;

    final file = File(filePath);
    final sink = file.openWrite();
    final totalBytes = streamInfo.size.totalBytes;
    int received = 0;

    // ignore: avoid_print
    print('[YT] starting stream download to $filePath');
    try {
      // Use youtube_explode_dart's own HTTP client — it carries the correct
      // signed headers (visitor-data, po-token, etc.) that Google requires.
      await for (final chunk in _yt.videos.streamsClient
          .get(streamInfo)
          .timeout(const Duration(minutes: 10))) {
        if (cancellationToken?.isCancelled == true) {
          throw const CancelledException();
        }
        sink.add(chunk);
        received += chunk.length;
        onProgress(totalBytes > 0 ? received / totalBytes : 0);
      }
      await sink.flush();
      await sink.close();
    } catch (e) {
      await sink.close();
      if (await file.exists()) await file.delete();
      rethrow;
    }

    int durationMs = result.duration?.inMilliseconds ?? 0;
    if (durationMs == 0) {
      final player = AudioPlayer();
      try {
        final d = await player.setFilePath(filePath);
        durationMs = d?.inMilliseconds ?? 0;
      } catch (_) {
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
