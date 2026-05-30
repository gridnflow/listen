import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _SectionHeader(title: 'Legal', theme: theme),
          Card(
            color: theme.colorScheme.surfaceContainerHigh,
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.privacy_tip_outlined,
                    color: theme.colorScheme.primary, size: 20),
              ),
              title: const Text('Privacy Policy'),
              trailing: Icon(Icons.open_in_new,
                  color: theme.colorScheme.onSurfaceVariant, size: 18),
              onTap: () => context.push('/settings/privacy-policy'),
            ),
          ),
          _SectionHeader(title: 'About', theme: theme),
          Card(
            color: theme.colorScheme.surfaceContainerHigh,
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFE91E8C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.music_note_rounded,
                    color: Colors.white, size: 20),
              ),
              title: const Text('Listen',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Version 0.1.0',
                  style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 13)),
              trailing: Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => const AlertDialog(
                    title: Text('Listen'),
                    content: Text('Version 0.1.0\n© 2025 Gridnflow'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final ThemeData theme;

  const _SectionHeader({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
