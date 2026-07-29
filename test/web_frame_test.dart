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

/// Largura e altura de um PNG, lidas do IHDR: os dois inteiros de quatro
/// bytes que vêm depois da assinatura e do nome do bloco.
(int, int) _pngSize(File file) {
  final bytes = file.readAsBytesSync();
  int at(int i) =>
      (bytes[i] << 24) | (bytes[i + 1] << 16) | (bytes[i + 2] << 8) | bytes[i + 3];
  return (at(16), at(20));
}

void main() {
  final html = File('web/index.html').readAsStringSync();

  /// O texto que o rastreador lê: sem comentários, sem script, sem estilo e
  /// sem tags — e, com as tags, sem os atributos. É a diferença entre estar
  /// no documento e estar escrito na página.
  final servedText = html
      .replaceAll(RegExp('<!--.*?-->', dotAll: true), ' ')
      .replaceAll(RegExp('<script.*?</script>', dotAll: true), ' ')
      .replaceAll(RegExp('<style.*?</style>', dotAll: true), ' ')
      .replaceAll(RegExp('<[^>]*>'), ' ');

  group('texto indexável', () {
    // O alvo do currículo é time internacional, e esta moldura é a única
    // parte do site que o Google lê. Servir português aqui era mirar o
    // mercado errado com a única página que existe para ser encontrada.
    test('o documento servido se declara em inglês', () {
      expect(html, contains('<html lang="en">'));
    });

    for (final fragment in const [
      'Bruno Rodrigues',
      'Mobile developer',
      'Aracaju',
    ]) {
      test('"$fragment" está no HTML servido', () {
        expect(servedText, contains(fragment));
      });
    }

    test('há um parágrafo, e não só rótulos soltos', () {
      final lede = RegExp(
        r'<p class="lede"[^>]*>(.*?)</p>',
        dotAll: true,
      ).firstMatch(html);
      expect(lede, isNotNull, reason: 'o parágrafo curto sumiu do HTML');
      expect(lede!.group(1)!.trim().length, greaterThan(120));
    });

    test('o título e o H1 dizem o mesmo nome', () {
      String inside(String tag) => RegExp(
        '<$tag[^>]*>(.*?)</$tag>',
        dotAll: true,
      ).firstMatch(html)!.group(1)!.trim();

      // "Bruno R." é o que cabe embaixo do ícone instalado, e é só lá que
      // ele serve: quem procura digita o nome inteiro.
      expect(inside('title'), contains(inside('h1')));
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

  group('a troca de idioma acontece no lugar', () {
    // Cada frase que muda de idioma carrega a versão em português num
    // atributo, e o script troca o texto do próprio elemento. Duas cópias de
    // texto no documento seriam conteúdo duplicado — o rastreador leria as
    // duas e escolheria uma.
    final pt = RegExp(
      'data-pt="([^"]+)"',
    ).allMatches(html).map((m) => m.group(1)!).toList();

    test('há par em português para o que muda', () {
      // Título, cargo, parágrafo, nota e as quatro frases da tela de
      // bloqueio. O H1 não conta: o nome é o mesmo nos dois idiomas.
      expect(pt.length, 8, reason: 'frases com par: $pt');
    });

    test('o português mora em atributo, e não escrito na página', () {
      for (final phrase in pt) {
        expect(
          servedText,
          isNot(contains(phrase)),
          reason: '"$phrase" aparece como texto: é a segunda cópia',
        );
      }
    });

    final swapAt = html.indexOf('navigator.language');

    test('o script vem depois do texto que troca', () {
      // Em <head> os elementos ainda não existem, e o laço não acharia nada.
      expect(swapAt, greaterThan(html.lastIndexOf('data-pt=')));
    });

    test('e não espera rede: inline e síncrono', () {
      // Com src, async ou defer o navegador pinta antes de trocar, e o
      // visitante em português vê uma piscada de inglês.
      final tag = html.substring(html.lastIndexOf('<script', swapAt), swapAt);
      for (final wait in const ['src=', 'async', 'defer']) {
        expect(tag, isNot(contains(wait)), reason: wait);
      }
    });
  });

  group('prévia de compartilhamento', () {
    String meta(String key) {
      final match = RegExp(
        '<meta (?:property|name)="$key" content="([^"]*)"',
      ).firstMatch(html);
      expect(match, isNotNull, reason: '$key não está no HTML');
      return match!.group(1)!;
    }

    final canonical = RegExp(
      '<link rel="canonical" href="([^"]*)"',
    ).firstMatch(html)!.group(1)!;

    // Rastreador de rede social não resolve caminho relativo: um og:image
    // relativo é prévia em branco no LinkedIn, sem erro em lugar nenhum.
    test('og:url e og:image são absolutos, na origem do canonical', () {
      for (final url in [
        meta('og:url'),
        meta('og:image'),
        meta('twitter:image'),
      ]) {
        expect(url, startsWith('https://'));
        expect(
          url,
          startsWith(canonical),
          reason: '$url não está na origem de $canonical — trocar o host '
              'pela metade é o jeito de isso sair calado',
        );
      }
    });

    test('a imagem é paisagem 1200×630 e existe no repositório', () {
      // Quadrado é recortado no meio em cartão largo, que é o formato do
      // LinkedIn e do X. E dimensão declarada errada reserva o espaço errado.
      final file = File('web/${Uri.parse(meta('og:image')).pathSegments.last}');
      expect(file.existsSync(), isTrue, reason: '${file.path} não existe');
      expect(_pngSize(file), (1200, 630));
      expect(meta('og:image:width'), '1200');
      expect(meta('og:image:height'), '630');
      expect(meta('og:image:alt'), isNotEmpty);
    });

    test('o X só mostra a imagem grande se o cartão for declarado', () {
      expect(meta('twitter:card'), 'summary_large_image');
    });

    test('o idioma do documento é o declarado, com o outro como alternativa', () {
      expect(meta('og:locale'), 'en_US');
      expect(meta('og:locale:alternate'), 'pt_BR');
    });
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

    test('o manifesto fala o mesmo idioma que o documento', () {
      expect(manifest['lang'], 'en');
    });

    // "." resolve contra a URL do manifesto, e não contra a raiz: instalado
    // de uma rota funda, o atalho abriria naquela rota.
    test('o atalho instalado abre na raiz', () {
      expect(manifest['start_url'], '/');
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

    // Aqui havia um teste do service worker, e ele cobrava duas strings no
    // bootstrap. As duas estavam lá, verdinhas, enquanto nenhum visitante
    // novo registrava service worker nenhum — o carregador do Flutter só
    // atualiza registro que já exista. Nenhuma leitura de arquivo pega isso:
    // registrar é coisa que acontece em execução, e só um navegador de
    // verdade sabe se aconteceu. Quem cobra agora é `tool/smoke.dart`, contra
    // o site publicado, e o CI o roda depois do deploy.

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

    // As quatro frases são as de `AppContent.lock`, nos dois idiomas: esta
    // camada imita a de cima, e palavra diferente viraria piscada na hora em
    // que o Flutter cobrisse a tela.
    test('tem o cumprimento, o nome, o cargo e a dica', () {
      for (final fragment in const [
        'hello',
        'my name is Bruno',
        'mobile developer',
        'swipe up',
      ]) {
        expect(lock, contains(fragment), reason: fragment);
      }
    });

    test('e a versão em português de cada uma', () {
      for (final fragment in const [
        'olá',
        'me chamo Bruno',
        'desenvolvedor mobile',
        'arraste para cima',
      ]) {
        expect(lock, contains('data-pt="$fragment"'), reason: fragment);
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
