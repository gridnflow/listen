import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

class AudioTracks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get artist => text().withDefault(const Constant('Unknown'))();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  TextColumn get filePath => text()();
  IntColumn get fileSize => integer().withDefault(const Constant(0))();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();
  IntColumn get playCount => integer().withDefault(const Constant(0))();
}

class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class PlaylistTracks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get playlistId => integer().references(Playlists, #id)();
  IntColumn get trackId => integer().references(AudioTracks, #id)();
  IntColumn get position => integer()();
}

@DriftDatabase(tables: [AudioTracks, Playlists, PlaylistTracks])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase._();

  @override
  int get schemaVersion => 1;

  // --- AudioTrack queries ---

  Future<List<AudioTrack>> getAllTracks() => select(audioTracks).get();

  Stream<List<AudioTrack>> watchAllTracks() => select(audioTracks).watch();

  Future<AudioTrack> insertTrack(AudioTracksCompanion entry) async {
    final id = await into(audioTracks).insert(entry);
    return (select(audioTracks)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<void> deleteTrack(int id) async {
    await (delete(playlistTracks)..where((pt) => pt.trackId.equals(id))).go();
    await (delete(audioTracks)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateLastPlayed(int id) async {
    final track = await (select(audioTracks)..where((t) => t.id.equals(id)))
        .getSingle();
    await (update(audioTracks)..where((t) => t.id.equals(id))).write(
      AudioTracksCompanion(
        lastPlayedAt: Value(DateTime.now()),
        playCount: Value(track.playCount + 1),
      ),
    );
  }

  Future<AudioTrack?> findTrackByPath(String path) async {
    return (select(audioTracks)..where((t) => t.filePath.equals(path)))
        .getSingleOrNull();
  }

  // --- Playlist queries ---

  Future<List<Playlist>> getAllPlaylists() => select(playlists).get();

  Stream<List<Playlist>> watchAllPlaylists() => select(playlists).watch();

  Future<Playlist> insertPlaylist(String name) async {
    final id = await into(playlists).insert(
      PlaylistsCompanion.insert(name: name),
    );
    return (select(playlists)..where((p) => p.id.equals(id))).getSingle();
  }

  Future<void> deletePlaylist(int id) async {
    await (delete(playlistTracks)..where((pt) => pt.playlistId.equals(id)))
        .go();
    await (delete(playlists)..where((p) => p.id.equals(id))).go();
  }

  Future<List<AudioTrack>> getPlaylistTracks(int playlistId) async {
    final query = select(playlistTracks).join([
      innerJoin(audioTracks, audioTracks.id.equalsExp(playlistTracks.trackId)),
    ])
      ..where(playlistTracks.playlistId.equals(playlistId))
      ..orderBy([OrderingTerm.asc(playlistTracks.position)]);
    final rows = await query.get();
    return rows.map((row) => row.readTable(audioTracks)).toList();
  }

  Future<bool> addTrackToPlaylist(int playlistId, int trackId) async {
    // Check for duplicate
    final existing = await (select(playlistTracks)
          ..where(
              (pt) => pt.playlistId.equals(playlistId) & pt.trackId.equals(trackId)))
        .getSingleOrNull();
    if (existing != null) return false;

    final count = await (select(playlistTracks)
          ..where((pt) => pt.playlistId.equals(playlistId)))
        .get();
    await into(playlistTracks).insert(
      PlaylistTracksCompanion.insert(
        playlistId: playlistId,
        trackId: trackId,
        position: count.length,
      ),
    );
    return true;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'listen.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
