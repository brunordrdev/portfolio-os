import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Andaime de Minha Caneta. Só existe para a rota ter destino nesta etapa.
class PenScreen extends StatelessWidget {
  const PenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: tokens.background,
      body: Center(
        child: Text(
          'Minha Caneta',
          style: TextStyle(color: tokens.onWallpaper, fontSize: 20),
        ),
      ),
    );
  }
}
