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
class AppScreen extends StatelessWidget {
  const AppScreen({super.key, required this.title, required this.blocks});

  final String title;
  final List<ContentBlock> blocks;

  /// Altura da faixa de gesto da base, para o texto não terminar embaixo dela.
  static const double _bottomGesture = 44;

  @override
  Widget build(BuildContext context) {
    final spec = context.platform;
    final tokens = context.tokens;

    // A escala sai da pele: o Android pede texto um pouco maior que o iOS, e
    // `appLabelSize` é a medida que a costura já tem para isso.
    final scale = spec.appLabelSize / 11;

    return Scaffold(
      backgroundColor: tokens.background,
      body: SafeArea(
        // O topo é dos cabeçalhos, que já respeitam a barra de status por
        // conta própria; a base é da faixa de gesto, tratada no fim da lista.
        top: false,
        bottom: false,
        child: CustomScrollView(
          slivers: [
            spec.screenHeader(
              title: title,
              onBack: () => _close(context),
              background: tokens.background,
              foreground: tokens.onWallpaper,
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                24,
                8,
                24,
                _bottomGesture + MediaQuery.paddingOf(context).bottom,
              ),
              sliver: SliverList.list(
                children: [
                  for (final block in blocks)
                    _Block(
                      block: block,
                      tokens: tokens,
                      spec: spec,
                      scale: scale,
                    ),
                ],
              ),
            ),
          ],
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
