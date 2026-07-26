import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Andaime dos quatro canais de contato da doca.
///
/// Um andaime só, com o nome por parâmetro, porque as quatro telas ainda são
/// a mesma coisa. Quando os endereços reais existirem, o mais provável é que
/// estes destinos deixem de ser telas e virem links externos — por isso não
/// vale abrir quatro arquivos agora.
class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key, required this.channel});

  final String channel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: tokens.background,
      body: Center(
        child: Text(
          channel,
          style: TextStyle(color: tokens.textPrimary, fontSize: 20),
        ),
      ),
    );
  }
}
