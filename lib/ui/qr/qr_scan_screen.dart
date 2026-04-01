import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:spooler_tag/providers/form_providers.dart';
import 'package:spooler_tag/services/qr/qr_service.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  final _qrService = QrService();
  bool _processed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: MobileScanner(
        onDetect: _onDetect,
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_processed) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue == null) continue;

      final data = _qrService.decode(rawValue);
      if (data != null) {
        _processed = true;
        ref.read(spoolFormProvider.notifier).loadFromOpenSpool(data);
        context.pop();
        return;
      }
    }

    // Only show error if we got barcodes but none were valid openspool data
    if (capture.barcodes.isNotEmpty) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Not a valid OpenSpool QR code'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
