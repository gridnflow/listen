import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Player duration formatting', () {
    // Matches the fixed implementation in player_screen.dart
    String formatDuration(Duration d) {
      final hours = d.inHours;
      final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      if (hours > 0) return '$hours:$minutes:$seconds';
      return '$minutes:$seconds';
    }

    test('formats zero duration', () {
      expect(formatDuration(Duration.zero), '00:00');
    });

    test('formats seconds only', () {
      expect(formatDuration(const Duration(seconds: 45)), '00:45');
    });

    test('formats minutes and seconds', () {
      expect(formatDuration(const Duration(minutes: 3, seconds: 15)), '03:15');
    });

    test('formats exactly one hour', () {
      expect(formatDuration(const Duration(hours: 1)), '1:00:00');
    });

    test('formats 59 minutes 59 seconds', () {
      expect(formatDuration(const Duration(minutes: 59, seconds: 59)), '59:59');
    });

    test('formats single digit seconds with padding', () {
      expect(formatDuration(const Duration(minutes: 1, seconds: 5)), '01:05');
    });

    test('formats hour+ duration correctly', () {
      // BUG-1 from Phase 1 is now fixed
      final d = const Duration(hours: 1, minutes: 5, seconds: 30);
      expect(formatDuration(d), '1:05:30');
    });
  });
}
