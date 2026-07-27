@Tags(['golden'])
library;

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_os/app/router.dart';
import 'package:portfolio_os/app/web_stage.dart';
import 'package:portfolio_os/content/app_content.dart';
import 'package:portfolio_os/core/platform/platform_scope.dart';
import 'package:portfolio_os/core/platform/platform_spec.dart';
import 'package:portfolio_os/core/settings/settings.dart';
import 'package:portfolio_os/core/theme/tokens.dart';
import 'package:portfolio_os/shared/widgets/app_glyph.dart';

/// As duas peles lado a lado, na mesma tela e no mesmo instante.
///
/// É o retrato que prova a tese: mesmo código, mesma paleta, mesmo conteúdo,
/// e duas linguagens de projeto diferentes. Qualquer coisa que apareça de um
/// lado e não do outro é uma diferença que a costura está produzindo — que é
/// o que ela existe para fazer.
void main() {
  final frozen = DateTime(2026, 7, 26, 22, 47);

  Widget skin(WidgetTester tester, PlatformSpec spec, String location) {
    final controller = PlatformController(spec);
    final router = createRouter(initialLocation: location);
    addTearDown(controller.dispose);
    addTearDown(router.dispose);

    return SizedBox(
      width: 390,
      child: SettingsScope(
        controller: SettingsController(),
        child: PlatformScope(
          controller: controller,
          child: ContentScope(
            content: AppContent.pt,
            child: TokensScope(
              tokens: AppTokens.dark,
              child: MaterialApp.router(
                routerConfig: router,
                debugShowCheckedModeBanner: false,
                // Com a moldura física, sem o queixo do site: o que se
                // compara aqui é o aparelho.
                builder: deviceSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // O que o retrato não consegue mostrar: em teste de widget não há fonte de
  // ícone carregada, então todo glifo de fonte sai como caixa cheia. O
  // chevron do iOS aparece porque é SVG; a seta do Material, não. Então a
  // diferença entre os dois é conferida na árvore, e não na imagem.
  testWidgets('cada pele usa o ícone de voltar da sua linguagem', (
    tester,
  ) async {
    for (final entry in <PlatformSpec, bool>{
      // No Android o botão de voltar é peça do sistema, e vem do Material.
      PlatformController.android: true,
      // No iOS é o traçado próprio do projeto: o chevron da Apple não se
      // clona, se redesenha.
      PlatformController.ios: false,
    }.entries) {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: skin(tester, entry.key, Routes.about),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byIcon(Icons.arrow_back),
        entry.value ? findsOneWidget : findsNothing,
        reason: '${entry.key.id}: ícone de voltar errado',
      );
      expect(
        find.byType(AppGlyph),
        entry.value ? findsNothing : findsWidgets,
        reason: '${entry.key.id}: glifo próprio no lugar errado',
      );
    }
  });

  for (final screen in const <String, String>{
    'bloqueio': Routes.lock,
    'inicio': Routes.home,
    'sobre': Routes.about,
    'experiencia': Routes.experience,
    'curriculo': Routes.resume,
    'ajustes': Routes.settings,
  }.entries) {
    testWidgets('lado a lado — ${screen.key}', (tester) async {
      await withClock(Clock.fixed(frozen), () async {
        tester.view.physicalSize = const Size(788, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: RepaintBoundary(
              child: ColoredBox(
                color: AppTokens.dark.surfaceBorder,
                child: Row(
                  children: [
                    skin(tester, PlatformController.ios, screen.value),
                    const SizedBox(width: 8),
                    skin(tester, PlatformController.android, screen.value),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(RepaintBoundary).first,
          matchesGoldenFile('goldens/peles-${screen.key}.png'),
        );
      });
    });
  }
}
