import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_providers.dart';
import '../../providers/spool_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late String _providerType;
  late TextEditingController _urlController;
  late String? _sortOrder;

  static const _sortOptions = <String?, String>{
    null: 'None',
    'filament.vendor.name:asc': 'Brand A-Z',
    'filament.material:asc': 'Material A-Z',
    'last_used:desc': 'Last Used',
  };

  @override
  void initState() {
    super.initState();
    _providerType = ref.read(providerTypeProvider);
    _urlController = TextEditingController(
      text: ref.read(spoolmanUrlProvider),
    );
    _sortOrder = ref.read(sortOrderProvider);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final url = _urlController.text;
    final sort = _sortOrder;
    final type = _providerType;

    final repo = ref.read(settingsRepositoryProvider);
    await repo.setSpoolmanUrl(url);
    await repo.setSortOrder(sort);
    await repo.setProviderType(type);

    ref.read(spoolmanUrlProvider.notifier).state = url;
    ref.read(sortOrderProvider.notifier).state = sort;
    ref.read(providerTypeProvider.notifier).state = type;
    ref.invalidate(spoolListProvider);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Spool Provider Type'),
            initialValue: _providerType,
            items: const [
              DropdownMenuItem(value: 'spoolman', child: Text('Spoolman')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _providerType = value);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(labelText: 'Server URL'),
            maxLength: 150,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            decoration: const InputDecoration(labelText: 'Sort Order'),
            initialValue: _sortOrder,
            items: _sortOptions.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (value) => setState(() => _sortOrder = value),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _onSave,
            child: const Text('Save'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
