@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_os/app/router.dart';
import 'package:portfolio_os/core/platform/platform_scope.dart';
import 'package:portfolio_os/core/theme/tokens.dart';
import 'package:portfolio_os/features/home/home_screen.dart';
import 'package:portfolio_os/features/lock/lock_screen.dart';

/// Retrato das duas telas da casca.
///
/// O resto da suíte verifica estrutura e comportamento: ela não enxerga
/// pintura. Foi assim que todo texto ficou sublinhado de amarelo sem nenhum
/// teste reclamar. Estes retratos existem para que regressão de pintura —
/// degradê que sumiu, contorno que endureceu, glifo trocado — falhe.
///
/// Nos retratos o texto sai como caixas cheias: a fonte de teste do Flutter
/// não tem desenho de letra. É de propósito, e é o que os torna estáveis.
///
/// Estão marcados com a etiqueta `golden` porque comparam pixel a pixel, e
/// pixel depende de quem desenha: os mesmos widgets num Mac arm64 e num Linux
/// x64 divergem em 1,13% dos pontos — mais do que a menor regressão real que
/// dá para produzir de propósito, que é 0,40%. Nenhum limiar separa os dois.
/// Por isso o CI roda esta etiqueta num runner macOS e o resto no Linux.
/// Regerar, depois de uma mudança visual de propósito:
///
///     flutter test --update-goldens test/golden_test.dart
void main() {
  Future<void> boot(WidgetTester tester, AppTokens tokens) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final controller = PlatformController(PlatformController.ios);
    final router = createRouter();
    addTearDown(controller.dispose);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      PlatformScope(
        controller: controller,
        child: TokensScope(
          tokens: tokens,
          // Igual ao app de verdade: sem a faixa de debug, que cobriria
          // justamente o canto onde ficam o sinal e a bateria.
          child: MaterialApp.router(
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('retrato do bloqueio', (tester) async {
    await boot(tester, AppTokens.dark);

    expect(find.byType(LockScreen), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/bloqueio.png'),
    );
  });

  testWidgets('retrato da tela inicial', (tester) async {
    await boot(tester, AppTokens.dark);

    await tester.tapAt(tester.getCenter(find.byType(LockScreen)));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/inicio.png'),
    );
  });
}
