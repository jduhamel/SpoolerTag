import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spooler_tag/providers/form_providers.dart';
import 'package:spooler_tag/providers/spool_providers.dart';

class SpoolDropdown extends ConsumerWidget {
  const SpoolDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spoolsAsync = ref.watch(spoolListProvider);
    final selectedSpool = ref.watch(selectedSpoolProvider);

    return spoolsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Error loading spools: $error',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      data: (spools) {
        if (spools.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No spools found - configure Spoolman in settings'),
          );
        }

        // Find selected spool's index by id match
        final selectedId = selectedSpool?.id;
        final matchIndex =
            spools.indexWhere((s) => s.id == selectedId);
        final currentSpool = matchIndex >= 0 ? spools[matchIndex] : null;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DropdownButtonFormField<int>(
            decoration: const InputDecoration(
              labelText: 'Select Spool',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.inventory_2),
            ),
            // ignore: deprecated_member_use
            value: currentSpool?.id,
            isExpanded: true,
            items: spools.map((spool) {
              return DropdownMenuItem(
                value: spool.id,
                child: Text(
                  '${spool.brand} - ${spool.displayName}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (id) {
              final spool = spools.firstWhere((s) => s.id == id);
              ref.read(selectedSpoolProvider.notifier).state = spool;
              ref.read(spoolFormProvider.notifier).loadFromFilamentSpool(spool);
            },
          ),
        );
      },
    );
  }
}
