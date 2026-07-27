import 'package:flutter/widgets.dart';

import '../../content/app_content.dart';
import '../../shared/widgets/app_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final content = context.content;
    return AppScreen(title: content.apps.about, blocks: content.about);
  }
}
