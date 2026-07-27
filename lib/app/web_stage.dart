import 'package:flutter/material.dart';

import '../core/platform/platform_scope.dart';
import '../core/theme/tokens.dart';

/// A composição da superfície Flutter: o sistema, e embaixo dele o queixo com
/// o interruptor de plataforma.
///
/// O interruptor mora aqui e não no HTML de propósito: em HTML ele precisaria
/// de uma ponte até o Dart para mexer no `PlatformController`, e a costura
/// deixaria de ter um ponto de troca só. Aqui ele é um widget como qualquer
/// outro, chamando o mesmo controlador que a detecção inicial chama.
///
/// Acima do ponto de quebra o CSS dá a esta superfície o tamanho de um
/// celular, então o queixo vira a base do aparelho. Abaixo dele a superfície
/// é a tela inteira, e o queixo vira uma barra no rodapé.
Widget webStage(BuildContext context, Widget? child) {
  return Column(
    // Sem esticar, o Column centraliza e o queixo encolhe até o tamanho do
    // conteúdo, deixando a tela do MaterialApp aparecer dos lados.
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(child: child ?? const SizedBox.shrink()),
      const PlatformSwitchBar(),
    ],
  );
}

/// O interruptor iOS ↔ Android.
///
/// Ele não guarda estado próprio: lê e escreve no `PlatformController`, que
/// continua sendo o único ponto de troca do projeto. A chave em si vem da
/// pele ativa — então o próprio controle muda de forma quando é acionado, que
/// é a tese do site em miniatura.
class PlatformSwitchBar extends StatelessWidget {
  const PlatformSwitchBar({super.key});

  static const double height = 64;

  @override
  Widget build(BuildContext context) {
    final controller = PlatformScope.of(context);
    final spec = context.platform;
    final tokens = context.tokens;
    final isAndroid = spec.id == PlatformController.android.id;

    // O queixo fica fora de qualquer tela, e portanto fora de qualquer
    // Scaffold. Sem este Material a chave do Material não desenha e o texto
    // herda o estilo de erro do framework.
    return Material(
      color: tokens.backgroundDeep,
      child: SizedBox(
        height: height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Side(
              label: PlatformController.ios.label,
              active: !isAndroid,
              tokens: tokens,
              onTap: () => controller.use(PlatformController.ios),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: spec.switchControl(
                value: isAndroid,
                onChanged: (wantsAndroid) => controller.use(
                  wantsAndroid
                      ? PlatformController.android
                      : PlatformController.ios,
                ),
              ),
            ),
            _Side(
              label: PlatformController.android.label,
              active: isAndroid,
              tokens: tokens,
              onTap: () => controller.use(PlatformController.android),
            ),
          ],
        ),
      ),
    );
  }
}

/// O nome de uma das peles. Tocar nele também troca: quem lê "Android" e
/// clica espera ir para o Android, e o que parece tocável funciona.
class _Side extends StatelessWidget {
  const _Side({
    required this.label,
    required this.active,
    required this.tokens,
    required this.onTap,
  });

  final String label;
  final bool active;
  final AppTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Text(
            label,
            style: TextStyle(
              color: active ? tokens.onWallpaper : tokens.onWallpaperMuted,
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
