import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Os retratos são gerados numa máquina e conferidos em outra: aqui um Mac
/// arm64, no CI um Linux x64. As duas desenham a mesma coisa, mas não com os
/// mesmos bits — a suavização de borda de um degradê ou de um traço curvo sai
/// com um ou dois pontos de diferença por canal.
///
/// O comparador padrão reprova qualquer pixel que difira, nem que seja em
/// 1/255, e por isso acusou 1,49% de diferença num retrato idêntico a olho.
/// Este aqui ignora essa margem e cobra o resto: um sublinhado que apareceu,
/// um contorno que mudou de cor ou um glifo trocado mexem em muitos pixels e
/// mexem muito em cada um.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final standard = goldenFileComparator as LocalFileComparator;
  goldenFileComparator = _TolerantComparator(standard.basedir);
  await testMain();
}

class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(Uri basedir)
    : super(basedir.resolve('flutter_test_config.dart'));

  /// Diferença por canal que ainda conta como o mesmo pixel.
  static const int _channelSlack = 16;

  /// Fração de pixels que pode divergir de verdade antes de reprovar.
  static const double _maxDifferent = 0.002;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final master = Uint8List.fromList(await getGoldenBytes(golden));
    final actual = await _decode(imageBytes);
    final expected = await _decode(master);

    if (actual.length != expected.length) {
      throw FlutterError(
        'Retrato "$golden": o tamanho da imagem mudou. '
        'Regenere com: flutter test --update-goldens',
      );
    }

    var different = 0;
    for (var i = 0; i < actual.length; i += 4) {
      for (var channel = 0; channel < 4; channel++) {
        final delta = (actual[i + channel] - expected[i + channel]).abs();
        if (delta > _channelSlack) {
          different++;
          break;
        }
      }
    }

    final total = actual.length ~/ 4;
    final fraction = different / total;
    if (fraction <= _maxDifferent) return true;

    // Só na falha: gera as imagens lado a lado que o Flutter escreve em
    // test/failures/, para dar para ver o que mudou.
    final result = await GoldenFileComparator.compareLists(imageBytes, master);
    final report = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(
      'Retrato "$golden": ${(fraction * 100).toStringAsFixed(2)}% dos pixels '
      'mudaram de verdade ($different de $total, além da margem de '
      '$_channelSlack por canal).\n$report',
    );
  }
}

Future<Uint8List> _decode(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return data!.buffer.asUint8List();
}
