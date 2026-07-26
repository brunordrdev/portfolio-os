import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Andaime da tela de bloqueio. Só existe para a rota ter destino nesta etapa.
class LockScreen extends StatelessWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: tokens.background,
      body: Center(
        child: Text(
          'Bloqueio',
          style: TextStyle(color: tokens.textPrimary, fontSize: 20),
        ),
      ),
    );
  }
}
