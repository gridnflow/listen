import 'dart:io';

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/database.dart';

class LibraryNotifier extends StateNotifier<void> {
  LibraryNotifier() : super(null);

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

      await db.insertTrack(
        AudioTracksCompanion.insert(
          title: fileName,
          filePath: file.path!,
          fileSize: Value(file.size),
        ),
      );
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

final libraryProvider = StateNotifierProvider<LibraryNotifier, void>((ref) {
  return LibraryNotifier();
});

final allTracksProvider = StreamProvider<List<AudioTrack>>((ref) {
  return AppDatabase.instance.watchAllTracks();
});
