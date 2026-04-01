import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spooler_tag/providers/form_providers.dart';
import 'package:spooler_tag/services/qr/qr_service.dart';

void main() {
  late ProviderContainer container;
  late SpoolFormNotifier notifier;

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(spoolFormProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  group('Full write flow', () {
    test('fill form -> build OpenSpoolData -> verify JSON output', () {
      // Set form fields
      notifier.setMaterial('PETG');
      notifier.setBrand('Bambu Lab');
      notifier.setColorHex('FF5733');
      notifier.setVariant('Silk');

      // Verify PETG default temps were applied
      final state = container.read(spoolFormProvider);
      expect(state.minTemp, 220);
      expect(state.maxTemp, 250);
      expect(state.bedMinTemp, 60);
      expect(state.bedMaxTemp, 80);

      // Generate a lot number
      notifier.generateNewLotNr();
      final stateWithLot = container.read(spoolFormProvider);
      expect(stateWithLot.lotNr.length, 9);

      // Build OpenSpoolData
      final data = notifier.buildOpenSpoolData();

      // Verify OpenSpoolData fields
      expect(data.type, 'PETG Silk');
      expect(data.brand, 'Bambu Lab');
      expect(data.colorHex, 'FF5733');
      expect(data.subtype, 'Silk');
      expect(data.minTemp, '220');
      expect(data.maxTemp, '250');
      expect(data.bedMinTemp, '60');
      expect(data.bedMaxTemp, '80');
      expect(data.lotNr, hasLength(9));
      expect(data.protocol, 'openspool');
      expect(data.version, '1.0');

      // Verify JSON round-trip with snake_case keys
      final json = data.toJson();
      expect(json['protocol'], 'openspool');
      expect(json['version'], '1.0');
      expect(json['type'], 'PETG Silk');
      expect(json['color_hex'], 'FF5733');
      expect(json['brand'], 'Bambu Lab');
      expect(json['min_temp'], '220');
      expect(json['max_temp'], '250');
      expect(json['bed_min_temp'], '60');
      expect(json['bed_max_temp'], '80');
      expect(json['subtype'], 'Silk');
      expect(json['lot_nr'], hasLength(9));

      // Verify JSON string parses correctly
      final jsonString = jsonEncode(json);
      final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
      expect(parsed['protocol'], 'openspool');
      expect(parsed['type'], 'PETG Silk');
      expect(parsed['color_hex'], 'FF5733');
      expect(parsed['brand'], 'Bambu Lab');
      expect(parsed['min_temp'], '220');
      expect(parsed['max_temp'], '250');
      expect(parsed['bed_min_temp'], '60');
      expect(parsed['bed_max_temp'], '80');
      expect(parsed['subtype'], 'Silk');
    });

    test('custom material and brand flow', () {
      notifier.setMaterial('Other');
      notifier.setCustomMaterial('PCTG');
      notifier.setBrand('Other');
      notifier.setCustomBrand('MyBrand');
      notifier.setVariant('Carbon');
      notifier.setColorHex('AABBCC');

      final data = notifier.buildOpenSpoolData();

      expect(data.type, 'PCTG Carbon');
      expect(data.brand, 'MyBrand');
      expect(data.colorHex, 'AABBCC');
      expect(data.subtype, 'Carbon');
    });

    test('no variant produces plain material type', () {
      notifier.setMaterial('PETG');
      notifier.setBrand('Generic');

      final data = notifier.buildOpenSpoolData();

      expect(data.type, 'PETG');
      expect(data.subtype, '');
    });

    test('empty lot number produces null in OpenSpoolData', () {
      notifier.setMaterial('PLA');
      notifier.setBrand('Test');

      final data = notifier.buildOpenSpoolData();
      expect(data.lotNr, isNull);

      final json = data.toJson();
      expect(json.containsKey('lot_nr'), isFalse);
    });
  });

  group('QR round-trip', () {
    test('encode form data as QR -> decode -> verify matches', () {
      notifier.setMaterial('PETG');
      notifier.setBrand('Bambu Lab');
      notifier.setColorHex('FF5733');
      notifier.setVariant('Silk');
      notifier.generateNewLotNr();

      final original = notifier.buildOpenSpoolData();

      final qrService = QrService();
      final encoded = qrService.encode(original);
      final decoded = qrService.decode(encoded);

      expect(decoded, isNotNull);
      expect(decoded!.protocol, original.protocol);
      expect(decoded.version, original.version);
      expect(decoded.type, original.type);
      expect(decoded.colorHex, original.colorHex);
      expect(decoded.brand, original.brand);
      expect(decoded.minTemp, original.minTemp);
      expect(decoded.maxTemp, original.maxTemp);
      expect(decoded.bedMinTemp, original.bedMinTemp);
      expect(decoded.bedMaxTemp, original.bedMaxTemp);
      expect(decoded.subtype, original.subtype);
      expect(decoded.lotNr, original.lotNr);
    });

    test('QR round-trip with no optional fields', () {
      notifier.setMaterial('PLA');
      notifier.setBrand('Generic');

      final original = notifier.buildOpenSpoolData();

      final qrService = QrService();
      final encoded = qrService.encode(original);
      final decoded = qrService.decode(encoded);

      expect(decoded, isNotNull);
      expect(decoded!.type, 'PLA');
      expect(decoded.brand, 'Generic');
      expect(decoded.lotNr, isNull);
      expect(decoded.spoolId, isNull);
    });
  });
}
