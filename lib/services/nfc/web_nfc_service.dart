import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'package:spooler_tag/models/nfc_result.dart';
import 'package:spooler_tag/models/open_spool_data.dart';
import 'package:spooler_tag/services/nfc/nfc_service.dart';

// Web NFC API bindings via js_interop

@JS('NDEFReader')
extension type NDEFReaderJS._(JSObject _) implements JSObject {
  external NDEFReaderJS();
  external JSPromise<JSAny?> scan();
  external JSPromise<JSAny?> write(JSAny message);
  external set onreading(JSFunction callback);
  external set onreadingerror(JSFunction callback);
}

extension type NDEFReadingEvent._(JSObject _) implements JSObject {
  external NDEFMessageJS get message;
}

extension type NDEFMessageJS._(JSObject _) implements JSObject {
  external JSArray<NDEFRecordJS> get records;
}

extension type NDEFRecordJS._(JSObject _) implements JSObject {
  external String get recordType;
  external String? get mediaType;
  external JSDataView? get data;
}

@JS('NDEFReader')
external JSFunction? get _ndefReaderConstructor;

class WebNfcService implements NfcService {
  @override
  Future<NfcCapability> checkAvailability() async {
    try {
      return _hasWebNfc() ? NfcCapability.available : NfcCapability.unsupported;
    } catch (_) {
      return NfcCapability.unsupported;
    }
  }

  bool _hasWebNfc() {
    return _ndefReaderConstructor != null;
  }

  @override
  Future<NfcResult> readTag() async {
    if (!_hasWebNfc()) {
      return NfcError('Web NFC is not supported in this browser');
    }

    final completer = Completer<NfcResult>();

    try {
      final reader = NDEFReaderJS();
      await reader.scan().toDart;

      reader.onreading = ((NDEFReadingEvent event) {
        try {
          final records = event.message.records;

          if (records.length == 0) {
            if (!completer.isCompleted) {
              completer.complete(NfcError('Tag is empty'));
            }
            return;
          }

          final record = records[0];
          final dataView = record.data;
          if (dataView == null) {
            if (!completer.isCompleted) {
              completer.complete(NfcError('Tag record has no data'));
            }
            return;
          }

          // Decode the DataView as UTF-8 text
          final textDecoder = web.TextDecoder('utf-8');
          final text = textDecoder.decode(dataView);

          final spoolData = OpenSpoolData.fromJson(text);
          if (!completer.isCompleted) {
            if (spoolData != null) {
              completer.complete(NfcReadSuccess(spoolData));
            } else {
              completer.complete(NfcError('Invalid OpenSpool data on tag'));
            }
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.complete(NfcError('Failed to parse tag data: $e'));
          }
        }
      }).toJS;

      reader.onreadingerror = ((JSObject event) {
        if (!completer.isCompleted) {
          completer.complete(NfcError('Error reading NFC tag'));
        }
      }).toJS;
    } catch (e) {
      if (!completer.isCompleted) {
        completer.complete(NfcError('Failed to start NFC scan: $e'));
      }
    }

    return completer.future;
  }

  @override
  Future<NfcResult> writeTag(OpenSpoolData data) async {
    if (!_hasWebNfc()) {
      return NfcError('Web NFC is not supported in this browser');
    }

    try {
      final reader = NDEFReaderJS();
      final jsonString = jsonEncode(data.toJson());

      final encoder = web.TextEncoder();
      final encoded = encoder.encode(jsonString);

      final record = <String, dynamic>{
        'recordType': 'mime',
        'mediaType': 'application/json',
        'data': encoded,
      }.jsify();

      final message = <String, dynamic>{
        'records': [record],
      }.jsify()!;

      await reader.write(message).toDart;
      return NfcWriteSuccess();
    } catch (e) {
      return NfcError('Failed to write NFC tag: $e');
    }
  }

  @override
  Future<void> stopSession() async {
    // Web NFC sessions end automatically; no explicit stop needed.
  }
}
