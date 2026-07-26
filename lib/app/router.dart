import 'package:go_router/go_router.dart';

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
}

/// Monta o roteador. As transições ainda são as do padrão: a curva de cada
/// plataforma entra quando a `PlatformSpec` for ligada às rotas.
GoRouter createRouter() {
  return GoRouter(
    initialLocation: Routes.lock,
    routes: [
      GoRoute(
        path: Routes.lock,
        builder: (context, state) => const LockScreen(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: Routes.pen,
        builder: (context, state) => const PenScreen(),
      ),
      GoRoute(
        path: Routes.projects,
        builder: (context, state) => const ProjectsScreen(),
      ),
      GoRoute(
        path: Routes.about,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: Routes.experience,
        builder: (context, state) => const ExperienceScreen(),
      ),
      GoRoute(
        path: Routes.resume,
        builder: (context, state) => const ResumeScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
