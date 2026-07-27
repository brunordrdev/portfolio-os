import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../core/platform/platform_scope.dart';
import '../core/theme/tokens.dart';
import '../shared/motion/app_open_page.dart';
import '../features/about/about_screen.dart';
import '../features/experience/experience_screen.dart';
import '../features/home/home_screen.dart';
import '../features/lock/lock_screen.dart';
import '../features/minha_caneta/pen_screen.dart';
import '../features/projects/projects_screen.dart';
import '../features/resume/resume_screen.dart';
import '../features/settings/settings_screen.dart';

/// Uma URL por app. Endereço em português, porque é o que o visitante lê.
abstract final class Routes {
  static const String lock = '/';
  static const String home = '/inicio';
  static const String pen = '/minha-caneta';
  static const String projects = '/projetos';
  static const String about = '/sobre';
  static const String experience = '/experiencia';
  static const String resume = '/curriculo';
  static const String settings = '/ajustes';

  // A doca não tem rota: os quatro canais de contato são links externos.
}

/// As seis rotas que são app. Entrar direto numa delas é um deep link.
const Set<String> _appPaths = {
  Routes.pen,
  Routes.projects,
  Routes.about,
  Routes.experience,
  Routes.resume,
  Routes.settings,
};

/// Monta a página de um app: o ladrilho cresce até virar a tela.
///
/// A rota lê a pele e a paleta daqui e as entrega prontas ao movimento —
/// nenhuma tela de app participa disso, nem sabe que existe transição.
Page<void> _appPage(BuildContext context, GoRouterState state, Widget child) {
  return AppOpenPage<void>(
    key: state.pageKey,
    name: state.uri.path,
    spec: context.platform,
    background: context.tokens.background,
    // `extra` só existe quando o app foi aberto por um ladrilho. Chegando
    // pela URL não houve ladrilho, e aí não há de onde crescer.
    origin: state.extra is AppOrigin ? state.extra! as AppOrigin : null,
    onGoHome: () => context.go(Routes.home),
    child: child,
  );
}

/// Monta o roteador.
///
/// `initialLocation` existe para o teste poder entrar direto num app, que é
/// o caminho do deep link. Na web quem manda é a URL do navegador.
GoRouter createRouter({String initialLocation = Routes.lock}) {
  late final GoRouter router;

  // A síntese de pilha vale só para a primeira entrada. Depois dela, navegar
  // é navegar: quem empilha é o toque no ladrilho.
  var entered = false;

  router = GoRouter(
    initialLocation: initialLocation,
    redirect: (context, state) {
      if (entered) return null;
      entered = true;
      final path = state.uri.path;
      if (!_appPaths.contains(path)) return null;

      // Entrar direto num app é chegar sem ter passado pela tela inicial, e
      // aí não haveria para onde voltar. Um celular de verdade sintetiza a
      // pilha do deep link; aqui é o mesmo: a tela inicial entra embaixo e o
      // app por cima, para o gesto de voltar funcionar em qualquer entrada.
      WidgetsBinding.instance.addPostFrameCallback((_) => router.push(path));
      return Routes.home;
    },
    routes: [
      GoRoute(
        path: Routes.lock,
        builder: (context, state) => const LockScreen(),
      ),
      GoRoute(
        path: Routes.home,
        // Destravar é a única transição com dono nesta etapa, e o tempo e a
        // curva são os da pele ativa: é o mesmo gesto lido de dois jeitos.
        pageBuilder: (context, state) {
          final spec = context.platform;
          return CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: spec.openDuration,
            reverseTransitionDuration: spec.closeDuration,
            child: const HomeScreen(),
            transitionsBuilder: (context, animation, secondary, child) {
              final eased = animation.drive(CurveTween(curve: spec.openCurve));
              return FadeTransition(
                opacity: eased,
                child: SlideTransition(
                  position: eased.drive(
                    Tween<Offset>(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ),
                  ),
                  child: child,
                ),
              );
            },
          );
        },
      ),
      GoRoute(
        path: Routes.pen,
        pageBuilder: (context, state) =>
            _appPage(context, state, const PenScreen()),
      ),
      GoRoute(
        path: Routes.projects,
        pageBuilder: (context, state) =>
            _appPage(context, state, const ProjectsScreen()),
      ),
      GoRoute(
        path: Routes.about,
        pageBuilder: (context, state) =>
            _appPage(context, state, const AboutScreen()),
      ),
      GoRoute(
        path: Routes.experience,
        pageBuilder: (context, state) =>
            _appPage(context, state, const ExperienceScreen()),
      ),
      GoRoute(
        path: Routes.resume,
        pageBuilder: (context, state) =>
            _appPage(context, state, const ResumeScreen()),
      ),
      GoRoute(
        path: Routes.settings,
        pageBuilder: (context, state) =>
            _appPage(context, state, const SettingsScreen()),
      ),
    ],
  );

  return router;
}
