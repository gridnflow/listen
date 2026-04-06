import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('Listen v0.1.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Listen',
                applicationVersion: '0.1.0',
                applicationLegalese: 'Offline audio player',
              );
            },
          ),
        ],
      ),
    );
  }
}
