import 'package:flutter/widgets.dart';

import '../../core/theme/tokens.dart';

/// O fundo do sistema: "Noite de Aracaju". Mar em cima, cidade embaixo.
///
/// Três camadas de luz, nenhuma imagem. A base leva a tela do frio ao quente
/// de uma ponta à outra, e os dois brilhos entram por fora do quadro — só a
/// borda de cada um aparece, que é o que dá impressão de fonte de luz
/// distante em vez de mancha desenhada no meio da tela.
///
/// Nascendo dos tokens, acompanha a troca de tema sem nenhum asset para
/// carregar: no claro é a mesma composição em outro horário do dia.
class Wallpaper extends StatelessWidget {
  const Wallpaper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return DecoratedBox(
      // 1. Base: a temperatura muda de cima para baixo.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            tokens.wallpaperTop,
            tokens.wallpaperMid,
            tokens.wallpaperBottom,
          ],
          stops: const [0.0, 0.52, 1.0],
        ),
      ),
      child: DecoratedBox(
        // 2. Luz fria, de cima. O centro fica acima da tela.
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -1.24),
            radius: 1.10,
            colors: [tokens.coolGlow, tokens.coolGlow.withValues(alpha: 0)],
            stops: const [0.0, 0.72],
          ),
        ),
        child: DecoratedBox(
          // 3. Luz quente, de baixo, por último. O centro fica abaixo da tela.
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, 1.04),
              radius: 1.05,
              colors: [tokens.warmGlow, tokens.warmGlow.withValues(alpha: 0)],
              stops: const [0.0, 0.70],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
