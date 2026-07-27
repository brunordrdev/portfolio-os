import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/platform/platform_spec.dart';
import '../widgets/home_indicator.dart';

/// De onde o app saiu: o retângulo que o ladrilho ocupava na tela e a cor com
/// que ele estava pintado.
///
/// Sem isso não há de onde crescer — é o que separa uma transição de
/// contêiner de um fade. Viaja como `extra` da rota, e volta nulo quando o
/// visitante chega pela URL: nesse caso não houve ladrilho nenhum.
@immutable
class AppOrigin {
  const AppOrigin({required this.rect, required this.color});

  final Rect rect;
  final Color color;
}

/// A página de um app: o ladrilho crescendo até virar a tela inteira.
class AppOpenPage<T> extends Page<T> {
  const AppOpenPage({
    required this.child,
    required this.spec,
    required this.background,
    required this.onGoHome,
    this.origin,
    super.key,
    super.name,
  });

  final Widget child;
  final PlatformSpec spec;

  /// Cor de chegada do contêiner: o fundo do app.
  final Color background;

  /// Como voltar para a tela inicial quando não há para onde desempilhar.
  final VoidCallback onGoHome;

  final AppOrigin? origin;

  @override
  Route<T> createRoute(BuildContext context) => AppOpenRoute<T>(this);
}

/// A rota. Guarda o movimento e o gesto de voltar.
class AppOpenRoute<T> extends PageRoute<T> {
  AppOpenRoute(AppOpenPage<T> page) : super(settings: page);

  AppOpenPage<T> get _page => settings as AppOpenPage<T>;

  /// Expostos para o teste conferir o movimento na própria rota, e não
  /// cronometrando o relógio.
  Curve get openCurve => _page.spec.openCurve;
  Curve get closeCurve => _page.spec.closeCurve;

  /// O raio de onde o movimento começa. Sai do ladrilho de verdade que abriu
  /// o app — 60 na grade, 52 na doca —, e não de um tamanho de referência: o
  /// retângulo da origem já carrega o lado, então perguntar a ele é a única
  /// forma de os dois não poderem discordar.
  double? get originRadius {
    final origin = _page.origin;
    if (origin == null) return null;
    return _page.spec.iconRadius(origin.rect.width).topLeft.x;
  }

  /// Sem ladrilho de origem não há de onde crescer, e a entrada é seca.
  @override
  Duration get transitionDuration =>
      _page.origin == null ? Duration.zero : _page.spec.openDuration;

  @override
  Duration get reverseTransitionDuration => _page.spec.closeDuration;

  /// O app tapa o que está atrás. Papel de parede não aparece por baixo.
  @override
  bool get opaque => true;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  CurvedAnimation? _eased;

  /// De qual borda o dedo veio, e se o fechamento nasceu de um arrasto.
  ///
  /// A segunda pergunta existe porque a transformação preditiva não pode
  /// parar quando o dedo levanta: ela precisa terminar o movimento que
  /// começou, ou a página saltaria de encolhida para o outro movimento no
  /// meio do caminho.
  ScreenEdge _dragEdge = ScreenEdge.left;
  bool _predictive = false;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _AppShell(route: this, page: _page, child: _page.child);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final origin = _page.origin;
    if (origin == null) {
      // Entrada seca, porque a duração de ida é zero. Mas a volta não pode
      // ser: um deep link também tem gesto de voltar, e sem nada acontecendo
      // enquanto o dedo anda ele viraria um tempo morto até o app sumir.
      return FadeTransition(opacity: animation, child: child);
    }

    _eased ??= CurvedAnimation(
      parent: animation,
      curve: _page.spec.openCurve,
      reverseCurve: _page.spec.closeCurve,
    );

    // Durante o arrasto a curva sai de cena: o dedo é que manda, e uma curva
    // no meio faria a tela andar diferente da mão.
    final dragging = navigator?.userGestureInProgress ?? false;

    // O movimento preditivo dura da primeira mexida até a animação assentar,
    // e não até o dedo levantar.
    if (_predictive && !dragging && animation.isCompleted) _predictive = false;

