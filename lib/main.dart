import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/database.dart';
import 'shared/providers/audio_provider.dart';
import 'shared/providers/podcast_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  AppDatabase.instance;

  // Initialize audio service
  final audioHandler = await AudioService.init(
    builder: () => ListenAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.listen.audio',
      androidNotificationChannelName: 'Listen Audio',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  final container = ProviderContainer(
    overrides: [
      audioHandlerProvider.overrideWithValue(audioHandler),
    ],
  );

  // Refresh podcast feeds on startup
  container.read(podcastActionsProvider).refreshAllPodcasts();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ListenApp(),
    ),
  );
}
