import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A família de ícones do sistema: traçada, `viewBox` 24×24, traço 1.7 e
/// pontas arredondadas. Desenho próprio — nada clonado da Apple.
///
/// Os desenhos são strings SVG no próprio código, sem arquivo de asset: são
/// poucos, mudam junto com o código e assim não há nada para carregar.
abstract final class AppGlyphs {
  /// Envolve só os caminhos no cabeçalho comum da família. O traço sai como
  /// `currentColor` para o `AppGlyph` poder pintá-lo com a cor do `IconTheme`.
  static String _drawn(String paths) =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
      'fill="none" stroke="currentColor" stroke-width="1.7" '
      'stroke-linecap="round" stroke-linejoin="round">$paths</svg>';

  // --- Inventário da grade e da doca, na ordem das matizes ----------------

  /// 0 · Minha Caneta
  static final String pen = _drawn(
    '<path d="M4 20l4-1 10-10a2.5 2.5 0 0 0-3.5-3.5L4.5 15.5 4 20z"/>'
    '<path d="M13.5 6.5l4 4"/>',
  );

  /// 1 · Projetos
  static final String layers = _drawn(
    '<path d="M12 3l8 4.5-8 4.5-8-4.5L12 3z"/>'
    '<path d="M4 12.5l8 4.5 8-4.5"/>'
    '<path d="M4 16.8l8 4.5 8-4.5"/>',
  );

  /// 2 · Sobre
  static final String user = _drawn(
    '<circle cx="12" cy="8.5" r="3.6"/>'
    '<path d="M4.8 20a7.2 7.2 0 0 1 14.4 0"/>',
  );

  /// 3 · Experiência
  static final String briefcase = _drawn(
    '<rect x="3" y="7.5" width="18" height="12.5" rx="2.2"/>'
    '<path d="M9 7.5V6a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v1.5"/>'
    '<path d="M3 13h18"/>',
  );

  /// 4 · Currículo
  static final String document = _drawn(
    '<path d="M6 3h7l5 5v13a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1z"/>'
    '<path d="M13 3v5h5"/>'
    '<path d="M8.5 13h7"/>'
    '<path d="M8.5 16.5h7"/>',
  );

  /// 5 · Ajustes
  ///
  /// Três cursores, cada um parado num ponto diferente. A engrenagem que
  /// estava aqui antes lia como sol: um círculo com raios em volta.
  static final String sliders = _drawn(
    '<path d="M3 6.5h18"/><circle cx="16" cy="6.5" r="2.1"/>'
    '<path d="M3 12h18"/><circle cx="9" cy="12" r="2.1"/>'
    '<path d="M3 17.5h18"/><circle cx="13" cy="17.5" r="2.1"/>',
  );

  /// 6 · Telefone
  static final String phone = _drawn(
    '<path d="M6.5 3.5h3l1.5 4-2 1.5a12 12 0 0 0 6 6l1.5-2 4 1.5v3a2 2 0 0 '
    '1-2.2 2A17.5 17.5 0 0 1 4.5 5.7 2 2 0 0 1 6.5 3.5z"/>',
  );

  /// 7 · Email
  static final String mail = _drawn(
    '<rect x="3" y="5.5" width="18" height="13" rx="2.2"/>'
    '<path d="M3.6 7l8.4 6 8.4-6"/>',
  );

  /// 8 · LinkedIn
  static final String linkedin = _drawn(
    '<rect x="3.5" y="3.5" width="17" height="17" rx="3"/>'
    '<path d="M8 10.5v6"/><path d="M8 7.6v.1"/>'
    '<path d="M12 16.5v-6"/><path d="M12 13a2.5 2.5 0 0 1 5 0v3.5"/>',
  );

  /// 9 · GitHub
  static final String branch = _drawn(
    '<circle cx="7" cy="5.5" r="2.2"/><circle cx="7" cy="18.5" r="2.2"/>'
    '<circle cx="17" cy="8.5" r="2.2"/>'
    '<path d="M7 7.7v8.6"/>'
    '<path d="M17 10.7c0 3.4-3.2 3.6-6.2 4.4"/>',
  );

  // --- Moldura do sistema -------------------------------------------------

  /// Sinal de rede, na barra de status.
  static final String wifi = _drawn(
    '<path d="M3.5 9.5a13 13 0 0 1 17 0"/>'
    '<path d="M6.5 13a8.5 8.5 0 0 1 11 0"/>'
    '<path d="M9.5 16.5a4 4 0 0 1 5 0"/>'
    '<path d="M12 20v.1"/>',
  );

  /// Bateria, na barra de status. Só o contorno: um nível de carga desenhado
  /// seria um número que não muda, e isso é enfeite.
  static final String battery = _drawn(
    '<rect x="2.5" y="8.5" width="16.5" height="7" rx="2.2"/>'
    '<path d="M21.5 11v2"/>',
  );

  /// Seta do convite para destravar.
  static final String arrowUp = _drawn(
    '<path d="M12 19.5V5"/><path d="M6.5 10.5L12 5l5.5 5.5"/>',
  );
}

/// Desenha um glifo da família com a cor e o tamanho do `IconTheme` em volta.
class AppGlyph extends StatelessWidget {
  const AppGlyph(this.svg, {super.key});

  final String svg;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final color = theme.color;
    final side = theme.size ?? 24;

    return SvgPicture.string(
      svg,
      width: side,
      height: side,
      colorFilter:
          color == null ? null : ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
