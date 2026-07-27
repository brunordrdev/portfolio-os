@Tags(['golden'])
library;

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_os/app/router.dart';
import 'package:portfolio_os/content/app_content.dart';
import 'package:portfolio_os/core/platform/platform_scope.dart';
import 'package:portfolio_os/core/platform/platform_spec.dart';
import 'package:portfolio_os/app/web_stage.dart';
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
  /// Um instante fixo. A tela de bloqueio mostra a data por extenso, e
  /// "domingo, 26 de julho" não tem a mesma largura de "segunda-feira, 27 de
  /// julho": sem congelar o relógio, o retrato reprova na virada do dia.
  final frozen = DateTime(2026, 7, 26, 22, 47);

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
        child: ContentScope(
          content: AppContent.pt,
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
      ),
    );
    await tester.pumpAndSettle();
  }

  /// As telas de conteúdo, nas quatro combinações. É onde o cabeçalho da
  /// plataforma aparece: título grande de um lado, barra presa do outro.
  const skins = <String, PlatformSpec>{
    'ios': PlatformController.ios,
    'android': PlatformController.android,
  };
  const palettes = <String, AppTokens>{
    'escuro': AppTokens.dark,
    'claro': AppTokens.light,
  };
  const screens = <String, String>{
    'sobre': Routes.about,
    'experiencia': Routes.experience,
    'curriculo': Routes.resume,
  };

  for (final skin in skins.entries) {
    for (final palette in palettes.entries) {
      for (final screen in screens.entries) {
        testWidgets('retrato de ${screen.key} — ${skin.key}/${palette.key}', (
          tester,
        ) async {
          await withClock(Clock.fixed(frozen), () async {
            tester.view.physicalSize = const Size(390, 844);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);

            final controller = PlatformController(skin.value);
            final router = createRouter(initialLocation: screen.value);
            addTearDown(controller.dispose);
            addTearDown(router.dispose);

            await tester.pumpWidget(
              PlatformScope(
                controller: controller,
                child: ContentScope(
                  content: AppContent.pt,
                  child: TokensScope(
                    tokens: palette.value,
                    child: MaterialApp.router(
                      routerConfig: router,
                      debugShowCheckedModeBanner: false,
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();

            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(
                'goldens/${screen.key}-${skin.key}-${palette.key}.png',
              ),
            );
          });
        });
      }
    }
  }

  /// A composição da superfície Flutter dos dois lados do ponto de quebra.
  ///
  /// Acima dele o CSS dá a esta superfície 390x908 — celular mais o queixo com
  /// o interruptor. Abaixo, ela é a tela inteira. O que o retrato não pega é a
  /// coluna de texto ao lado, que é HTML: quem confere aquilo é o curl na URL
  /// publicada, porque é assim que um rastreador a vê.
  for (final stage in const <String, Size>{
    'acima-do-corte': Size(390, 908),
    'abaixo-do-corte': Size(390, 844),
  }.entries) {
    testWidgets('retrato da composição ${stage.key}', (tester) async {
      await withClock(Clock.fixed(frozen), () async {
        tester.view.physicalSize = stage.value;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final controller = PlatformController(PlatformController.ios);
        final router = createRouter(initialLocation: Routes.home);
        addTearDown(controller.dispose);
        addTearDown(router.dispose);

        await tester.pumpWidget(
          PlatformScope(
            controller: controller,
            child: ContentScope(
              content: AppContent.pt,
              child: TokensScope(
                tokens: AppTokens.dark,
                child: MaterialApp.router(
                  routerConfig: router,
                  debugShowCheckedModeBanner: false,
                  builder: webStage,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PlatformSwitchBar), findsOneWidget);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/composicao-${stage.key}.png'),
        );
      });
    });
  }

  testWidgets('retrato do bloqueio', (tester) async {
    await withClock(Clock.fixed(frozen), () async {
      await boot(tester, AppTokens.dark);

      expect(find.byType(LockScreen), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/bloqueio.png'),
      );
    });
  });

  testWidgets('retrato da tela inicial', (tester) async {
    await withClock(Clock.fixed(frozen), () async {
      await boot(tester, AppTokens.dark);

      await tester.tapAt(tester.getCenter(find.byType(LockScreen)));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/inicio.png'),
      );
    });
  });
}
