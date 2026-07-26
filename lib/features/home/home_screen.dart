import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/platform/platform_scope.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/app_glyph.dart';
import '../../shared/widgets/app_icon.dart';
import '../../shared/widgets/home_indicator.dart';
import '../../shared/widgets/status_bar.dart';
import '../../shared/widgets/wallpaper.dart';

/// Um ladrilho da tela inicial: nome, desenho, matiz e destino.
class _Entry {
  const _Entry({
    required this.label,
    required this.glyph,
    required this.hue,
    required this.route,
    this.badge,
  });

  final String label;
  final String glyph;

  /// Índice em `AppTokens.glyphs`.
  final int hue;
  final String route;
  final int? badge;
}

/// A grade é conteúdo. Seis apps, três por linha, uma página só.
final List<_Entry> _grid = [
  // O selo mora aqui e em nenhum outro lugar: o projeto mais novo. Vermelho
  // só significa alguma coisa enquanto for escasso.
  _Entry(
    label: 'Minha Caneta',
    glyph: AppGlyphs.pen,
    hue: 0,
    route: Routes.pen,
    badge: 1,
  ),
  _Entry(
    label: 'Projetos',
    glyph: AppGlyphs.layers,
    hue: 1,
    route: Routes.projects,
  ),
  _Entry(label: 'Sobre', glyph: AppGlyphs.user, hue: 2, route: Routes.about),
  _Entry(
    label: 'Experiência',
    glyph: AppGlyphs.briefcase,
    hue: 3,
    route: Routes.experience,
  ),
  _Entry(
    label: 'Currículo',
    glyph: AppGlyphs.document,
    hue: 4,
    route: Routes.resume,
  ),
  _Entry(
    label: 'Ajustes',
    glyph: AppGlyphs.gear,
    hue: 5,
    route: Routes.settings,
  ),
];

/// A doca é contato. Quatro canais, sem rótulo.
final List<_Entry> _dock = [
  _Entry(label: 'Telefone', glyph: AppGlyphs.phone, hue: 6, route: Routes.phone),
  _Entry(label: 'Email', glyph: AppGlyphs.mail, hue: 7, route: Routes.email),
  _Entry(
    label: 'LinkedIn',
    glyph: AppGlyphs.linkedin,
    hue: 8,
    route: Routes.linkedin,
  ),
  _Entry(
    label: 'GitHub',
    glyph: AppGlyphs.branch,
    hue: 9,
    route: Routes.github,
  ),
];

/// A tela inicial: grade de seis, doca de quatro. Uma página, sem paginação —
/// não há segunda página, então não há bolinha para mostrar.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final spec = context.platform;
    final tokens = context.tokens;

    return Wallpaper(
      child: Column(
        children: [
          const StatusBar(),
          const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                _GridRow(entries: _grid.sublist(0, 3), tokens: tokens),
                const SizedBox(height: 24),
                _GridRow(entries: _grid.sublist(3, 6), tokens: tokens),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(spec.surfaceRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  color: tokens.dockFill,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 6,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final entry in _dock)
                        AppIcon(
                          label: entry.label,
                          glyph: AppGlyph(entry.glyph),
                          hue: tokens.glyphs[entry.hue],
                          size: 52,
                          showLabel: false,
                          onTap: () => context.go(entry.route),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const HomeIndicator(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

/// Uma linha da grade, com as três células do mesmo tamanho.
class _GridRow extends StatelessWidget {
  const _GridRow({required this.entries, required this.tokens});

  final List<_Entry> entries;
  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final entry in entries)
          Expanded(
            child: Center(
              child: AppIcon(
                label: entry.label,
                glyph: AppGlyph(entry.glyph),
                hue: tokens.glyphs[entry.hue],
                badge: entry.badge,
                onTap: () => context.go(entry.route),
              ),
            ),
          ),
      ],
    );
  }
}
