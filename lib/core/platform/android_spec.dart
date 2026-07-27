import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../../shared/widgets/device_frame.dart';
import 'platform_spec.dart';

/// A pele Android, no Material 3.
///
/// Ela nasceu crua no primeiro dia, de propósito: existir desde o começo é o
/// que obrigou cada membro novo da interface a ter duas respostas, e é por
/// isso que lapidá-la agora coube inteiramente aqui, sem tocar em uma linha
/// de tela.
///
/// Material 3 de especificação, não a pele de nenhum fabricante. As medidas
/// vêm do M3: barra superior de 64, linha de lista de 56, divisor de 1,
/// camada de estado a 8% e 10%, canto extragrande de 28. As cores não: essas
/// são as do projeto. Cor dinâmica ficaria bonita e diria que a paleta é do
/// aparelho, quando ela é do sistema que este site desenha.
class AndroidSpec extends PlatformSpec {
  const AndroidSpec();

  @override
  String get id => 'android';

  @override
  String get label => 'Android';

  @override
  BorderRadius iconRadius(double size) => BorderRadius.circular(size * 0.5);

  @override
  double get surfaceRadius => 28;

  @override
  Duration get openDuration => const Duration(milliseconds: 350);

  @override
  Duration get closeDuration => const Duration(milliseconds: 300);

  @override
  Curve get openCurve => Curves.easeInOutCubicEmphasized;

  @override
  Curve get closeCurve => Curves.easeInOutCubicEmphasized;

  @override
  List<String> get fontFallback => const ['Roboto', 'Noto Sans', 'Arial'];

  @override
  double get appLabelSize => 12;

  @override
  FontWeight get appLabelWeight => FontWeight.w500;

