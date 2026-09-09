import 'package:flutter_test/flutter_test.dart';
import 'package:stocrm_mobile_app/main.dart';

void main() {
  testWidgets('Auth screen shows brand', (tester) async {
    await tester.pumpWidget(const DriveStoApp());
    expect(find.text('DRIVE СТО'), findsOneWidget);
    expect(find.text('Получить код'), findsOneWidget);
  });
}
