import 'package:flutter/widgets.dart';

/// Uma borda lateral da tela.
enum ScreenEdge { left, right }

/// Contrato único do que muda entre um sistema e outro.
///
/// Nenhuma tela deste projeto pergunta em qual plataforma está rodando: ela
/// pede à `PlatformSpec` ativa. Quando uma tela precisar de um comportamento
/// que difere entre os dois sistemas, o caminho é **acrescentar um membro
/// aqui** — nunca abrir uma exceção dentro da tela.
abstract class PlatformSpec {
  /// Uma spec não guarda estado: são só respostas. O construtor const deixa
  /// cada pele existir como uma instância única no programa inteiro.
  const PlatformSpec();

  // --- Identidade ---------------------------------------------------------

  /// Chave estável da plataforma, usada em testes e persistência.
  String get id;

  /// Nome mostrado ao visitante quando ele vira a chave.
  String get label;

  // --- Forma --------------------------------------------------------------

  /// Arredondamento do ladrilho de um ícone de lado `size`.
  BorderRadius iconRadius(double size);

  /// Arredondamento de painéis, cartões e folhas.
  double get surfaceRadius;

  // --- Movimento ----------------------------------------------------------

  /// Tempo de abertura de um app.
  Duration get openDuration;

  /// Tempo de fechamento de um app.
  Duration get closeDuration;

  /// Curva de abertura de um app.
  Curve get openCurve;

  /// Curva de fechamento de um app.
  Curve get closeCurve;

  // --- Tipografia ---------------------------------------------------------

  /// Pilha de fontes do sistema, na ordem de preferência.
  List<String> get fontFallback;

  /// Corpo do rótulo abaixo do ícone.
  double get appLabelSize;

  /// Peso do rótulo abaixo do ícone.
  FontWeight get appLabelWeight;

  // --- Moldura do sistema -------------------------------------------------

  /// Se a plataforma desenha a barra de gesto na base.
  bool get hasHomeIndicator;

  /// Altura da barra de status no topo.
  double get systemChromeHeight;

  /// De quais bordas laterais o gesto de voltar pode nascer. É a única coisa
  /// que muda entre as plataformas nesse gesto: o resto — acompanhar o dedo,
  /// desistir antes da metade, assentar com a curva de fechar — é igual.
  Set<ScreenEdge> get backGestureEdges;

  // --- Componentes --------------------------------------------------------

  /// Envolve `child` com a resposta de toque da plataforma.
  Widget tappable({
    required Widget child,
    required VoidCallback onTap,
    BorderRadius? radius,
  });

  /// Chave liga/desliga da plataforma.
  Widget switchControl({
    required bool value,
    required ValueChanged<bool> onChanged,
  });

  /// Cabeçalho de uma tela de app, como sliver.
  ///
  /// É a diferença de plataforma mais visível do sistema: no iOS um título
  /// grande que encolhe ao rolar e um chevron de voltar; no Android a barra
  /// superior do Material, com o título alinhado à esquerda. As cores vêm de
  /// fora porque quem conhece os tokens é a tela, não a pele.
  Widget screenHeader({
    required String title,
    required VoidCallback onBack,
    required Color background,
    required Color foreground,
  });

  /// Rota de página com a transição da plataforma.
  Route<T> pageRoute<T>({
    required WidgetBuilder builder,
    required RouteSettings settings,
  });
}
