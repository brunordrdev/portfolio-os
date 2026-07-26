import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Andaime de Currículo. Só existe para a rota ter destino nesta etapa.
class ResumeScreen extends StatelessWidget {
  const ResumeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: tokens.background,
      body: Center(
        child: Text(
          'Currículo',
          style: TextStyle(color: tokens.textPrimary, fontSize: 20),
        ),
      ),
    );
  }
}
