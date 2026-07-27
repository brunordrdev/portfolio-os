import 'package:flutter/widgets.dart';

/// A moldura física do aparelho: cantos arredondados, borda e o recorte da
/// câmera.
///
/// Um desenho só, com as medidas por parâmetro. Cada pele diz o quanto
/// arredondar, quão grossa é a borda e que forma tem o recorte — pílula
/// central de um lado, furo redondo do outro — e o desenho é o mesmo.
class DeviceFramePainter extends CustomPainter {
  const DeviceFramePainter({
    required this.cornerRadius,
    required this.borderWidth,
    required this.bezel,
    required this.cutout,
    required this.cutoutTop,
    required this.cutoutRadius,
  });

  final double cornerRadius;
  final double borderWidth;
  final Color bezel;

  /// O tamanho do recorte da câmera.
  final Size cutout;

  /// A que distância do topo ele fica.
  final double cutoutTop;

  final double cutoutRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = bezel;
    final screen = Offset.zero & size;
    final rounded = RRect.fromRectAndRadius(
      screen,
      Radius.circular(cornerRadius),
    );

    // Os cantos: o que sobra entre o retângulo da tela e o arredondado.
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(screen),
        Path()..addRRect(rounded),
      ),
      paint,
    );

    // A borda, por dentro do arredondado.
    canvas.drawRRect(
      rounded.deflate(borderWidth / 2),
      Paint()
        ..color = bezel
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );

    // O recorte da câmera, centralizado no topo.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          (size.width - cutout.width) / 2,
          cutoutTop,
          cutout.width,
          cutout.height,
        ),
        Radius.circular(cutoutRadius),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(DeviceFramePainter old) =>
      old.cornerRadius != cornerRadius ||
      old.borderWidth != borderWidth ||
      old.bezel != bezel ||
      old.cutout != cutout ||
      old.cutoutTop != cutoutTop ||
      old.cutoutRadius != cutoutRadius;
}