    if (_predictive) {
      // `buildTransitions` roda quando o estado da rota muda, e não a cada
      // quadro: quem precisa acompanhar o dedo é o widget devolvido. Sem
      // este AnimatedBuilder a transformação seria calculada uma vez, com a
      // página ainda aberta, e nada se moveria.
      final spec = _page.spec;
      return AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, content) {
          final drag = spec.backDrag(
            progress: animation.value,
            edge: _dragEdge,
          );
          if (drag == null) return content!;
          return Transform.translate(
            offset: drag.offset,
            child: Transform.scale(
              scale: drag.scale,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(drag.cornerRadius),
                child: content,
              ),
            ),
          );
        },
      );
    }

    return _ContainerTransform(
      progress: dragging ? animation : _eased!,
      origin: origin,
      background: _page.background,
      cornerRadius: originRadius!,
      child: child,
    );
  }

  @override
  void dispose() {
    _eased?.dispose();
    super.dispose();
  }

  /// Fecha o app. Se não há nada embaixo — o visitante entrou direto pela
  /// URL — vai para a tela inicial em vez de sair do site.
  void close() {
    if (isFirst) {
      _page.onGoHome();
    } else {
      navigator?.maybePop();
    }
  }

  /// Começa um voltar interativo, ou devolve nulo se não é hora.
  BackGesture? startBackGesture(ScreenEdge edge) {
    final nav = navigator;
    if (nav == null || controller == null) return null;
    if (isFirst || !isCurrent || nav.userGestureInProgress) return null;
    // `setState` aqui não é adorno: é o que agenda uma nova chamada a
    // `buildTransitions`. Sem ela a rota continuaria mostrando a transição
    // que montou antes de o dedo encostar.
    setState(() {
      _dragEdge = edge;
      _predictive = _page.spec.backDrag(progress: 1, edge: edge) != null;
    });
    return BackGesture(
      controller: controller!,
      navigator: nav,
      settleCurve: _page.spec.closeCurve,
      settleDuration: _page.spec.closeDuration,
    );
  }
}

/// O movimento: um retângulo que cresce, arredonda menos e troca de cor.
///
/// O conteúdo do app é sempre disposto do tamanho da tela e ancorado onde vai
/// terminar; o retângulo só revela mais dele. Se o conteúdo fosse disposto do
/// tamanho do retângulo, ele se reorganizaria a cada quadro.
class _ContainerTransform extends StatelessWidget {
  const _ContainerTransform({
    required this.progress,
    required this.origin,
    required this.background,
    required this.cornerRadius,
    required this.child,
  });

  /// Fração da animação em que o conteúdo começa a aparecer.
  static const double _contentEntersAt = 0.6;

  final Animation<double> progress;
  final AppOrigin origin;
  final Color background;
  final double cornerRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screen = Offset.zero & constraints.biggest;

