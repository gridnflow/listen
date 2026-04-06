import 'package:flutter_test/flutter_test.dart';
import 'package:listen/core/router/app_router.dart';

void main() {
  group('AppRouter configuration', () {
    test('router is configured and not null', () {
      expect(appRouter, isNotNull);
    });
  });
}
