import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_os/app/portfolio_app.dart';
import 'package:portfolio_os/content/app_content.dart';

/// O idioma segue o mesmo princípio da plataforma e do tema: o site abre
/// adaptado ao visitante, sem perguntar nada.
void main() {
  group('idioma pela preferência do navegador', () {
    const cases = <String, ({Locale locale, String language, String name})>{
      'pt-BR': (
        locale: Locale('pt', 'BR'),
        language: 'pt',
        name: 'me chamo Bruno',
      ),
      // Qualquer variante de português abre em português.
      'pt-PT': (
        locale: Locale('pt', 'PT'),
        language: 'pt',
        name: 'me chamo Bruno',
      ),
      'en-US': (
        locale: Locale('en', 'US'),
        language: 'en',
        name: 'my name is Bruno',
      ),
      // O resto do mundo abre em inglês.
      'fr-FR': (
        locale: Locale('fr', 'FR'),
        language: 'en',
        name: 'my name is Bruno',
      ),
      'ja-JP': (
        locale: Locale('ja', 'JP'),
        language: 'en',
        name: 'my name is Bruno',
      ),
    };

    for (final entry in cases.entries) {
      test('${entry.key} escolhe ${entry.value.language}', () {
        expect(
          AppContent.forLocale(entry.value.locale).language,
          entry.value.language,
        );
      });

      testWidgets('${entry.key} chega na tela', (tester) async {
        tester.platformDispatcher.localeTestValue = entry.value.locale;
        addTearDown(tester.platformDispatcher.clearLocaleTestValue);

        await tester.pumpWidget(const PortfolioApp());
        await tester.pumpAndSettle();

        expect(find.text(entry.value.name), findsOneWidget);
      });
    }
  });

  test('os dois idiomas dizem as mesmas coisas', () {
    // Um texto escrito num idioma só é um texto que ninguém percebe faltar.
    expect(AppContent.pt.about.length, AppContent.en.about.length);
    expect(AppContent.pt.experience.length, AppContent.en.experience.length);
    expect(AppContent.pt.resume.length, AppContent.en.resume.length);
    expect(AppContent.pt.projects.length, AppContent.en.projects.length);
    expect(AppContent.pt.lock.weekdays.length, 7);
    expect(AppContent.en.lock.weekdays.length, 7);
    expect(AppContent.pt.lock.months.length, 12);
    expect(AppContent.en.lock.months.length, 12);

    // E na mesma ordem: título com título, apoio com apoio, prosa com prosa.
    for (var i = 0; i < AppContent.pt.experience.length; i++) {
      expect(
        AppContent.en.experience[i].runtimeType,
        AppContent.pt.experience[i].runtimeType,
        reason: 'bloco $i de Experiência',
      );
    }
  });

  test('a data muda de ordem conforme o idioma', () {
    final date = DateTime(2026, 7, 26);
    expect(AppContent.pt.lock.dateLine(date), 'domingo, 26 de julho · Aracaju');
    expect(AppContent.en.lock.dateLine(date), 'Sunday, July 26 · Aracaju');
  });
}
