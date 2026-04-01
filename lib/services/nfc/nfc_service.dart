import 'package:spooler_tag/models/nfc_result.dart';
import 'package:spooler_tag/models/open_spool_data.dart';
import 'package:spooler_tag/services/nfc/nfc_service_factory.dart'
    as nfc_factory;

enum NfcCapability { available, disabled, unsupported }

enum NfcMode { idle, reading, writing }

abstract class NfcService {
  Future<NfcCapability> checkAvailability();
  Future<NfcResult> readTag();
  Future<NfcResult> writeTag(OpenSpoolData data);
  Future<void> stopSession();
}

NfcService createNfcService() => nfc_factory.createPlatformNfcService();

NfcService createUnsupportedNfcService() => _UnsupportedNfcService();

class _UnsupportedNfcService implements NfcService {
  @override
  Future<NfcCapability> checkAvailability() async =>
      NfcCapability.unsupported;

  @override
  Future<NfcResult> readTag() async =>
      throw UnsupportedError('NFC is not supported on this platform');

  @override
  Future<NfcResult> writeTag(OpenSpoolData data) async =>
      throw UnsupportedError('NFC is not supported on this platform');

  @override
  Future<void> stopSession() async {}
}
