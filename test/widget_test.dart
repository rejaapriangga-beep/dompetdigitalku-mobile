// Basic smoke test — just verifies the app widget tree builds without throwing.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dompetdigitalku/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const DompetDigitalKuApp());
    await tester.pump();

    // Either the loading indicator or the login screen should be present
    // right after first pump, depending on how fast secure storage resolves.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
