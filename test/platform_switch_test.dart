import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_os/app/portfolio_app.dart';
import 'package:portfolio_os/app/web_stage.dart';
import 'package:portfolio_os/core/platform/platform_scope.dart';
import 'package:portfolio_os/core/platform/platform_spec.dart';
import 'package:portfolio_os/features/home/home_screen.dart';
import 'package:portfolio_os/features/lock/lock_screen.dart';
import 'package:portfolio_os/core/theme/tokens.dart';
import 'package:portfolio_os/shared/motion/app_open_page.dart';
import 'package:portfolio_os/shared/widgets/app_icon.dart';

/// O interruptor vive dentro do Flutter, ao lado do sistema, e mexe no
/// `PlatformController` — que continua sendo o único ponto de troca.
///
/// Os testes partem da pele que estiver ativa em vez de fixar uma: o que
/// precisa ser verdade é que virar a chave leva para a outra e volta, não que
/// a entrada seja esta ou aquela.
void main() {
  /// O raio do ladrilho denuncia a pele em uso sem precisar perguntar a ela:
  /// 0.225 do lado no iOS, metade no Android.
  double tileRadius(WidgetTester tester) {
    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(AppIcon).first,
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = container.decoration! as BoxDecoration;
    return (decoration.borderRadius! as BorderRadius).topLeft.x;
  }

  Future<PlatformController> open(WidgetTester tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('pt', 'BR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);

    await tester.pumpWidget(const PortfolioApp());
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(find.byType(LockScreen)));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    return PlatformScope.of(tester.element(find.byType(HomeScreen)));
  }

  testWidgets('o interruptor aparece sem precisar caçar', (tester) async {
    await open(tester);

    expect(find.byType(PlatformSwitchBar), findsOneWidget);
    expect(find.text(PlatformController.ios.label), findsOneWidget);
    expect(find.text(PlatformController.android.label), findsOneWidget);
  });

  testWidgets('virar a chave repinta o sistema inteiro', (tester) async {
    final controller = await open(tester);

    final started = controller.spec;
    final other = started.id == PlatformController.ios.id
        ? PlatformController.android
        : PlatformController.ios;

    expect(tileRadius(tester), started.iconRadius(60).topLeft.x);

    await tester.tap(find.text(other.label));
    await tester.pumpAndSettle();

    expect(
      controller.spec.id,
      other.id,
      reason: 'a troca passa pelo ponto único',
    );
    expect(
      tileRadius(tester),
      other.iconRadius(60).topLeft.x,
      reason: 'o ladrilho tem que ter sido redesenhado pela outra pele',
    );

    await tester.tap(find.text(started.label));
    await tester.pumpAndSettle();

    expect(controller.spec.id, started.id);
    expect(tileRadius(tester), started.iconRadius(60).topLeft.x);
  });

  testWidgets('a chave reflete a pele em uso, não um estado próprio', (
    tester,
  ) async {
    final controller = await open(tester);

    final other = controller.spec.id == PlatformController.ios.id
        ? PlatformController.android
        : PlatformController.ios;

    // Virando por fora do interruptor, ele tem que acompanhar.
    controller.use(other);
    await tester.pumpAndSettle();

    expect(tileRadius(tester), other.iconRadius(60).topLeft.x);
  });

  /// O raio de onde a transição de contêiner começa sai do ladrilho de
  /// verdade, e não de um tamanho de referência. Como a doca virou link
  /// externo, nenhuma rota nasce mais de um ladrilho de 52 — então os dois
  /// tamanhos passam por aqui, pelo caminho que o app usa de verdade.
  group('o raio de abertura vem do tamanho do ladrilho', () {
    for (final spec in <PlatformSpec>[
      PlatformController.ios,
      PlatformController.android,
    ]) {
      for (final side in const [60.0, 52.0]) {
        test('${spec.id} · ladrilho de ${side.toInt()}', () {
          final route = AppOpenRoute<void>(
            AppOpenPage<void>(
              spec: spec,
              background: AppTokens.dark.background,
              onGoHome: () {},
              origin: AppOrigin(
                rect: Rect.fromLTWH(10, 20, side, side),
                color: AppTokens.dark.surface,
              ),
              child: const SizedBox.shrink(),
            ),
          );

          expect(route.originRadius, spec.iconRadius(side).topLeft.x);
        });
      }
    }

    test('sem ladrilho não há raio', () {
      final route = AppOpenRoute<void>(
        AppOpenPage<void>(
          spec: PlatformController.ios,
          background: AppTokens.dark.background,
          onGoHome: () {},
          child: const SizedBox.shrink(),
        ),
      );

      expect(route.originRadius, isNull);
    });
  });
}
