import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_os/core/theme/tokens.dart';

/// A moldura web é HTML, e HTML não enxerga Dart.
///
/// O Flutter web desenha em canvas: nada do que ele escreve entra no DOM, e
/// portanto nada dele é indexado. Por isso o nome, o cargo, a cidade e um
/// parágrafo existem em HTML de verdade — e por isso as cores da moldura são
/// cópia dos tokens. Cópia sem conferência descola: este teste é a conferência.
String _hex(Color color) =>
    '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

/// Com alfa, na ordem do CSS: #RRGGBBAA. Em Dart o alfa vem primeiro.
String _rgba(Color color) {
  final argb = color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
  return '#${argb.substring(2)}${argb.substring(0, 2)}';
}

void main() {
  final html = File('web/index.html').readAsStringSync();

  group('texto indexável', () {
    for (final fragment in const [
      'Bruno Rodrigues',
      'Desenvolvedor mobile',
      'Aracaju',
    ]) {
      test('"$fragment" está no HTML servido', () {
        expect(html, contains(fragment));
      });
    }

    test('há um parágrafo, e não só rótulos soltos', () {
      final lede = RegExp(
        r'<p class="lede">(.*?)</p>',
        dotAll: true,
      ).firstMatch(html);
      expect(lede, isNotNull, reason: 'o parágrafo curto sumiu do HTML');
      expect(lede!.group(1)!.trim().length, greaterThan(120));
    });

    for (final tag in const [
      'name="description"',
      'property="og:title"',
      'property="og:description"',
      'property="og:url"',
      'property="og:image"',
    ]) {
      test('$tag presente', () => expect(html, contains(tag)));
    }
  });

  group('as cores da moldura são as do sistema', () {
    // Ancorado no @media do CSS: as metas theme-color também falam de
    // prefers-color-scheme, e cortar por ali pegaria o pedaço errado.
    const darkRule = '@media (prefers-color-scheme: dark)';
    final darkBlock = html.substring(html.indexOf(darkRule));
    final lightBlock = html.substring(0, html.indexOf(darkRule));

    String value(String block, String name) {
      final match = RegExp('--$name:\\s*(#[0-9A-Fa-f]{6,8})').firstMatch(block);
      expect(match, isNotNull, reason: '--$name não encontrado');
      return match!.group(1)!.toUpperCase();
    }

    final expected = <String, (Color light, Color dark)>{
      'frame-bg': (AppTokens.light.background, AppTokens.dark.background),
      'wp-top': (AppTokens.light.wallpaperTop, AppTokens.dark.wallpaperTop),
      'wp-mid': (AppTokens.light.wallpaperMid, AppTokens.dark.wallpaperMid),
      'wp-bottom': (
        AppTokens.light.wallpaperBottom,
        AppTokens.dark.wallpaperBottom,
      ),
      'frame-ink': (AppTokens.light.onWallpaper, AppTokens.dark.onWallpaper),
      'frame-muted': (
        AppTokens.light.onWallpaperMuted,
        AppTokens.dark.onWallpaperMuted,
      ),
      'frame-accent': (AppTokens.light.accent, AppTokens.dark.accent),
    };

    for (final entry in expected.entries) {
      test('--${entry.key} bate com o token', () {
        expect(value(lightBlock, entry.key), _hex(entry.value.$1));
        expect(value(darkBlock, entry.key), _hex(entry.value.$2));
      });
    }
  });

  group('instalável na tela de início', () {
    final manifest =
        jsonDecode(File('web/manifest.json').readAsStringSync())
            as Map<String, dynamic>;

    test('o manifesto tem nome, modo e cores', () {
      expect(manifest['name'], isNotEmpty);
      expect(manifest['short_name'], isNotEmpty);
      expect(manifest['display'], 'standalone');
      expect(manifest['theme_color'], _hex(AppTokens.dark.background));
      expect(manifest['background_color'], _hex(AppTokens.dark.background));
    });

    test('tem ícone comum e recortável, em 192 e 512', () {
      final icons = (manifest['icons']! as List).cast<Map<String, dynamic>>();
      for (final purpose in const ['any', 'maskable']) {
        for (final size in const ['192x192', '512x512']) {
          expect(
            icons.any((i) => i['purpose'] == purpose && i['sizes'] == size),
            isTrue,
            reason: 'falta ícone \$purpose \$size',
          );
        }
      }
      for (final icon in icons) {
        expect(
          File('web/${icon['src']}').existsSync(),
          isTrue,
          reason: '${icon['src']} está no manifesto mas não existe',
        );
      }
    });

    test('o iOS tem ícone e nome curto para a tela de início', () {
      expect(html, contains('rel="apple-touch-icon"'));
      expect(html, contains('name="apple-mobile-web-app-title"'));
    });

    // Sem service worker o Chrome não oferece instalar, e o bootstrap
    // próprio não o registra de graça.
    test('o service worker é registrado pelo bootstrap próprio', () {
      final bootstrap = File('web/flutter_bootstrap.js').readAsStringSync();
      expect(bootstrap, contains('serviceWorkerSettings'));
      expect(bootstrap, contains('flutter_service_worker_version'));
    });

    test('a moldura do navegador acompanha o tema', () {
      for (final entry in <String, Color>{
        'light': AppTokens.light.background,
        'dark': AppTokens.dark.background,
      }.entries) {
        expect(
          html,
          contains(
            'name="theme-color" media="(prefers-color-scheme: ${entry.key})" '
            'content="${_hex(entry.value)}"',
          ),
          reason: 'theme-color de ${entry.key} fora dos tokens',
        );
      }
    });
  });

  group('a tela de bloqueio existe antes do Flutter', () {
    // O Flutter web leva segundos para montar numa rede ruim. Até esta
    // camada existir, o visitante de celular via a tela vazia nesse tempo.
    // Recortado na própria camada: procurar no documento inteiro passaria
    // pela meta description, que também diz "desenvolvedor mobile".
    final lock = html.substring(
      html.indexOf('<div id="lock">'),
      html.indexOf('<div id="stage">'),
    );

    test('tem o cumprimento, o nome, o cargo e a dica', () {
      for (final fragment in const [
        'olá',
        'me chamo Bruno',
        'desenvolvedor mobile',
        'arraste para cima',
      ]) {
        expect(lock, contains(fragment), reason: fragment);
      }
    });

    test('fica atrás do Flutter, que a cobre sem piscar', () {
      // Sem fundo em #stage, o que se vê enquanto ele está vazio é a camada
      // de baixo. Com fundo, haveria um retângulo liso no lugar dela.
      expect(html, contains('#stage { z-index: 1; background: transparent; }'));
      expect(html, contains('#lock { z-index: 0; }'));
    });

    test('não inventa relógio', () {
      // Hora que não anda é enfeite, e enfeite é proibido pela regra 5.
      expect(RegExp(r'\d\d:\d\d').hasMatch(lock), isFalse);
    });

    for (final glow in const ['wp-cool', 'wp-warm']) {
      test('--$glow tem alfa embutido, como o token', () {
        expect(
          RegExp('--$glow:\\s*#[0-9A-Fa-f]{8}').hasMatch(html),
          isTrue,
          reason: '$glow precisa dos oito dígitos: a luz tem alfa',
        );
      });
    }

    test('os brilhos batem com os tokens', () {
      final darkRule = '@media (prefers-color-scheme: dark)';
      final dark = html.substring(html.indexOf(darkRule));
      final light = html.substring(0, html.indexOf(darkRule));
      String value(String block, String name) =>
          RegExp('--$name:\\s*(#[0-9A-Fa-f]{8})').firstMatch(block)!.group(1)!;

      expect(value(light, 'wp-cool'), _rgba(AppTokens.light.coolGlow));
      expect(value(light, 'wp-warm'), _rgba(AppTokens.light.warmGlow));
      expect(value(dark, 'wp-cool'), _rgba(AppTokens.dark.coolGlow));
      expect(value(dark, 'wp-warm'), _rgba(AppTokens.dark.warmGlow));
    });
  });

  group('o Flutter é carregado dentro da moldura', () {
    final bootstrap = File('web/flutter_bootstrap.js').readAsStringSync();

    test('num elemento próprio, e não no body', () {
      expect(bootstrap, contains('hostElement'));
      expect(bootstrap, contains('#stage'));
      expect(html, contains('id="stage"'));
    });

    test('o ponto de quebra existe no CSS', () {
      expect(html, contains('max-width: 899px'));
    });
  });
}
