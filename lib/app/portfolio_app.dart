import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../content/app_content.dart';
import '../core/platform/platform_scope.dart';
import '../core/platform/platform_spec.dart';
import '../core/theme/tokens.dart';
import 'router.dart';

/// Raiz do portfólio: a costura da plataforma e a paleta ficam acima do app,
/// para que virar qualquer uma das duas chaves não encoste em tela nenhuma.
class PortfolioApp extends StatefulWidget {
  const PortfolioApp({super.key});

  /// Força um tema, ignorando a preferência do sistema. `null` devolve o
  /// controle ao sistema. É o gancho que Ajustes vai usar.
  static void overrideBrightness(BuildContext context, Brightness? brightness) {
    context.findAncestorStateOfType<_PortfolioAppState>()!.overrideBrightness(
      brightness,
    );
  }

  @override
  State<PortfolioApp> createState() => _PortfolioAppState();
}

class _PortfolioAppState extends State<PortfolioApp>
    with WidgetsBindingObserver {
  final PlatformController _platform = PlatformController();
  final GoRouter _router = createRouter();

  /// `null` significa "siga o sistema".
  Brightness? _brightnessOverride;

  void overrideBrightness(Brightness? brightness) {
    if (_brightnessOverride == brightness) return;
    setState(() => _brightnessOverride = brightness);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  /// O visitante pode trocar o idioma do sistema com o site aberto.
  @override
  void didChangeLocales(List<Locale>? locales) => setState(() {});

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _platform.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // O MediaQuery do MaterialApp nasce abaixo dele, e os tokens precisam
    // envolvê-lo. Então abrimos um aqui, a partir da View, para poder ler a
    // preferência de brilho antes de escolher a paleta.
    return MediaQuery.fromView(
      view: View.of(context),
      child: Builder(builder: _buildScopes),
    );
  }

  Widget _buildScopes(BuildContext context) {
    final brightness =
        _brightnessOverride ?? MediaQuery.platformBrightnessOf(context);
    final tokens = brightness == Brightness.dark
        ? AppTokens.dark
        : AppTokens.light;

    // Mesmo princípio da plataforma e do tema: abre adaptado ao visitante.
    final content = AppContent.forLocale(
      View.of(context).platformDispatcher.locale,
    );

    return PlatformScope(
      controller: _platform,
      child: ContentScope(
        content: content,
        child: TokensScope(
          tokens: tokens,
          // Este Builder depende do PlatformScope: quando a chave vira, o tema
          // do app se refaz sozinho com a pilha de fontes da outra plataforma.
          child: Builder(
            builder: (context) => MaterialApp.router(
              title: 'Bruno Rodrigues',
              debugShowCheckedModeBanner: false,
              routerConfig: _router,
              theme: _themeFrom(tokens, context.platform),
            ),
          ),
        ),
      ),
    );
  }

  /// O tema do Material existe só para os componentes prontos (chave, onda,
  /// texto padrão) não destoarem. A verdade das cores continua nos tokens.
  ThemeData _themeFrom(AppTokens tokens, PlatformSpec spec) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: tokens.accent,
        brightness: tokens.brightness,
      ),
      scaffoldBackgroundColor: tokens.background,
      fontFamilyFallback: spec.fontFallback,
    );
  }
}
