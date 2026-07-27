import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Andaime de Experiência. Só existe para a rota ter destino nesta etapa.
class ExperienceScreen extends StatelessWidget {
  const ExperienceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: tokens.background,
      body: Center(
        child: Text(
          'Experiência',
          style: TextStyle(color: tokens.onWallpaper, fontSize: 20),
        ),
      ),
    );
  }
}
