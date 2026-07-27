import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_os/app/router.dart';
import 'package:portfolio_os/core/platform/platform_scope.dart';
import 'package:portfolio_os/core/platform/platform_spec.dart';
import 'package:portfolio_os/core/theme/tokens.dart';
import 'package:portfolio_os/features/lock/lock_screen.dart';
import 'package:portfolio_os/shared/widgets/wallpaper.dart';

/// Todo texto sobre o papel de parede precisa de 4,5:1.
///
/// Este teste existe por causa de um defeito que viveu desde o primeiro
/// commit sem ninguém ver: `textPrimary` era ao mesmo tempo a cor do glifo
/// dentro do ladrilho e a do rótulo sobre o papel de parede. Branco resolve
/// o primeiro caso e reprova o segundo, e no tema claro os rótulos ficaram
/// em 1,3:1 — praticamente invisíveis. Nenhum teste de estrutura via isso, e
/// nenhum retrato reprova por contraste ruim: um retrato só compara com ele
/// mesmo.
///
/// A medição é feita no pixel de verdade. O papel de parede é repintado
/// sozinho, do mesmo tamanho, e a cor é lida embaixo de cada elemento — sem
/// o próprio texto no caminho. Cor com alfa é composta sobre o fundo antes
/// de medir, senão o número mente a favor.
const double _minimumContrast = 4.5;

double _linear(int channel) {
  final s = channel / 255;
  return s <= 0.03928
      ? s / 12.92
      : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
}

double _luminance(int r, int g, int b) =>
    0.2126 * _linear(r) + 0.7152 * _linear(g) + 0.0722 * _linear(b);

double _contrast(double a, double b) =>
    (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);

int _byte(double component) => (component * 255).round().clamp(0, 255);

void main() {
  const skins = <String, PlatformSpec>{
    'iOS': PlatformController.ios,
    'Android': PlatformController.android,
  };
  const palettes = <String, AppTokens>{
    'escuro': AppTokens.dark,
    'claro': AppTokens.light,
  };

  // A tela de bloqueio escreve a data por extenso; sem congelar o relógio o
  // texto muda de largura e as posições medidas mudam junto.
  final frozen = DateTime(2026, 7, 26, 22, 47);

  for (final skin in skins.entries) {
    for (final palette in palettes.entries) {
      final tokens = palette.value;
      final combo = '${skin.key} / ${palette.key}';

      testWidgets('contraste sobre o papel de parede — $combo', (tester) async {
        await withClock(Clock.fixed(frozen), () async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          final controller = PlatformController(skin.value);
          final router = createRouter();
          addTearDown(controller.dispose);
          addTearDown(router.dispose);

          Future<void> pumpApp() async {
            await tester.pumpWidget(
              PlatformScope(
                controller: controller,
                child: TokensScope(
                  tokens: tokens,
                  child: MaterialApp.router(
                    routerConfig: router,
                    debugShowCheckedModeBanner: false,
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
          }

          /// Cada texto sobre o papel: onde está e de que cor foi escrito.
          final samples = <String, (Offset, Color)>{};

          void collect(String description, Finder finder) {
            final widget = tester.widget<Text>(finder);
            samples[description] = (
              tester.getCenter(finder),
              widget.style!.color!,
            );
          }

          // --- Tela de bloqueio ---
          await pumpApp();
          collect('bloqueio · hora', find.text('22:47').first);
          collect('bloqueio · data', find.textContaining('Aracaju'));
          collect('bloqueio · olá', find.text('olá'));
          collect('bloqueio · nome', find.text('me chamo Bruno'));
          collect('bloqueio · cargo', find.text('desenvolvedor mobile'));
          collect('bloqueio · dica', find.text('arraste para cima'));

          // --- Tela inicial ---
          await tester.tapAt(tester.getCenter(find.byType(LockScreen)));
          await tester.pumpAndSettle();
          collect('início · hora', find.text('22:47').first);
          for (final label in const [
            'Minha Caneta',
            'Projetos',
            'Sobre',
            'Experiência',
            'Currículo',
            'Ajustes',
          ]) {
            collect('início · $label', find.text(label));
          }

          // Repinta só o papel de parede para ler a cor de trás de cada um.
          await tester.pumpWidget(
            RepaintBoundary(
              child: TokensScope(
                tokens: tokens,
                child: const Wallpaper(child: SizedBox.expand()),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byType(RepaintBoundary).first,
          );
          final image = await tester.runAsync(() => boundary.toImage());
          final data = await tester.runAsync(
            () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
          );
          final pixels = data!.buffer.asUint8List();
          final width = image!.width;

          final failures = <String>[];
          for (final sample in samples.entries) {
            final (position, color) = sample.value;
            final x = position.dx.round().clamp(0, width - 1);
            final y = position.dy.round().clamp(0, image.height - 1);
            final index = (y * width + x) * 4;

            final backR = pixels[index];
            final backG = pixels[index + 1];
            final backB = pixels[index + 2];

            // Texto translúcido não vale pela cor do token: vale pelo que
            // sobra depois de misturar com o fundo.
            final alpha = color.a;
            final frontR = (_byte(color.r) * alpha + backR * (1 - alpha))
                .round();
            final frontG = (_byte(color.g) * alpha + backG * (1 - alpha))
                .round();
            final frontB = (_byte(color.b) * alpha + backB * (1 - alpha))
                .round();

            final ratio = _contrast(
              _luminance(frontR, frontG, frontB),
              _luminance(backR, backG, backB),
            );

            if (ratio < _minimumContrast) {
              failures.add(
                '  ${sample.key}: ${ratio.toStringAsFixed(2)}:1 '
                '(texto #${_hex(frontR, frontG, frontB)} sobre '
                '#${_hex(backR, backG, backB)})',
              );
            }
          }

          expect(
            failures,
            isEmpty,
            reason:
                'Texto ilegível sobre o papel de parede em $combo — o mínimo '
                'é ${_minimumContrast.toStringAsFixed(1)}:1:\n'
                '${failures.join('\n')}\n'
                'Texto sobre papel de parede usa onWallpaper ou '
                'onWallpaperMuted, nunca onTile.',
          );
        });
      });
    }
  }
}

String _hex(int r, int g, int b) => [r, g, b]
    .map((c) => c.toRadixString(16).padLeft(2, '0').toUpperCase())
    .join();
