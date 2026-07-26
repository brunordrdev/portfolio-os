import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Andaime da tela inicial. Só existe para a rota ter destino nesta etapa.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: tokens.background,
      body: Center(
        child: Text(
          'Início',
          style: TextStyle(color: tokens.textPrimary, fontSize: 20),
        ),
      ),
    );
  }
}
