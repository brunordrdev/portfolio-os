import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_os/app/portfolio_app.dart';
import 'package:portfolio_os/core/theme/tokens.dart';
import 'package:portfolio_os/core/settings/settings.dart';
import 'package:portfolio_os/features/about/about_screen.dart';
import 'package:portfolio_os/features/home/home_screen.dart';
import 'package:portfolio_os/features/lock/lock_screen.dart';
import 'package:portfolio_os/features/settings/settings_screen.dart';
import 'package:portfolio_os/shared/widgets/app_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ajustes: escolher idioma e tema, e a escolha sobreviver.
void main() {
  setUp(ScrollMemory.forget);

  /// Abre o sistema com uma gaveta de escolhas já guardada.
  Future<void> boot(WidgetTester tester, SettingsStore store) async {
    tester.platformDispatcher.localeTestValue = const Locale('pt', 'BR');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);

    // Árvore nova a cada chamada. Sem isto o Flutter reaproveita o State e
    // a segunda montagem seria uma reconstrução, não um recarregamento — o
    // controlador antigo continuaria vivo e o teste não provaria nada.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      PortfolioApp(settings: SettingsController(store: store)),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(find.byType(LockScreen)));
    await tester.pumpAndSettle();
  }

  Future<void> openApp(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  group('idioma', () {
    testWidgets('trocar muda todo o texto sem recarregar', (tester) async {
      await boot(tester, MemoryStore());
      await openApp(tester, 'Ajustes');

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Aparência'), findsOneWidget);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      // A tela onde o toque aconteceu mudou...
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Aparência'), findsNothing);

      // ...e o resto do sistema também, sem passar por lugar nenhum.
      // O cabeçalho usa glifo próprio, então `pageBack` não o acha. Escape
      // fecha o app do mesmo jeito, e é caminho de verdade.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Ajustes'), findsNothing);
    });

    testWidgets('a escolha sobrevive ao recarregar', (tester) async {
      // Uma gaveta só, duas execuções do app: é o que "recarregar" significa.
      final store = MemoryStore();

      await boot(tester, store);
      await openApp(tester, 'Ajustes');
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.text('Appearance'), findsOneWidget);

      await boot(tester, store);
      expect(find.text('Settings'), findsOneWidget, reason: 'abriu em inglês');
    });

    testWidgets('Sistema volta a seguir o navegador', (tester) async {
      final store = MemoryStore();

      await boot(tester, store);
      await openApp(tester, 'Ajustes');
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      // "Sistema" existe nas duas seções; a de idioma vem primeiro.
      await tester.tap(find.text('System').first);
      await tester.pumpAndSettle();

      // O navegador do teste está em pt-BR.
      expect(find.text('Ajustes'), findsOneWidget);

      await boot(tester, store);
      expect(find.text('Ajustes'), findsOneWidget);
    });
  });

  group('aparência', () {
    testWidgets('escolher Escuro pinta o sistema de escuro', (tester) async {
      final store = MemoryStore();
      await boot(tester, store);
      await openApp(tester, 'Ajustes');

      await tester.tap(find.text('Escuro'));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, AppTokens.dark.background);

      await tester.tap(find.text('Claro'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
        AppTokens.light.background,
      );
    });

    testWidgets('a escolha de tema sobrevive ao recarregar', (tester) async {
      final store = MemoryStore();

      await boot(tester, store);
      await openApp(tester, 'Ajustes');
      await tester.tap(find.text('Claro'));
      await tester.pumpAndSettle();

      await boot(tester, store);
      await openApp(tester, 'Ajustes');
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
        AppTokens.light.background,
      );
    });
  });

  group('estado preservado', () {
    testWidgets('sair de um app e voltar mantém a rolagem', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await boot(tester, MemoryStore());
      await openApp(tester, 'Sobre');
      expect(find.byType(AboutScreen), findsOneWidget);

      final scrollable = find.byType(Scrollable).first;
      await tester.drag(scrollable, const Offset(0, -420));
      await tester.pumpAndSettle();

      final rolled = tester.widget<Scrollable>(scrollable).controller!.offset;
      expect(rolled, greaterThan(200), reason: 'a tela precisa ter rolado');

      // Sai e volta, como o visitante faria.
      // O cabeçalho usa glifo próprio, então `pageBack` não o acha. Escape
      // fecha o app do mesmo jeito, e é caminho de verdade.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      await openApp(tester, 'Sobre');
      expect(find.byType(AboutScreen), findsOneWidget);

      final restored = tester
          .widget<Scrollable>(find.byType(Scrollable).first)
          .controller!
          .offset;
      expect(restored, rolled, reason: 'voltou para o topo em vez da posição');
    });
  });

  group('o armazenamento do navegador', () {
    test('lê e escreve o que foi guardado', () async {
      SharedPreferences.setMockInitialValues({
        'portfolio_os.language': 'english',
      });

      final store = await PreferencesStore.open();
      final settings = SettingsController(store: store);
      expect(settings.language, LanguageChoice.english);

      settings.useTheme(ThemeChoice.dark);
      await Future<void>.delayed(Duration.zero);

      final reopened = SettingsController(store: await PreferencesStore.open());
      expect(reopened.theme, ThemeChoice.dark);
      expect(reopened.language, LanguageChoice.english);
    });

    test('valor desconhecido volta ao padrão', () {
      final settings = SettingsController(
        store: MemoryStore({'portfolio_os.theme': 'sepia'}),
      );
      expect(settings.theme, ThemeChoice.system);
    });

    // Este é o caso que derrubou o site inteiro por causa de uma preferência:
    // `main` dava `await` no armazenamento sem guarda, e armazenamento que
    // não responde — plugin sem registro, aba anônima bloqueada — matava
    // `main` antes do `runApp`. O visitante ficava com a tela de bloqueio de
    // CSS para sempre, e nada em teste enxergava, porque em teste o
    // armazenamento é um mapa que sempre responde.
    test('armazenamento que não responde não derruba o site', () async {
      final store = await openSettingsStore(
        open: () => Future<SettingsStore>.error(
          MissingPluginException('sem implementação para getAll'),
        ),
      );

      expect(store, isA<MemoryStore>(), reason: 'devia ter caído na memória');

      final settings = SettingsController(store: store);
      expect(settings.language, LanguageChoice.system);

      // E o site continua usável: a escolha vale nesta visita, só não na
      // próxima. Degradar é perder a memória, não perder a tela.
      settings.useLanguage(LanguageChoice.english);
      expect(settings.language, LanguageChoice.english);
    });

    test('armazenamento que responde é usado como está', () async {
      final opened = MemoryStore({'portfolio_os.language': 'english'});
      final store = await openSettingsStore(open: () async => opened);

      expect(identical(store, opened), isTrue);
      expect(SettingsController(store: store).language, LanguageChoice.english);
    });
  });
}
