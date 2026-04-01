import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spooler_tag/data/local/brand_database.dart';
import 'package:spooler_tag/providers/form_providers.dart';

class BrandSelector extends ConsumerWidget {
  const BrandSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(spoolFormProvider);
    final formNotifier = ref.read(spoolFormProvider.notifier);

    final effectiveBrand = BrandDatabase.brands.contains(formState.brand)
        ? formState.brand
        : 'Other';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Brand',
            border: OutlineInputBorder(),
          ),
          // ignore: deprecated_member_use
          value: effectiveBrand,
          items: BrandDatabase.brands
              .map((b) => DropdownMenuItem(value: b, child: Text(b)))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              formNotifier.setBrand(value);
            }
          },
        ),
        if (effectiveBrand == 'Other') ...[
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Custom Brand',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: formState.customBrand)
              ..selection = TextSelection.collapsed(
                  offset: formState.customBrand.length),
            onChanged: formNotifier.setCustomBrand,
          ),
        ],
      ],
    );
  }
}
