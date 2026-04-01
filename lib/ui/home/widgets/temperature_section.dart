import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spooler_tag/providers/form_providers.dart';

class TemperatureSection extends ConsumerWidget {
  const TemperatureSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(spoolFormProvider);
    final formNotifier = ref.read(spoolFormProvider.notifier);

    return Column(
      children: [
        _TempCard(
          title: 'Nozzle Temperature',
          minValue: formState.minTemp,
          maxValue: formState.maxTemp,
          minField: TempField.minTemp,
          maxField: TempField.maxTemp,
          formNotifier: formNotifier,
        ),
        const SizedBox(height: 8),
        _TempCard(
          title: 'Bed Temperature',
          minValue: formState.bedMinTemp,
          maxValue: formState.bedMaxTemp,
          minField: TempField.bedMinTemp,
          maxField: TempField.bedMaxTemp,
          formNotifier: formNotifier,
        ),
      ],
    );
  }
}

class _TempCard extends StatelessWidget {
  final String title;
  final int minValue;
  final int maxValue;
  final TempField minField;
  final TempField maxField;
  final SpoolFormNotifier formNotifier;

  const _TempCard({
    required this.title,
    required this.minValue,
    required this.maxValue,
    required this.minField,
    required this.maxField,
    required this.formNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _TempRow(
              label: 'Min',
              value: minValue,
              field: minField,
              formNotifier: formNotifier,
            ),
            const SizedBox(height: 4),
            _TempRow(
              label: 'Max',
              value: maxValue,
              field: maxField,
              formNotifier: formNotifier,
            ),
          ],
        ),
      ),
    );
  }
}

class _TempRow extends StatelessWidget {
  final String label;
  final int value;
  final TempField field;
  final SpoolFormNotifier formNotifier;

  const _TempRow({
    required this.label,
    required this.value,
    required this.field,
    required this.formNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 36, child: Text(label)),
        IconButton(
          icon: const Text('-5'),
          onPressed: () => formNotifier.adjustTemp(field, -5),
          visualDensity: VisualDensity.compact,
        ),
        SizedBox(
          width: 72,
          child: TextField(
            controller: TextEditingController(text: value.toString()),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              border: OutlineInputBorder(),
              suffixText: '\u00B0C',
            ),
            onSubmitted: (text) {
              final parsed = int.tryParse(text);
              if (parsed != null) {
                final delta = parsed - value;
                formNotifier.adjustTemp(field, delta);
              }
            },
          ),
        ),
        IconButton(
          icon: const Text('+5'),
          onPressed: () => formNotifier.adjustTemp(field, 5),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
