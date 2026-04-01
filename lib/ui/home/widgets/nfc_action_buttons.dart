import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spooler_tag/models/nfc_result.dart';
import 'package:spooler_tag/providers/form_providers.dart';
import 'package:spooler_tag/providers/nfc_providers.dart';
import 'package:spooler_tag/services/nfc/nfc_service.dart';

class NfcActionButtons extends ConsumerWidget {
  const NfcActionButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _writeTag(context, ref),
                  icon: const Icon(Icons.nfc),
                  label: const Text('Write to NFC'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _readTag(context, ref),
                  icon: const Icon(Icons.nfc),
                  label: const Text('Read NFC Tag'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _previewTag(context, ref),
            icon: const Icon(Icons.code),
            label: const Text('Preview Tag Data'),
          ),
        ],
      ),
    );
  }

  void _previewTag(BuildContext context, WidgetRef ref) {
    final formNotifier = ref.read(spoolFormProvider.notifier);
    final data = formNotifier.buildOpenSpoolData();
    final json = const JsonEncoder.withIndent('  ').convert(data.toJson());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('NDEF Tag Preview'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'MIME type: application/json',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  json,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${utf8.encode(jsonEncode(data.toJson())).length} bytes',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _writeTag(BuildContext context, WidgetRef ref) async {
    final nfcService = ref.read(nfcServiceProvider);
    final formNotifier = ref.read(spoolFormProvider.notifier);
    final data = formNotifier.buildOpenSpoolData();

    ref.read(nfcModeProvider.notifier).state = NfcMode.writing;
    ref.read(nfcResultProvider.notifier).state = null;

    try {
      final result = await nfcService.writeTag(data);
      ref.read(nfcResultProvider.notifier).state = result;
    } catch (e) {
      ref.read(nfcResultProvider.notifier).state = NfcError(e.toString());
    } finally {
      ref.read(nfcModeProvider.notifier).state = NfcMode.idle;
    }
  }

  Future<void> _readTag(BuildContext context, WidgetRef ref) async {
    final nfcService = ref.read(nfcServiceProvider);
    final formNotifier = ref.read(spoolFormProvider.notifier);

    ref.read(nfcModeProvider.notifier).state = NfcMode.reading;
    ref.read(nfcResultProvider.notifier).state = null;

    try {
      final result = await nfcService.readTag();
      ref.read(nfcResultProvider.notifier).state = result;
      if (result is NfcReadSuccess) {
        formNotifier.loadFromOpenSpool(result.data);
      }
    } catch (e) {
      ref.read(nfcResultProvider.notifier).state = NfcError(e.toString());
    } finally {
      ref.read(nfcModeProvider.notifier).state = NfcMode.idle;
    }
  }
}
