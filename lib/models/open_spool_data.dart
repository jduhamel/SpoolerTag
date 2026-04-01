import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'package:spooler_tag/data/local/material_database.dart';
import 'package:spooler_tag/models/filament_spool.dart';

class OpenSpoolData {
  final String protocol;
  final String version;
  final String type;
  final String? colorHex;
  final String brand;
  final String minTemp;
  final String maxTemp;
  final String? bedMinTemp;
  final String? bedMaxTemp;
  final String subtype;
  final String? spoolId;
  final String? lotNr;

  OpenSpoolData({
    this.protocol = 'openspool',
    this.version = '1.0',
    required this.type,
    required this.colorHex,
    required this.brand,
    required this.minTemp,
    required this.maxTemp,
    this.bedMinTemp,
    this.bedMaxTemp,
    required this.subtype,
    this.spoolId,
    this.lotNr,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'protocol': protocol,
      'version': version,
      'type': type,
      'color_hex': colorHex ?? '',
      'brand': brand,
      'min_temp': minTemp,
      'max_temp': maxTemp,
    };

    if (bedMinTemp != null) map['bed_min_temp'] = bedMinTemp;
    if (bedMaxTemp != null) map['bed_max_temp'] = bedMaxTemp;
    if (subtype.isNotEmpty) map['subtype'] = subtype;
    if (spoolId != null) map['spool_id'] = spoolId;
    if (lotNr != null) map['lot_nr'] = lotNr;

    return map;
  }

  static OpenSpoolData? fromJson(String jsonString) {
    try {
      // Strip characters before the first '{'
      final braceIndex = jsonString.indexOf('{');
      if (braceIndex < 0) return null;
      final cleaned = jsonString.substring(braceIndex);

      final map = jsonDecode(cleaned) as Map<String, dynamic>;

      if (map['protocol'] != 'openspool') return null;

      final type = map['type'] as String? ?? '';
      final materialData = MaterialDatabase.getMaterial(type);

      return OpenSpoolData(
        protocol: map['protocol'] as String? ?? 'openspool',
        version: map['version'] as String? ?? '1.0',
        type: type,
        colorHex: _nonEmpty(map['color_hex'] as String?),
        brand: map['brand'] as String? ?? '',
        minTemp: (map['min_temp'] as String?) ??
            (materialData?.defaultMinTemp.toString() ?? ''),
        maxTemp: (map['max_temp'] as String?) ??
            (materialData?.defaultMaxTemp.toString() ?? ''),
        bedMinTemp: map['bed_min_temp'] as String?,
        bedMaxTemp: map['bed_max_temp'] as String?,
        subtype: map['subtype'] as String? ?? 'Basic',
        spoolId: map['spool_id'] as String?,
        lotNr: map['lot_nr'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  static OpenSpoolData toOpenSpoolData(FilamentSpool spool) {
    return OpenSpoolData(
      type: spool.displayName,
      colorHex: spool.colorHex,
      brand: spool.brand,
      minTemp: spool.minTemp?.toString() ?? '',
      maxTemp: spool.maxTemp?.toString() ?? '',
      bedMinTemp: spool.bedMinTemp?.toString(),
      bedMaxTemp: spool.bedMaxTemp?.toString(),
      subtype: spool.variant,
      spoolId: spool.id?.toString(),
      lotNr: spool.lotNr,
    );
  }

  static String generateLotNr() {
    final uuid = const Uuid().v4();
    return uuid.replaceAll('-', '').substring(0, 9).toUpperCase();
  }

  static String? _nonEmpty(String? value) {
    if (value == null || value.isEmpty) return null;
    return value;
  }
}
