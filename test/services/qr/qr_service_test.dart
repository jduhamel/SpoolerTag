import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:spooler_tag/models/open_spool_data.dart';
import 'package:spooler_tag/services/qr/qr_service.dart';

OpenSpoolData _testSpool({
  String type = 'PLA',
  String? colorHex = 'FF0000',
  String brand = 'Bambu Lab',
  String minTemp = '190',
  String maxTemp = '220',
  String subtype = 'Basic',
  String? bedMinTemp,
  String? bedMaxTemp,
  String? spoolId,
  String? lotNr,
}) =>
    OpenSpoolData(
      type: type,
      colorHex: colorHex,
      brand: brand,
      minTemp: minTemp,
      maxTemp: maxTemp,
      subtype: subtype,
      bedMinTemp: bedMinTemp,
      bedMaxTemp: bedMaxTemp,
      spoolId: spoolId,
      lotNr: lotNr,
    );

void main() {
  late QrService service;

  setUp(() {
    service = QrService();
  });

  group('QrService.encode', () {
    test('returns a valid JSON string', () {
      final data = _testSpool();
      final encoded = service.encode(data);

      // Should be parseable JSON
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(decoded, isA<Map<String, dynamic>>());
    });

    test('JSON matches OpenSpoolData.toJson() output', () {
      final data = _testSpool(
        bedMinTemp: '60',
        bedMaxTemp: '80',
        spoolId: '42',
        lotNr: 'ABC123DEF',
      );
      final encoded = service.encode(data);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;

      expect(decoded, equals(data.toJson()));
    });

    test('includes protocol and version fields', () {
      final encoded = service.encode(_testSpool());
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;

      expect(decoded['protocol'], 'openspool');
      expect(decoded['version'], '1.0');
    });
  });

  group('QrService.decode', () {
    test('returns OpenSpoolData for valid openspool JSON', () {
      final json = jsonEncode({
        'protocol': 'openspool',
        'version': '1.0',
        'type': 'PLA',
        'color_hex': 'FF0000',
        'brand': 'Bambu Lab',
        'min_temp': '190',
        'max_temp': '220',
        'subtype': 'Basic',
      });

      final result = service.decode(json);

      expect(result, isNotNull);
      expect(result!.type, 'PLA');
      expect(result.brand, 'Bambu Lab');
      expect(result.colorHex, 'FF0000');
    });

    test('returns null for invalid JSON', () {
      expect(service.decode('not json'), isNull);
      expect(service.decode(''), isNull);
      expect(service.decode('{malformed'), isNull);
    });

    test('returns null for non-openspool JSON', () {
      final json = jsonEncode({
        'protocol': 'other_protocol',
        'version': '1.0',
        'type': 'PLA',
      });

      expect(service.decode(json), isNull);
    });

    test('returns null for JSON missing protocol field', () {
      final json = jsonEncode({
        'type': 'PLA',
        'brand': 'Generic',
      });

      expect(service.decode(json), isNull);
    });
  });

  group('QrService round-trip', () {
    test('encode then decode produces equivalent data', () {
      final original = _testSpool(
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

      final encoded = service.encode(original);
      final restored = service.decode(encoded);

      expect(restored, isNotNull);
      expect(restored!.protocol, original.protocol);
      expect(restored.version, original.version);
      expect(restored.type, original.type);
      expect(restored.colorHex, original.colorHex);
      expect(restored.brand, original.brand);
      expect(restored.minTemp, original.minTemp);
      expect(restored.maxTemp, original.maxTemp);
      expect(restored.subtype, original.subtype);
      expect(restored.bedMinTemp, original.bedMinTemp);
      expect(restored.bedMaxTemp, original.bedMaxTemp);
      expect(restored.spoolId, original.spoolId);
      expect(restored.lotNr, original.lotNr);
    });

    test('round-trip with null optional fields', () {
      final original = _testSpool(
        colorHex: null,
        bedMinTemp: null,
        bedMaxTemp: null,
        spoolId: null,
        lotNr: null,
      );

      final encoded = service.encode(original);
      final restored = service.decode(encoded);

      expect(restored, isNotNull);
      expect(restored!.colorHex, isNull);
      expect(restored.bedMinTemp, isNull);
      expect(restored.bedMaxTemp, isNull);
      expect(restored.spoolId, isNull);
      expect(restored.lotNr, isNull);
    });
  });
}
