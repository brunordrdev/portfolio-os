import 'package:flutter/widgets.dart';

import '../../core/platform/platform_scope.dart';
import '../../core/theme/tokens.dart';
import 'app_glyph.dart';
import 'minute_clock.dart';

/// A barra do sistema: hora real à esquerda, sinal e bateria à direita.
///
/// Altura e pilha de fontes vêm da pele ativa. Não há porcentagem de bateria
/// nem contagem de notificação: número que não muda é enfeite.
class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final spec = context.platform;
    final tokens = context.tokens;

    return SizedBox(
      height: spec.systemChromeHeight,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: spec.statusBar.gutter),
        child: Row(
          children: [
            MinuteClock(
              builder: (context, now) => Text(
                clockText(now),
                style: TextStyle(
                  color: tokens.onWallpaper,
                  fontSize: spec.statusBar.textSize,
                  fontWeight: spec.statusBar.textWeight,
                  fontFamilyFallback: spec.fontFallback,
                  height: 1,
                ),
              ),
            ),
            const Spacer(),
            IconTheme(
              data: IconThemeData(
                color: tokens.onWallpaper,
                size: spec.statusBar.iconSize,
              ),
              child: Row(
                children: [
                  AppGlyph(AppGlyphs.wifi),
                  SizedBox(width: spec.statusBar.iconGap),
                  AppGlyph(AppGlyphs.battery),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
