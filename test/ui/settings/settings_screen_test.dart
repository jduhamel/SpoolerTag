import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spooler_tag/data/local/settings_repository.dart';
import 'package:spooler_tag/providers/settings_providers.dart';
import 'package:spooler_tag/providers/spool_providers.dart';
import 'package:spooler_tag/models/filament_spool.dart';
import 'package:spooler_tag/ui/settings/settings_screen.dart';

class MockSettingsRepository extends SettingsRepository {
  String? savedUrl;
  String? savedSort;
  String? savedType;

  @override
  Future<void> setSpoolmanUrl(String url) async => savedUrl = url;

  @override
  Future<void> setSortOrder(String? sort) async => savedSort = sort;

  @override
  Future<void> setProviderType(String type) async => savedType = type;
}

Widget _buildTestApp({
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: const SettingsScreen(),
    ),
  );
}

void main() {
  group('SettingsScreen', () {
    testWidgets('renders all form fields and buttons', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        overrides: [
          spoolListProvider.overrideWith(
            (ref) => Future.value(<FilamentSpool>[]),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Spool Provider Type'), findsOneWidget);
      expect(find.text('Server URL'), findsOneWidget);
      expect(find.text('Sort Order'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('initializes with current provider values', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        overrides: [
          spoolmanUrlProvider.overrideWith((ref) => 'http://myserver:7912'),
          sortOrderProvider.overrideWith((ref) => 'filament.material:asc'),
          providerTypeProvider.overrideWith((ref) => 'spoolman'),
          spoolListProvider.overrideWith(
            (ref) => Future.value(<FilamentSpool>[]),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // URL field should show the overridden value
      expect(find.text('http://myserver:7912'), findsOneWidget);
      // Sort dropdown should show Material A-Z
      expect(find.text('Material A-Z'), findsOneWidget);
    });

    testWidgets('save persists values to repository', (tester) async {
      final mockRepo = MockSettingsRepository();
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(mockRepo),
            spoolmanUrlProvider.overrideWith((ref) => 'http://192.168.1.'),
            sortOrderProvider.overrideWith((ref) => null),
            providerTypeProvider.overrideWith((ref) => 'spoolman'),
            spoolListProvider.overrideWith(
              (ref) => Future.value(<FilamentSpool>[]),
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Consumer(
                builder: (context, ref, _) {
                  container = ProviderScope.containerOf(context);
                  return ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                    child: const Text('Open'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Edit URL field
      final urlField = find.byType(TextField);
      await tester.enterText(urlField, 'http://10.0.0.5:7912');
      await tester.pumpAndSettle();

      // Tap save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(mockRepo.savedUrl, 'http://10.0.0.5:7912');
      expect(mockRepo.savedSort, isNull);
      expect(mockRepo.savedType, 'spoolman');

      // State providers should be updated
      expect(container.read(spoolmanUrlProvider), 'http://10.0.0.5:7912');

      // Should have popped back
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('cancel pops without saving', (tester) async {
      final mockRepo = MockSettingsRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(mockRepo),
            spoolListProvider.overrideWith(
              (ref) => Future.value(<FilamentSpool>[]),
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Should have popped back
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Settings'), findsNothing);

      // Nothing should have been saved
      expect(mockRepo.savedUrl, isNull);
      expect(mockRepo.savedSort, isNull);
      expect(mockRepo.savedType, isNull);
    });

    testWidgets('changing sort order updates dropdown', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        overrides: [
          spoolListProvider.overrideWith(
            (ref) => Future.value(<FilamentSpool>[]),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Find the Sort Order dropdown and tap it
      // Default is "None"
      expect(find.text('None'), findsOneWidget);

      // Open sort dropdown (second DropdownButtonFormField)
      final sortDropdown = find.byType(DropdownButtonFormField<String?>);
      await tester.tap(sortDropdown);
      await tester.pumpAndSettle();

      // Select "Brand A-Z"
      await tester.tap(find.text('Brand A-Z').last);
      await tester.pumpAndSettle();

      expect(find.text('Brand A-Z'), findsOneWidget);
    });
  });
}
