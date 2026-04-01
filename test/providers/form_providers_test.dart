import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spooler_tag/models/filament_spool.dart';
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

  group('SpoolFormNotifier initial state', () {
    test('has PLA defaults', () {
      final state = container.read(spoolFormProvider);

      expect(state.material, 'PLA');
      expect(state.minTemp, 190);
      expect(state.maxTemp, 220);
      expect(state.bedMinTemp, 40);
      expect(state.bedMaxTemp, 65);
    });

    test('has empty brand, variant, and null colorHex', () {
      final state = container.read(spoolFormProvider);

      expect(state.brand, '');
      expect(state.variant, '');
      expect(state.colorHex, isNull);
    });

    test('lotNr is empty and not from spoolman', () {
      final state = container.read(spoolFormProvider);

      expect(state.lotNr, '');
      expect(state.isLotNrFromSpoolman, false);
    });
  });

  group('loadFromOpenSpool()', () {
    test('populates all fields correctly', () {
      final data = OpenSpoolData(
        type: 'PETG',
        colorHex: 'FF0000',
        brand: 'Prusa',
        minTemp: '230',
        maxTemp: '250',
        bedMinTemp: '70',
        bedMaxTemp: '85',
        subtype: 'Carbon Fiber',
        spoolId: '42',
        lotNr: 'ABC123',
      );

      notifier.loadFromOpenSpool(data);
      final state = container.read(spoolFormProvider);

      expect(state.material, 'PETG');
      expect(state.variant, 'Carbon Fiber');
      expect(state.colorHex, 'FF0000');
      expect(state.brand, 'Prusa');
      expect(state.minTemp, 230);
      expect(state.maxTemp, 250);
      expect(state.bedMinTemp, 70);
      expect(state.bedMaxTemp, 85);
      expect(state.lotNr, 'ABC123');
      expect(state.spoolId, '42');
    });

    test('maps "Basic" subtype to empty variant', () {
      final data = OpenSpoolData(
        type: 'PLA',
        colorHex: null,
        brand: 'Generic',
        minTemp: '190',
        maxTemp: '220',
        subtype: 'Basic',
      );

      notifier.loadFromOpenSpool(data);
      final state = container.read(spoolFormProvider);

      expect(state.variant, '');
    });

    test('uses material defaults when temps are empty', () {
      final data = OpenSpoolData(
        type: 'ABS',
        colorHex: null,
        brand: '',
        minTemp: '',
        maxTemp: '',
        subtype: '',
      );

      notifier.loadFromOpenSpool(data);
      final state = container.read(spoolFormProvider);

      expect(state.minTemp, 220);
      expect(state.maxTemp, 260);
      expect(state.bedMinTemp, 80);
      expect(state.bedMaxTemp, 110);
    });
  });

  group('loadFromFilamentSpool()', () {
    test('maps FilamentSpool fields to form state', () {
      final spool = FilamentSpool(
        id: 7,
        material: 'PETG',
        variant: 'Silk',
        brand: 'eSUN',
        colorHex: '00FF00',
        minTemp: 225,
        maxTemp: 245,
        bedMinTemp: 65,
        bedMaxTemp: 80,
        lotNr: 'LOT456',
        spoolmanName: 'eSUN Silk PETG',
      );

      notifier.loadFromFilamentSpool(spool);
      final state = container.read(spoolFormProvider);

      expect(state.material, 'PETG');
      expect(state.variant, 'Silk');
      expect(state.brand, 'eSUN');
      expect(state.colorHex, '00FF00');
      expect(state.minTemp, 225);
      expect(state.maxTemp, 245);
      expect(state.bedMinTemp, 65);
      expect(state.bedMaxTemp, 80);
      expect(state.lotNr, 'LOT456');
      expect(state.spoolId, '7');
    });

    test('marks lot as from-spoolman when spool has lotNr', () {
      final spool = FilamentSpool(
        id: 1,
        material: 'PLA',
        brand: 'Generic',
        lotNr: 'ABC',
      );

      notifier.loadFromFilamentSpool(spool);
      final state = container.read(spoolFormProvider);

      expect(state.isLotNrFromSpoolman, true);
    });

    test('isLotNrFromSpoolman is false when spool has no lotNr', () {
      final spool = FilamentSpool(
        id: 1,
        material: 'PLA',
        brand: 'Generic',
      );

      notifier.loadFromFilamentSpool(spool);
      final state = container.read(spoolFormProvider);

      expect(state.isLotNrFromSpoolman, false);
    });

    test('isLotNrFromSpoolman is false when spool has empty lotNr', () {
      final spool = FilamentSpool(
        id: 1,
        material: 'PLA',
        brand: 'Generic',
        lotNr: '',
      );

      notifier.loadFromFilamentSpool(spool);
      final state = container.read(spoolFormProvider);

      expect(state.isLotNrFromSpoolman, false);
    });

    test('uses material defaults for null temps', () {
      final spool = FilamentSpool(
        id: 1,
        material: 'PLA',
        brand: 'Generic',
      );

      notifier.loadFromFilamentSpool(spool);
      final state = container.read(spoolFormProvider);

      expect(state.minTemp, 190);
      expect(state.maxTemp, 220);
      expect(state.bedMinTemp, 40);
      expect(state.bedMaxTemp, 65);
    });
  });

  group('setMaterial()', () {
    test('resets temps to ABS defaults', () {
      notifier.setMaterial('ABS');
      final state = container.read(spoolFormProvider);

      expect(state.material, 'ABS');
      expect(state.minTemp, 220);
      expect(state.maxTemp, 260);
      expect(state.bedMinTemp, 80);
      expect(state.bedMaxTemp, 110);
    });

    test('resets temps to Other defaults', () {
      notifier.setMaterial('Other');
      final state = container.read(spoolFormProvider);

      expect(state.material, 'Other');
      expect(state.minTemp, 200);
      expect(state.maxTemp, 220);
      expect(state.bedMinTemp, 50);
      expect(state.bedMaxTemp, 70);
    });

    test('keeps other fields unchanged', () {
      notifier.setBrand('TestBrand');
      notifier.setVariant('Silk');
      notifier.setColorHex('FF0000');
      notifier.setMaterial('PETG');

      final state = container.read(spoolFormProvider);

      expect(state.brand, 'TestBrand');
      expect(state.variant, 'Silk');
      expect(state.colorHex, 'FF0000');
      expect(state.material, 'PETG');
    });
  });

  group('adjustTemp()', () {
    test('increments minTemp by 5', () {
      notifier.adjustTemp(TempField.minTemp, 5);
      final state = container.read(spoolFormProvider);

      expect(state.minTemp, 195);
    });

    test('decrements maxTemp by 5', () {
      notifier.adjustTemp(TempField.maxTemp, -5);
      final state = container.read(spoolFormProvider);

      expect(state.maxTemp, 215);
    });

    test('adjusts bedMinTemp', () {
      notifier.adjustTemp(TempField.bedMinTemp, 10);
      final state = container.read(spoolFormProvider);

      expect(state.bedMinTemp, 50);
    });

    test('adjusts bedMaxTemp', () {
      notifier.adjustTemp(TempField.bedMaxTemp, -10);
      final state = container.read(spoolFormProvider);

      expect(state.bedMaxTemp, 55);
    });
  });

  group('buildOpenSpoolData()', () {
    test('constructs valid OpenSpoolData with correct field mapping', () {
      notifier.setMaterial('PLA');
      notifier.setVariant('Silk');
      notifier.setBrand('eSUN');
      notifier.setColorHex('FF00FF');
      notifier.setLotNr('ABC123');

      final data = notifier.buildOpenSpoolData();

      expect(data.type, 'PLA Silk');
      expect(data.subtype, 'Silk');
      expect(data.colorHex, 'FF00FF');
      expect(data.brand, 'eSUN');
      expect(data.minTemp, '190');
      expect(data.maxTemp, '220');
      expect(data.bedMinTemp, '40');
      expect(data.bedMaxTemp, '65');
      expect(data.lotNr, 'ABC123');
    });

    test('type is just material when variant is empty', () {
      notifier.setMaterial('PETG');
      notifier.setVariant('');

      final data = notifier.buildOpenSpoolData();

      expect(data.type, 'PETG');
      expect(data.subtype, '');
    });

    test('uses customMaterial when material is Other', () {
      notifier.setMaterial('Other');
      notifier.setCustomMaterial('Wood');

      final data = notifier.buildOpenSpoolData();

      expect(data.type, 'Wood');
    });

    test('uses customBrand when brand is Other', () {
      notifier.setBrand('Other');
      notifier.setCustomBrand('MyBrand');

      final data = notifier.buildOpenSpoolData();

      expect(data.brand, 'MyBrand');
    });

    test('lotNr is null when empty', () {
      final data = notifier.buildOpenSpoolData();

      expect(data.lotNr, isNull);
    });
  });

  group('generateNewLotNr()', () {
    test('produces 9-char hex string', () {
      notifier.generateNewLotNr();
      final state = container.read(spoolFormProvider);

      expect(state.lotNr.length, 9);
      expect(state.lotNr, matches(RegExp(r'^[0-9A-F]{9}$')));
    });

    test('sets isLotNrFromSpoolman to false', () {
      // First load a spool with lot number
      final spool = FilamentSpool(
        id: 1,
        material: 'PLA',
        brand: 'Generic',
        lotNr: 'LOT123',
      );
      notifier.loadFromFilamentSpool(spool);
      expect(container.read(spoolFormProvider).isLotNrFromSpoolman, true);

      notifier.generateNewLotNr();
      expect(container.read(spoolFormProvider).isLotNrFromSpoolman, false);
    });
  });

  group('setLotNr()', () {
    test('accepts valid hex string and uppercases', () {
      notifier.setLotNr('abc123');
      final state = container.read(spoolFormProvider);

      expect(state.lotNr, 'ABC123');
    });

    test('rejects non-hex characters', () {
      notifier.setLotNr('GHIxyz!@#');
      final state = container.read(spoolFormProvider);

      expect(state.lotNr, '');
    });

    test('limits to 16 characters', () {
      notifier.setLotNr('AABBCCDDEEFF00112233');
      final state = container.read(spoolFormProvider);

      expect(state.lotNr.length, 16);
      expect(state.lotNr, 'AABBCCDDEEFF0011');
    });

    test('filters out non-hex then clamps', () {
      notifier.setLotNr('AB-CD-EF-GH-12-34');
      final state = container.read(spoolFormProvider);

      expect(state.lotNr, 'ABCDEF1234');
    });
  });
}
