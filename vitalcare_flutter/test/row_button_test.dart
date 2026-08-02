import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalcare_flutter/core/widgets/app_button.dart';

void main() {
  testWidgets('AppButton in dashboard-style Row inside scroll view', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Dashboard')),
                    AppButton.accent('+ New Appointment'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppButton inside plain Row auto-sizes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              const Expanded(child: Text('Title')),
              AppButton.accent('Button'),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppButton inside Column fills width', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [AppButton.primary('Submit')],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
