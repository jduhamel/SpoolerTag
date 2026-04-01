import 'package:spooler_tag/data/local/material_database.dart';
import 'package:spooler_tag/models/open_spool_data.dart';

class FilamentSpool {
  final int? id;
  final String material;
  final String variant;
  final String brand;
  final String? colorHex;
  final int? minTemp;
  final int? maxTemp;
  final int? bedMinTemp;
  final int? bedMaxTemp;
  final double? remainingWeight;
  final double usedWeight;
  final String? location;
  final String? lotNr;
  final bool archived;
  final String? spoolmanName;

  FilamentSpool({
    this.id,
    required this.material,
    this.variant = '',
    required this.brand,
    this.colorHex,
    this.minTemp,
    this.maxTemp,
    this.bedMinTemp,
    this.bedMaxTemp,
    this.remainingWeight,
    this.usedWeight = 0.0,
    this.location,
    this.lotNr,
    this.archived = false,
    this.spoolmanName,
  });

  String get displayName =>
      variant.isNotEmpty ? '$material $variant' : material;

  factory FilamentSpool.fromSpoolman({
    int? id,
    required String material,
    String variant = '',
    required String brand,
    String? colorHex,
    int? extruderTemp,
    int? bedTemp,
    double? remainingWeight,
    double usedWeight = 0.0,
    String? location,
    String? lotNr,
    bool archived = false,
    String? spoolmanName,
  }) {
    final materialData = MaterialDatabase.getMaterial(material);

    int? minTemp;
    int? maxTemp;
    if (extruderTemp != null) {
      if (materialData != null &&
          extruderTemp >= materialData.defaultMinTemp &&
          extruderTemp <= materialData.defaultMaxTemp) {
        minTemp = materialData.defaultMinTemp;
        maxTemp = materialData.defaultMaxTemp;
      } else {
        minTemp = extruderTemp;
        maxTemp = extruderTemp + 20;
      }
    }

    int? bedMinTemp;
    int? bedMaxTemp;
    if (bedTemp != null) {
      if (materialData != null &&
          bedTemp >= materialData.defaultBedMinTemp &&
          bedTemp <= materialData.defaultBedMaxTemp) {
        bedMinTemp = materialData.defaultBedMinTemp;
        bedMaxTemp = materialData.defaultBedMaxTemp;
      } else {
        bedMinTemp = bedTemp;
        bedMaxTemp = bedTemp + 10;
      }
    }

    return FilamentSpool(
      id: id,
      material: material,
      variant: variant,
      brand: brand,
      colorHex: colorHex,
      minTemp: minTemp,
      maxTemp: maxTemp,
      bedMinTemp: bedMinTemp,
      bedMaxTemp: bedMaxTemp,
      remainingWeight: remainingWeight,
      usedWeight: usedWeight,
      location: location,
      lotNr: lotNr,
      archived: archived,
      spoolmanName: spoolmanName,
    );
  }

  factory FilamentSpool.fromOpenSpool(OpenSpoolData data) {
    final materialData = MaterialDatabase.getMaterial(data.type);

    int? parseTemp(String? value, int? fallback) {
      if (value != null && value.isNotEmpty) {
        return int.tryParse(value) ?? fallback;
      }
      return fallback;
    }

    return FilamentSpool(
      id: data.spoolId != null ? int.tryParse(data.spoolId!) : null,
      material: data.type,
      variant: data.subtype != 'Basic' ? data.subtype : '',
      brand: data.brand,
      colorHex: data.colorHex,
      minTemp: parseTemp(data.minTemp, materialData?.defaultMinTemp),
      maxTemp: parseTemp(data.maxTemp, materialData?.defaultMaxTemp),
      bedMinTemp: parseTemp(data.bedMinTemp, materialData?.defaultBedMinTemp),
      bedMaxTemp: parseTemp(data.bedMaxTemp, materialData?.defaultBedMaxTemp),
      lotNr: data.lotNr,
    );
  }
}
