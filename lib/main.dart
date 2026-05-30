import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/database.dart';
import 'shared/providers/audio_provider.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  AppDatabase.instance;

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

  FlutterNativeSplash.remove();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ListenApp(),
    ),
  );
}
