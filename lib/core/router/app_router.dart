import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/library/presentation/library_screen.dart';
import '../../features/player/presentation/player_screen.dart';
import '../../features/playlist/presentation/playlist_detail_screen.dart';
import '../../features/playlist/presentation/playlists_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../shared/providers/audio_provider.dart';
import '../../shared/widgets/mini_player.dart';

final appRouter = GoRouter(
  initialLocation: '/library',
  routes: [
    ShellRoute(
      builder: (context, state, child) => ScaffoldWithNav(child: child),
      routes: [
        GoRoute(
          path: '/library',
          builder: (context, state) => const LibraryScreen(),
        ),
        GoRoute(
          path: '/playlists',
          builder: (context, state) => const PlaylistsScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = int.parse(state.pathParameters['id']!);
                return PlaylistDetailScreen(playlistId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/player',
      builder: (context, state) => const PlayerScreen(),
    ),
  ],
);

class ScaffoldWithNav extends ConsumerWidget {
  final Widget child;

  const ScaffoldWithNav({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(audioProvider);
    final hasTrack = playerState.currentTrack != null;

    return Scaffold(
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasTrack) const MiniPlayer(),
          NavigationBar(
            selectedIndex: _calculateSelectedIndex(context),
            onDestinationSelected: (index) => _onItemTapped(index, context),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music),
                label: 'Library',
              ),
              NavigationDestination(
                icon: Icon(Icons.playlist_play_outlined),
                selectedIcon: Icon(Icons.playlist_play),
                label: 'Playlists',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/library')) return 0;
    if (location.startsWith('/playlists')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/library');
      case 1:
        context.go('/playlists');
      case 2:
        context.go('/settings');
    }
  }
}
