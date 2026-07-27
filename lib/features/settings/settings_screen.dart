import 'package:flutter/widgets.dart';

import '../../content/app_content.dart';
import '../../shared/widgets/app_screen.dart';

/// Andaime: já tem o cabeçalho da plataforma, ainda não tem conteúdo.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreen(title: context.content.apps.settings, blocks: const []);
  }
}
