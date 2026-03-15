import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/main.dart';
import 'package:my_first_app/screens/login_screen.dart';

void main() {
  testWidgets('App starts with LoginScreen', (WidgetTester tester) async {
    // Передаем обязательный параметр initialRoute
    await tester.pumpWidget(const MyApp(initialRoute: LoginScreen()));

    await tester.pumpAndSettle();
    expect(find.text('ЭИОС'), findsWidgets);
  });
}