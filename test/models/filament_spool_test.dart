import 'package:flutter_test/flutter_test.dart';
import 'package:spooler_tag/models/filament_spool.dart';
import 'package:spooler_tag/models/open_spool_data.dart';

void main() {
  group('FilamentSpool', () {
    group('fromSpoolman() temperature logic', () {
      test(
        'extruder temp within material default range uses material defaults',
        () {
          // PLA defaults: min=190, max=220
          // Spoolman extruder temp 200 is within [190, 220]
          final spool = FilamentSpool.fromSpoolman(
            material: 'PLA',
            extruderTemp: 200,
            bedTemp: 50,
            brand: 'Generic',
          );

          expect(spool.minTemp, 190);
          expect(spool.maxTemp, 220);
        },
      );

      test(
        'extruder temp outside material default range uses spoolman temp',
        () {
          // PLA defaults: min=190, max=220
          // Spoolman extruder temp 230 is outside [190, 220]
          final spool = FilamentSpool.fromSpoolman(
            material: 'PLA',
            extruderTemp: 230,
            bedTemp: 50,
            brand: 'Generic',
          );

          expect(spool.minTemp, 230);
          expect(spool.maxTemp, 250); // 230 + 20
        },
      );

      test('bed temp within material default range uses material defaults', () {
        // PLA bed defaults: min=40, max=65
        // Spoolman bed temp 50 is within [40, 65]
        final spool = FilamentSpool.fromSpoolman(
          material: 'PLA',
          extruderTemp: 200,
          bedTemp: 50,
          brand: 'Generic',
        );

        expect(spool.bedMinTemp, 40);
        expect(spool.bedMaxTemp, 65);
      });

      test('bed temp outside material default range uses spoolman temp', () {
        // PLA bed defaults: min=40, max=65
        // Spoolman bed temp 70 is outside [40, 65]
        final spool = FilamentSpool.fromSpoolman(
          material: 'PLA',
          extruderTemp: 200,
          bedTemp: 70,
          brand: 'Generic',
        );

        expect(spool.bedMinTemp, 70);
        expect(spool.bedMaxTemp, 80); // 70 + 10
      });

      test('unknown material uses spoolman temps directly', () {
        final spool = FilamentSpool.fromSpoolman(
          material: 'UnknownMaterial',
          extruderTemp: 250,
          bedTemp: 90,
          brand: 'Generic',
        );

        expect(spool.minTemp, 250);
        expect(spool.maxTemp, 270); // 250 + 20
        expect(spool.bedMinTemp, 90);
        expect(spool.bedMaxTemp, 100); // 90 + 10
      });

      test('null extruder temp results in null min/max temp', () {
        final spool = FilamentSpool.fromSpoolman(
          material: 'PLA',
          extruderTemp: null,
          bedTemp: 50,
          brand: 'Generic',
        );

        expect(spool.minTemp, isNull);
        expect(spool.maxTemp, isNull);
      });

      test('null bed temp results in null bed min/max temp', () {
        final spool = FilamentSpool.fromSpoolman(
          material: 'PLA',
          extruderTemp: 200,
          bedTemp: null,
          brand: 'Generic',
        );

        expect(spool.bedMinTemp, isNull);
        expect(spool.bedMaxTemp, isNull);
      });

      test('extruder temp at exact boundary uses material defaults', () {
        // PLA defaults: min=190, max=220
        // Temp exactly at min boundary
        final spoolAtMin = FilamentSpool.fromSpoolman(
          material: 'PLA',
          extruderTemp: 190,
          bedTemp: 50,
          brand: 'Generic',
        );
        expect(spoolAtMin.minTemp, 190);
        expect(spoolAtMin.maxTemp, 220);

        // Temp exactly at max boundary
        final spoolAtMax = FilamentSpool.fromSpoolman(
          material: 'PLA',
          extruderTemp: 220,
          bedTemp: 50,
          brand: 'Generic',
        );
        expect(spoolAtMax.minTemp, 190);
        expect(spoolAtMax.maxTemp, 220);
      });
    });

    group('fromOpenSpool()', () {
      test('variant is empty when subtype is "Basic"', () {
        final data = OpenSpoolData(
          type: 'PLA',
          colorHex: 'FF0000',
          brand: 'Bambu Lab',
          minTemp: '190',
          maxTemp: '220',
          subtype: 'Basic',
        );

        final spool = FilamentSpool.fromOpenSpool(data);

        expect(spool.variant, '');
        expect(spool.material, 'PLA');
      });

      test('variant is subtype when subtype is not "Basic"', () {
        final data = OpenSpoolData(
          type: 'PLA',
          colorHex: 'FF0000',
          brand: 'Bambu Lab',
          minTemp: '190',
          maxTemp: '220',
          subtype: 'Silk',
        );

        final spool = FilamentSpool.fromOpenSpool(data);
        expect(spool.variant, 'Silk');
      });

      test('parses spoolId to int', () {
        final data = OpenSpoolData(
          type: 'PLA',
          colorHex: null,
          brand: 'Generic',
          minTemp: '190',
          maxTemp: '220',
          subtype: 'Basic',
          spoolId: '42',
        );

        final spool = FilamentSpool.fromOpenSpool(data);
        expect(spool.id, 42);
      });

      test('spoolId is null when not a valid int', () {
        final data = OpenSpoolData(
          type: 'PLA',
          colorHex: null,
          brand: 'Generic',
          minTemp: '190',
          maxTemp: '220',
          subtype: 'Basic',
          spoolId: 'notanumber',
        );

        final spool = FilamentSpool.fromOpenSpool(data);
        expect(spool.id, isNull);
      });

      test('spoolId is null when null in data', () {
        final data = OpenSpoolData(
          type: 'PLA',
          colorHex: null,
          brand: 'Generic',
          minTemp: '190',
          maxTemp: '220',
          subtype: 'Basic',
          spoolId: null,
        );

        final spool = FilamentSpool.fromOpenSpool(data);
        expect(spool.id, isNull);
      });

      test('temps are parsed from strings', () {
        final data = OpenSpoolData(
          type: 'PLA',
          colorHex: null,
          brand: 'Generic',
          minTemp: '195',
          maxTemp: '215',
          subtype: 'Basic',
          bedMinTemp: '55',
          bedMaxTemp: '70',
        );

        final spool = FilamentSpool.fromOpenSpool(data);
        expect(spool.minTemp, 195);
        expect(spool.maxTemp, 215);
        expect(spool.bedMinTemp, 55);
        expect(spool.bedMaxTemp, 70);
      });

      test('falls back to material defaults for missing temps', () {
        final data = OpenSpoolData(
          type: 'PLA',
          colorHex: null,
          brand: 'Generic',
          minTemp: '',
          maxTemp: '',
          subtype: 'Basic',
        );

        final spool = FilamentSpool.fromOpenSpool(data);
        // Should fall back to PLA defaults
        expect(spool.minTemp, 190);
        expect(spool.maxTemp, 220);
      });
    });

    group('displayName', () {
      test('returns "material variant" when variant non-empty', () {
        final spool = FilamentSpool(
          material: 'PLA',
          variant: 'Silk',
          brand: 'Generic',
        );

        expect(spool.displayName, 'PLA Silk');
      });

      test('returns just material when variant is empty', () {
        final spool = FilamentSpool(
          material: 'PLA',
          variant: '',
          brand: 'Generic',
        );

        expect(spool.displayName, 'PLA');
      });
    });
  });
}