  // A pílula da navegação por gestos do Android: mais estreita que a do iOS
  // e mais grossa, com as pontas em semicírculo.
  @override
  Widget bottomChrome() {
    return Builder(
      builder: (context) {
        final tokens = context.tokens;
        return Container(
          width: 108,
          height: 4,
          decoration: BoxDecoration(
            color: tokens.onWallpaperMuted,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }

  // Um furo de câmera ocupa muito menos que uma ilha, então o Android
  // reserva menos topo — mas ainda mais do que os 26 de antes, que deixavam
  // a barra colada na borda.
  @override
  double get systemChromeHeight => 32;

  // Sem cápsula: no Android os ícones da doca ficam soltos sobre o papel de
  // parede. Nada de contêiner, nada de desfoque — só os ícones.
  @override
  Widget dock({required Widget child}) => child;

  // Furo de câmera redondo, canto mais fechado e borda fina.
  @override
  Widget deviceFrame() {
    return Builder(
      builder: (context) {
        final tokens = context.tokens;
        return CustomPaint(
          painter: DeviceFramePainter(
            cornerRadius: 28,
            borderWidth: 1.5,
            bezel: tokens.deviceBezel,
            cutout: const Size(18, 18),
            cutoutTop: 14,
            cutoutRadius: 9,
          ),
        );
      },
    );
  }

  // Qualquer borda lateral volta.
  @override
  Set<ScreenEdge> get backGestureEdges => const {
    ScreenEdge.left,
    ScreenEdge.right,
  };

  @override
  Widget tappable({
    required Widget child,
    required VoidCallback onTap,
    BorderRadius? radius,
  }) {
    return Builder(
      builder: (context) {
        final tokens = context.tokens;
        return Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            // A ondulação do Android 12 em diante não é o círculo que se
            // expande: é o brilho que se espalha e some.
            splashFactory: InkSparkle.splashFactory,
            // Camada de estado do M3: 8% ao passar, 10% ao focar e ao
            // pressionar. Números da especificação, cor do projeto.
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return tokens.onWallpaper.withValues(alpha: 0.10);
              }
              if (states.contains(WidgetState.focused)) {
                return tokens.onWallpaper.withValues(alpha: 0.10);
              }
              if (states.contains(WidgetState.hovered)) {
                return tokens.onWallpaper.withValues(alpha: 0.08);
              }
              return null;
            }),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget switchControl({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Builder(
      builder: (context) {
        final tokens = context.tokens;
        return Switch(
          value: value,
          onChanged: onChanged,
          // No M3 o polegar ligado carrega uma marca e cresce; o desligado é
          // menor e vazio. É o que distingue a chave do Material da do iOS,
          // que só desliza.
          thumbIcon: WidgetStateProperty.resolveWith((states) {
            if (!states.contains(WidgetState.selected)) return null;
            return Icon(Icons.check, size: 16, color: tokens.background);
          }),
          activeThumbColor: tokens.background,
          activeTrackColor: tokens.accent,
          inactiveThumbColor: tokens.onWallpaperMuted,
          inactiveTrackColor: tokens.surface,
          trackOutlineColor: WidgetStatePropertyAll(tokens.surfaceBorder),
        );
      },
    );
  }

  // Barra superior do Material: título à esquerda, seta com haste, sem
  // sombra. Ela fica presa no topo em vez de encolher.
  @override
  Widget screenHeader({
    required String title,
    required VoidCallback onBack,
    required Color background,
    required Color foreground,
  }) {
    return SliverAppBar(
      pinned: true,
      // Barra pequena do M3: 64 de altura, título de 22 alinhado à esquerda
      // depois do botão, que ocupa os 48 de alvo com ícone de 24.
      toolbarHeight: 64,
      backgroundColor: background,
      // Ao rolar conteúdo por baixo, a barra do M3 se destaca por um véu do
      // tom principal — não por sombra. Nada a declarar aqui: o padrão do
      // Material 3 tira esse tom do ColorScheme, que o app semeia com
      // `tokens.accent`. O véu é do projeto sem precisar de parâmetro novo.
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      title: Text(
        title,
        style: TextStyle(
          color: foreground,
          fontSize: 22,
          height: 1.27,
          fontWeight: FontWeight.w400,
          fontFamilyFallback: fontFallback,
        ),
      ),
      // Aqui o ícone é do Material, e não da família traçada do projeto: o
      // botão de voltar é peça do sistema, e o desenho próprio fica para os
      // ícones de app, que são conteúdo.
      leading: IconButton(
        onPressed: onBack,
        iconSize: 24,
        icon: Icon(Icons.arrow_back, color: foreground),
      ),
    );
  }

  // Cabeçalho no acento, linhas de borda a borda e divisores do Material.
  @override
  Widget settingsSection({required String header, required List<Widget> rows}) {
    return Builder(
      builder: (context) {
        final tokens = context.tokens;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Subcabeçalho de lista do M3: recuo de 16, corpo de 14 no peso
            // médio, na cor de apoio. O acento reprovaria no contraste —
            // 4,10:1 sobre a página clara, abaixo do piso de 4,5.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 10),
              child: Text(
                header,
                style: TextStyle(
                  color: tokens.onWallpaperMuted,
                  fontSize: 14,
                  height: 1.43,
                  letterSpacing: 0.1,
                  fontWeight: FontWeight.w500,
                  fontFamilyFallback: fontFallback,
                ),
              ),
            ),
            for (var i = 0; i < rows.length; i++) ...[
              // Divisor do M3: 1 de espessura, de borda a borda, no tom de
              // contorno. Sem recuo — quem recua o divisor é a lista com
              // ícone à esquerda, e esta não tem.
              if (i > 0)
                Divider(height: 1, thickness: 1, color: tokens.surfaceBorder),
              rows[i],
            ],
          ],
        );
      },
    );
  }

  @override
  Widget settingsOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) {
        final tokens = context.tokens;
        return tappable(
          onTap: onTap,
          // Linha de lista de uma linha no M3: 56 de altura mínima, com o
          // controle à esquerda dentro do alvo de 48 e o texto a 16 da borda.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 16, 0),
              child: Row(
                children: [
                  RadioGroup<bool>(
                    groupValue: selected,
                    onChanged: (_) => onTap(),
                    child: Radio<bool>(
                      value: true,
                      fillColor: WidgetStatePropertyAll(
                        selected ? tokens.accent : tokens.onWallpaperMuted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: tokens.onWallpaper,
                        fontSize: 16,
                        height: 1.5,
                        letterSpacing: 0.15,
                        fontFamilyFallback: fontFallback,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Voltar preditivo do Material 3: enquanto o dedo anda, a página encolhe
  // até 90% em torno do próprio centro, arredonda até o canto do sistema e
  // escorrega para longe da borda que está sendo arrastada — descobrindo o
  // que está atrás dela antes de o gesto terminar. É o que diz ao visitante
  // para onde ele está indo enquanto ainda dá tempo de desistir.
  @override
  BackDrag? backDrag({required double progress, required ScreenEdge edge}) {
    final travelled = (1 - progress).clamp(0.0, 1.0);
    return BackDrag(
      scale: 1 - 0.10 * travelled,
      cornerRadius: surfaceRadius * travelled,
      offset: Offset((edge == ScreenEdge.left ? 16 : -16) * travelled, 0),
    );
  }

  @override
  Route<T> pageRoute<T>({
    required WidgetBuilder builder,
    required RouteSettings settings,
  }) {
    return MaterialPageRoute<T>(builder: builder, settings: settings);
  }
}
