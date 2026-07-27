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
    // Fora do bloco escuro estão os valores claros; dentro dele, os escuros.
    final darkBlock = html.substring(
      html.indexOf('prefers-color-scheme: dark'),
    );
    final lightBlock = html.substring(0, html.indexOf('prefers-color-scheme'));

    String value(String block, String name) {
      final match = RegExp('--$name:\\s*(#[0-9A-Fa-f]{6})').firstMatch(block);
      expect(match, isNotNull, reason: '--$name não encontrado');
      return match!.group(1)!.toUpperCase();
    }

    final expected = <String, (Color light, Color dark)>{
      'frame-bg': (AppTokens.light.background, AppTokens.dark.background),
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
