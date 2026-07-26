import 'package:flutter/widgets.dart';

/// Toda cor do sistema mora aqui.
///
/// Widget nenhum escreve `Color(0xFF...)`: um hexadecimal solto numa tela
/// sobrevive à troca de tema e quebra o modo claro. Cor entra por `AppTokens`,
/// que chega pelo `TokensScope`.
@immutable
class AppTokens {
  const AppTokens({
    required this.brightness,
    required this.background,
    required this.backgroundDeep,
    required this.surface,
    required this.surfaceBorder,
    required this.dockFill,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.badge,
    required this.coolGlow,
    required this.glyphs,
  });

  /// De que lado do tema este conjunto está. Quem precisa decidir entre claro
  /// e escuro pergunta aqui, e não ao `Theme` — assim há uma fonte só.
  final Brightness brightness;

  /// Fundo do papel de parede.
  final Color background;

  /// Fundo do degradê, mais profundo que `background`.
  final Color backgroundDeep;

  /// Preenchimento de ladrilhos, cartões e folhas.
  final Color surface;

  /// Fio de contorno de uma superfície.
  final Color surfaceBorder;

  /// Vidro da doca, com alfa.
  final Color dockFill;

  /// Texto sobre o papel de parede e rótulo de ícone.
  final Color textPrimary;

  /// Texto de apoio dentro de superfícies.
  final Color textSecondary;

  /// Âmbar da identidade: seleção, foco, destaque.
  final Color accent;

  /// Vermelho do selo. Escasso de propósito — um ícone só o usa.
  final Color badge;

  /// Azul do brilho frio do papel de parede, no canto oposto ao acento.
  /// Entra sempre com alfa baixo: é luz, não superfície.
  final Color coolGlow;

  /// Matizes dos glifos, uma por app, na ordem da grade.
  final List<Color> glyphs;

  /// Estilo A — escuro quente. É a identidade e o padrão.
  static const AppTokens dark = AppTokens(
    brightness: Brightness.dark,
    background: Color(0xFF16130F),
    backgroundDeep: Color(0xFF0E0C0A),
    surface: Color(0xFF1F1C17),
    surfaceBorder: Color(0xFF322C24),
    dockFill: Color(0x9E28241E),
    textPrimary: Color(0xFFECE5D9),
    textSecondary: Color(0xFF8D8478),
    accent: Color(0xFFE8A94E),
    badge: Color(0xFFE2532F),
    coolGlow: Color(0xFF5A7896),
    glyphs: [
      Color(0xFFE29070),
      Color(0xFF69BDB0),
      Color(0xFFE0B163),
      Color(0xFF8FA8D0),
      Color(0xFFA9B39E),
      Color(0xFFB0AAA0),
      Color(0xFF7CC493),
      Color(0xFF84B6DE),
      Color(0xFF7AA8D2),
      Color(0xFFC3BDB2),
    ],
  );

  /// Estilo B — claro. Abre conforme a preferência do sistema do visitante.
  static const AppTokens light = AppTokens(
    brightness: Brightness.light,
    background: Color(0xFFFFC9AE),
    backgroundDeep: Color(0xFFA8D8D2),
    surface: Color(0xFFFFFFFF),
    surfaceBorder: Color(0xFFE2DBD0),
    dockFill: Color(0x57FFFFFF),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF948B7D),
    accent: Color(0xFFE2683F),
    badge: Color(0xFFE2532F),
    coolGlow: Color(0xFF5A7896),
    glyphs: [
      Color(0xFFE2532F),
      Color(0xFF159183),
      Color(0xFFE39418),
      Color(0xFF4667A6),
      Color(0xFF75846C),
      Color(0xFF84817B),
      Color(0xFF26A04C),
      Color(0xFF2B7CC0),
      Color(0xFF1E5F96),
      Color(0xFF22222A),
    ],
  );
}

/// Leva os `AppTokens` do tema em uso para baixo na árvore.
class TokensScope extends InheritedWidget {
  const TokensScope({
    super.key,
    required this.tokens,
    required super.child,
  });

  final AppTokens tokens;

  static AppTokens of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TokensScope>();
    assert(scope != null, 'Nenhum TokensScope acima deste widget.');
    return scope!.tokens;
  }

  @override
  bool updateShouldNotify(TokensScope oldWidget) => tokens != oldWidget.tokens;
}

extension TokensScopeExtension on BuildContext {
  /// A paleta do tema em uso.
  AppTokens get tokens => TokensScope.of(this);
}
