import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siba/screens/login_page.dart';
import 'package:siba/theme/siba_theme.dart';

void main() {
  testWidgets('Muestra el acceso de SIBA', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildSibaTheme(), home: const LoginPage()),
    );

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Entrar'), findsOneWidget);
  });
}
