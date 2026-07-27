import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_os/app/portfolio_app.dart';
import 'package:portfolio_os/features/lock/lock_screen.dart';

void main() {
  testWidgets('a raiz abre na tela de bloqueio', (WidgetTester tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('pt', 'BR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);

    await tester.pumpWidget(const PortfolioApp());
    await tester.pumpAndSettle();

    expect(find.byType(LockScreen), findsOneWidget);
    expect(find.text('me chamo Bruno'), findsOneWidget);
  });
}
