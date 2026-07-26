import 'package:flutter/material.dart';

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

  @override
  Widget tappable({
    required Widget child,
    required VoidCallback onTap,
    BorderRadius? radius,
  }) {
    return Material(
      type: MaterialType.transparency,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: child,
      ),
    );
  }

  @override
  Widget switchControl({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Switch(value: value, onChanged: onChanged);
  }

  @override
  Route<T> pageRoute<T>({
    required WidgetBuilder builder,
    required RouteSettings settings,
  }) {
    return MaterialPageRoute<T>(builder: builder, settings: settings);
  }
}
