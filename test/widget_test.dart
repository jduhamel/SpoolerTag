import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spooler_tag/app.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SpoolerTagApp()),
    );

    expect(find.text('Home'), findsWidgets);
  });
}
