import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:spooler_tag/models/open_spool_data.dart';

void main() {
  group('OpenSpoolData', () {
    group('toJson()', () {
      test('produces correct snake_case keys', () {
        final data = OpenSpoolData(
          type: 'PLA',
          colorHex: 'FF0000',
          brand: 'Bambu Lab',
          minTemp: '190',
          maxTemp: '220',
          subtype: 'Silk',
        );

        final json = data.toJson();

        expect(json.containsKey('protocol'), true);
        expect(json.containsKey('version'), true);
        expect(json.containsKey('type'), true);
        expect(json.containsKey('color_hex'), true);
        expect(json.containsKey('brand'), true);
        expect(json.containsKey('min_temp'), true);
        expect(json.containsKey('max_temp'), true);
        expect(json.containsKey('subtype'), true);

        // No camelCase keys
        expect(json.containsKey('colorHex'), false);
        expect(json.containsKey('minTemp'), false);
        expect(json.containsKey('maxTemp'), false);
        expect(json.containsKey('bedMinTemp'), false);
        expect(json.containsKey('bedMaxTemp'), false);
        expect(json.containsKey('spoolId'), false);
        expect(json.containsKey('lotNr'), false);
      });

      test('colorHex serializes as empty string when null', () {
        final data = OpenSpoolData(
          type: 'PLA',
          colorHex: null,
          brand: 'Generic',
          minTemp: '190',
          maxTemp: '220',
          subtype: 'Basic',
        );

        final json = data.toJson();
        expect(json['color_hex'], '');
      });

      test('optional fields are absent from JSON when null', () {
        final data = OpenSpoolData(
          type: 'PLA',
          colorHex: 'FF0000',
          brand: 'Generic',
          minTemp: '190',
          maxTemp: '220',
          subtype: 'Basic',
          bedMinTemp: null,
          bedMaxTemp: null,
          spoolId: null,
          lotNr: null,
        );

        final json = data.toJson();
        expect(json.containsKey('bed_min_temp'), false);
        expect(json.containsKey('bed_max_temp'), false);
        expect(json.containsKey('spool_id'), false);
        expect(json.containsKey('lot_nr'), false);
      });

      test('optional fields are present when non-null', () {
        final data = OpenSpoolData(
          type: 'PLA',
          colorHex: 'FF0000',
          brand: 'Generic',
          minTemp: '190',
          maxTemp: '220',
          subtype: 'Basic',
          bedMinTemp: '60',
          bedMaxTemp: '80',
          spoolId: '42',
          lotNr: 'ABC123DEF',
        );

        final json = data.toJson();
        expect(json['bed_min_temp'], '60');
        expect(json['bed_max_temp'], '80');
        expect(json['spool_id'], '42');
        expect(json['lot_nr'], 'ABC123DEF');
      });

      test('subtype is included when non-empty', () {
        final data = OpenSpoolData(
          type: 'PLA',
          colorHex: null,
          brand: 'Generic',
          minTemp: '190',
          maxTemp: '220',
          subtype: 'Silk',
        );

        final json = data.toJson();
        expect(json['subtype'], 'Silk');
      });

      test('subtype is absent when empty string', () {
        final data = OpenSpoolData(
          type: 'PLA',
          colorHex: null,
          brand: 'Generic',
          minTemp: '190',
          maxTemp: '220',
          subtype: '',
        );

        final json = data.toJson();
        expect(json.containsKey('subtype'), false);
      });
    });

    group('fromJson()', () {
      test('round-trips all fields', () {
        final original = OpenSpoolData(
          type: 'PETG',
          colorHex: '00FF00',
          brand: 'eSUN',
          minTemp: '220',
          maxTemp: '250',
          subtype: 'CF',
          bedMinTemp: '60',
          bedMaxTemp: '80',
          spoolId: '7',
          lotNr: 'A1B2C3D4E',
        );

        final jsonStr = jsonEncode(original.toJson());
        final restored = OpenSpoolData.fromJson(jsonStr);

        expect(restored, isNotNull);
        expect(restored!.protocol, 'openspool');
        expect(restored.version, '1.0');
        expect(restored.type, 'PETG');
        expect(restored.colorHex, '00FF00');
        expect(restored.brand, 'eSUN');
        expect(restored.minTemp, '220');
        expect(restored.maxTemp, '250');
        expect(restored.subtype, 'CF');
        expect(restored.bedMinTemp, '60');
        expect(restored.bedMaxTemp, '80');
        expect(restored.spoolId, '7');
        expect(restored.lotNr, 'A1B2C3D4E');
      });

      test('handles language prefix (e.g., "en{...}" strips to "{")', () {
        final jsonStr =
            'en{"protocol":"openspool","version":"1.0","type":"PLA","color_hex":"","brand":"Generic","min_temp":"200","max_temp":"220"}';

        final data = OpenSpoolData.fromJson(jsonStr);

        expect(data, isNotNull);
        expect(data!.type, 'PLA');
        expect(data.brand, 'Generic');
      });

      test('returns null for non-openspool JSON', () {
        final jsonStr = '{"protocol":"other","version":"1.0","type":"PLA"}';
        final data = OpenSpoolData.fromJson(jsonStr);
        expect(data, isNull);
      });

      test('returns null for invalid JSON', () {
        final data = OpenSpoolData.fromJson('not json at all');
        expect(data, isNull);
      });

      test('uses material defaults when temps missing', () {
        final jsonStr = jsonEncode({
          'protocol': 'openspool',
          'version': '1.0',
          'type': 'PLA',
          'color_hex': '',
          'brand': 'Generic',
        });

        final data = OpenSpoolData.fromJson(jsonStr);

        expect(data, isNotNull);
        expect(data!.minTemp, '190');
        expect(data.maxTemp, '220');
      });

      test('defaults subtype to "Basic" when field is missing', () {
        final jsonStr = jsonEncode({
          'protocol': 'openspool',
          'version': '1.0',
          'type': 'PLA',
          'color_hex': '',
          'brand': 'Generic',
          'min_temp': '190',
          'max_temp': '220',
        });

        final data = OpenSpoolData.fromJson(jsonStr);

        expect(data, isNotNull);
        expect(data!.subtype, 'Basic');
      });
    });

    group('generateLotNr()', () {
      test('produces 9-char uppercase hex string', () {
        final lotNr = OpenSpoolData.generateLotNr();

        expect(lotNr.length, 9);
        expect(lotNr, matches(RegExp(r'^[0-9A-F]{9}$')));
      });

      test('generates different values on each call', () {
        final a = OpenSpoolData.generateLotNr();
        final b = OpenSpoolData.generateLotNr();
        expect(a, isNot(equals(b)));
      });
    });

    group('toOpenSpoolData()', () {
      // Tested in filament_spool_test.dart indirectly
      test('subtype is raw variant string', () {
        final data = OpenSpoolData(
          type: 'PLA',
          colorHex: null,
          brand: 'Generic',
          minTemp: '190',
          maxTemp: '220',
          subtype: 'Basic',
        );

        final json = data.toJson();
        expect(json['subtype'], 'Basic');
      });
    });
  });
}
