import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/portfolio_app.dart';

void main() {
  // Tira o "#" do endereço: /sobre em vez de /#/sobre. Uma URL por app só
  // vale se ela puder ser compartilhada e indexada.
  usePathUrlStrategy();
  runApp(const PortfolioApp());
}
