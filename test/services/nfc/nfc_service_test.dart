import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spooler_tag/models/nfc_result.dart';
import 'package:spooler_tag/models/open_spool_data.dart';
import 'package:spooler_tag/providers/nfc_providers.dart';
import 'package:spooler_tag/services/nfc/nfc_service.dart';

class MockNfcService implements NfcService {
  NfcCapability capability = NfcCapability.available;
  NfcResult? readResult;
  NfcResult? writeResult;
  bool sessionStopped = false;

  @override
  Future<NfcCapability> checkAvailability() async => capability;

  @override
  Future<NfcResult> readTag() async => readResult!;

  @override
  Future<NfcResult> writeTag(OpenSpoolData data) async => writeResult!;

  @override
  Future<void> stopSession() async {
    sessionStopped = true;
  }
}

OpenSpoolData _testSpool() => OpenSpoolData(
      type: 'PLA',
      colorHex: '#FF0000',
      brand: 'TestBrand',
      minTemp: '190',
      maxTemp: '220',
      subtype: 'Basic',
    );

void main() {
  group('MockNfcService', () {
    late MockNfcService service;

    setUp(() {
      service = MockNfcService();
    });

    test('checkAvailability returns configured capability', () async {
      expect(await service.checkAvailability(), NfcCapability.available);

      service.capability = NfcCapability.unsupported;
      expect(await service.checkAvailability(), NfcCapability.unsupported);

      service.capability = NfcCapability.disabled;
      expect(await service.checkAvailability(), NfcCapability.disabled);
    });

    test('readTag returns NfcReadSuccess with correct data', () async {
      final spool = _testSpool();
      service.readResult = NfcReadSuccess(spool);

      final result = await service.readTag();
      expect(result, isA<NfcReadSuccess>());

      final success = result as NfcReadSuccess;
      expect(success.data.type, 'PLA');
      expect(success.data.brand, 'TestBrand');
      expect(success.data.colorHex, '#FF0000');
    });

    test('writeTag returns NfcWriteSuccess', () async {
      service.writeResult = NfcWriteSuccess();

      final result = await service.writeTag(_testSpool());
      expect(result, isA<NfcWriteSuccess>());
    });

    test('readTag returns NfcError on failure', () async {
      service.readResult = NfcError('Tag does not support NDEF');

      final result = await service.readTag();
      expect(result, isA<NfcError>());
      expect((result as NfcError).message, 'Tag does not support NDEF');
    });

    test('writeTag returns NfcError on failure', () async {
      service.writeResult = NfcError('Tag is not writable');

      final result = await service.writeTag(_testSpool());
      expect(result, isA<NfcError>());
      expect((result as NfcError).message, 'Tag is not writable');
    });

    test('stopSession sets flag', () async {
      expect(service.sessionStopped, isFalse);
      await service.stopSession();
      expect(service.sessionStopped, isTrue);
    });
  });

  group('RecentTagNotifier', () {
    test('starts as null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(recentTagProvider), isNull);
    });

    test('setTag stores data', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(recentTagProvider.notifier).setTag(_testSpool());
      expect(container.read(recentTagProvider), isNotNull);
      expect(container.read(recentTagProvider)!.type, 'PLA');
    });

    test('clear removes data immediately', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(recentTagProvider.notifier);
      notifier.setTag(_testSpool());
      expect(container.read(recentTagProvider), isNotNull);

      notifier.clear();
      expect(container.read(recentTagProvider), isNull);
    });

    test('auto-clears after tagCacheDuration', () {
      fakeAsync((async) {
        final container = ProviderContainer();

        container.read(recentTagProvider.notifier).setTag(_testSpool());
        expect(container.read(recentTagProvider), isNotNull);

        async.elapse(const Duration(seconds: 4));
        expect(container.read(recentTagProvider), isNotNull);

        async.elapse(const Duration(seconds: 2));
        expect(container.read(recentTagProvider), isNull);

        container.dispose();
      });
    });

    test('setTag resets the timer', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        final notifier = container.read(recentTagProvider.notifier);

        notifier.setTag(_testSpool());
        async.elapse(const Duration(seconds: 3));
        expect(container.read(recentTagProvider), isNotNull);

        // Reset timer by setting again
        notifier.setTag(_testSpool());
        async.elapse(const Duration(seconds: 3));
        expect(container.read(recentTagProvider), isNotNull);

        async.elapse(const Duration(seconds: 3));
        expect(container.read(recentTagProvider), isNull);

        container.dispose();
      });
    });
  });

  group('NFC providers', () {
    test('nfcServiceProvider can be overridden with mock', () async {
      final mock = MockNfcService();
      mock.capability = NfcCapability.available;

      final container = ProviderContainer(
        overrides: [nfcServiceProvider.overrideWithValue(mock)],
      );
      addTearDown(container.dispose);

      final capability = await container.read(nfcCapabilityProvider.future);
      expect(capability, NfcCapability.available);
    });

    test('nfcModeProvider defaults to idle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(nfcModeProvider), NfcMode.idle);
    });

    test('nfcResultProvider defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(nfcResultProvider), isNull);
    });

    test('provider state transitions: idle to reading to success', () async {
      final mock = MockNfcService();
      mock.readResult = NfcReadSuccess(_testSpool());

      final container = ProviderContainer(
        overrides: [nfcServiceProvider.overrideWithValue(mock)],
      );
      addTearDown(container.dispose);

      // Start idle
      expect(container.read(nfcModeProvider), NfcMode.idle);

      // Transition to reading
      container.read(nfcModeProvider.notifier).state = NfcMode.reading;
      expect(container.read(nfcModeProvider), NfcMode.reading);

      // Perform read
      final service = container.read(nfcServiceProvider);
      final result = await service.readTag();
      container.read(nfcResultProvider.notifier).state = result;

      // Back to idle
      container.read(nfcModeProvider.notifier).state = NfcMode.idle;
      expect(container.read(nfcModeProvider), NfcMode.idle);
      expect(container.read(nfcResultProvider), isA<NfcReadSuccess>());
    });

    test('provider state transitions: idle to writing to success', () async {
      final mock = MockNfcService();
      mock.writeResult = NfcWriteSuccess();

      final container = ProviderContainer(
        overrides: [nfcServiceProvider.overrideWithValue(mock)],
      );
      addTearDown(container.dispose);

      expect(container.read(nfcModeProvider), NfcMode.idle);

      container.read(nfcModeProvider.notifier).state = NfcMode.writing;
      expect(container.read(nfcModeProvider), NfcMode.writing);

      final service = container.read(nfcServiceProvider);
      final result = await service.writeTag(_testSpool());
      container.read(nfcResultProvider.notifier).state = result;

      container.read(nfcModeProvider.notifier).state = NfcMode.idle;
      expect(container.read(nfcModeProvider), NfcMode.idle);
      expect(container.read(nfcResultProvider), isA<NfcWriteSuccess>());
    });
  });
}
