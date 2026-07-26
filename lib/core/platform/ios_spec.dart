import 'package:flutter/cupertino.dart';

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
  BorderRadius iconRadius(double size) =>
      BorderRadius.circular(size * 0.225);

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

  @override
  bool get hasHomeIndicator => true;

  @override
  double get systemChromeHeight => 22;

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
