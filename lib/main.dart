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
  // dele a cada visita.
  final settings = SettingsController(store: await PreferencesStore.open());

  runApp(PortfolioApp(settings: settings));
}
