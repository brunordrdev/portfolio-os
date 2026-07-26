import 'package:flutter/widgets.dart';

import '../../core/platform/platform_scope.dart';
import '../../core/theme/tokens.dart';

/// A barra de gesto da base. Só existe onde a plataforma a desenha — quem
/// decide é a pele, não a tela.
class HomeIndicator extends StatelessWidget {
  const HomeIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final spec = context.platform;
    if (!spec.hasHomeIndicator) return const SizedBox.shrink();

    final tokens = context.tokens;
    return Container(
      width: 134,
      height: 5,
      decoration: BoxDecoration(
        color: tokens.textPrimary.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
