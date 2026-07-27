import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/platform/platform_scope.dart';
import '../../core/theme/tokens.dart';

/// Ladrilho de um app da tela inicial.
///
/// Pega a forma e a resposta de toque da pele ativa e as cores dos tokens.
/// Não sabe — e não pode saber — em qual sistema está rodando.
class AppIcon extends StatelessWidget {
  const AppIcon({
    super.key,
    required this.label,
    required this.glyph,
    required this.hue,
    required this.onTap,
    this.size = 60,
    this.badge,
    this.showLabel = true,
  });

  /// Nome do app. Some da tela quando `showLabel` é falso, mas continua
  /// sendo o nome anunciado por leitor de tela.
  final String label;

  /// O desenho do ícone. Recebe a cor pelo `IconTheme`.
  final Widget glyph;

  /// Matiz deste app, vinda de `AppTokens.glyphs`.
  final Color hue;

  final VoidCallback onTap;

  /// Lado do ladrilho.
  final double size;

  /// Contagem do selo. Um ícone só do sistema recebe selo.
  final int? badge;

  /// A doca mostra só os ladrilhos; a grade mostra os nomes.
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final spec = context.platform;
    final tokens = context.tokens;
    final radius = spec.iconRadius(size);
    final isDark = tokens.brightness == Brightness.dark;

    // No escuro o ladrilho é neutro e o glifo carrega a matiz. No claro a
    // relação inverte: o ladrilho recebe a matiz e o glifo fica branco.
    final tileColor = isDark ? tokens.surface : hue;
    final glyphColor = isDark ? hue : tokens.onTile;

    // O selo transborda o canto do ladrilho — é assim que um aviso se lê.
    // Mas nada pintado fora dos limites do widget recebe toque: por isso o
    // alvo é uma caixa com folga, o ladrilho fica deslocado dentro dela e o
    // transbordo acontece dentro da caixa. A folga é simétrica na horizontal
    // para o ladrilho continuar centrado sob o rótulo, e só no topo na
    // vertical, para não abrir um vão extra antes do rótulo.
    final overhang = size * 0.16;
    final boxWidth = size + overhang * 2;
    final boxHeight = size + overhang;

    // O selo se apoia no canto real do ladrilho, e não no canto da caixa.
    // Quando a plataforma arredonda o ícone até virar círculo esses dois
    // pontos deixam de ser o mesmo: o canto do ícone está sobre a curva, a
    // 45°. É de lá que o selo transborda, e é lá que o toque alcança.
    final corner = radius.topRight.x;
    final badgeDiameter = size * 0.34;
    final cornerInset = corner * (1 - 1 / math.sqrt2);
    final badgeCenter = Offset(
      boxWidth - overhang - cornerInset,
      overhang + cornerInset,
    );

    final target = SizedBox(
      width: boxWidth,
      height: boxHeight,
      child: Stack(
        children: [
          Positioned(
            left: overhang,
            top: overhang,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: tileColor,
                borderRadius: radius,
                border: isDark ? Border.all(color: tokens.surfaceBorder) : null,
              ),
              child: Center(
                child: IconTheme(
                  data: IconThemeData(color: glyphColor, size: size * 0.46),
                  child: glyph,
                ),
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              left: badgeCenter.dx - badgeDiameter / 2,
              top: badgeCenter.dy - badgeDiameter / 2,
              child: _Badge(
                count: badge!,
                diameter: badgeDiameter,
                fill: tokens.badge,
                textColor: tokens.onTile,
              ),
            ),
        ],
      ),
    );

    final icon = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        spec.tappable(onTap: onTap, radius: radius, child: target),
        if (showLabel) ...[
          SizedBox(height: size * 0.1),
          // O nome abre o app junto com o ladrilho: escrito embaixo do ícone
          // ele parece parte dele, e o que parece tocável funciona. Fica fora
          // do `tappable` porque a resposta visual da pele pertence ao
          // ladrilho — no iOS é ele que encolhe, não a legenda.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.onWallpaper,
                fontSize: spec.appLabelSize,
                fontWeight: spec.appLabelWeight,
                height: 1.2,
              ),
            ),
          ),
        ],
      ],
    );

    // Com o rótulo na tela o nome já é anunciado. Sem ele, um leitor de tela
    // encontraria um botão sem nome — então o nome entra pela semântica.
    if (showLabel) return icon;
    return Semantics(label: label, button: true, child: icon);
  }
}

/// Selo de contagem. Vermelho só vale alguma coisa porque é escasso.
class _Badge extends StatelessWidget {
  const _Badge({
    required this.count,
    required this.diameter,
    required this.fill,
    required this.textColor,
  });

  final int count;
  final double diameter;
  final Color fill;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: diameter, minHeight: diameter),
      padding: EdgeInsets.symmetric(horizontal: diameter * 0.2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(diameter),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: textColor,
          fontSize: diameter * 0.6,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}
