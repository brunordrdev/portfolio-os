import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'android_spec.dart';
import 'ios_spec.dart';
import 'platform_spec.dart';

/// O único ponto de troca do projeto.
///
/// Guarda a `PlatformSpec` ativa e avisa quem depende dela. Virar a chave
/// aqui repinta o sistema inteiro sem que nenhuma tela seja tocada — se um
/// dia for preciso tocar em tela, a costura vazou e o conserto é na costura.
class PlatformController extends ChangeNotifier {
  /// Sem argumento, a plataforma é detectada a partir do aparelho do visitante.
  PlatformController([PlatformSpec? initial])
      : _spec = initial ?? _detectFromHost();

  /// As duas peles do sistema. Como não guardam estado, uma instância const
  /// de cada basta para o programa inteiro.
  static const PlatformSpec ios = IOSSpec();
  static const PlatformSpec android = AndroidSpec();

  PlatformSpec _spec;

  /// A pele em uso agora.
  PlatformSpec get spec => _spec;

  /// Detecção inicial. Só quem está de fato num Android entra na pele
  /// Android: ela é crua de propósito na v1, e quem chega de um desktop
  /// não escolheu vê-la — abre no iOS, que é a identidade do projeto.
  static PlatformSpec _detectFromHost() =>
      defaultTargetPlatform == TargetPlatform.android ? android : ios;

  /// Passa a usar uma pele específica.
  void use(PlatformSpec spec) {
    if (spec.id == _spec.id) return;
    _spec = spec;
    notifyListeners();
  }

  /// Vira a chave para a outra plataforma.
  void toggle() => use(_spec is IOSSpec ? android : ios);
}

/// Leva o `PlatformController` para baixo na árvore e reconstrói quem depende
/// dele quando a chave vira.
class PlatformScope extends InheritedNotifier<PlatformController> {
  const PlatformScope({
    super.key,
    required PlatformController controller,
    required super.child,
  }) : super(notifier: controller);

  static PlatformController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PlatformScope>();
    assert(scope != null, 'Nenhum PlatformScope acima deste widget.');
    return scope!.notifier!;
  }
}

extension PlatformScopeExtension on BuildContext {
  /// A pele ativa. É por aqui que toda tela pergunta como se comportar.
  PlatformSpec get platform => PlatformScope.of(this).spec;
}
