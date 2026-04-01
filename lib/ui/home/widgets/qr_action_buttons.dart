import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spooler_tag/providers/form_providers.dart';

class QrActionButtons extends ConsumerWidget {
  const QrActionButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                final data =
                    ref.read(spoolFormProvider.notifier).buildOpenSpoolData();
                context.push('/qr/display', extra: data);
              },
              icon: const Icon(Icons.qr_code),
              label: const Text('Show QR Code'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.push('/qr/scan'),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR Code'),
            ),
          ),
        ],
      ),
    );
  }
}
