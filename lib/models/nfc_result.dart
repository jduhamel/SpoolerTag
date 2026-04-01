import 'package:spooler_tag/models/open_spool_data.dart';

sealed class NfcResult {}

class NfcReadSuccess extends NfcResult {
  final OpenSpoolData data;
  NfcReadSuccess(this.data);
}

class NfcWriteSuccess extends NfcResult {}

class NfcError extends NfcResult {
  final String message;
  NfcError(this.message);
}

class NfcTagDetected extends NfcResult {}
