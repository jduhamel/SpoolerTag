import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:spooler_tag/models/open_spool_data.dart';
import 'package:spooler_tag/services/qr/qr_service.dart';

class QrDisplayScreen extends StatelessWidget {
  const QrDisplayScreen({super.key, required this.data});

  final OpenSpoolData data;

  @override
  Widget build(BuildContext context) {
    final qrData = QrService().encode(data);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('QR Code')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${data.type} - ${data.brand}',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                if (data.colorHex != null && data.colorHex!.isNotEmpty)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _parseColor(data.colorHex!),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                QrImageView(
                  data: qrData,
                  size: 280,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Color _parseColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return Colors.grey;
    if (cleaned.length == 6) return Color(0xFF000000 | value);
    return Color(value);
  }
}
