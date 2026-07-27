import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_os/content/app_content.dart';

/// A fonte embutida é um subconjunto, e subconjunto é uma aposta.
///
/// O Roboto completo tem 3 mil caracteres e pesa 220 KB nos três pesos; o
/// recorte para latim e acentuação do português pesa 67. A conta fecha, mas
/// uma letra fora do recorte não some com aviso: ela vira um quadradinho na
/// tela do visitante, e só na pele Android, que é a que usa a fonte.
///
/// Este teste lê o `cmap` do arquivo e confere que toda letra que o site
/// escreve está lá dentro.
Set<int> _covered(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);

  var cmap = -1;
  final tables = data.getUint16(4);
  for (var i = 0; i < tables; i++) {
    final record = 12 + i * 16;
    final tag = String.fromCharCodes(bytes.sublist(record, record + 4));
    if (tag == 'cmap') cmap = data.getUint32(record + 8);
  }
  expect(cmap, isNot(-1), reason: 'fonte sem tabela cmap');

  // Formato 4: o mapeamento do plano básico, que é onde vive o latim.
  var subtable = -1;
  final encodings = data.getUint16(cmap + 2);
  for (var i = 0; i < encodings; i++) {
    final offset = data.getUint32(cmap + 4 + i * 8 + 4);
    if (data.getUint16(cmap + offset) == 4) subtable = cmap + offset;
  }
  expect(subtable, isNot(-1), reason: 'cmap sem subtabela formato 4');

  final segments = data.getUint16(subtable + 6) ~/ 2;
  final ends = subtable + 14;
  final starts = ends + segments * 2 + 2;
  final deltas = starts + segments * 2;
  final ranges = deltas + segments * 2;

  final covered = <int>{};
  for (var s = 0; s < segments; s++) {
    final start = data.getUint16(starts + s * 2);
    final end = data.getUint16(ends + s * 2);
    final delta = data.getUint16(deltas + s * 2);
    final range = data.getUint16(ranges + s * 2);
    if (start == 0xFFFF) continue;

    for (var code = start; code <= end; code++) {
      final glyph = range == 0
          ? (code + delta) & 0xFFFF
          : data.getUint16(ranges + s * 2 + range + (code - start) * 2);
      // Glifo zero é "não tenho este caractere", e é ele que vira quadrado.
      if (glyph != 0) covered.add(code);
    }
  }
  return covered;
}

/// Tudo que o sistema escreve, nos dois idiomas.
Iterable<String> _everythingWritten(AppContent content) sync* {
  final apps = content.apps;
  yield* [
    apps.pen,
    apps.projects,
    apps.about,
    apps.experience,
    apps.resume,
    apps.settings,
    apps.phone,
    apps.email,
    apps.linkedin,
    apps.github,
  ];

  final lock = content.lock;
  yield* [lock.greeting, lock.name, lock.role, lock.hint, lock.dateTemplate];
  yield* lock.weekdays;
  yield* lock.months;

  for (final block in [
    ...content.about,
    ...content.experience,
    ...content.resume,
    ...content.projects,
  ]) {
    yield block.text;
  }

  final settings = content.settings;
  yield* [
    settings.languageSection,
    settings.appearanceSection,
    settings.systemSection,
    settings.portuguese,
    settings.english,
    settings.light,
    settings.dark,
    settings.followSystem,
  ];
  for (final fact in settings.facts) {
    yield* [fact.label, fact.value, fact.why];
  }

  // Os dígitos do relógio, que não estão em texto nenhum do conteúdo.
  yield '0123456789:';
}

void main() {
  for (final weight in const ['Light', 'Regular', 'Medium']) {
    test('Roboto-$weight cobre tudo que o site escreve', () {
      final file = File('assets/fonts/Roboto-$weight.ttf');
      expect(file.existsSync(), isTrue, reason: '${file.path} não existe');

      final covered = _covered(file.readAsBytesSync());
      final missing = <int>{};

      for (final content in const [AppContent.pt, AppContent.en]) {
        for (final text in _everythingWritten(content)) {
          for (final code in text.runes) {
            if (!covered.contains(code)) missing.add(code);
          }
        }
      }

      expect(
        missing,
        isEmpty,
        reason:
            'fora do subconjunto: '
            '${missing.map((c) => '${String.fromCharCode(c)} '
                '(U+${c.toRadixString(16).toUpperCase().padLeft(4, '0')})').join(', ')}',
      );
    });
  }
}
