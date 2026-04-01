import 'package:spooler_tag/models/filament_spool.dart';

abstract class SpoolProvider {
  String get name;
  String get settingsLabel;
  bool get requiresUrl;

  Future<String?> validateUrl(String url);

  Future<List<FilamentSpool>> getSpools({
    required String baseUrl,
    String? sortBy,
    bool forceRefresh = false,
  });

  Future<FilamentSpool?> getSpoolById({
    required String baseUrl,
    required String id,
  });
}
