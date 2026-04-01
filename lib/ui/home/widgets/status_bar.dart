import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spooler_tag/models/nfc_result.dart';
import 'package:spooler_tag/providers/nfc_providers.dart';
import 'package:spooler_tag/services/nfc/nfc_service.dart';

class StatusBar extends ConsumerStatefulWidget {
  const StatusBar({super.key});

  @override
  ConsumerState<StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends ConsumerState<StatusBar> {
  Timer? _dismissTimer;
  bool _visible = false;

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(nfcModeProvider);
    final result = ref.watch(nfcResultProvider);

    String statusMessage;
    Color color;

    if (mode == NfcMode.reading) {
      statusMessage = 'Hold device near NFC tag...';
      color = Colors.amber;
      _scheduleAutoDismiss(ref);
    } else if (mode == NfcMode.writing) {
      statusMessage = 'Hold device near NFC tag to write...';
      color = Colors.amber;
      _scheduleAutoDismiss(ref);
    } else if (result != null) {
      switch (result) {
        case NfcWriteSuccess():
          statusMessage = 'Tag written successfully!';
          color = Colors.green;
        case NfcReadSuccess():
          statusMessage = 'Tag read successfully!';
          color = Colors.green;
        case NfcError(:final message):
          statusMessage = 'Error: $message';
          color = Colors.red;
        case NfcTagDetected():
          statusMessage = 'Tag detected';
          color = Colors.amber;
      }
      _scheduleAutoDismiss(ref);
    } else {
      _visible = false;
      return const SizedBox.shrink();
    }

    _visible = true;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _visible ? null : 0,
      child: Material(
        color: color,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (mode != NfcMode.idle)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  statusMessage,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scheduleAutoDismiss(WidgetRef ref) {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(milliseconds: 3600), () {
      if (mounted) {
        ref.read(nfcModeProvider.notifier).state = NfcMode.idle;
        ref.read(nfcResultProvider.notifier).state = null;
      }
    });
  }
}
