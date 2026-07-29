import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/portfolio_app.dart';
import 'core/settings/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tira o "#" do endereço: /sobre em vez de /#/sobre. Uma URL por app só
  // vale se ela puder ser compartilhada e indexada.
  usePathUrlStrategy();

  // A escolha guardada é lida antes do primeiro quadro. Lida depois, quem
  // escolheu inglês veria o site abrir em português e se corrigir na cara
  // dele a cada visita. E é lida com guarda — ver `openSettingsStore`: sem
  // ela, armazenamento que não responde derruba `main` antes do `runApp`.
  final store = await openSettingsStore();

  runApp(PortfolioApp(settings: SettingsController(store: store)));
}
