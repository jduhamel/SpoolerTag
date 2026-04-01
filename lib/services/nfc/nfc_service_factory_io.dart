import 'package:flutter/foundation.dart';

import 'package:spooler_tag/services/nfc/mobile_nfc_service.dart';
import 'package:spooler_tag/services/nfc/nfc_service.dart';

NfcService createPlatformNfcService() {
  if (defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android) {
    return MobileNfcService();
  }
  return createUnsupportedNfcService();
}
