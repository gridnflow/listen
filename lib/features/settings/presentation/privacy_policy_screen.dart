import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Privacy Policy', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Last updated: May 2025', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            _Section(
              title: '1. Information We Collect',
              body: 'Listen does not collect any personal information. All data (music library, playlists, playback history) is stored locally on your device and never transmitted to external servers.',
            ),
            _Section(
              title: '2. Local Storage',
              body: 'The app stores the following data locally on your device:\n• Music file metadata (title, artist, duration)\n• Playlist names and track associations\n• Playback progress and play counts\n\nThis data is never shared with third parties.',
            ),
            _Section(
              title: '3. YouTube Integration',
              body: 'When using the YouTube Download feature, the app communicates with YouTube\'s public API to search for and stream audio. This communication is governed by YouTube\'s Terms of Service and Google\'s Privacy Policy. We do not store or transmit any YouTube account information.',
            ),
            _Section(
              title: '4. Permissions',
              body: 'The app requests the following permissions:\n• Storage access: to read local music files\n• Internet access: for YouTube search and download\n• Foreground service: for background audio playback\n\nNo permissions are used beyond their stated purpose.',
            ),
            _Section(
              title: '5. Third-Party Services',
              body: 'This app does not use any analytics, advertising, or tracking services.',
            ),
            _Section(
              title: '6. Children\'s Privacy',
              body: 'This app does not knowingly collect information from children under the age of 13.',
            ),
            _Section(
              title: '7. Changes to This Policy',
              body: 'We may update this Privacy Policy from time to time. Changes will be reflected in the app update notes.',
            ),
            _Section(
              title: '8. Contact',
              body: 'If you have any questions about this Privacy Policy, please contact us at:\nsupport@gridnflow.com',
            ),
            const SizedBox(height: 32),
            Text(
              '© 2025 Gridnflow. All rights reserved.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
        ],
      ),
    );
  }
}
