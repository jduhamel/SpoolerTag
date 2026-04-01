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
    final capability = ref.watch(nfcCapabilityProvider);

    return capability.when(
      data: (cap) {
        if (cap != NfcCapability.available) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
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
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
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
