import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/services/database.dart';

class PodcastDownloadService {
  final Dio _dio;

  PodcastDownloadService(this._dio);

  Future<String> downloadEpisode({
    required int podcastId,
    required int episodeId,
    required String audioUrl,
    required void Function(int progress) onProgress,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final podcastDir =
        Directory(p.join(appDir.path, 'podcasts', podcastId.toString()));
    if (!await podcastDir.exists()) {
      await podcastDir.create(recursive: true);
    }

    final extension = _getExtension(audioUrl);
    final filePath = p.join(podcastDir.path, '$episodeId$extension');

    await _dio.download(
      audioUrl,
      filePath,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          final progress = ((received / total) * 100).round();
          onProgress(progress);
        }
      },
    );

    // Update DB with final path
    await AppDatabase.instance
        .updateEpisodeDownload(episodeId, filePath, 100);

    return filePath;
  }

  Future<void> deleteDownload(int episodeId) async {
    await AppDatabase.instance.deleteEpisodeDownload(episodeId);
  }

  String _getExtension(String url) {
    final uri = Uri.parse(url);
    final path = uri.path.toLowerCase();
    if (path.endsWith('.mp3')) return '.mp3';
    if (path.endsWith('.m4a')) return '.m4a';
    if (path.endsWith('.ogg')) return '.ogg';
    if (path.endsWith('.opus')) return '.opus';
    return '.mp3';
  }
}