        return AnimatedBuilder(
          animation: progress,
          child: child,
          builder: (context, content) {
            final t = progress.value.clamp(0.0, 1.0);

            // Parado no fim: sem recorte, sem camada de opacidade, sem custo.
            if (t >= 1) return content!;

            final rect = Rect.lerp(origin.rect, screen, t)!;
            final corner = lerpDouble(cornerRadius, 0, t)!;
            final fill = Color.lerp(origin.color, background, t)!;
            final opacity = ((t - _contentEntersAt) / (1 - _contentEntersAt))
                .clamp(0.0, 1.0);

            return Stack(
              children: [
                Positioned.fromRect(
                  rect: rect,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(corner),
                    child: Stack(
                      children: [
                        Positioned.fill(child: ColoredBox(color: fill)),
                        Positioned(
                          left: -rect.left,
                          top: -rect.top,
                          width: screen.width,
                          height: screen.height,
                          child: Opacity(opacity: opacity, child: content),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// A moldura do sistema em volta de um app aberto: as bordas que voltam, a
/// faixa de baixo que leva para casa, e o Escape.
///
/// Mora aqui e não nas telas de propósito. Nenhuma tela precisa saber que
/// existe gesto de voltar, nem de quais bordas ele nasce nesta plataforma.
class _AppShell extends StatelessWidget {
  const _AppShell({
    required this.route,
    required this.page,
    required this.child,
  });

  /// Faixa sensível na borda lateral.
  static const double _edgeWidth = 24;

  /// Faixa sensível na base.
  static const double _homeStripHeight = 34;

  final AppOpenRoute route;
  final AppOpenPage page;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          route.close();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Stack(
        children: [
          child,
          for (final edge in page.spec.backGestureEdges)
            Positioned(
              left: edge == ScreenEdge.left ? 0 : null,
              right: edge == ScreenEdge.right ? 0 : null,
              top: 0,
              bottom: _homeStripHeight,
              width: _edgeWidth,
              child: _BackEdge(edge: edge, route: route),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _homeStripHeight,
            child: _HomeStrip(onGoHome: page.onGoHome),
          ),
        ],
      ),
    );
  }
}

/// A borda que volta. Acompanha o dedo e desiste se soltar antes da metade.
class _BackEdge extends StatefulWidget {
  const _BackEdge({required this.edge, required this.route});

  final ScreenEdge edge;
  final AppOpenRoute route;

  @override
  State<_BackEdge> createState() => _BackEdgeState();
}

class _BackEdgeState extends State<_BackEdge> {
  BackGesture? _gesture;

  /// Puxar da esquerda fecha indo para a direita; da direita, o contrário.
  double get _direction => widget.edge == ScreenEdge.left ? 1 : -1;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) =>
          _gesture = widget.route.startBackGesture(widget.edge),
      onHorizontalDragUpdate: (details) {
        _gesture?.dragUpdate((details.primaryDelta ?? 0) * _direction / width);
      },
      onHorizontalDragEnd: (details) {
        _gesture?.dragEnd((details.primaryVelocity ?? 0) * _direction / width);
        _gesture = null;
      },
      onHorizontalDragCancel: () {
        _gesture?.dragEnd(0);
        _gesture = null;
      },
    );
  }
}

/// A faixa da base: arrastar para cima volta para a tela inicial.
class _HomeStrip extends StatefulWidget {
  const _HomeStrip({required this.onGoHome});

  final VoidCallback onGoHome;

  @override
  State<_HomeStrip> createState() => _HomeStripState();
}

class _HomeStripState extends State<_HomeStrip> {
  static const double _distance = 24;
  static const double _velocity = -220;

  double _dragged = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (_) => _dragged = 0,
      onVerticalDragUpdate: (details) => _dragged += details.primaryDelta ?? 0,
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < _velocity || _dragged < -_distance) widget.onGoHome();
      },
      child: const Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: HomeIndicator(),
        ),
      ),
    );
  }
}

/// Liga o dedo à animação da rota.
///
/// O arrasto move a própria animação de abrir, e não uma animação paralela:
/// é isso que faz soltar no meio do caminho continuar de onde parou, em vez
/// de saltar para o começo de outro movimento.
class BackGesture {
  BackGesture({
    required this.controller,
    required this.navigator,
    required this.settleCurve,
    required this.settleDuration,
  }) {
    navigator.didStartUserGesture();
  }

  final AnimationController controller;
  final NavigatorState navigator;
  final Curve settleCurve;
  final Duration settleDuration;

  /// `fraction` é quanto do caminho de fechar o dedo andou.
  void dragUpdate(double fraction) {
    controller.value = (controller.value - fraction).clamp(0.0, 1.0);
  }

  void dragEnd(double velocity) {
    // Com velocidade, o arremesso decide; sem ela, decide onde parou.
    final closing = velocity.abs() >= 1 ? velocity > 0 : controller.value < 0.5;

    if (closing) {
      navigator.pop();
    } else {
      controller.animateTo(
        1,
        duration: settleDuration * (1 - controller.value),
        curve: settleCurve,
      );
    }

    if (controller.isAnimating) {
      late AnimationStatusListener listener;
      listener = (status) {
        navigator.didStopUserGesture();
        controller.removeStatusListener(listener);
      };
      controller.addStatusListener(listener);
    } else {
      navigator.didStopUserGesture();
    }
  }
}
