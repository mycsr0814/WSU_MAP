import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/welcome_view.dart';

void main() {
  testWidgets('WelcomeView smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WelcomeView());

    // WelcomeView에 '0'이라는 텍스트가 없으므로 findsNothing으로 확인
    expect(find.text('0'), findsNothing);

    // WelcomeView에 'Welcome'이라는 텍스트가 있다면 findsOneWidget으로 확인
    expect(find.text('Welcome'), findsOneWidget);

    // 추가 테스트는 WelcomeView의 실제 UI에 맞게 작성하세요.
  });
}
