import 'package:url_launcher/url_launcher.dart';

/// Para onde a doca leva. Não depende de idioma: é o mesmo endereço nos dois.
abstract final class Contacts {
  static final Uri phone = Uri.parse('https://wa.me/5579988180686');
  static final Uri email = Uri.parse('mailto:brunordr.dev@gmail.com');
  static final Uri linkedin = Uri.parse(
    'https://www.linkedin.com/in/brunordrdev',
  );
  static final Uri github = Uri.parse('https://github.com/brunordrdev');
}

/// Sai do site em aba nova.
///
/// Aba nova de propósito: o portfólio é um sistema com estado — tela
/// destravada, app aberto, idioma escolhido — e trocar de aba jogaria tudo
/// fora para o visitante voltar e recomeçar do bloqueio.
Future<bool> openExternal(Uri url) =>
    launchUrl(url, webOnlyWindowName: '_blank');
