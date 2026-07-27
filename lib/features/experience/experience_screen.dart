import 'package:flutter/widgets.dart';

import '../../content/app_content.dart';
import '../../shared/widgets/app_screen.dart';

class ExperienceScreen extends StatelessWidget {
  const ExperienceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final content = context.content;
    return AppScreen(
      title: content.apps.experience,
      blocks: content.experience,
    );
  }
}
