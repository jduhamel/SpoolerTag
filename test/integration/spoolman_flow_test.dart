import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spooler_tag/data/spool_provider/spoolman/spoolman_models.dart';
import 'package:spooler_tag/models/filament_spool.dart';
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

  group('Spoolman selection flow', () {
    test(
      'select spool with temps in range -> uses material defaults',
      () {
        final spoolmanSpool = SpoolmanSpool(
          id: 99,
          filament: SpoolmanFilament(
            id: 1,
            name: 'Polymaker PLA Red',
            material: 'PLA',
            vendor: SpoolmanVendor(name: 'Polymaker'),
            colorHex: 'FF0000',
            settingsExtruderTemp: 200,
            settingsBedTemp: 50,
          ),
          lotNr: 'SPOOLMAN1',
        );

        final spool = FilamentSpool.fromSpoolman(
          id: spoolmanSpool.id,
          material: spoolmanSpool.filament.material,
          brand: spoolmanSpool.filament.vendor?.name ?? '',
          colorHex: spoolmanSpool.filament.colorHex,
          extruderTemp: spoolmanSpool.filament.settingsExtruderTemp,
          bedTemp: spoolmanSpool.filament.settingsBedTemp,
          lotNr: spoolmanSpool.lotNr,
        );

        // Temps within PLA range (190-220, 40-65) -> use defaults
        expect(spool.minTemp, 190);
        expect(spool.maxTemp, 220);
        expect(spool.bedMinTemp, 40);
        expect(spool.bedMaxTemp, 65);

        // Load into form
        notifier.loadFromFilamentSpool(spool);

        final state = container.read(spoolFormProvider);
        expect(state.material, 'PLA');
        expect(state.brand, 'Polymaker');
        expect(state.colorHex, 'FF0000');
        expect(state.minTemp, 190);
        expect(state.maxTemp, 220);
        expect(state.bedMinTemp, 40);
        expect(state.bedMaxTemp, 65);
        expect(state.spoolId, '99');
        expect(state.lotNr, 'SPOOLMAN1');
        expect(state.isLotNrFromSpoolman, isTrue);

        // Build OpenSpoolData and verify
        final data = notifier.buildOpenSpoolData();
        expect(data.type, 'PLA');
        expect(data.brand, 'Polymaker');
        expect(data.colorHex, 'FF0000');
        expect(data.minTemp, '190');
        expect(data.maxTemp, '220');
        expect(data.bedMinTemp, '40');
        expect(data.bedMaxTemp, '65');
        expect(data.spoolId, '99');
        expect(data.lotNr, 'SPOOLMAN1');
      },
    );

    test(
      'select spool with extruder temp outside range -> uses custom temps',
      () {
        final spool = FilamentSpool.fromSpoolman(
          id: 100,
          material: 'PLA',
          brand: 'Unknown',
          colorHex: '00FF00',
          extruderTemp: 250, // Outside PLA range 190-220
          bedTemp: 50, // Within PLA bed range 40-65
          lotNr: 'CUSTOM01',
        );

        // Extruder temp outside range -> custom: 250, 250+20=270
        expect(spool.minTemp, 250);
        expect(spool.maxTemp, 270);
        // Bed temp within range -> defaults
        expect(spool.bedMinTemp, 40);
        expect(spool.bedMaxTemp, 65);

        notifier.loadFromFilamentSpool(spool);

        final state = container.read(spoolFormProvider);
        expect(state.minTemp, 250);
        expect(state.maxTemp, 270);
        expect(state.bedMinTemp, 40);
        expect(state.bedMaxTemp, 65);
      },
    );

    test(
      'select spool with bed temp outside range -> uses custom bed temps',
      () {
        final spool = FilamentSpool.fromSpoolman(
          id: 101,
          material: 'PLA',
          brand: 'Unknown',
          colorHex: '0000FF',
          extruderTemp: 200, // Within PLA range
          bedTemp: 80, // Outside PLA bed range 40-65
        );

        // Extruder within range -> defaults
        expect(spool.minTemp, 190);
        expect(spool.maxTemp, 220);
        // Bed temp outside range -> custom: 80, 80+10=90
        expect(spool.bedMinTemp, 80);
        expect(spool.bedMaxTemp, 90);
      },
    );

    test('spool with no temps -> form uses material defaults', () {
      final spool = FilamentSpool.fromSpoolman(
        id: 102,
        material: 'ABS',
        brand: 'eSUN',
        colorHex: '000000',
      );

      // No temps provided -> null
      expect(spool.minTemp, isNull);
      expect(spool.maxTemp, isNull);
      expect(spool.bedMinTemp, isNull);
      expect(spool.bedMaxTemp, isNull);

      notifier.loadFromFilamentSpool(spool);

      // Form should use ABS material defaults
      final state = container.read(spoolFormProvider);
      expect(state.material, 'ABS');
      expect(state.minTemp, 220);
      expect(state.maxTemp, 260);
      expect(state.bedMinTemp, 80);
      expect(state.bedMaxTemp, 110);
    });

    test('spool with variant preserved through flow', () {
      final spool = FilamentSpool.fromSpoolman(
        id: 103,
        material: 'PLA',
        variant: 'Silk',
        brand: 'Polymaker',
        colorHex: 'FFD700',
        extruderTemp: 210,
        bedTemp: 50,
      );

      notifier.loadFromFilamentSpool(spool);

      final data = notifier.buildOpenSpoolData();
      expect(data.type, 'PLA Silk');
      expect(data.subtype, 'Silk');
    });
  });
}
