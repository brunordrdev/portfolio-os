import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_os/core/platform/platform_scope.dart';
import 'package:portfolio_os/core/platform/platform_spec.dart';
import 'package:portfolio_os/core/theme/tokens.dart';
import 'package:portfolio_os/shared/motion/app_open_page.dart';
import 'package:portfolio_os/shared/widgets/app_icon.dart';

/// Este arquivo é a rede de proteção da costura.
///
/// O `AppIcon` não sabe em qual plataforma está: ele pergunta à `PlatformSpec`.
/// Quando a pele Android for lapidada, é aqui que vai aparecer se a lapidação
/// quebrou a forma, o contraste ou — o mais fácil de quebrar sem perceber — a
/// área de toque do selo, que transborda o canto do ladrilho.
Widget _harness(
  PlatformController controller,
  AppTokens tokens,
  void Function(AppOrigin) onTap,
) {
  return PlatformScope(
    controller: controller,
    child: TokensScope(
      tokens: tokens,
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppIcon(
              label: 'Projetos',
              glyph: const Icon(Icons.circle),
              hue: tokens.glyphs.first,
              onTap: onTap,
              badge: 1,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
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
      group('AppIcon — ${skin.key} / ${palette.key}', () {
        late int taps;

        Future<void> mount(WidgetTester tester) async {
          taps = 0;
          final controller = PlatformController(skin.value);
          addTearDown(controller.dispose);
          await tester.pumpWidget(
            _harness(controller, palette.value, (_) => taps++),
          );
          await tester.pumpAndSettle();
        }

        testWidgets('desenha rótulo e selo', (tester) async {
          await mount(tester);

          expect(find.text('Projetos'), findsOneWidget);
          expect(find.text('1'), findsOneWidget);
        });

        testWidgets('o ladrilho responde ao toque', (tester) async {
          await mount(tester);

          await tester.tap(find.byIcon(Icons.circle));
          await tester.pumpAndSettle();

          expect(taps, 1);
        });

        // O caso que já quebrou uma vez: com o ladrilho redondo, o recorte
        // de toque engolia o selo. Ele parecia tocável e não era.
        testWidgets('o selo responde ao toque', (tester) async {
          await mount(tester);

          await tester.tap(find.text('1'));
          await tester.pumpAndSettle();

          expect(taps, 1);
        });

        // Não basta o centro do selo responder: a metade que transborda o
        // ladrilho é justamente a que caía fora do recorte.
        testWidgets('a borda externa do selo também responde', (tester) async {
          await mount(tester);

          // 60 é o lado padrão do ladrilho; o selo tem 34% disso.
          const badgeRadius = 60 * 0.34 / 2;
          const reach = badgeRadius * 0.7 / math.sqrt2;

          await tester.tapAt(
            tester.getCenter(find.text('1')) + const Offset(reach, -reach),
          );
          await tester.pumpAndSettle();

          expect(taps, 1);
        });
      });
    }
  }

  testWidgets('sem selo, o ícone continua inteiro e tocável', (tester) async {
    var taps = 0;
    final controller = PlatformController(PlatformController.android);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      PlatformScope(
        controller: controller,
        child: TokensScope(
          tokens: AppTokens.dark,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: AppIcon(
                  label: 'Sobre',
                  glyph: const Icon(Icons.circle),
                  hue: AppTokens.dark.glyphs.first,
                  onTap: (_) => taps++,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1'), findsNothing);

    await tester.tap(find.byIcon(Icons.circle));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });
}
