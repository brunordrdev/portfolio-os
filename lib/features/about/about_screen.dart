import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Andaime de Sobre. Só existe para a rota ter destino nesta etapa.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: tokens.background,
      body: Center(
        child: Text(
          'Sobre',
          style: TextStyle(color: tokens.onWallpaper, fontSize: 20),
        ),
      ),
    );
  }
}
