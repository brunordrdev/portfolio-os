import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_os/app/router.dart';
import 'package:portfolio_os/core/platform/platform_scope.dart';
import 'package:portfolio_os/core/platform/platform_spec.dart';
import 'package:portfolio_os/core/theme/tokens.dart';
import 'package:portfolio_os/features/home/home_screen.dart';
import 'package:portfolio_os/features/lock/lock_screen.dart';
import 'package:portfolio_os/shared/widgets/app_icon.dart';

/// A casca inteira — bloqueio e tela inicial — sob uma pele e uma paleta
/// escolhidas, com o roteador de verdade.
///
/// As quatro combinações rodam sempre. É o que garante que lapidar a pele
/// Android depois não quebre a casca em silêncio.
void main() {
  // Sem um Material acima, todo Text herda o estilo de erro do framework:
  // vermelho, monoespaçado e sublinhado em amarelo duplo. Compila, passa em
  // todo teste de estrutura e aparece na cara do visitante.
  group('nenhuma tela herda o estilo de erro do Material', () {
    for (final route in const [
      Routes.lock,
      Routes.home,
      Routes.pen,
      Routes.projects,
      Routes.about,
      Routes.experience,
      Routes.resume,
      Routes.settings,
      Routes.phone,
      Routes.email,
      Routes.linkedin,
      Routes.github,
    ]) {
      testWidgets(route, (tester) async {
        final controller = PlatformController(PlatformController.ios);
        final router = createRouter();
        addTearDown(controller.dispose);
        addTearDown(router.dispose);

        await tester.pumpWidget(
          PlatformScope(
            controller: controller,
            child: TokensScope(
              tokens: AppTokens.dark,
              child: MaterialApp.router(routerConfig: router),
            ),
          ),
        );
        await tester.pumpAndSettle();

        if (route != Routes.lock) {
          router.go(route);
          await tester.pumpAndSettle();
        }

        final texts = find.byType(Text);
        expect(texts, findsWidgets, reason: 'a tela precisa ter algum texto');

        final style = DefaultTextStyle.of(tester.element(texts.first)).style;
        expect(style.decoration ?? TextDecoration.none, TextDecoration.none);
      });
    }
  });

  const skins = <String, PlatformSpec>{
    'iOS': PlatformController.ios,
    'Android': PlatformController.android,
  };
  const palettes = <String, AppTokens>{
    'escuro': AppTokens.dark,
    'claro': AppTokens.light,
  };

  for (final skin in skins.entries) {
    for (final palette in palettes.entries) {
      final combo = '${skin.key} / ${palette.key}';

      Future<void> boot(WidgetTester tester) async {
        final controller = PlatformController(skin.value);
        final router = createRouter();
        addTearDown(controller.dispose);
        addTearDown(router.dispose);

        await tester.pumpWidget(
          PlatformScope(
            controller: controller,
            child: TokensScope(
              tokens: palette.value,
              child: MaterialApp.router(routerConfig: router),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      group('bloqueio — $combo', () {
        testWidgets('abre no bloqueio, não na tela inicial', (tester) async {
          await boot(tester);

          expect(find.byType(LockScreen), findsOneWidget);
          expect(find.byType(HomeScreen), findsNothing);
        });

        // Caminho 1: o gesto da casa.
        testWidgets('arrastar para cima destrava', (tester) async {
          await boot(tester);

          await tester.fling(
            find.byType(LockScreen),
            const Offset(0, -260),
            1000,
          );
          await tester.pumpAndSettle();

          expect(find.byType(HomeScreen), findsOneWidget);
        });

        // Caminho 2: no desktop, muita gente não tenta arrastar.
        testWidgets('tocar em qualquer lugar destrava', (tester) async {
          await boot(tester);

          await tester.tapAt(tester.getCenter(find.byType(LockScreen)));
          await tester.pumpAndSettle();

          expect(find.byType(HomeScreen), findsOneWidget);
        });

        // Caminho 3: teclado não é conveniência, é acessibilidade.
        for (final key in const <String, LogicalKeyboardKey>{
          'Enter': LogicalKeyboardKey.enter,
          'Espaço': LogicalKeyboardKey.space,
          'seta para cima': LogicalKeyboardKey.arrowUp,
        }.entries) {
          testWidgets('${key.key} destrava', (tester) async {
            await boot(tester);

            await tester.sendKeyEvent(key.value);
            await tester.pumpAndSettle();

            expect(find.byType(HomeScreen), findsOneWidget);
          });
        }
      });

      group('tela inicial — $combo', () {
        Future<void> unlock(WidgetTester tester) async {
          await boot(tester);
          await tester.tapAt(tester.getCenter(find.byType(LockScreen)));
          await tester.pumpAndSettle();
        }

        testWidgets('mostra dez ícones: seis na grade, quatro na doca', (
          tester,
        ) async {
          await unlock(tester);

          expect(find.byType(AppIcon), findsNWidgets(10));
        });

        testWidgets('a grade nomeia os seis apps e a doca não nomeia nada', (
          tester,
        ) async {
          await unlock(tester);

          for (final name in const [
            'Minha Caneta',
            'Projetos',
            'Sobre',
            'Experiência',
            'Currículo',
            'Ajustes',
          ]) {
            expect(find.text(name), findsOneWidget, reason: name);
          }
          for (final name in const [
            'Telefone',
            'Email',
            'LinkedIn',
            'GitHub',
          ]) {
            expect(find.text(name), findsNothing, reason: name);
          }
        });

        // Regra 6: vermelho só significa alguma coisa se for escasso.
        testWidgets('um ícone só carrega selo, e é o Minha Caneta', (
          tester,
        ) async {
          await unlock(tester);

          final badged = tester
              .widgetList<AppIcon>(find.byType(AppIcon))
              .where((icon) => icon.badge != null)
              .toList();

          expect(badged, hasLength(1));
          expect(badged.single.label, 'Minha Caneta');
        });

        testWidgets('cada ícone da grade leva à sua rota', (tester) async {
          await unlock(tester);

          await tester.tap(find.text('Sobre'));
          await tester.pumpAndSettle();

          expect(find.byType(HomeScreen), findsNothing);
          expect(find.text('Sobre'), findsOneWidget);
        });

        testWidgets('os ícones da doca também levam a algum lugar', (
          tester,
        ) async {
          await unlock(tester);

          final dockIcon = tester
              .widgetList<AppIcon>(find.byType(AppIcon))
              .firstWhere((icon) => icon.label == 'GitHub');
          expect(dockIcon.showLabel, isFalse);

          await tester.tap(
            find.byWidgetPredicate(
              (w) => w is AppIcon && w.label == 'GitHub',
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(HomeScreen), findsNothing);
          expect(find.text('GitHub'), findsOneWidget);
        });
      });
    }
  }
}
