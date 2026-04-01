import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spooler_tag/core/constants.dart';
import 'package:spooler_tag/data/local/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(),
);

/// Loads all settings from SharedPreferences on startup.
/// Read this once at app init, then use the StateProviders for live values.
final initialSettingsProvider = FutureProvider<_SettingsSnapshot>((ref) async {
  final repo = ref.read(settingsRepositoryProvider);
  final url = await repo.getSpoolmanUrl();
  final sort = await repo.getSortOrder();
  final type = await repo.getProviderType();
  return _SettingsSnapshot(
    spoolmanUrl: url,
    sortOrder: sort,
    providerType: type,
  );
});

final spoolmanUrlProvider = StateProvider<String>(
  (ref) => AppConstants.defaultSpoolmanUrl,
);

final sortOrderProvider = StateProvider<String?>(
  (ref) => null,
);

final providerTypeProvider = StateProvider<String>(
  (ref) => 'spoolman',
);

class _SettingsSnapshot {
  final String spoolmanUrl;
  final String? sortOrder;
  final String providerType;

  const _SettingsSnapshot({
    required this.spoolmanUrl,
    required this.sortOrder,
    required this.providerType,
  });
}
