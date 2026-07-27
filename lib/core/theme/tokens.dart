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
    required this.onTile,
    required this.onWallpaper,
    required this.onWallpaperMuted,
    required this.textSecondary,
    required this.accent,
    required this.accentOnSurface,
    required this.badge,
    required this.wallpaperTop,
    required this.wallpaperMid,
    required this.wallpaperBottom,
    required this.deviceBezel,
    required this.coolGlow,
    required this.warmGlow,
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

  /// Cor de tudo que é desenhado DENTRO de um ladrilho: o glifo do ícone e
  /// o número do selo. O ladrilho é escuro no tema escuro e colorido no
  /// claro, então nos dois casos o que fica em cima dele é claro.
  ///
  /// Nunca use isto sobre o papel de parede: foi exatamente essa confusão
  /// que deixou o rótulo dos ícones em 1,3:1 no tema claro.
  final Color onTile;

  /// Texto sobre o papel de parede.
  final Color onWallpaper;

  /// Texto de apoio sobre o papel de parede — data, cargo, dica. Mais fraco
  /// que `onWallpaper`, mas ainda legível: é cor própria, não alfa por cima.
  final Color onWallpaperMuted;

  /// Texto de apoio dentro de superfícies claras (cartões, folhas).
  final Color textSecondary;

  /// Âmbar da identidade: seleção, foco, destaque. É seguro sobre o papel de
  /// parede, que é onde ele aparece — o "olá" da tela de bloqueio.
  final Color accent;

  /// O mesmo acento, para texto sobre fundo liso.
  ///
  /// No escuro os dois são iguais: o fundo é escuro dos dois lados. No claro
  /// não: o acento da identidade dá 4,10:1 sobre a página, abaixo do piso de
  /// 4,5, então aqui ele é mais escuro. Um token só não servia para os dois
  /// trabalhos, que é o gatilho que estava estacionado no CLAUDE.md.
  final Color accentOnSurface;

  /// Vermelho do selo. Escasso de propósito — um ícone só o usa.
  final Color badge;

  // --- Papel de parede: "Noite de Aracaju" --------------------------------
  //
  // Mar em cima, cidade embaixo. As três paradas fazem a base e os dois
  // brilhos entram por fora da tela, um de cada ponta. Os brilhos já vêm
  // com alfa embutido: são luz, não superfície.

  /// Parada de cima da base — o lado frio.
  final Color wallpaperTop;

  /// Parada do meio da base, onde as duas temperaturas se cruzam.
  final Color wallpaperMid;

  /// Parada de baixo da base — o lado quente.
  final Color wallpaperBottom;

  /// A moldura física do aparelho: cantos, borda e o recorte da câmera.
  ///
  /// Preta nos dois temas, porque moldura de aparelho é preta — ela não é
  /// superfície do sistema, é o vidro em volta dele.
  final Color deviceBezel;

  /// Luz fria, vindo de cima.
  final Color coolGlow;

  /// Luz quente, vindo de baixo.
  final Color warmGlow;

  /// Matizes dos glifos, uma por app, na ordem da grade.
  final List<Color> glyphs;

  /// Estilo A — escuro quente. É a identidade e o padrão.
  static const AppTokens dark = AppTokens(
    brightness: Brightness.dark,
    background: Color(0xFF16130F),
    backgroundDeep: Color(0xFF0E0C0A),
    surface: Color(0xFF1F1C17),
    // Claro o bastante para o ladrilho ter base contra o papel de parede,
    // escuro o bastante para não virar contorno desenhado.
    surfaceBorder: Color(0xFF4A4238),
    dockFill: Color(0x9E28241E),
    onTile: Color(0xFFECE5D9),
    onWallpaper: Color(0xFFECE5D9),
    onWallpaperMuted: Color(0xFFB8AEA0),
    textSecondary: Color(0xFF8D8478),
    accent: Color(0xFFE8A94E),
    accentOnSurface: Color(0xFFE8A94E),
    badge: Color(0xFFE2532F),
    wallpaperTop: Color(0xFF0A1113),
    wallpaperMid: Color(0xFF100D0B),
    wallpaperBottom: Color(0xFF191009),
    deviceBezel: Color(0xFF000000),
    coolGlow: Color(0x66386E7C),
    warmGlow: Color(0x57F0A046),
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
    onTile: Color(0xFFFFFFFF),
    onWallpaper: Color(0xFF5A4A3A),
    onWallpaperMuted: Color(0xFF63503F),
    textSecondary: Color(0xFF948B7D),
    accent: Color(0xFFA64420),
    // 5,29:1 sobre a página e 7,81:1 sobre o cartão embutido.
    accentOnSurface: Color(0xFF8E3616),
    badge: Color(0xFFE2532F),
    wallpaperTop: Color(0xFFBFE3E0),
    wallpaperMid: Color(0xFFFFE0C4),
    wallpaperBottom: Color(0xFFFFCBA4),
    deviceBezel: Color(0xFF000000),
    coolGlow: Color(0x427FC9C0),
    warmGlow: Color(0x4DFF9E5C),
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
  const TokensScope({super.key, required this.tokens, required super.child});

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
