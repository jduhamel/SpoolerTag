import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spooler_tag/models/filament_spool.dart';
import 'package:spooler_tag/providers/nfc_providers.dart';
import 'package:spooler_tag/providers/spool_providers.dart';
import 'package:spooler_tag/services/nfc/nfc_service.dart';
import 'package:spooler_tag/ui/home/home_screen.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spoolListProvider.overrideWith(
            (ref) => Future.value(<FilamentSpool>[]),
          ),
          nfcCapabilityProvider.overrideWith(
            (ref) => Future.value(NfcCapability.unsupported),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SpoolerTag'), findsOneWidget);
  });
}
