import 'package:flutter/widgets.dart';

import '../../content/app_content.dart';
import '../../shared/widgets/app_screen.dart';

class ResumeScreen extends StatelessWidget {
  const ResumeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final content = context.content;
    return AppScreen(title: content.apps.resume, blocks: content.resume);
  }
}
