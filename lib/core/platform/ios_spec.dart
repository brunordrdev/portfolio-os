import 'package:flutter/cupertino.dart';

import '../theme/tokens.dart';
import '../../shared/widgets/app_glyph.dart';
import 'platform_spec.dart';

/// A pele iOS: cantos de esquadro contínuo, curvas cúbicas e toque sem
/// ondulação — o dedo apenas encolhe e apaga o alvo.
class IOSSpec extends PlatformSpec {
  const IOSSpec();

  @override
  String get id => 'ios';

  @override
  String get label => 'iOS';

  @override
  BorderRadius iconRadius(double size) => BorderRadius.circular(size * 0.225);

  @override
  double get surfaceRadius => 26;

  @override
  Duration get openDuration => const Duration(milliseconds: 420);

  @override
  Duration get closeDuration => const Duration(milliseconds: 340);

  @override
  Curve get openCurve => Curves.easeOutCubic;

  @override
  Curve get closeCurve => Curves.easeInCubic;

  @override
  List<String> get fontFallback => const [
    '-apple-system',
    'BlinkMacSystemFont',
    'SF Pro Text',
    'Helvetica Neue',
  ];

  @override
  double get appLabelSize => 11;

  @override
  FontWeight get appLabelWeight => FontWeight.w400;

  // A barra de gesto do iOS: larga, fina e clara.
  @override
  Widget bottomChrome() {
    return Builder(
      builder: (context) {
        final tokens = context.tokens;
        return Container(
          width: 134,
          height: 5,
          decoration: BoxDecoration(
            color: tokens.onWallpaperMuted,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      },
    );
  }

  @override
  double get systemChromeHeight => 22;

  // Só a borda esquerda: no iOS a direita não volta.
  @override
  Set<ScreenEdge> get backGestureEdges => const {ScreenEdge.left};

  // O toque do iOS não espalha tinta, então o raio não é usado aqui: ele só
  // existe na assinatura porque a outra plataforma precisa recortar a onda.
  @override
  Widget tappable({
    required Widget child,
    required VoidCallback onTap,
    BorderRadius? radius,
  }) {
    return _PressFade(onTap: onTap, child: child);
  }

  @override
  Widget switchControl({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return CupertinoSwitch(value: value, onChanged: onChanged);
  }

  // Título grande que encolhe ao rolar e vira título de barra. É o gesto
  // tipográfico mais reconhecível do iOS.
  @override
  Widget screenHeader({
    required String title,
    required VoidCallback onBack,
    required Color background,
    required Color foreground,
  }) {
    return CupertinoSliverNavigationBar(
      largeTitle: Text(title, style: TextStyle(color: foreground)),
      middle: Text(title, style: TextStyle(color: foreground, fontSize: 17)),
      backgroundColor: background,
      border: null,
      automaticallyImplyLeading: false,
      leading: _PressFade(
        onTap: onBack,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: IconTheme(
            data: IconThemeData(color: foreground, size: 26),
            child: AppGlyph(AppGlyphs.chevronLeft),
          ),
        ),
      ),
    );
  }

  // Cartão embutido, com o título fora dele em maiúsculas pequenas e os
  // separadores recuados até onde o texto começa.
  @override
  Widget settingsSection({required String header, required List<Widget> rows}) {
    return Builder(
      builder: (context) {
        final tokens = context.tokens;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 26, 16, 7),
              child: Text(
                header.toUpperCase(),
                style: TextStyle(
                  color: tokens.onWallpaperMuted,
                  fontSize: 12.5,
                  letterSpacing: 0.6,
                  fontFamilyFallback: fontFallback,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: tokens.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < rows.length; i++) ...[
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: ColoredBox(
                            color: tokens.surfaceBorder,
                            child: const SizedBox(
                              height: 0.7,
                              width: double.infinity,
                            ),
                          ),
                        ),
                      rows[i],
                    ],
                  ],
                ),
              ),
            ),
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
            padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: tokens.onWallpaper,
                      fontSize: 16,
                      fontFamilyFallback: fontFallback,
                    ),
                  ),
                ),
                if (selected) _CheckMark(color: tokens.accent),
              ],
            ),
          ),
        );
      },
    );
  }

  // O iOS não transforma a página que sai por conta própria: ela continua
  // encolhendo de volta para o ladrilho que a abriu, acompanhando o dedo.
  @override
  BackDrag? backDrag({required double progress, required ScreenEdge edge}) =>
      null;

  @override
  Route<T> pageRoute<T>({
    required WidgetBuilder builder,
    required RouteSettings settings,
  }) {
    return CupertinoPageRoute<T>(builder: builder, settings: settings);
  }
}

/// Resposta de toque do iOS: escala 0.94 e opacidade 0.6 em 140ms.
class _PressFade extends StatefulWidget {
  const _PressFade({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_PressFade> createState() => _PressFadeState();
}

class _PressFadeState extends State<_PressFade> {
  static const Duration _duration = Duration(milliseconds: 140);

  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed == pressed) return;
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedOpacity(
        opacity: _pressed ? 0.6 : 1,
        duration: _duration,
        curve: Curves.easeOut,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1,
          duration: _duration,
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// A marca de conferido do iOS: uma escolha feita não muda a linha de lugar,
/// só acrescenta o sinal à direita.
class _CheckMark extends StatelessWidget {
  const _CheckMark({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconTheme(
      data: IconThemeData(color: color, size: 20),
      child: AppGlyph(AppGlyphs.check),
    );
  }
}
