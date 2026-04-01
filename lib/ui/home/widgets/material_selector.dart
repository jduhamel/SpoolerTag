import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spooler_tag/data/local/material_database.dart';
import 'package:spooler_tag/providers/form_providers.dart';

class MaterialSelector extends ConsumerWidget {
  const MaterialSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(spoolFormProvider);
    final formNotifier = ref.read(spoolFormProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Material',
            border: OutlineInputBorder(),
          ),
          // ignore: deprecated_member_use
          value: MaterialDatabase.materials.any((m) => m.name == formState.material)
              ? formState.material
              : 'Other',
          items: MaterialDatabase.materials
              .map((m) => DropdownMenuItem(value: m.name, child: Text(m.name)))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              formNotifier.setMaterial(value);
            }
          },
        ),
        if (formState.material == 'Other') ...[
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Custom Material',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: formState.customMaterial)
              ..selection = TextSelection.collapsed(
                  offset: formState.customMaterial.length),
            onChanged: formNotifier.setCustomMaterial,
          ),
        ],
      ],
    );
  }
}
