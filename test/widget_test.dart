import 'package:flutter_test/flutter_test.dart';
import 'package:project/main.dart';
import 'package:project/utils/app_strings.dart';

void main() {
  testWidgets('Home screen renders assignment title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text(AppStrings.homeTitle), findsOneWidget);
  });
}
