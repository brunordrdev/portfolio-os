import 'package:flutter/widgets.dart';

import '../../core/platform/platform_scope.dart';

/// A peça que a plataforma desenha na base da tela.
///
/// Não decide nada: pergunta à pele ativa e desenha o que ela devolver. É a
/// barra de gesto do iOS de um lado, a pílula da navegação por gestos do
/// Android do outro.
class HomeIndicator extends StatelessWidget {
  const HomeIndicator({super.key});

  @override
  Widget build(BuildContext context) => context.platform.bottomChrome();
}
