import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_note/app/kumo_app.dart';

void main() {
  testWidgets('Kumo Notes opens the library', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: KumoApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Kumo Notes'), findsOneWidget);
    expect(find.text('New notebook'), findsOneWidget);
    expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
  });
}