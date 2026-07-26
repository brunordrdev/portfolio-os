import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Andaime de Projetos. Só existe para a rota ter destino nesta etapa.
class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: tokens.background,
      body: Center(
        child: Text(
          'Projetos',
          style: TextStyle(color: tokens.textPrimary, fontSize: 20),
        ),
      ),
    );
  }
}
