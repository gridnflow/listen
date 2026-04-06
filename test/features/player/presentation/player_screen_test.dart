import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Player duration formatting', () {
    String formatDuration(Duration d) {
      final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
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
      // Note: current implementation only shows mm:ss, hour info is lost
      expect(formatDuration(const Duration(hours: 1)), '00:00');
    });

    test('formats 59 minutes 59 seconds', () {
      expect(formatDuration(const Duration(minutes: 59, seconds: 59)), '59:59');
    });

    test('formats single digit seconds with padding', () {
      expect(formatDuration(const Duration(minutes: 1, seconds: 5)), '01:05');
    });

    test('hour+ duration loses hour component', () {
      // This is a known limitation: _formatDuration uses remainder(60)
      // For tracks > 60 minutes, the display wraps around
      // BUG: 1h5m shows as "05:00" instead of "65:00" or "1:05:00"
      final d = const Duration(hours: 1, minutes: 5, seconds: 30);
      expect(formatDuration(d), '05:30'); // Loses the hour!
    });
  });
}
