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

class Podcasts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get author => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get feedUrl => text().unique()();
  TextColumn get artworkUrl => text().withDefault(const Constant(''))();
  BoolColumn get autoDownload =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get subscribedAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastCheckedAt => dateTime().nullable()();
}

class Episodes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get podcastId => integer().references(Podcasts, #id)();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get audioUrl => text()();
  TextColumn get guid => text()();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  DateTimeColumn get publishedAt => dateTime().nullable()();
  TextColumn get localFilePath => text().nullable()();
  IntColumn get downloadProgress =>
      integer().withDefault(const Constant(0))();
  IntColumn get playbackPositionMs =>
      integer().withDefault(const Constant(0))();
  BoolColumn get isPlayed => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(
    tables: [AudioTracks, Playlists, PlaylistTracks, Podcasts, Episodes])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase._();

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(podcasts);
            await m.createTable(episodes);
          }
        },
      );

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
    final existing = await (select(playlistTracks)
          ..where((pt) =>
              pt.playlistId.equals(playlistId) & pt.trackId.equals(trackId)))
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

  // --- Podcast queries ---

  Stream<List<Podcast>> watchSubscribedPodcasts() =>
      (select(podcasts)..orderBy([(p) => OrderingTerm.desc(p.subscribedAt)]))
          .watch();

  Future<List<Podcast>> getAllPodcasts() => select(podcasts).get();

  Future<Podcast?> findPodcastByFeedUrl(String feedUrl) async {
    return (select(podcasts)..where((p) => p.feedUrl.equals(feedUrl)))
        .getSingleOrNull();
  }

  Future<Podcast> insertPodcast(PodcastsCompanion entry) async {
    final id = await into(podcasts).insert(entry);
    return (select(podcasts)..where((p) => p.id.equals(id))).getSingle();
  }

  Future<void> deletePodcast(int id) async {
    // Delete downloaded episode files
    final eps = await (select(episodes)
          ..where((e) => e.podcastId.equals(id)))
        .get();
    for (final ep in eps) {
      if (ep.localFilePath != null) {
        final file = File(ep.localFilePath!);
        if (await file.exists()) await file.delete();
      }
    }
    await (delete(episodes)..where((e) => e.podcastId.equals(id))).go();
    await (delete(podcasts)..where((p) => p.id.equals(id))).go();
  }

  Future<void> updatePodcastLastChecked(int id) async {
    await (update(podcasts)..where((p) => p.id.equals(id))).write(
      PodcastsCompanion(lastCheckedAt: Value(DateTime.now())),
    );
  }

  // --- Episode queries ---

  Stream<List<Episode>> watchEpisodes(int podcastId) =>
      (select(episodes)
            ..where((e) => e.podcastId.equals(podcastId))
            ..orderBy([(e) => OrderingTerm.desc(e.publishedAt)]))
          .watch();

  Future<List<Episode>> getEpisodes(int podcastId) =>
      (select(episodes)
            ..where((e) => e.podcastId.equals(podcastId))
            ..orderBy([(e) => OrderingTerm.desc(e.publishedAt)]))
          .get();

  Future<Episode?> findEpisodeByGuid(int podcastId, String guid) async {
    return (select(episodes)
          ..where(
              (e) => e.podcastId.equals(podcastId) & e.guid.equals(guid)))
        .getSingleOrNull();
  }

  Future<Episode> insertEpisode(EpisodesCompanion entry) async {
    final id = await into(episodes).insert(entry);
    return (select(episodes)..where((e) => e.id.equals(id))).getSingle();
  }

  Future<void> updateEpisodeDownload(
      int id, String localFilePath, int progress) async {
    await (update(episodes)..where((e) => e.id.equals(id))).write(
      EpisodesCompanion(
        localFilePath: Value(localFilePath),
        downloadProgress: Value(progress),
      ),
    );
  }

  Future<void> updateEpisodeDownloadProgress(int id, int progress) async {
    await (update(episodes)..where((e) => e.id.equals(id))).write(
      EpisodesCompanion(downloadProgress: Value(progress)),
    );
  }

  Future<void> updateEpisodePlaybackPosition(int id, int positionMs) async {
    await (update(episodes)..where((e) => e.id.equals(id))).write(
      EpisodesCompanion(playbackPositionMs: Value(positionMs)),
    );
  }

  Future<void> markEpisodePlayed(int id) async {
    await (update(episodes)..where((e) => e.id.equals(id))).write(
      const EpisodesCompanion(isPlayed: Value(true)),
    );
  }

  Future<void> deleteEpisodeDownload(int id) async {
    final episode =
        await (select(episodes)..where((e) => e.id.equals(id))).getSingle();
    if (episode.localFilePath != null) {
      final file = File(episode.localFilePath!);
      if (await file.exists()) await file.delete();
    }
    await (update(episodes)..where((e) => e.id.equals(id))).write(
      const EpisodesCompanion(
        localFilePath: Value(null),
        downloadProgress: Value(0),
      ),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'listen.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
