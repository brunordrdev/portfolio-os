import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../content/app_content.dart';
import '../../content/contacts.dart';
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
    required this.glyph,
    required this.hue,
    required this.route,
    this.badge,
  });

  final String glyph;

  /// Índice em `AppTokens.glyphs`.
  final int hue;
  final String route;
  final int? badge;
}

/// A grade é conteúdo. Seis apps, três por linha, uma página só.
///
/// O nome de cada um vem do arquivo de conteúdo na hora de desenhar: aqui
/// ficam só forma, matiz e destino.
final List<_Entry> _grid = [
  // O selo mora aqui e em nenhum outro lugar: o projeto mais novo. Vermelho
  // só significa alguma coisa enquanto for escasso.
  _Entry(glyph: AppGlyphs.pen, hue: 0, route: Routes.pen, badge: 1),
  _Entry(glyph: AppGlyphs.layers, hue: 1, route: Routes.projects),
  _Entry(glyph: AppGlyphs.user, hue: 2, route: Routes.about),
  _Entry(glyph: AppGlyphs.briefcase, hue: 3, route: Routes.experience),
  _Entry(glyph: AppGlyphs.document, hue: 4, route: Routes.resume),
  _Entry(glyph: AppGlyphs.sliders, hue: 5, route: Routes.settings),
];

/// Nome de cada app da grade, na mesma ordem.
List<String> _gridNames(AppNames apps) => [
  apps.pen,
  apps.projects,
  apps.about,
  apps.experience,
  apps.resume,
  apps.settings,
];

/// Um canal de contato da doca. Não tem rota: sai do site.
class _Channel {
  const _Channel({required this.glyph, required this.hue, required this.url});

  final String glyph;
  final int hue;
  final Uri url;
}

/// A doca é contato. Quatro canais, sem rótulo, todos para fora.
final List<_Channel> _dock = [
  _Channel(glyph: AppGlyphs.phone, hue: 6, url: Contacts.phone),
  _Channel(glyph: AppGlyphs.mail, hue: 7, url: Contacts.email),
  _Channel(glyph: AppGlyphs.linkedin, hue: 8, url: Contacts.linkedin),
  _Channel(glyph: AppGlyphs.branch, hue: 9, url: Contacts.github),
];

List<String> _dockNames(AppNames apps) => [
  apps.phone,
  apps.email,
  apps.linkedin,
  apps.github,
];

/// A tela inicial: grade de seis, doca de quatro. Uma página, sem paginação —
/// não há segunda página, então não há bolinha para mostrar.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final spec = context.platform;
    final tokens = context.tokens;
    final apps = context.content.apps;
    final dockNames = _dockNames(apps);

    // O Scaffold existe pelo Material que ele traz: sem um Material acima,
    // todo Text herda o estilo de erro do framework — vermelho, monoespaçado
    // e sublinhado em amarelo duplo. O fundo é transparente porque quem pinta
    // aqui é o papel de parede.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Wallpaper(
        child: Column(
          children: [
            const StatusBar(),
            const SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                children: [
                  _GridRow(
                    entries: _grid.sublist(0, 3),
                    names: _gridNames(apps).sublist(0, 3),
                    tokens: tokens,
                  ),
                  const SizedBox(height: 24),
                  _GridRow(
                    entries: _grid.sublist(3, 6),
                    names: _gridNames(apps).sublist(3, 6),
                    tokens: tokens,
                  ),
                ],
              ),
            ),
            const Spacer(),
            spec.dock(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final (index, channel) in _dock.indexed)
                    AppIcon(
                      label: dockNames[index],
                      glyph: AppGlyph(channel.glyph),
                      hue: tokens.glyphs[channel.hue],
                      size: 52,
                      showLabel: false,
                      // A doca sai do site: não abre app, abre aba.
                      onTap: (_) => openExternal(channel.url),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const HomeIndicator(),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

/// Uma linha da grade, com as três células do mesmo tamanho.
class _GridRow extends StatelessWidget {
  const _GridRow({
    required this.entries,
    required this.names,
    required this.tokens,
  });

  final List<_Entry> entries;
  final List<String> names;
  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (index, entry) in entries.indexed)
          Expanded(
            child: Center(
              child: AppIcon(
                label: names[index],
                glyph: AppGlyph(entry.glyph),
                hue: tokens.glyphs[entry.hue],
                badge: entry.badge,
                onTap: (origin) => context.push(entry.route, extra: origin),
              ),
            ),
          ),
      ],
    );
  }
}
