import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/app/app.dart';

void main() {
  testWidgets('App initializes cleanly and renders initial Today screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: YaadibookApp()));

    await tester.pumpAndSettle();

    // Verify app bar title and initial widgets render
    expect(find.text('Yaadibook'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Customers'), findsOneWidget);
    expect(find.text('Quick Add'), findsOneWidget);
    expect(find.text('Reminders'), findsWidgets);
    expect(find.text('More'), findsOneWidget);
  });
}
