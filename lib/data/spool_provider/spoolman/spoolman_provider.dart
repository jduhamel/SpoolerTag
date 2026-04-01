import 'package:dio/dio.dart';
import 'package:spooler_tag/core/constants.dart';
import 'package:spooler_tag/data/spool_provider/spool_provider.dart';
import 'package:spooler_tag/data/spool_provider/spoolman/spoolman_models.dart';
import 'package:spooler_tag/models/filament_spool.dart';

class SpoolmanProvider implements SpoolProvider {
  SpoolmanProvider({Dio? dio}) : _injectedDio = dio;

  final Dio? _injectedDio;
  Dio? _dio;

  List<FilamentSpool>? _cachedSpools;
  DateTime? _lastFetchTime;

  @override
  String get name => 'Spoolman';

  @override
  String get settingsLabel => 'Spoolman Server URL';

  @override
  bool get requiresUrl => true;

  Dio _getClient() {
    if (_injectedDio != null) return _injectedDio;
    return _dio ??= Dio(
      BaseOptions(
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.readTimeout,
      ),
    );
  }

  String _normalizeUrl(String url) {
    return url.endsWith('/') ? url : '$url/';
  }

  @override
  Future<String?> validateUrl(String url) async {
    try {
      final base = _normalizeUrl(url);
      final response = await _getClient().get('${base}api/v1/health');
      if (response.statusCode == 200) return null;
      return 'Server returned status ${response.statusCode}';
    } on DioException catch (e) {
      return e.message ?? 'Connection failed';
    }
  }

  @override
  Future<List<FilamentSpool>> getSpools({
    required String baseUrl,
    String? sortBy,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _isCacheValid()) {
      return _cachedSpools!;
    }

    try {
      final spools = await _fetchAllSpools(baseUrl, sortBy);
      _cachedSpools = spools;
      _lastFetchTime = DateTime.now();
      return spools;
    } on DioException {
      if (_cachedSpools != null) return _cachedSpools!;
      return [];
    }
  }

  @override
  Future<FilamentSpool?> getSpoolById({
    required String baseUrl,
    required String id,
  }) async {
    final numericId = int.tryParse(id);
    if (numericId == null) return null;

    // Check cache first
    if (_cachedSpools != null) {
      final cached = _cachedSpools!.where((s) => s.id == numericId);
      if (cached.isNotEmpty) return cached.first;
    }

    try {
      final base = _normalizeUrl(baseUrl);
      final response = await _getClient().get('${base}api/v1/spool/$numericId');
      final spoolmanSpool = SpoolmanSpool.fromJson(
        response.data as Map<String, dynamic>,
      );
      return _mapSpool(spoolmanSpool);
    } on DioException {
      return null;
    }
  }

  bool _isCacheValid() {
    if (_cachedSpools == null || _lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) <
        AppConstants.cacheValidity;
  }

  Future<List<FilamentSpool>> _fetchAllSpools(
    String baseUrl,
    String? sortBy,
  ) async {
    final base = _normalizeUrl(baseUrl);
    final allSpools = <FilamentSpool>[];
    var offset = 0;

    while (true) {
      final queryParams = <String, dynamic>{
        'limit': AppConstants.pageSize,
        'offset': offset,
      };
      if (sortBy != null) queryParams['sort'] = sortBy;

      final response = await _getClient().get(
        '${base}api/v1/spool',
        queryParameters: queryParams,
      );

      final data = response.data as List<dynamic>;
      final batch =
          data
              .map((e) => SpoolmanSpool.fromJson(e as Map<String, dynamic>))
              .map(_mapSpool)
              .toList();

      allSpools.addAll(batch);

      if (batch.length < AppConstants.pageSize) break;
      offset += AppConstants.pageSize;
    }

    return allSpools;
  }

  FilamentSpool _mapSpool(SpoolmanSpool spool) {
    return FilamentSpool.fromSpoolman(
      id: spool.id,
      material: spool.filament.material,
      variant: spool.filament.name,
      brand: spool.filament.vendor?.name ?? 'Unknown',
      colorHex: spool.filament.colorHex,
      extruderTemp: spool.filament.settingsExtruderTemp,
      bedTemp: spool.filament.settingsBedTemp,
      remainingWeight: spool.remainingWeight,
      usedWeight: spool.usedWeight,
      location: spool.location,
      lotNr: spool.lotNr,
      archived: spool.archived,
      spoolmanName: spool.filament.name,
    );
  }
}
