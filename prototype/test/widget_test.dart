import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stocrm_mobile_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('Shorts then auth brand', (tester) async {
    await tester.pumpWidget(const DriveStoApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('VAG MARKET'), findsWidgets);
    await tester.tap(find.text('В приложение'));
    await tester.pump();
    expect(find.text('Продолжить'), findsOneWidget);
  });
}
