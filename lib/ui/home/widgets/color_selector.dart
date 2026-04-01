import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flex_color_picker/flex_color_picker.dart';

import 'package:spooler_tag/providers/form_providers.dart';

class _PresetColor {
  final String name;
  final String? hex;

  const _PresetColor(this.name, this.hex);
}

const _presetColors = [
  _PresetColor('No Color', null),
  _PresetColor('White', 'FFFFFF'),
  _PresetColor('Red', 'FF0000'),
  _PresetColor('Blue', '0000FF'),
  _PresetColor('Green', '00FF00'),
  _PresetColor('Yellow', 'FFFF00'),
  _PresetColor('Orange', 'FFA500'),
  _PresetColor('Pink', 'FFC0CB'),
  _PresetColor('Black', '000000'),
];

const _customValue = '__custom__';

class ColorSelector extends ConsumerWidget {
  const ColorSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(spoolFormProvider);
    final formNotifier = ref.read(spoolFormProvider.notifier);
    final colorHex = formState.colorHex;

    // Determine current dropdown value
    final matchingPreset = _presetColors.where((p) => p.hex == colorHex);
    final dropdownValue = matchingPreset.isNotEmpty
        ? (matchingPreset.first.hex ?? '')
        : _customValue;

    final items = <DropdownMenuItem<String>>[
      for (final preset in _presetColors)
        DropdownMenuItem(
          value: preset.hex ?? '',
          child: Row(
            children: [
              _ColorCircle(hex: preset.hex),
              const SizedBox(width: 8),
              Text(preset.name),
            ],
          ),
        ),
      DropdownMenuItem(
        value: _customValue,
        child: Row(
          children: [
            _ColorCircle(hex: colorHex),
            const SizedBox(width: 8),
            const Text('Custom...'),
          ],
        ),
      ),
    ];

    return Row(
      children: [
        _ColorCircle(hex: colorHex, size: 32),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Color',
              border: OutlineInputBorder(),
            ),
            // ignore: deprecated_member_use
            value: dropdownValue,
            items: items,
            onChanged: (value) {
              if (value == _customValue) {
                _showColorPicker(context, colorHex, formNotifier);
              } else {
                formNotifier.setColorHex(value!.isEmpty ? null : value);
              }
            },
          ),
        ),
      ],
    );
  }

  void _showColorPicker(
    BuildContext context,
    String? currentHex,
    SpoolFormNotifier formNotifier,
  ) {
    Color initial = Colors.blue;
    if (currentHex != null && currentHex.length == 6) {
      initial = Color(int.parse('FF$currentHex', radix: 16));
    }

    Color pickedColor = initial;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            color: initial,
            onColorChanged: (color) => pickedColor = color,
            pickersEnabled: const <ColorPickerType, bool>{
              ColorPickerType.wheel: true,
              ColorPickerType.primary: false,
              ColorPickerType.accent: false,
            },
            enableOpacity: false,
            showColorCode: true,
            colorCodeHasColor: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // Extract hex without alpha
              final hex = pickedColor.toARGB32()
                  .toRadixString(16)
                  .padLeft(8, '0')
                  .substring(2)
                  .toUpperCase();
              formNotifier.setColorHex(hex);
              Navigator.of(context).pop();
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }
}

class _ColorCircle extends StatelessWidget {
  final String? hex;
  final double size;

  const _ColorCircle({this.hex, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final color = hex != null && hex!.length == 6
        ? Color(int.parse('FF$hex', radix: 16))
        : null;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color ?? Colors.transparent,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      child: color == null
          ? Icon(Icons.block, size: size * 0.7, color: Colors.grey)
          : null,
    );
  }
}
