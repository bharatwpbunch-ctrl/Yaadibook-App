import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaadibook/app/app.dart';

void main() {
  testWidgets('Bottom navigation tabs switch active screens', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: YaadibookApp()));
    await tester.pumpAndSettle();

    // Verify Today screen is initial
    expect(find.text("Today's Overview"), findsOneWidget);

    // Switch to Customers tab
    await tester.tap(find.byIcon(Icons.people_outline));
    await tester.pumpAndSettle();
    expect(find.text('Customers'), findsWidgets);

    // Switch to Quick Add tab
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();
    expect(find.text('Quick Add'), findsWidgets);

    // Switch to Reminders tab
    await tester.tap(find.byIcon(Icons.notifications_none_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Reminders'), findsWidgets);

    // Switch to More tab
    await tester.tap(find.byIcon(Icons.more_horiz_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Maruti AC & CCTV Services'), findsOneWidget);
  });
}
