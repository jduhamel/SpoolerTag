import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spooler_tag/data/spool_provider/spool_provider.dart';
import 'package:spooler_tag/data/spool_provider/spoolman/spoolman_provider.dart';
import 'package:spooler_tag/models/filament_spool.dart';
import 'package:spooler_tag/providers/settings_providers.dart';

final currentSpoolProviderProvider = Provider<SpoolProvider>((ref) {
  final type = ref.watch(providerTypeProvider);
  return switch (type) {
    'spoolman' => SpoolmanProvider(),
    _ => SpoolmanProvider(),
  };
});

final spoolListProvider = FutureProvider<List<FilamentSpool>>((ref) async {
  final provider = ref.watch(currentSpoolProviderProvider);
  final url = ref.watch(spoolmanUrlProvider);
  final sort = ref.watch(sortOrderProvider);
  return provider.getSpools(baseUrl: url, sortBy: sort);
});

final selectedSpoolProvider = StateProvider<FilamentSpool?>((ref) => null);
