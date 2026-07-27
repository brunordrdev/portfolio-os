import 'package:flutter/material.dart';

import '../../content/app_content.dart';
import '../../core/platform/platform_scope.dart';
import '../../core/platform/platform_spec.dart';
import '../../core/theme/tokens.dart';
import '../motion/app_open_page.dart';

/// A moldura comum das telas de conteúdo: cabeçalho da plataforma, rolagem e
/// texto bem espaçado.
///
/// Nenhuma tela monta o próprio cabeçalho — ele vem da pele ativa, e é aí que
/// a troca de plataforma aparece mais: título grande que encolhe de um lado,
/// barra presa no topo do outro.
/// Onde cada tela parou de rolar.
///
/// Sair de um app destrói a rota e o estado dela junto, então a posição
/// precisa morar fora da árvore para quem volta encontrar a mesma página em
/// vez do topo. Dura a sessão: recarregar começa do começo, como num celular
/// que foi desligado.
abstract final class ScrollMemory {
  static final Map<String, double> _offsets = {};

  static double offsetOf(String key) => _offsets[key] ?? 0;

  static void remember(String key, double offset) => _offsets[key] = offset;

  @visibleForTesting
  static void forget() => _offsets.clear();
}

class AppScreen extends StatefulWidget {
  const AppScreen({
    super.key,
    required this.title,
    this.blocks = const [],
    this.children = const [],
    this.sidePadding = 24,
  });

  final String title;
  final List<ContentBlock> blocks;

  /// Conteúdo que não é texto corrido — a lista de Ajustes, por exemplo.
  final List<Widget> children;

  /// Texto corrido pede respiro nas laterais; lista de ajustes vai de borda a
  /// borda, e cada pele decide o próprio recuo.
  final double sidePadding;

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  late final ScrollController _scroll = ScrollController(
    initialScrollOffset: ScrollMemory.offsetOf(widget.title),
  )..addListener(_remember);

  void _remember() {
    if (_scroll.hasClients) {
      ScrollMemory.remember(widget.title, _scroll.offset);
    }
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_remember)
      ..dispose();
    super.dispose();
  }

  /// Altura da faixa de gesto da base, para o texto não terminar embaixo dela.
  static const double _bottomGesture = 44;

  @override
  Widget build(BuildContext context) {
    final spec = context.platform;
    final tokens = context.tokens;

    // Régua própria da costura. Já foi derivada de `appLabelSize`, que é
    // medida de rótulo de ícone — funcionava, mas por coincidência.
    final scale = spec.readingScale;

    return Scaffold(
      backgroundColor: tokens.background,
      // O recorte da câmera come o topo da tela, e cabeçalho de app não pode
      // passar por baixo dele. Entregue como recuo do MediaQuery, os dois
      // cabeçalhos o respeitam sozinhos — é assim que eles esperam receber a
      // notícia de que há hardware ali em cima.
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: MediaQuery.paddingOf(
            context,
          ).copyWith(top: spec.systemChromeHeight),
        ),
        child: SafeArea(
          // O topo é dos cabeçalhos, que agora recebem o recuo acima; a base
          // é da faixa de gesto, tratada no fim da lista.
          top: false,
          bottom: false,
          child: CustomScrollView(
            controller: _scroll,
            slivers: [
              spec.screenHeader(
                title: widget.title,
                onBack: () => _close(context),
                background: tokens.background,
                foreground: tokens.onWallpaper,
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  widget.sidePadding,
                  8,
                  widget.sidePadding,
                  _bottomGesture + MediaQuery.paddingOf(context).bottom,
                ),
                sliver: SliverList.list(
                  children: [
                    for (final block in widget.blocks)
                      _Block(
                        block: block,
                        tokens: tokens,
                        spec: spec,
                        scale: scale,
                      ),
                    ...widget.children,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _close(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route is AppOpenRoute) {
      route.close();
    } else {
      Navigator.of(context).maybePop();
    }
  }
}

/// Um bloco de texto. Sem cartão, sem ícone, sem linha do tempo: o que separa
/// um item do outro é espaço, e o que hierarquiza é peso e cor.
class _Block extends StatelessWidget {
  const _Block({
    required this.block,
    required this.tokens,
    required this.spec,
    required this.scale,
  });

  final ContentBlock block;
  final AppTokens tokens;
  final PlatformSpec spec;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return switch (block) {
      ItemTitle() => Padding(
        padding: const EdgeInsets.only(top: 34, bottom: 4),
        child: Text(
          block.text,
          style: TextStyle(
            color: tokens.onWallpaper,
            fontSize: 18 * scale,
            fontWeight: FontWeight.w600,
            height: 1.3,
            fontFamilyFallback: spec.fontFallback,
          ),
        ),
      ),
      ItemMeta() => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Text(
          block.text,
          style: TextStyle(
            color: tokens.onWallpaperMuted,
            fontSize: 12.5 * scale,
            height: 1.45,
            letterSpacing: 0.2,
            fontFamilyFallback: spec.fontFallback,
          ),
        ),
      ),
      Prose() => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Text(
          block.text,
          style: TextStyle(
            color: tokens.onWallpaper,
            fontSize: 15.5 * scale,
            height: 1.62,
            fontFamilyFallback: spec.fontFallback,
          ),
        ),
      ),
    };
  }
}
