import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spooler_tag/models/open_spool_data.dart';
import 'package:spooler_tag/providers/form_providers.dart';

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

  group('Full read flow', () {
    test('NFC tag JSON -> parse -> populate form', () {
      const jsonString = '''
{
  "protocol": "openspool",
  "version": "1.0",
  "type": "ABS",
  "color_hex": "000000",
  "brand": "eSUN",
  "min_temp": "230",
  "max_temp": "260",
  "bed_min_temp": "90",
  "bed_max_temp": "110",
  "subtype": "Pro",
  "spool_id": "42",
  "lot_nr": "ABC123DEF"
}
''';

      final data = OpenSpoolData.fromJson(jsonString);
      expect(data, isNotNull);

      notifier.loadFromOpenSpool(data!);

      final state = container.read(spoolFormProvider);
      expect(state.material, 'ABS');
      expect(state.variant, 'Pro');
      expect(state.colorHex, '000000');
      expect(state.brand, 'eSUN');
      expect(state.minTemp, 230);
      expect(state.maxTemp, 260);
      expect(state.bedMinTemp, 90);
      expect(state.bedMaxTemp, 110);
      expect(state.lotNr, 'ABC123DEF');
      expect(state.spoolId, '42');
    });

    test('JSON with language prefix parses correctly', () {
      final innerJson = jsonEncode({
        'protocol': 'openspool',
        'version': '1.0',
        'type': 'PLA',
        'color_hex': 'FFFFFF',
        'brand': 'Prusa',
        'min_temp': '190',
        'max_temp': '220',
        'bed_min_temp': '40',
        'bed_max_temp': '65',
        'subtype': 'Matte',
        'lot_nr': '123456789',
      });

      final prefixed = 'en$innerJson';

      final data = OpenSpoolData.fromJson(prefixed);
      expect(data, isNotNull);

      notifier.loadFromOpenSpool(data!);

      final state = container.read(spoolFormProvider);
      expect(state.material, 'PLA');
      expect(state.variant, 'Matte');
      expect(state.colorHex, 'FFFFFF');
      expect(state.brand, 'Prusa');
      expect(state.minTemp, 190);
      expect(state.maxTemp, 220);
      expect(state.bedMinTemp, 40);
      expect(state.bedMaxTemp, 65);
      expect(state.lotNr, '123456789');
    });

    test('missing optional fields use material defaults', () {
      const jsonString = '''
{
  "protocol": "openspool",
  "version": "1.0",
  "type": "PETG",
  "color_hex": "00FF00",
  "brand": "Hatchbox",
  "min_temp": "220",
  "max_temp": "250"
}
''';

      final data = OpenSpoolData.fromJson(jsonString);
      expect(data, isNotNull);

      notifier.loadFromOpenSpool(data!);

      final state = container.read(spoolFormProvider);
      expect(state.material, 'PETG');
      expect(state.variant, ''); // 'Basic' subtype default maps to ''
      expect(state.brand, 'Hatchbox');
      expect(state.minTemp, 220);
      expect(state.maxTemp, 250);
      // bed temps null in JSON -> parseTemp falls back to material defaults
      expect(state.bedMinTemp, 60); // PETG default
      expect(state.bedMaxTemp, 80); // PETG default
      expect(state.lotNr, '');
      expect(state.spoolId, isNull);
    });

    test('invalid JSON returns null', () {
      final data = OpenSpoolData.fromJson('not json at all');
      expect(data, isNull);
    });

    test('non-openspool protocol returns null', () {
      const jsonString = '''
{
  "protocol": "other",
  "version": "1.0",
  "type": "PLA"
}
''';
      final data = OpenSpoolData.fromJson(jsonString);
      expect(data, isNull);
    });
  });
}
