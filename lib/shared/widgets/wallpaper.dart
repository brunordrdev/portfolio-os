import 'package:flutter/widgets.dart';

import '../../core/theme/tokens.dart';

/// O fundo do sistema: três camadas de luz, nenhuma imagem.
///
/// Sem asset de propósito nesta etapa — o papel de parede autoral vem depois,
/// e um degradê que nasce dos tokens acompanha a troca de tema sozinho.
class Wallpaper extends StatelessWidget {
  const Wallpaper({super.key, required this.child});

  final Widget child;

  // 170° na convenção do CSS (0° aponta para cima, girando no sentido
  // horário): quase de cima para baixo, inclinado um pouco à direita.
  static const Alignment _baseBegin = Alignment(-0.174, -0.985);
  static const Alignment _baseEnd = Alignment(0.174, 0.985);

  /// Converte uma posição em fração do quadro (0..1) para o sistema de
  /// alinhamento do Flutter, onde o centro é 0 e as bordas são -1 e 1.
  static Alignment _at(double x, double y) => Alignment(x * 2 - 1, y * 2 - 1);

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return DecoratedBox(
      // Base: a inclinação faz o canto inferior direito afundar.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: _baseBegin,
          end: _baseEnd,
          colors: [tokens.background, tokens.backgroundDeep],
        ),
      ),
      child: DecoratedBox(
        // Brilho quente, embaixo à esquerda: é o acento vazando no fundo.
        // Precisa dar para ver os dois brilhos sem procurar.
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: _at(0.22, 0.88),
            radius: 1.05,
            colors: [
              tokens.accent.withValues(alpha: 0.28),
              tokens.accent.withValues(alpha: 0),
            ],
          ),
        ),
        child: DecoratedBox(
          // Brilho frio, em cima à direita, no canto oposto ao quente.
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: _at(0.82, 0.14),
              radius: 0.9,
              colors: [
                tokens.coolGlow.withValues(alpha: 0.22),
                tokens.coolGlow.withValues(alpha: 0),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
