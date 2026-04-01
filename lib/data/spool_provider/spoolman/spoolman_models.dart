import 'package:json_annotation/json_annotation.dart';

part 'spoolman_models.g.dart';

@JsonSerializable()
class SpoolmanSpool {
  final int? id;
  final SpoolmanFilament filament;
  @JsonKey(name: 'remaining_weight')
  final double? remainingWeight;
  @JsonKey(name: 'used_weight')
  final double usedWeight;
  final String? location;
  @JsonKey(name: 'lot_nr')
  final String? lotNr;
  final bool archived;

  SpoolmanSpool({
    this.id,
    required this.filament,
    this.remainingWeight,
    this.usedWeight = 0.0,
    this.location,
    this.lotNr,
    this.archived = false,
  });

  factory SpoolmanSpool.fromJson(Map<String, dynamic> json) =>
      _$SpoolmanSpoolFromJson(json);

  Map<String, dynamic> toJson() => _$SpoolmanSpoolToJson(this);
}

@JsonSerializable()
class SpoolmanFilament {
  final int id;
  final String name;
  final String material;
  final SpoolmanVendor? vendor;
  @JsonKey(name: 'color_hex')
  final String? colorHex;
  @JsonKey(name: 'settings_extruder_temp')
  final int? settingsExtruderTemp;
  @JsonKey(name: 'settings_bed_temp')
  final int? settingsBedTemp;

  SpoolmanFilament({
    required this.id,
    required this.name,
    required this.material,
    this.vendor,
    this.colorHex,
    this.settingsExtruderTemp,
    this.settingsBedTemp,
  });

  factory SpoolmanFilament.fromJson(Map<String, dynamic> json) =>
      _$SpoolmanFilamentFromJson(json);

  Map<String, dynamic> toJson() => _$SpoolmanFilamentToJson(this);
}

@JsonSerializable()
class SpoolmanVendor {
  final String name;

  SpoolmanVendor({required this.name});

  factory SpoolmanVendor.fromJson(Map<String, dynamic> json) =>
      _$SpoolmanVendorFromJson(json);

  Map<String, dynamic> toJson() => _$SpoolmanVendorToJson(this);
}
