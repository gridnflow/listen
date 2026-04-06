import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  AppDatabase.instance;

  runApp(
    const ProviderScope(
      child: ListenApp(),
    ),
  );
}
