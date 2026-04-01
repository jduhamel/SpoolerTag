import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spooler_tag/core/constants.dart';
import 'package:spooler_tag/data/local/settings_repository.dart';

void main() {
  late SettingsRepository repo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = SettingsRepository();
  });

  group('spoolmanUrl', () {
    test('returns default when nothing saved', () async {
      final url = await repo.getSpoolmanUrl();
      expect(url, AppConstants.defaultSpoolmanUrl);
    });

    test('saves and loads a value', () async {
      await repo.setSpoolmanUrl('http://10.0.0.5:7912');
      final url = await repo.getSpoolmanUrl();
      expect(url, 'http://10.0.0.5:7912');
    });

    test('saves empty string', () async {
      await repo.setSpoolmanUrl('');
      final url = await repo.getSpoolmanUrl();
      expect(url, '');
    });

    test('overwrites previous value', () async {
      await repo.setSpoolmanUrl('http://first');
      await repo.setSpoolmanUrl('http://second');
      final url = await repo.getSpoolmanUrl();
      expect(url, 'http://second');
    });
  });

  group('sortOrder', () {
    test('returns null when nothing saved', () async {
      final sort = await repo.getSortOrder();
      expect(sort, isNull);
    });

    test('saves and loads a value', () async {
      await repo.setSortOrder('name_asc');
      final sort = await repo.getSortOrder();
      expect(sort, 'name_asc');
    });

    test('saves null to clear value', () async {
      await repo.setSortOrder('name_asc');
      await repo.setSortOrder(null);
      final sort = await repo.getSortOrder();
      expect(sort, isNull);
    });

    test('saves empty string as distinct from null', () async {
      await repo.setSortOrder('');
      final sort = await repo.getSortOrder();
      expect(sort, '');
    });
  });

  group('providerType', () {
    test('returns default when nothing saved', () async {
      final type = await repo.getProviderType();
      expect(type, 'spoolman');
    });

    test('saves and loads a value', () async {
      await repo.setProviderType('manual');
      final type = await repo.getProviderType();
      expect(type, 'manual');
    });

    test('saves empty string', () async {
      await repo.setProviderType('');
      final type = await repo.getProviderType();
      expect(type, '');
    });
  });

  group('cross-field isolation', () {
    test('setting one field does not affect others', () async {
      await repo.setSpoolmanUrl('http://custom');
      final sort = await repo.getSortOrder();
      final type = await repo.getProviderType();
      expect(sort, isNull);
      expect(type, 'spoolman');
    });
  });

  group('persistence across instances', () {
    test('new repository instance reads previously saved values', () async {
      await repo.setSpoolmanUrl('http://saved');
      await repo.setSortOrder('color_desc');
      await repo.setProviderType('manual');

      final repo2 = SettingsRepository();
      expect(await repo2.getSpoolmanUrl(), 'http://saved');
      expect(await repo2.getSortOrder(), 'color_desc');
      expect(await repo2.getProviderType(), 'manual');
    });
  });
}
