import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_os/app/router.dart';
import 'package:portfolio_os/content/app_content.dart';
import 'package:portfolio_os/core/platform/platform_scope.dart';
import 'package:portfolio_os/core/settings/settings.dart';
import 'package:portfolio_os/core/platform/platform_spec.dart';
import 'package:portfolio_os/core/theme/tokens.dart';
import 'package:portfolio_os/features/about/about_screen.dart';
import 'package:portfolio_os/features/home/home_screen.dart';
import 'package:portfolio_os/features/lock/lock_screen.dart';
import 'package:portfolio_os/shared/motion/app_open_page.dart';

/// O movimento da casca: abrir, fechar e voltar.
///
/// A duração e a curva são conferidas na própria rota, e não cronometrando o
/// relógio: um teste que mede tempo de animação passa a reprovar sozinho na
/// primeira máquina lenta, e não é o tempo que interessa — é de onde ele vem.
void main() {
  const skins = <String, PlatformSpec>{
    'iOS': PlatformController.ios,
    'Android': PlatformController.android,
  };
  const palettes = <String, AppTokens>{
    'escuro': AppTokens.dark,
    'claro': AppTokens.light,
  };

  const screen = Size(390, 844);

  for (final skin in skins.entries) {
    for (final palette in palettes.entries) {
      final spec = skin.value;
      final combo = '${skin.key} / ${palette.key}';

      group('movimento — $combo', () {
        /// Destrava e abre "Sobre" pelo ladrilho, como o visitante faria.
        Future<void> openApp(WidgetTester tester) async {
          tester.view.physicalSize = screen;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          final controller = PlatformController(spec);
          final router = createRouter();
          addTearDown(controller.dispose);
          addTearDown(router.dispose);

          await tester.pumpWidget(
            SettingsScope(
              controller: SettingsController(),
              child: PlatformScope(
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
            ),
          );
          await tester.pumpAndSettle();

          await tester.tapAt(tester.getCenter(find.byType(LockScreen)));
          await tester.pumpAndSettle();

          await tester.tap(find.text('Sobre'));
          await tester.pumpAndSettle();
          expect(find.byType(AboutScreen), findsOneWidget);
        }

        AppOpenRoute openRoute(WidgetTester tester) {
          return ModalRoute.of(tester.element(find.byType(AboutScreen)))!
              as AppOpenRoute;
        }

        testWidgets('a rota de abertura usa o tempo e a curva da pele', (
          tester,
        ) async {
          await openApp(tester);
          final route = openRoute(tester);

          expect(route.transitionDuration, spec.openDuration);
          expect(route.reverseTransitionDuration, spec.closeDuration);
          expect(route.openCurve, spec.openCurve);
          expect(route.closeCurve, spec.closeCurve);
        });

        testWidgets('o app cresce a partir do ladrilho que o abriu', (
          tester,
        ) async {
          await openApp(tester);
          final route = openRoute(tester);
          final page = route.settings as AppOpenPage;

          // Sem origem seria um fade, não uma transição de contêiner.
          expect(page.origin, isNotNull);

          // O ladrilho de "Sobre" é o terceiro da primeira linha: à direita
          // e em cima, longe do centro da tela.
          final origin = page.origin!.rect;
          expect(origin.width, lessThan(screen.width / 3));
          expect(origin.center.dx, greaterThan(screen.width / 2));
          expect(origin.center.dy, lessThan(screen.height / 3));
        });

        // O raio de partida sai do ladrilho de verdade. Grade e doca têm
        // lados diferentes, e um número de referência chumbado sempre estaria
        // errado para pelo menos um dos dois.
        testWidgets('o movimento parte do tamanho do ladrilho da grade', (
          tester,
        ) async {
          await openApp(tester);
          final route = openRoute(tester);
          final origin = (route.settings as AppOpenPage).origin!;

          expect(origin.rect.width, 60);
          expect(route.originRadius, spec.iconRadius(60).topLeft.x);
        });

        testWidgets('o app tapa o que está atrás', (tester) async {
          await openApp(tester);

          expect(openRoute(tester).opaque, isTrue);
          expect(find.byType(HomeScreen), findsNothing);
        });

        // O gesto nativo de cada plataforma. As bordas estão escritas aqui à
        // mão de propósito: perguntar a `spec.backGestureEdges` faria o teste
        // concordar com qualquer resposta que a spec desse, inclusive a
        // errada. O que precisa ser cobrado é o comportamento de cada
        // plataforma, não a coerência da implementação consigo mesma.
        final closes = skin.key == 'iOS'
            ? const {ScreenEdge.left}
            : const {ScreenEdge.left, ScreenEdge.right};

        testWidgets('a pele declara as bordas que voltam', (tester) async {
          expect(spec.backGestureEdges, closes);
        });

        for (final edge in ScreenEdge.values) {
          final allowed = closes.contains(edge);
          final side = edge == ScreenEdge.left ? 'esquerda' : 'direita';

          testWidgets(
            allowed
                ? 'arrastar da borda $side fecha o app'
                : 'arrastar da borda $side não fecha o app',
            (tester) async {
              await openApp(tester);

              final from = edge == ScreenEdge.left
                  ? const Offset(6, 400)
                  : Offset(screen.width - 6, 400);
              final travel = edge == ScreenEdge.left
                  ? const Offset(320, 0)
                  : const Offset(-320, 0);

              await tester.flingFrom(from, travel, 900);
              await tester.pumpAndSettle();

              if (allowed) {
                expect(find.byType(HomeScreen), findsOneWidget);
                expect(find.byType(AboutScreen), findsNothing);
              } else {
                expect(find.byType(AboutScreen), findsOneWidget);
              }
            },
          );
        }

        testWidgets(
          'a tela acompanha o dedo e volta se soltar antes da metade',
          (tester) async {
            await openApp(tester);
            final route = openRoute(tester);
            expect(route.animation!.value, 1.0);

            // Arrasto curto e sem velocidade: desiste no meio do caminho.
            final gesture = await tester.startGesture(const Offset(6, 400));
            for (var i = 0; i < 5; i++) {
              await gesture.moveBy(const Offset(12, 0));
              await tester.pump();
            }

            // Sem isto o teste passaria mesmo que o gesto nunca tivesse
            // começado: o app continuaria aberto por não ter acontecido nada.
            expect(
              route.animation!.value,
              lessThan(1.0),
              reason: 'a animação da rota tem que seguir o dedo',
            );
            expect(route.animation!.value, greaterThan(0.5));

            await gesture.up();
            await tester.pumpAndSettle();

            expect(find.byType(AboutScreen), findsOneWidget);
            expect(route.animation!.value, 1.0);
          },
        );

        testWidgets('arrastar para cima na base volta para a tela inicial', (
          tester,
        ) async {
          await openApp(tester);

          await tester.flingFrom(
            Offset(screen.width / 2, screen.height - 12),
            const Offset(0, -160),
            900,
          );
          await tester.pumpAndSettle();

          expect(find.byType(HomeScreen), findsOneWidget);
        });

        testWidgets('Escape fecha o app', (tester) async {
          await openApp(tester);

          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();

          expect(find.byType(HomeScreen), findsOneWidget);
          expect(find.byType(AboutScreen), findsNothing);
        });

        // Entrar direto pela URL. Um celular sintetiza a pilha do deep link,
        // e aqui é igual: o gesto de voltar não pode depender de por onde o
        // visitante entrou.
        group('deep link', () {
          Future<AppOpenRoute> enterByUrl(WidgetTester tester) async {
            tester.view.physicalSize = screen;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);

            final controller = PlatformController(spec);
            final router = createRouter(initialLocation: Routes.about);
            addTearDown(controller.dispose);
            addTearDown(router.dispose);

            await tester.pumpWidget(
              SettingsScope(
                controller: SettingsController(),
                child: PlatformScope(
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
              ),
            );
            await tester.pumpAndSettle();

            expect(find.byType(AboutScreen), findsOneWidget);
            return ModalRoute.of(tester.element(find.byType(AboutScreen)))!
                as AppOpenRoute;
          }

          testWidgets('monta a tela inicial embaixo', (tester) async {
            final route = await enterByUrl(tester);

            expect(
              route.isFirst,
              isFalse,
              reason: 'o app precisa ter para onde voltar',
            );
            expect(
              find.byType(HomeScreen, skipOffstage: false),
              findsOneWidget,
            );
          });

          testWidgets('entra sem transição de abertura', (tester) async {
            final route = await enterByUrl(tester);

            expect((route.settings as AppOpenPage).origin, isNull);
            expect(route.transitionDuration, Duration.zero);
          });

          testWidgets('o gesto de voltar funciona igual', (tester) async {
            await enterByUrl(tester);

            await tester.flingFrom(
              const Offset(6, 400),
              const Offset(320, 0),
              900,
            );
            await tester.pumpAndSettle();

            expect(find.byType(HomeScreen), findsOneWidget);
            expect(find.byType(AboutScreen), findsNothing);
          });
        });
      });
    }
  }
}
