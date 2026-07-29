import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Em que idioma o site abre.
enum LanguageChoice { portuguese, english, system }

/// Em que tema o site abre.
enum ThemeChoice { light, dark, system }

/// Onde a escolha fica guardada entre visitas.
///
/// A interface existe para o teste não precisar do navegador: em produção é
/// o armazenamento local, em teste é um mapa que o próprio teste inspeciona.
abstract interface class SettingsStore {
  Map<String, String> get values;
  Future<void> write(String key, String value);
}

/// Guarda na memória e some ao fechar. É o padrão fora do navegador.
class MemoryStore implements SettingsStore {
  MemoryStore([Map<String, String>? initial]) : values = {...?initial};

  @override
  final Map<String, String> values;

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

/// Guarda no armazenamento local do navegador, e por isso sobrevive ao
/// recarregar — que é o ponto: quem escolheu inglês não escolhe de novo a
/// cada visita.
class PreferencesStore implements SettingsStore {
  PreferencesStore._(this._preferences, this.values);

  static Future<PreferencesStore> open() async {
    final preferences = await SharedPreferences.getInstance();
    return PreferencesStore._(preferences, {
      for (final key in preferences.getKeys())
        if (key.startsWith(SettingsController.prefix))
          key: preferences.getString(key) ?? '',
    });
  }

  final SharedPreferences _preferences;

  @override
  final Map<String, String> values;

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
    await _preferences.setString(key, value);
  }
}

/// Abre o armazenamento do navegador, e cai na memória se ele não responder.
///
/// Aba anônima com armazenamento bloqueado, plugin que não registrou, política
/// do navegador: em qualquer um deles o site abre, e só a escolha não
/// sobrevive ao recarregar. Sem esta guarda o `await` derruba `main` antes do
/// `runApp`, e o visitante fica olhando a tela de bloqueio de CSS para sempre
/// — falha total por causa de uma preferência.
///
/// `open` existe para o teste: em produção é sempre `PreferencesStore.open`.
Future<SettingsStore> openSettingsStore({
  Future<SettingsStore> Function()? open,
}) async {
  try {
    return await (open ?? PreferencesStore.open)();
  } catch (_) {
    return MemoryStore();
  }
}

/// A escolha do visitante sobre idioma e tema.
///
/// "Sistema" é o padrão e não é ausência de escolha: é a escolha de seguir o
/// navegador, do mesmo jeito que a plataforma e o tema já faziam antes desta
/// tela existir. Quem nunca abriu Ajustes continua vendo o site adaptado.
class SettingsController extends ChangeNotifier {
  SettingsController({SettingsStore? store}) : _store = store ?? MemoryStore() {
    _language = _read(
      _languageKey,
      LanguageChoice.values,
      LanguageChoice.system,
    );
    _theme = _read(_themeKey, ThemeChoice.values, ThemeChoice.system);
  }

  static const String prefix = 'portfolio_os.';
  static const String _languageKey = '${prefix}language';
  static const String _themeKey = '${prefix}theme';

  final SettingsStore _store;

  late LanguageChoice _language;
  late ThemeChoice _theme;

  LanguageChoice get language => _language;
  ThemeChoice get theme => _theme;

  T _read<T extends Enum>(String key, List<T> options, T fallback) {
    final stored = _store.values[key];
    for (final option in options) {
      if (option.name == stored) return option;
    }
    // Valor desconhecido é valor de uma versão que não existe mais: volta ao
    // padrão em vez de quebrar.
    return fallback;
  }

  void useLanguage(LanguageChoice choice) {
    if (_language == choice) return;
    _language = choice;
    _store.write(_languageKey, choice.name);
    notifyListeners();
  }

  void useTheme(ThemeChoice choice) {
    if (_theme == choice) return;
    _theme = choice;
    _store.write(_themeKey, choice.name);
    notifyListeners();
  }
}

/// Leva o controlador de Ajustes para baixo e reconstrói quem depende dele.
class SettingsScope extends InheritedNotifier<SettingsController> {
  const SettingsScope({
    super.key,
    required SettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static SettingsController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SettingsScope>();
    assert(scope != null, 'Nenhum SettingsScope acima deste widget.');
    return scope!.notifier!;
  }
}

extension SettingsScopeExtension on BuildContext {
  SettingsController get settings => SettingsScope.of(this);
}
