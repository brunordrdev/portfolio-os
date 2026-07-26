import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_os/app/portfolio_app.dart';

void main() {
  testWidgets('a raiz abre na tela de bloqueio', (WidgetTester tester) async {
    await tester.pumpWidget(const PortfolioApp());
    await tester.pumpAndSettle();

    expect(find.text('Bloqueio'), findsOneWidget);
  });
}
