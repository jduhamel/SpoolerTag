import 'dart:convert';

import 'package:spooler_tag/models/open_spool_data.dart';

class QrService {
  String encode(OpenSpoolData data) => jsonEncode(data.toJson());

  OpenSpoolData? decode(String rawData) => OpenSpoolData.fromJson(rawData);
}
