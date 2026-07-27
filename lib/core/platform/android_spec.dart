import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../../shared/widgets/app_glyph.dart';
import 'platform_spec.dart';

/// A pele Android: ladrilho redondo, curva enfática nos dois sentidos e toque
/// com ondulação.
///
/// Esta implementação é crua de propósito. Ela existe desde o primeiro dia
/// para manter a interface honesta: qualquer membro novo em `PlatformSpec`
/// precisa de uma resposta aqui, e é isso que impede o projeto de virar um
/// app iOS com um interruptor decorativo. Lapidar a pele é assunto de outra
/// etapa — mexer aqui nunca pode exigir mexer em tela.
class AndroidSpec extends PlatformSpec {
  const AndroidSpec();

  @override
  String get id => 'android';

  @override
  String get label => 'Android';

  @override
  BorderRadius iconRadius(double size) => BorderRadius.circular(size * 0.5);

  @override
  double get surfaceRadius => 28;

  @override
  Duration get openDuration => const Duration(milliseconds: 350);

  @override
  Duration get closeDuration => const Duration(milliseconds: 300);

  @override
  Curve get openCurve => Curves.easeInOutCubicEmphasized;

  @override
  Curve get closeCurve => Curves.easeInOutCubicEmphasized;

  @override
  List<String> get fontFallback => const ['Roboto', 'Noto Sans', 'Arial'];

  @override
  double get appLabelSize => 12;

  @override
  FontWeight get appLabelWeight => FontWeight.w500;

  @override
  bool get hasHomeIndicator => false;

  @override
  double get systemChromeHeight => 26;

  // Qualquer borda lateral volta.
  @override
  Set<ScreenEdge> get backGestureEdges => const {
    ScreenEdge.left,
    ScreenEdge.right,
  };

  @override
  Widget tappable({
    required Widget child,
    required VoidCallback onTap,
    BorderRadius? radius,
  }) {
    return Material(
      type: MaterialType.transparency,
      borderRadius: radius,
      child: InkWell(onTap: onTap, borderRadius: radius, child: child),
    );
  }

  @override
  Widget switchControl({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Switch(value: value, onChanged: onChanged);
  }

  // Barra superior do Material: título à esquerda, seta com haste, sem
  // sombra. Ela fica presa no topo em vez de encolher.
  @override
  Widget screenHeader({
    required String title,
    required VoidCallback onBack,
    required Color background,
    required Color foreground,
  }) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: background,
      surfaceTintColor: background,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      title: Text(
        title,
        style: TextStyle(
          color: foreground,
          fontSize: 22,
          fontWeight: FontWeight.w400,
        ),
      ),
      leading: IconButton(
        onPressed: onBack,
        icon: IconTheme(
          data: IconThemeData(color: foreground, size: 24),
          child: AppGlyph(AppGlyphs.arrowLeft),
        ),
      ),
    );
  }

  // Cabeçalho no acento, linhas de borda a borda e divisores do Material.
  @override
  Widget settingsSection({required String header, required List<Widget> rows}) {
    return Builder(
      builder: (context) {
        final tokens = context.tokens;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 10),
              child: Text(
                header,
                style: TextStyle(
                  // O acento reprovaria sobre o fundo claro: 4,10:1, abaixo
                  // do piso de 4,5. O apagado é o tom de subcabeçalho do
                  // Material e passa nos dois temas.
                  color: tokens.onWallpaperMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamilyFallback: fontFallback,
                ),
              ),
            ),
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                Divider(height: 1, thickness: 1, color: tokens.surfaceBorder),
              rows[i],
            ],
          ],
        );
      },
    );
  }

  @override
  Widget settingsOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) {
        final tokens = context.tokens;
        return tappable(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
            child: Row(
              children: [
                RadioGroup<bool>(
                  groupValue: selected,
                  onChanged: (_) => onTap(),
                  child: Radio<bool>(
                    value: true,
                    fillColor: WidgetStatePropertyAll(
                      selected ? tokens.accent : tokens.onWallpaperMuted,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: tokens.onWallpaper,
                        fontSize: 16,
                        fontFamilyFallback: fontFallback,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Route<T> pageRoute<T>({
    required WidgetBuilder builder,
    required RouteSettings settings,
  }) {
    return MaterialPageRoute<T>(builder: builder, settings: settings);
  }
}
