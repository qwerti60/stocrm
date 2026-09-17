import 'package:flutter_test/flutter_test.dart';
import 'package:stocrm_mobile_app/main.dart';

void main() {
  testWidgets('Shorts then auth brand', (tester) async {
    await tester.pumpWidget(const DriveStoApp());
    expect(find.text('VAG MARKET'), findsWidgets);
    await tester.tap(find.text('В приложение'));
    await tester.pump();
    expect(find.text('Получить код'), findsOneWidget);
  });
}
