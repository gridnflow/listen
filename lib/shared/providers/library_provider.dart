import 'dart:io';

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../core/services/database.dart';
import '../../core/services/permission_service.dart';

class LibraryState {
  final bool isScanning;

  const LibraryState({this.isScanning = false});

  LibraryState copyWith({bool? isScanning}) {
    return LibraryState(isScanning: isScanning ?? this.isScanning);
  }
}

class LibraryNotifier extends StateNotifier<LibraryState> {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  LibraryNotifier() : super(const LibraryState());

  Future<void> importFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result == null) return;

    final db = AppDatabase.instance;

    for (final file in result.files) {
      if (file.path == null) continue;

      final fileName =
          file.name.replaceAll(RegExp(r'\.[^.]+$'), ''); // strip extension

      // Skip if already in library
      final existing = await db.findTrackByPath(file.path!);
      if (existing != null) continue;

      await db.insertTrack(
        AudioTracksCompanion.insert(
          title: fileName,
          filePath: file.path!,
          fileSize: Value(file.size),
        ),
      );
    }
  }

  Future<int> scanDeviceAudio() async {
    final hasPermission = await PermissionService.requestStoragePermission();
    if (!hasPermission) return 0;

    state = state.copyWith(isScanning: true);

    try {
      final songs = await _audioQuery.querySongs(
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
      );

      final db = AppDatabase.instance;
      int importedCount = 0;

      for (final song in songs) {
        if (song.data.isEmpty) continue;

        // Skip if already in library
        final existing = await db.findTrackByPath(song.data);
        if (existing != null) continue;

        await db.insertTrack(
          AudioTracksCompanion.insert(
            title: song.title,
            artist: Value(song.artist ?? 'Unknown'),
            durationMs: Value(song.duration ?? 0),
            filePath: song.data,
            fileSize: Value(song.size),
          ),
        );
        importedCount++;
      }

      return importedCount;
    } finally {
      state = state.copyWith(isScanning: false);
    }
  }

  Future<void> deleteTrack(AudioTrack track) async {
    final db = AppDatabase.instance;
    await db.deleteTrack(track.id);

    // Delete file if it exists in app directory
    final file = File(track.filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

final libraryProvider =
    StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  return LibraryNotifier();
});

final allTracksProvider = StreamProvider<List<AudioTrack>>((ref) {
  return AppDatabase.instance.watchAllTracks();
});

final allPlaylistsProvider = StreamProvider<List<Playlist>>((ref) {
  return AppDatabase.instance.watchAllPlaylists();
});
