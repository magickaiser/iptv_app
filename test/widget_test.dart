import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frametv/app.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: IptvApp()),
    );

    // Verify that the login screen is shown initially.
    expect(find.text('Inicia sesión'), findsOneWidget);
    expect(find.text('FrameTV'), findsOneWidget);
  });
}
