import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spooler_tag/data/local/material_database.dart';
import 'package:spooler_tag/models/filament_spool.dart';
import 'package:spooler_tag/models/open_spool_data.dart';

enum TempField { minTemp, maxTemp, bedMinTemp, bedMaxTemp }

class SpoolFormState {
  final String material;
  final String customMaterial;
  final String variant;
  final String brand;
  final String customBrand;
  final String? colorHex;
  final int minTemp;
  final int maxTemp;
  final int bedMinTemp;
  final int bedMaxTemp;
  final String lotNr;
  final bool isLotNrFromSpoolman;
  final String? spoolId;

  const SpoolFormState({
    this.material = 'PLA',
    this.customMaterial = '',
    this.variant = '',
    this.brand = '',
    this.customBrand = '',
    this.colorHex,
    this.minTemp = 190,
    this.maxTemp = 220,
    this.bedMinTemp = 40,
    this.bedMaxTemp = 65,
    this.lotNr = '',
    this.isLotNrFromSpoolman = false,
    this.spoolId,
  });

  SpoolFormState copyWith({
    String? material,
    String? customMaterial,
    String? variant,
    String? brand,
    String? customBrand,
    Object? colorHex = _sentinel,
    int? minTemp,
    int? maxTemp,
    int? bedMinTemp,
    int? bedMaxTemp,
    String? lotNr,
    bool? isLotNrFromSpoolman,
    Object? spoolId = _sentinel,
  }) {
    return SpoolFormState(
      material: material ?? this.material,
      customMaterial: customMaterial ?? this.customMaterial,
      variant: variant ?? this.variant,
      brand: brand ?? this.brand,
      customBrand: customBrand ?? this.customBrand,
      colorHex: colorHex == _sentinel
          ? this.colorHex
          : colorHex as String?,
      minTemp: minTemp ?? this.minTemp,
      maxTemp: maxTemp ?? this.maxTemp,
      bedMinTemp: bedMinTemp ?? this.bedMinTemp,
      bedMaxTemp: bedMaxTemp ?? this.bedMaxTemp,
      lotNr: lotNr ?? this.lotNr,
      isLotNrFromSpoolman: isLotNrFromSpoolman ?? this.isLotNrFromSpoolman,
      spoolId: spoolId == _sentinel
          ? this.spoolId
          : spoolId as String?,
    );
  }

  static const _sentinel = Object();
}

class SpoolFormNotifier extends Notifier<SpoolFormState> {
  @override
  SpoolFormState build() => const SpoolFormState();

  void loadFromOpenSpool(OpenSpoolData data) {
    final materialData = MaterialDatabase.getMaterial(data.type);

    int parseTemp(String? value, int? fallback) {
      if (value != null && value.isNotEmpty) {
        return int.tryParse(value) ?? fallback ?? 0;
      }
      return fallback ?? 0;
    }

    state = SpoolFormState(
      material: data.type,
      variant: data.subtype == 'Basic' ? '' : data.subtype,
      brand: data.brand,
      colorHex: data.colorHex,
      minTemp: parseTemp(data.minTemp, materialData?.defaultMinTemp),
      maxTemp: parseTemp(data.maxTemp, materialData?.defaultMaxTemp),
      bedMinTemp: parseTemp(data.bedMinTemp, materialData?.defaultBedMinTemp),
      bedMaxTemp: parseTemp(data.bedMaxTemp, materialData?.defaultBedMaxTemp),
      lotNr: data.lotNr ?? '',
      spoolId: data.spoolId,
    );
  }

  void loadFromFilamentSpool(FilamentSpool spool) {
    final materialData = MaterialDatabase.getMaterial(spool.material);

    state = SpoolFormState(
      material: spool.material,
      variant: spool.variant,
      brand: spool.brand,
      colorHex: spool.colorHex,
      minTemp: spool.minTemp ?? materialData?.defaultMinTemp ?? 0,
      maxTemp: spool.maxTemp ?? materialData?.defaultMaxTemp ?? 0,
      bedMinTemp: spool.bedMinTemp ?? materialData?.defaultBedMinTemp ?? 0,
      bedMaxTemp: spool.bedMaxTemp ?? materialData?.defaultBedMaxTemp ?? 0,
      lotNr: spool.lotNr ?? '',
      isLotNrFromSpoolman:
          spool.lotNr != null && spool.lotNr!.isNotEmpty,
      spoolId: spool.id?.toString(),
    );
  }

  void setMaterial(String material) {
    final materialData = MaterialDatabase.getMaterial(material);
    if (materialData != null) {
      state = state.copyWith(
        material: material,
        minTemp: materialData.defaultMinTemp,
        maxTemp: materialData.defaultMaxTemp,
        bedMinTemp: materialData.defaultBedMinTemp,
        bedMaxTemp: materialData.defaultBedMaxTemp,
      );
    } else {
      state = state.copyWith(material: material);
    }
  }

  void setBrand(String brand) => state = state.copyWith(brand: brand);

  void setCustomMaterial(String value) =>
      state = state.copyWith(customMaterial: value);

  void setCustomBrand(String value) =>
      state = state.copyWith(customBrand: value);

  void setVariant(String variant) => state = state.copyWith(variant: variant);

  void setColorHex(String? hex) => state = state.copyWith(colorHex: hex);

  void adjustTemp(TempField field, int delta) {
    state = switch (field) {
      TempField.minTemp => state.copyWith(minTemp: state.minTemp + delta),
      TempField.maxTemp => state.copyWith(maxTemp: state.maxTemp + delta),
      TempField.bedMinTemp =>
        state.copyWith(bedMinTemp: state.bedMinTemp + delta),
      TempField.bedMaxTemp =>
        state.copyWith(bedMaxTemp: state.bedMaxTemp + delta),
    };
  }

  void setLotNr(String value) {
    final filtered =
        value.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '').toUpperCase();
    final clamped =
        filtered.length > 16 ? filtered.substring(0, 16) : filtered;
    state = state.copyWith(lotNr: clamped);
  }

  void generateNewLotNr() {
    state = state.copyWith(
      lotNr: OpenSpoolData.generateLotNr(),
      isLotNrFromSpoolman: false,
    );
  }

  OpenSpoolData buildOpenSpoolData() {
    final effectiveMaterial =
        state.material == 'Other' ? state.customMaterial : state.material;
    final effectiveBrand =
        state.brand == 'Other' ? state.customBrand : state.brand;
    final displayName = state.variant.isNotEmpty
        ? '$effectiveMaterial ${state.variant}'
        : effectiveMaterial;

    return OpenSpoolData(
      type: displayName,
      colorHex: state.colorHex,
      brand: effectiveBrand,
      minTemp: state.minTemp.toString(),
      maxTemp: state.maxTemp.toString(),
      bedMinTemp: state.bedMinTemp.toString(),
      bedMaxTemp: state.bedMaxTemp.toString(),
      subtype: state.variant,
      spoolId: state.spoolId,
      lotNr: state.lotNr.isNotEmpty ? state.lotNr : null,
    );
  }
}

final spoolFormProvider =
    NotifierProvider<SpoolFormNotifier, SpoolFormState>(SpoolFormNotifier.new);
