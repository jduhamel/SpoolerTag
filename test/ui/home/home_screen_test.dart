import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spooler_tag/data/local/material_database.dart';
import 'package:spooler_tag/models/filament_spool.dart';
import 'package:spooler_tag/providers/form_providers.dart';
import 'package:spooler_tag/providers/nfc_providers.dart';
import 'package:spooler_tag/providers/spool_providers.dart';
import 'package:spooler_tag/services/nfc/nfc_service.dart';
import 'package:spooler_tag/ui/home/home_screen.dart';
import 'package:spooler_tag/ui/home/widgets/material_selector.dart';
import 'package:spooler_tag/ui/home/widgets/nfc_action_buttons.dart';
import 'package:spooler_tag/ui/home/widgets/qr_action_buttons.dart';

Widget _buildTestApp({
  List<Override> overrides = const [],
  Widget? child,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: child ?? const HomeScreen(),
    ),
  );
}

void main() {
  group('HomeScreen', () {
    testWidgets('renders app bar with title and settings button',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        overrides: [
          spoolListProvider.overrideWith(
            (ref) => Future.value(<FilamentSpool>[]),
          ),
          nfcCapabilityProvider.overrideWith(
            (ref) => Future.value(NfcCapability.unsupported),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('SpoolerTag'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('shows empty state when no spools', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        overrides: [
          spoolListProvider.overrideWith(
            (ref) => Future.value(<FilamentSpool>[]),
          ),
          nfcCapabilityProvider.overrideWith(
            (ref) => Future.value(NfcCapability.unsupported),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(
        find.text('No spools found - configure Spoolman in settings'),
        findsOneWidget,
      );
    });

    testWidgets('shows spool dropdown with spools loaded', (tester) async {
      final testSpools = [
        FilamentSpool(
          id: 1,
          material: 'PLA',
          brand: 'Bambu Lab',
          colorHex: 'FF0000',
        ),
        FilamentSpool(
          id: 2,
          material: 'PETG',
          variant: 'Silk',
          brand: 'eSUN',
        ),
      ];

      await tester.pumpWidget(_buildTestApp(
        overrides: [
          spoolListProvider.overrideWith(
            (ref) => Future.value(testSpools),
          ),
          nfcCapabilityProvider.overrideWith(
            (ref) => Future.value(NfcCapability.unsupported),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Select Spool'), findsOneWidget);
    });

    testWidgets('renders filament form sections', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        overrides: [
          spoolListProvider.overrideWith(
            (ref) => Future.value(<FilamentSpool>[]),
          ),
          nfcCapabilityProvider.overrideWith(
            (ref) => Future.value(NfcCapability.unsupported),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Verify form fields are present
      expect(find.text('Material'), findsOneWidget);
      expect(find.text('Variant'), findsOneWidget);
      expect(find.text('Color'), findsOneWidget);
      expect(find.text('Brand'), findsOneWidget);
      expect(find.text('Nozzle Temperature'), findsOneWidget);
      expect(find.text('Bed Temperature'), findsOneWidget);
      expect(find.text('Lot Number (hex)'), findsOneWidget);
      expect(find.text('New Lot #'), findsOneWidget);
    });
  });

  group('MaterialSelector', () {
    testWidgets('shows all materials in dropdown', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        child: const Scaffold(body: SingleChildScrollView(child: MaterialSelector())),
      ));
      await tester.pumpAndSettle();

      // Open the dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // All materials should appear in the dropdown list
      for (final material in MaterialDatabase.materials) {
        expect(find.text(material.name), findsWidgets);
      }
    });

    testWidgets('changing material updates form state', (tester) async {
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          child: Builder(builder: (context) {
            return MaterialApp(
              home: Consumer(
                builder: (context, ref, _) {
                  // Capture the container via ref
                  container = ProviderScope.containerOf(context);
                  return const Scaffold(
                    body: SingleChildScrollView(child: MaterialSelector()),
                  );
                },
              ),
            );
          }),
        ),
      );
      await tester.pumpAndSettle();

      // Tap to open dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Select ABS
      await tester.tap(find.text('ABS').last);
      await tester.pumpAndSettle();

      final state = container.read(spoolFormProvider);
      expect(state.material, 'ABS');
      // Temps should reset to ABS defaults
      expect(state.minTemp, 220);
      expect(state.maxTemp, 260);
    });
  });

  group('NfcActionButtons', () {
    testWidgets('hidden when NFC is unsupported', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        overrides: [
          nfcCapabilityProvider.overrideWith(
            (ref) => Future.value(NfcCapability.unsupported),
          ),
        ],
        child: const Scaffold(body: NfcActionButtons()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Write to NFC'), findsNothing);
      expect(find.text('Read NFC Tag'), findsNothing);
    });

    testWidgets('visible when NFC is available', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        overrides: [
          nfcCapabilityProvider.overrideWith(
            (ref) => Future.value(NfcCapability.available),
          ),
        ],
        child: const Scaffold(body: NfcActionButtons()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Write to NFC'), findsOneWidget);
      expect(find.text('Read NFC Tag'), findsOneWidget);
    });
  });

  group('QrActionButtons', () {
    testWidgets('always visible', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        child: const Scaffold(body: QrActionButtons()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Show QR Code'), findsOneWidget);
      expect(find.text('Scan QR Code'), findsOneWidget);
    });

    testWidgets('visible as fallback when NFC unsupported', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        overrides: [
          spoolListProvider.overrideWith(
            (ref) => Future.value(<FilamentSpool>[]),
          ),
          nfcCapabilityProvider.overrideWith(
            (ref) => Future.value(NfcCapability.unsupported),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // NFC buttons should be hidden
      expect(find.text('Write to NFC'), findsNothing);
      // QR buttons should be visible
      expect(find.text('Show QR Code'), findsOneWidget);
      expect(find.text('Scan QR Code'), findsOneWidget);
    });
  });
}
