import 'package:flutter/widgets.dart';

import '../../content/app_content.dart';
import '../../content/contacts.dart';
import '../../core/platform/platform_scope.dart';
import '../../core/settings/settings.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/app_screen.dart';

/// Ajustes: idioma, aparência e a ficha técnica do sistema.
///
/// A tela não sabe em qual plataforma está. Ela pede seções e opções à pele
/// ativa e recebe, de um lado, o cartão embutido com marca de conferido do
/// iOS; do outro, o cabeçalho no acento e os botões de rádio do Material.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final spec = context.platform;
    final content = context.content;
    final text = content.settings;
    final settings = context.settings;

    return AppScreen(
      title: content.apps.settings,
      sidePadding: 0,
      children: [
        spec.settingsSection(
          header: text.languageSection,
          rows: [
            for (final option in <(String, LanguageChoice)>[
              (text.portuguese, LanguageChoice.portuguese),
              (text.english, LanguageChoice.english),
              (text.followSystem, LanguageChoice.system),
            ])
              spec.settingsOption(
                label: option.$1,
                selected: settings.language == option.$2,
                onTap: () => settings.useLanguage(option.$2),
              ),
          ],
        ),
        spec.settingsSection(
          header: text.appearanceSection,
          rows: [
            for (final option in <(String, ThemeChoice)>[
              (text.light, ThemeChoice.light),
              (text.dark, ThemeChoice.dark),
              (text.followSystem, ThemeChoice.system),
            ])
              spec.settingsOption(
                label: option.$1,
                selected: settings.theme == option.$2,
                onTap: () => settings.useTheme(option.$2),
              ),
          ],
        ),
        spec.settingsSection(
          header: text.systemSection,
          rows: [for (final fact in text.facts) _Fact(fact: fact)],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// Uma escolha técnica e o motivo dela.
///
/// O motivo fica junto de propósito: uma lista de tecnologias diz o que a
/// pessoa usou, e o motivo de cada uma diz se ela escolheu.
class _Fact extends StatelessWidget {
  const _Fact({required this.fact});

  final SystemFact fact;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final spec = context.platform;
    final url = fact.url;

    final body = spec.settingsRow(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  fact.label,
                  style: TextStyle(
                    color: tokens.onWallpaper,
                    fontSize: 16,
                    fontFamilyFallback: spec.fontFallback,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  fact.value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    // O que abre algo é escrito em acento; o resto, não.
                    color: url == null
                        ? tokens.onWallpaperMuted
                        : tokens.accentOnSurface,
                    fontSize: 14.5,
                    fontFamilyFallback: spec.fontFallback,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            fact.why,
            style: TextStyle(
              color: tokens.onWallpaperMuted,
              fontSize: 13.5,
              height: 1.5,
              fontFamilyFallback: spec.fontFallback,
            ),
          ),
        ],
      ),
    );

    if (url == null) return body;
    return spec.tappable(
      onTap: () => openExternal(Uri.parse(url)),
      child: body,
    );
  }
}
