import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spooler_tag/providers/form_providers.dart';
import 'package:spooler_tag/ui/home/widgets/brand_selector.dart';
import 'package:spooler_tag/ui/home/widgets/color_selector.dart';
import 'package:spooler_tag/ui/home/widgets/material_selector.dart';
import 'package:spooler_tag/ui/home/widgets/nfc_action_buttons.dart';
import 'package:spooler_tag/ui/home/widgets/qr_action_buttons.dart';
import 'package:spooler_tag/ui/home/widgets/temperature_section.dart';

class FilamentForm extends ConsumerWidget {
  const FilamentForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(spoolFormProvider);
    final formNotifier = ref.read(spoolFormProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MaterialSelector(),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Variant',
              border: OutlineInputBorder(),
              hintText: 'e.g. Silk, Matte, CF',
            ),
            controller: TextEditingController(text: formState.variant)
              ..selection =
                  TextSelection.collapsed(offset: formState.variant.length),
            onChanged: formNotifier.setVariant,
          ),
          const SizedBox(height: 12),
          const ColorSelector(),
          const SizedBox(height: 12),
          const BrandSelector(),
          const SizedBox(height: 12),
          const TemperatureSection(),
          const SizedBox(height: 12),
          _LotNumberField(
            lotNr: formState.lotNr,
            isFromSpoolman: formState.isLotNrFromSpoolman,
            formNotifier: formNotifier,
          ),
          const SizedBox(height: 16),
          const NfcActionButtons(),
          const QrActionButtons(),
        ],
      ),
    );
  }
}

class _LotNumberField extends StatelessWidget {
  final String lotNr;
  final bool isFromSpoolman;
  final SpoolFormNotifier formNotifier;

  const _LotNumberField({
    required this.lotNr,
    required this.isFromSpoolman,
    required this.formNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Lot Number (hex)',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: lotNr)
              ..selection = TextSelection.collapsed(offset: lotNr.length),
            readOnly: isFromSpoolman,
            maxLength: 16,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f]')),
            ],
            onChanged: formNotifier.setLotNr,
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.tonal(
          onPressed: isFromSpoolman ? null : formNotifier.generateNewLotNr,
          child: const Text('New Lot #'),
        ),
      ],
    );
  }
}
