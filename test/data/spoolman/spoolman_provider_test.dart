import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spooler_tag/data/spool_provider/spoolman/spoolman_provider.dart';

/// A mock HTTP adapter that records requests and returns canned responses.
class MockHttpAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  final List<ResponseBody Function(RequestOptions)> _responseQueue = [];
  ResponseBody Function(RequestOptions)? _defaultResponse;

  void enqueue(ResponseBody Function(RequestOptions) handler) {
    _responseQueue.add(handler);
  }

  void setDefault(ResponseBody Function(RequestOptions) handler) {
    _defaultResponse = handler;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (_responseQueue.isNotEmpty) {
      return _responseQueue.removeAt(0)(options);
    }
    if (_defaultResponse != null) {
      return _defaultResponse!(options);
    }
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
      message: 'No mock response configured',
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Builds a JSON string for a list of SpoolmanSpool objects.
Map<String, dynamic> _spoolJson({
  int id = 1,
  String material = 'PLA',
  String filamentName = 'Generic PLA',
  String vendorName = 'Generic',
  String? colorHex = 'FF0000',
  int? extruderTemp = 200,
  int? bedTemp = 60,
  double? remainingWeight = 800.0,
  double usedWeight = 200.0,
  String? location,
  String? lotNr,
  bool archived = false,
}) {
  return {
    'id': id,
    'filament': {
      'id': id,
      'name': filamentName,
      'material': material,
      'vendor': {'name': vendorName},
      'color_hex': colorHex,
      'settings_extruder_temp': extruderTemp,
      'settings_bed_temp': bedTemp,
    },
    'remaining_weight': remainingWeight,
    'used_weight': usedWeight,
    'location': location,
    'lot_nr': lotNr,
    'archived': archived,
  };
}

ResponseBody _jsonListResponse(List<Map<String, dynamic>> items) {
  return ResponseBody.fromString(
    jsonEncode(items),
    200,
    headers: {
      'content-type': ['application/json'],
    },
  );
}

ResponseBody _jsonResponse(Map<String, dynamic> item) {
  return ResponseBody.fromString(
    jsonEncode(item),
    200,
    headers: {
      'content-type': ['application/json'],
    },
  );
}

Dio _createDio(MockHttpAdapter adapter) {
  final dio = Dio();
  dio.httpClientAdapter = adapter;
  // Use a response transformer that decodes JSON
  return dio;
}

void main() {
  late MockHttpAdapter adapter;
  late Dio dio;
  late SpoolmanProvider provider;

  setUp(() {
    adapter = MockHttpAdapter();
    dio = _createDio(adapter);
    provider = SpoolmanProvider(dio: dio);
  });

  group('SpoolmanProvider', () {
    group('getSpools() pagination', () {
      test('fetches multiple pages until batch < pageSize', () async {
        // First page: 10 items (full page, so fetch next)
        final page1 = List.generate(10, (i) => _spoolJson(id: i));
        // Second page: 5 items (< pageSize, stop)
        final page2 = List.generate(5, (i) => _spoolJson(id: 10 + i));

        adapter.enqueue((_) => _jsonListResponse(page1));
        adapter.enqueue((_) => _jsonListResponse(page2));

        final spools = await provider.getSpools(
          baseUrl: 'http://localhost:7912',
        );

        expect(spools.length, 15);
        expect(adapter.requests.length, 2);
        expect(
          adapter.requests[0].uri.toString(),
          contains('offset=0'),
        );
        expect(
          adapter.requests[1].uri.toString(),
          contains('offset=10'),
        );
      });

      test('single page when batch < pageSize', () async {
        final page = List.generate(3, (i) => _spoolJson(id: i));
        adapter.enqueue((_) => _jsonListResponse(page));

        final spools = await provider.getSpools(
          baseUrl: 'http://localhost:7912',
        );

        expect(spools.length, 3);
        expect(adapter.requests.length, 1);
      });

      test('passes sort parameter', () async {
        adapter.enqueue((_) => _jsonListResponse([]));

        await provider.getSpools(
          baseUrl: 'http://localhost:7912',
          sortBy: 'filament.name',
        );

        expect(
          adapter.requests.first.uri.queryParameters['sort'],
          'filament.name',
        );
      });
    });

    group('caching', () {
      test('second call within cache window returns cached data', () async {
        final page = [_spoolJson(id: 1)];
        adapter.enqueue((_) => _jsonListResponse(page));

        await provider.getSpools(baseUrl: 'http://localhost:7912');
        final spools = await provider.getSpools(
          baseUrl: 'http://localhost:7912',
        );

        expect(spools.length, 1);
        // Only one HTTP call made
        expect(adapter.requests.length, 1);
      });

      test('forceRefresh bypasses cache', () async {
        final page1 = [_spoolJson(id: 1)];
        final page2 = [_spoolJson(id: 1), _spoolJson(id: 2)];
        adapter.enqueue((_) => _jsonListResponse(page1));
        adapter.enqueue((_) => _jsonListResponse(page2));

        await provider.getSpools(baseUrl: 'http://localhost:7912');
        final spools = await provider.getSpools(
          baseUrl: 'http://localhost:7912',
          forceRefresh: true,
        );

        expect(spools.length, 2);
        expect(adapter.requests.length, 2);
      });
    });

    group('network error handling', () {
      test('returns cached data on network error', () async {
        final page = [_spoolJson(id: 1)];
        adapter.enqueue((_) => _jsonListResponse(page));

        // Populate cache
        await provider.getSpools(
          baseUrl: 'http://localhost:7912',
          forceRefresh: false,
        );

        // Next call fails
        adapter.enqueue(
          (opts) => throw DioException(
            requestOptions: opts,
            type: DioExceptionType.connectionTimeout,
          ),
        );

        final spools = await provider.getSpools(
          baseUrl: 'http://localhost:7912',
          forceRefresh: true,
        );

        expect(spools.length, 1);
      });

      test('returns empty list on network error with no cache', () async {
        adapter.enqueue(
          (opts) => throw DioException(
            requestOptions: opts,
            type: DioExceptionType.connectionTimeout,
          ),
        );

        final spools = await provider.getSpools(
          baseUrl: 'http://localhost:7912',
        );

        expect(spools, isEmpty);
      });
    });

    group('getSpoolById()', () {
      test('returns null for non-numeric ID', () async {
        final result = await provider.getSpoolById(
          baseUrl: 'http://localhost:7912',
          id: 'abc',
        );

        expect(result, isNull);
        expect(adapter.requests, isEmpty);
      });

      test('returns spool from cache when available', () async {
        final page = [_spoolJson(id: 42)];
        adapter.enqueue((_) => _jsonListResponse(page));

        await provider.getSpools(baseUrl: 'http://localhost:7912');

        final result = await provider.getSpoolById(
          baseUrl: 'http://localhost:7912',
          id: '42',
        );

        expect(result, isNotNull);
        expect(result!.id, 42);
        // No additional HTTP call
        expect(adapter.requests.length, 1);
      });

      test('falls back to API when not in cache', () async {
        adapter.enqueue((_) => _jsonResponse(_spoolJson(id: 99)));

        final result = await provider.getSpoolById(
          baseUrl: 'http://localhost:7912',
          id: '99',
        );

        expect(result, isNotNull);
        expect(result!.id, 99);
        expect(adapter.requests.length, 1);
        expect(adapter.requests.first.uri.path, '/api/v1/spool/99');
      });

      test('returns null on network error', () async {
        adapter.enqueue(
          (opts) => throw DioException(
            requestOptions: opts,
            type: DioExceptionType.connectionTimeout,
          ),
        );

        final result = await provider.getSpoolById(
          baseUrl: 'http://localhost:7912',
          id: '99',
        );

        expect(result, isNull);
      });
    });

    group('temperature mapping', () {
      test('maps extruder and bed temps from SpoolmanSpool', () async {
        final page = [
          _spoolJson(
            id: 1,
            material: 'PLA',
            extruderTemp: 200,
            bedTemp: 50,
          ),
        ];
        adapter.enqueue((_) => _jsonListResponse(page));

        final spools = await provider.getSpools(
          baseUrl: 'http://localhost:7912',
        );

        // PLA defaults: extruder 190-220, bed 40-65
        // 200 is in range, so should use PLA defaults
        expect(spools.first.minTemp, 190);
        expect(spools.first.maxTemp, 220);
        expect(spools.first.bedMinTemp, 40);
        expect(spools.first.bedMaxTemp, 65);
      });

      test('maps null temps correctly', () async {
        final page = [
          _spoolJson(id: 1, extruderTemp: null, bedTemp: null),
        ];
        adapter.enqueue((_) => _jsonListResponse(page));

        final spools = await provider.getSpools(
          baseUrl: 'http://localhost:7912',
        );

        expect(spools.first.minTemp, isNull);
        expect(spools.first.maxTemp, isNull);
        expect(spools.first.bedMinTemp, isNull);
        expect(spools.first.bedMaxTemp, isNull);
      });
    });

    group('URL normalization', () {
      test('appends trailing slash to base URL', () async {
        adapter.enqueue((_) => _jsonListResponse([]));

        await provider.getSpools(baseUrl: 'http://localhost:7912');

        expect(
          adapter.requests.first.uri.toString(),
          startsWith('http://localhost:7912/'),
        );
      });

      test('does not double trailing slash', () async {
        adapter.enqueue((_) => _jsonListResponse([]));

        await provider.getSpools(baseUrl: 'http://localhost:7912/');

        final path = adapter.requests.first.uri.path;
        expect(path, isNot(contains('//')));
      });
    });

    group('field mapping', () {
      test('maps all SpoolmanSpool fields to FilamentSpool', () async {
        final page = [
          _spoolJson(
            id: 5,
            material: 'PETG',
            filamentName: 'Prusament PETG',
            vendorName: 'Prusa',
            colorHex: '00FF00',
            remainingWeight: 750.0,
            usedWeight: 250.0,
            location: 'Shelf A',
            lotNr: 'LOT123',
            archived: true,
          ),
        ];
        adapter.enqueue((_) => _jsonListResponse(page));

        final spools = await provider.getSpools(
          baseUrl: 'http://localhost:7912',
        );

        final spool = spools.first;
        expect(spool.id, 5);
        expect(spool.material, 'PETG');
        expect(spool.variant, 'Prusament PETG');
        expect(spool.brand, 'Prusa');
        expect(spool.colorHex, '00FF00');
        expect(spool.remainingWeight, 750.0);
        expect(spool.usedWeight, 250.0);
        expect(spool.location, 'Shelf A');
        expect(spool.lotNr, 'LOT123');
        expect(spool.archived, true);
        expect(spool.spoolmanName, 'Prusament PETG');
      });

      test('maps missing vendor to Unknown', () async {
        final json = _spoolJson(id: 1);
        // Remove vendor
        (json['filament'] as Map<String, dynamic>)['vendor'] = null;
        adapter.enqueue((_) => _jsonListResponse([json]));

        final spools = await provider.getSpools(
          baseUrl: 'http://localhost:7912',
        );

        expect(spools.first.brand, 'Unknown');
      });
    });
  });
}
