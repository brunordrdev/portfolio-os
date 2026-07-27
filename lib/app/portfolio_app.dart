import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../content/app_content.dart';
import '../core/platform/platform_scope.dart';
import '../core/settings/settings.dart';
import '../core/platform/platform_spec.dart';
import '../core/theme/tokens.dart';
import 'router.dart';
import 'web_stage.dart';

/// Raiz do portfólio: a costura da plataforma e a paleta ficam acima do app,
/// para que virar qualquer uma das duas chaves não encoste em tela nenhuma.
class PortfolioApp extends StatefulWidget {
  const PortfolioApp({super.key, this.settings});

  /// Vem pronto de `main`, já carregado do armazenamento local. Nulo em
  /// teste, onde cada caso começa sem escolha nenhuma guardada.
  final SettingsController? settings;

  @override
  State<PortfolioApp> createState() => _PortfolioAppState();
}

class _PortfolioAppState extends State<PortfolioApp>
    with WidgetsBindingObserver {
  final PlatformController _platform = PlatformController();
  final GoRouter _router = createRouter();
  late final SettingsController _settings =
      widget.settings ?? SettingsController();

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
    _settings.dispose();
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
    // O SettingsScope fica abaixo daqui, então notificar reconstrói as telas
    // mas não este ponto — e é aqui que idioma e tema são escolhidos. Sem
    // ouvir, virar a chave em Ajustes mudaria a lista e mais nada.
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) => _buildApp(context),
    );
  }

  Widget _buildApp(BuildContext context) {
    // "Sistema" não é ausência de escolha: é a escolha de seguir o navegador,
    // que é como o site se comportava antes de Ajustes existir.
    final brightness = switch (_settings.theme) {
      ThemeChoice.light => Brightness.light,
      ThemeChoice.dark => Brightness.dark,
      ThemeChoice.system => MediaQuery.platformBrightnessOf(context),
    };
    final tokens = brightness == Brightness.dark
        ? AppTokens.dark
        : AppTokens.light;

    final content = switch (_settings.language) {
      LanguageChoice.portuguese => AppContent.pt,
      LanguageChoice.english => AppContent.en,
      LanguageChoice.system => AppContent.forLocale(
        View.of(context).platformDispatcher.locale,
      ),
    };

    return SettingsScope(
      controller: _settings,
      child: PlatformScope(
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
                // O interruptor de plataforma fica fora das telas e dentro do
                // Flutter: nenhuma tela sabe que ele existe.
                builder: webStage,
              ),
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
