import 'package:flutter_test/flutter_test.dart';

import 'package:spooler_tag/core/constants.dart';

void main() {
  group('AppConstants', () {
    test('cacheValidity is 30 seconds', () {
      expect(
        AppConstants.cacheValidity,
        const Duration(milliseconds: 30000),
      );
      expect(AppConstants.cacheValidity.inSeconds, 30);
    });

    test('pageSize is 10', () {
      expect(AppConstants.pageSize, 10);
    });

    test('defaultSpoolmanUrl starts with http', () {
      expect(AppConstants.defaultSpoolmanUrl, startsWith('http://'));
    });

    test('connectTimeout is 3 seconds', () {
      expect(
        AppConstants.connectTimeout,
        const Duration(milliseconds: 3000),
      );
    });

    test('readTimeout is 5 seconds', () {
      expect(
        AppConstants.readTimeout,
        const Duration(milliseconds: 5000),
      );
    });

    test('tagCacheDuration is 5 seconds', () {
      expect(
        AppConstants.tagCacheDuration,
        const Duration(seconds: 5),
      );
    });
  });
}
