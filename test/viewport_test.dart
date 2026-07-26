import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_os/app/router.dart';
import 'package:portfolio_os/core/platform/platform_scope.dart';
import 'package:portfolio_os/core/theme/tokens.dart';
import 'package:portfolio_os/features/home/home_screen.dart';
import 'package:portfolio_os/features/lock/lock_screen.dart';

/// A casca precisa caber na tela onde ela é a tese: um celular. Estourar
/// layout em 320 de largura não aparece em nenhum outro teste, porque o
/// resto roda em 800x600.
void main() {
  for (final size in const [
    Size(390, 844),  // iPhone 14
    Size(360, 800),  // Android comum
    Size(320, 568),  // o menor que ainda importa
    Size(1440, 900), // desktop
  ]) {
    testWidgets('casca cabe em ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = PlatformController(PlatformController.ios);
      final router = createRouter();
      addTearDown(controller.dispose);
      addTearDown(router.dispose);

      await tester.pumpWidget(PlatformScope(
        controller: controller,
        child: TokensScope(
          tokens: AppTokens.dark,
          child: MaterialApp.router(routerConfig: router),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(LockScreen), findsOneWidget);

      await tester.tapAt(tester.getCenter(find.byType(LockScreen)));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  }
}
