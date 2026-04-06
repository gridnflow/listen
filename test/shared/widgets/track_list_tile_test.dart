import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listen/core/services/database.dart';
import 'package:listen/shared/widgets/track_list_tile.dart';

AudioTrack _makeTrack({
  String title = 'Test Track',
  String artist = 'Test Artist',
}) {
  return AudioTrack(
    id: 1,
    title: title,
    artist: artist,
    durationMs: 180000,
    filePath: '/test.mp3',
    fileSize: 1024,
    addedAt: DateTime.now(),
    lastPlayedAt: null,
    playCount: 0,
  );
}

void main() {
  group('TrackListTile', () {
    testWidgets('displays track title and artist', (tester) async {
      final track = _makeTrack(title: 'My Song', artist: 'My Band');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackListTile(
              track: track,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('My Song'), findsOneWidget);
      expect(find.text('My Band'), findsOneWidget);
    });

    testWidgets('shows delete button when onDelete is provided', (tester) async {
      final track = _makeTrack();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackListTile(
              track: track,
              onTap: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('hides delete button when onDelete is null', (tester) async {
      final track = _makeTrack();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackListTile(
              track: track,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      final track = _makeTrack();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackListTile(
              track: track,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      expect(tapped, true);
    });

    testWidgets('shows confirmation dialog on delete', (tester) async {
      final track = _makeTrack(title: 'Song to Delete');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackListTile(
              track: track,
              onTap: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete track'), findsOneWidget);
      expect(find.text('Remove "Song to Delete" from your library?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('cancel button dismisses delete dialog', (tester) async {
      bool deleted = false;
      final track = _makeTrack();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackListTile(
              track: track,
              onTap: () {},
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(deleted, false);
      expect(find.text('Delete track'), findsNothing);
    });

    testWidgets('confirm delete calls onDelete', (tester) async {
      bool deleted = false;
      final track = _makeTrack();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackListTile(
              track: track,
              onTap: () {},
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(deleted, true);
    });

    testWidgets('displays music note icon', (tester) async {
      final track = _makeTrack();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackListTile(
              track: track,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.music_note), findsOneWidget);
    });

    testWidgets('long title is ellipsized', (tester) async {
      final track = _makeTrack(
        title: 'This is a very very very very very very very very long track title that should be truncated',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackListTile(
              track: track,
              onTap: () {},
            ),
          ),
        ),
      );

      final titleWidget = tester.widget<Text>(find.text(track.title));
      expect(titleWidget.maxLines, 1);
      expect(titleWidget.overflow, TextOverflow.ellipsis);
    });
  });
}
