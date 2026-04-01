import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:nfc_manager/nfc_manager.dart' hide NfcError;

import 'package:spooler_tag/models/nfc_result.dart';
import 'package:spooler_tag/models/open_spool_data.dart';
import 'package:spooler_tag/services/nfc/nfc_service.dart';

class MobileNfcService implements NfcService {
  @override
  Future<NfcCapability> checkAvailability() async {
    final isAvailable = await NfcManager.instance.isAvailable();
    return isAvailable ? NfcCapability.available : NfcCapability.unsupported;
  }

  @override
  Future<NfcResult> readTag() async {
    final completer = Completer<NfcResult>();

    await NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null) {
            completer.complete(NfcError('Tag does not support NDEF'));
            await NfcManager.instance.stopSession();
            return;
          }

          final ndefMessage = await ndef.read();
          if (ndefMessage.records.isEmpty) {
            completer.complete(NfcError('Tag is empty'));
            await NfcManager.instance.stopSession();
            return;
          }

          final record = ndefMessage.records.first;
          final payload = String.fromCharCodes(record.payload);

          final data = OpenSpoolData.fromJson(payload);
          if (data != null) {
            completer.complete(NfcReadSuccess(data));
          } else {
            completer.complete(NfcError('Invalid OpenSpool data on tag'));
          }

          await NfcManager.instance.stopSession();
        } catch (e) {
          if (!completer.isCompleted) {
            completer.complete(NfcError('Failed to read tag: $e'));
          }
          await NfcManager.instance.stopSession(errorMessage: 'Read failed');
        }
      },
      onError: (error) async {
        if (!completer.isCompleted) {
          completer.complete(NfcError('NFC error: $error'));
        }
      },
    );

    return completer.future;
  }

  @override
  Future<NfcResult> writeTag(OpenSpoolData data) async {
    final completer = Completer<NfcResult>();
    final jsonString = jsonEncode(data.toJson());

    await NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null || !ndef.isWritable) {
            completer.complete(NfcError('Tag is not writable'));
            await NfcManager.instance.stopSession(
              errorMessage: 'Not writable',
            );
            return;
          }

          final record = NdefRecord.createMime(
            'application/json',
            Uint8List.fromList(utf8.encode(jsonString)),
          );
          final message = NdefMessage([record]);

          await ndef.write(message);
          completer.complete(NfcWriteSuccess());
          await NfcManager.instance.stopSession();
        } catch (e) {
          if (!completer.isCompleted) {
            completer.complete(NfcError('Failed to write tag: $e'));
          }
          await NfcManager.instance
              .stopSession(errorMessage: 'Write failed');
        }
      },
      onError: (error) async {
        if (!completer.isCompleted) {
          completer.complete(NfcError('NFC error: $error'));
        }
      },
    );

    return completer.future;
  }

  @override
  Future<void> stopSession() async {
    await NfcManager.instance.stopSession();
  }
}
