import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Andaime de Ajustes. Só existe para a rota ter destino nesta etapa.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: tokens.background,
      body: Center(
        child: Text(
          'Ajustes',
          style: TextStyle(color: tokens.onWallpaper, fontSize: 20),
        ),
      ),
    );
  }
}
