import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spooler_tag/core/constants.dart';
import 'package:spooler_tag/models/nfc_result.dart';
import 'package:spooler_tag/models/open_spool_data.dart';
import 'package:spooler_tag/services/nfc/nfc_service.dart';

final nfcServiceProvider = Provider<NfcService>((ref) => createNfcService());

final nfcCapabilityProvider = FutureProvider<NfcCapability>((ref) async {
  final service = ref.watch(nfcServiceProvider);
  return service.checkAvailability();
});

final nfcModeProvider = StateProvider<NfcMode>((ref) => NfcMode.idle);

final nfcResultProvider = StateProvider<NfcResult?>((ref) => null);

class RecentTagNotifier extends Notifier<OpenSpoolData?> {
  Timer? _clearTimer;

  @override
  OpenSpoolData? build() => null;

  void setTag(OpenSpoolData data) {
    _clearTimer?.cancel();
    state = data;
    _clearTimer = Timer(AppConstants.tagCacheDuration, () {
      state = null;
    });
  }

  void clear() {
    _clearTimer?.cancel();
    state = null;
  }
}

final recentTagProvider =
    NotifierProvider<RecentTagNotifier, OpenSpoolData?>(RecentTagNotifier.new);
