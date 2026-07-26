import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_os/core/platform/platform_scope.dart';

void main() {
  group('PlatformController', () {
    test('toggle vira a chave nos dois sentidos e avisa uma vez por vez', () {
      final controller = PlatformController(PlatformController.ios);
      addTearDown(controller.dispose);

      var notices = 0;
      controller.addListener(() => notices++);

      expect(controller.spec.id, 'ios');

      controller.toggle();
      expect(controller.spec.id, 'android');

      controller.toggle();
      expect(controller.spec.id, 'ios');

      expect(notices, 2);
    });

    test('pedir a pele que já está ativa não reconstrói nada', () {
      final controller = PlatformController(PlatformController.ios);
      addTearDown(controller.dispose);

      var notices = 0;
      controller.addListener(() => notices++);

      controller.use(PlatformController.ios);

      expect(notices, 0);
    });
  });

  group('detecção inicial', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    PlatformController controllerOn(TargetPlatform host) {
      debugDefaultTargetPlatformOverride = host;
      final controller = PlatformController();
      addTearDown(controller.dispose);
      return controller;
    }

    test('só um aparelho Android abre na pele Android', () {
      expect(controllerOn(TargetPlatform.android).spec.id, 'android');
    });

    // A pele Android é crua de propósito na v1. Quem chega de um desktop não
    // escolheu vê-la, então cai na pele iOS, que é a identidade do projeto.
    for (final host in const [
      TargetPlatform.iOS,
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.fuchsia,
    ]) {
      test('${host.name} abre na pele iOS', () {
        expect(controllerOn(host).spec.id, 'ios');
      });
    }
  });
}
