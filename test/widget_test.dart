import 'package:flutter_test/flutter_test.dart';
import 'package:medivila_apps/main.dart';

void main() {
  testWidgets('MedivilaApp basic smoke test', (WidgetTester tester) async {
    expect(const MedivilaApp(), isNotNull);
  });
}
