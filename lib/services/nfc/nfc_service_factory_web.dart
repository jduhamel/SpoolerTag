import 'package:spooler_tag/services/nfc/nfc_service.dart';
import 'package:spooler_tag/services/nfc/web_nfc_service.dart';

NfcService createPlatformNfcService() => WebNfcService();
