import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:portfolio_os/app/router.dart';
import 'package:portfolio_os/content/app_content.dart';
import 'package:portfolio_os/core/platform/platform_scope.dart';
import 'package:portfolio_os/core/platform/platform_spec.dart';
import 'package:portfolio_os/core/theme/tokens.dart';
import 'package:portfolio_os/features/home/home_screen.dart';
import 'package:portfolio_os/features/lock/lock_screen.dart';
import 'package:portfolio_os/shared/widgets/app_icon.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// A doca sai do site. São os únicos quatro pontos do sistema que levam para
/// fora, e o "para fora" tem que ser aba nova: o portfólio é um sistema com
/// estado, e trocar de aba jogaria fora tela destravada e app aberto.
class _RecordingLauncher extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  final List<(String url, String? window)> opened = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    opened.add((url, options.webOnlyWindowName));
    return true;
  }
}

void main() {
  const skins = <String, PlatformSpec>{
    'iOS': PlatformController.ios,
    'Android': PlatformController.android,
  };
  const palettes = <String, AppTokens>{
    'escuro': AppTokens.dark,
    'claro': AppTokens.light,
  };

  const destinations = <String, String>{
    'Telefone': 'https://wa.me/5579988180686',
    'Email': 'mailto:brunordr.dev@gmail.com',
    'LinkedIn': 'https://www.linkedin.com/in/brunordrdev',
    'GitHub': 'https://github.com/brunordrdev',
  };

  for (final skin in skins.entries) {
    for (final palette in palettes.entries) {
      final combo = '${skin.key} / ${palette.key}';

      for (final destination in destinations.entries) {
        testWidgets('${destination.key} abre em aba nova — $combo', (
          tester,
        ) async {
          final launcher = _RecordingLauncher();
          final original = UrlLauncherPlatform.instance;
          UrlLauncherPlatform.instance = launcher;
          addTearDown(() => UrlLauncherPlatform.instance = original);

          final controller = PlatformController(skin.value);
          final router = createRouter();
          addTearDown(controller.dispose);
          addTearDown(router.dispose);

          await tester.pumpWidget(
            PlatformScope(
              controller: controller,
              child: ContentScope(
                content: AppContent.pt,
                child: TokensScope(
                  tokens: palette.value,
                  child: MaterialApp.router(
                    routerConfig: router,
                    debugShowCheckedModeBanner: false,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tapAt(tester.getCenter(find.byType(LockScreen)));
          await tester.pumpAndSettle();

          await tester.tap(
            find.byWidgetPredicate(
              (w) => w is AppIcon && w.label == destination.key,
            ),
          );
          await tester.pumpAndSettle();

          expect(launcher.opened, hasLength(1));
          expect(launcher.opened.single.$1, destination.value);
          expect(
            launcher.opened.single.$2,
            '_blank',
            reason: 'sem _blank o link trocaria a aba e mataria o sistema',
          );

          // Sai do site: não navega dentro dele.
          expect(find.byType(HomeScreen), findsOneWidget);
        });
      }
    }
  }
}
