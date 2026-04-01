// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spoolman_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpoolmanSpool _$SpoolmanSpoolFromJson(Map<String, dynamic> json) =>
    SpoolmanSpool(
      id: (json['id'] as num?)?.toInt(),
      filament: SpoolmanFilament.fromJson(
        json['filament'] as Map<String, dynamic>,
      ),
      remainingWeight: (json['remaining_weight'] as num?)?.toDouble(),
      usedWeight: (json['used_weight'] as num?)?.toDouble() ?? 0.0,
      location: json['location'] as String?,
      lotNr: json['lot_nr'] as String?,
      archived: json['archived'] as bool? ?? false,
    );

Map<String, dynamic> _$SpoolmanSpoolToJson(SpoolmanSpool instance) =>
    <String, dynamic>{
      'id': instance.id,
      'filament': instance.filament,
      'remaining_weight': instance.remainingWeight,
      'used_weight': instance.usedWeight,
      'location': instance.location,
      'lot_nr': instance.lotNr,
      'archived': instance.archived,
    };

SpoolmanFilament _$SpoolmanFilamentFromJson(Map<String, dynamic> json) =>
    SpoolmanFilament(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      material: json['material'] as String,
      vendor: json['vendor'] == null
          ? null
          : SpoolmanVendor.fromJson(json['vendor'] as Map<String, dynamic>),
      colorHex: json['color_hex'] as String?,
      settingsExtruderTemp: (json['settings_extruder_temp'] as num?)?.toInt(),
      settingsBedTemp: (json['settings_bed_temp'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SpoolmanFilamentToJson(SpoolmanFilament instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'material': instance.material,
      'vendor': instance.vendor,
      'color_hex': instance.colorHex,
      'settings_extruder_temp': instance.settingsExtruderTemp,
      'settings_bed_temp': instance.settingsBedTemp,
    };

SpoolmanVendor _$SpoolmanVendorFromJson(Map<String, dynamic> json) =>
    SpoolmanVendor(name: json['name'] as String);

Map<String, dynamic> _$SpoolmanVendorToJson(SpoolmanVendor instance) =>
    <String, dynamic>{'name': instance.name};
