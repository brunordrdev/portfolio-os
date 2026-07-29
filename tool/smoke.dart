// Verificador de fumaça: carrega a URL publicada num navegador de verdade e
// confere comportamento, não código.
//
// É o degrau que faltava. A suíte roda antes do build e enxerga o repositório;
// nada nela vê o site montando. Os dois defeitos que passaram batidos eram
// exatamente dessa classe: o service worker que não registrava (o teste lia
// uma string no arquivo) e a preferência que não sobrevivia ao recarregar (o
// teste injetava memória e nunca tocou no navegador). Um verificador que só lê
// arquivo não pega nenhum dos dois, por mais testes que tenha.
//
// Roda DEPOIS do deploy, contra o endereço público — antes não haveria o que
// carregar. Fala com o Chrome pelo protocolo de depuração, sem dependência
// nova: `dart:io` já tem WebSocket.
//
//     dart run tool/smoke.dart https://portfolio-os-1rq.pages.dev
//
// A chave `CHROME` do ambiente aponta um binário específico, se preciso.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Uma verificação: o nome que sai no relatório e o que ela cobra.
typedef Check = ({String name, Future<void> Function() run});

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stdout.writeln('uso: dart run tool/smoke.dart <url>');
    exit(64);
  }
  final url = args.single.endsWith('/') ? args.single : '${args.single}/';

  stdout.writeln('Verificando $url num Chrome de verdade.\n');
  final chrome = await Browser.launch();
  final failures = <String, Object>{};
  var total = 0;
  try {
    final page = await chrome.openPage();
    final checks = smokeChecks(url, page);
    total = checks.length;
    for (final check in checks) {
      try {
        await check.run();
        stdout.writeln('  ok    ${check.name}');
      } catch (error) {
        failures[check.name] = error;
        stdout.writeln('  FALHA ${check.name}');
      }
    }
  } finally {
    await chrome.close();
  }

  if (failures.isEmpty) {
    stdout.writeln('\nO site publicado está de pé: ${_plural(total)}.');
    return;
  }
  stdout.writeln('\n${_plural(failures.length)} de ${_plural(total)} falharam em $url:\n');
  failures.forEach((name, error) => stdout.writeln('  $name\n    $error\n'));
  exit(1);
}

String _plural(int count) => count == 1 ? '1 verificação' : '$count verificações';

/// As verificações, na ordem em que precisam acontecer: as duas últimas
/// dependem de a página já ter sido carregada uma vez.
List<Check> smokeChecks(String url, Page page) {
  // Guardado entre verificações: o idioma que o site mostrou na primeira
  // carga decide qual idioma a verificação de persistência vai plantar.
  var firstLoadInEnglish = true;

  return [
    (
      name: 'o HTML servido está em inglês, sem depender de JavaScript',
      run: () async {
        final html = await _get(Uri.parse(url));
        _expect(html.contains('<html lang="en">'), 'falta <html lang="en">');
        for (final fragment in const ['Bruno Rodrigues', 'Mobile developer', 'swipe up']) {
          _expect(html.contains(fragment), 'o HTML servido não traz "$fragment"');
        }
        _expect(html.contains('data-pt="arraste para cima"'),
            'o par em português sumiu: a troca de idioma não teria o que trocar');
      },
    ),
    (
      name: 'o app monta e desenha a tela de bloqueio',
      run: () async {
        await page.goto(url);
        final text = await page.lockScreenText();
        firstLoadInEnglish = text.contains('swipe up');
        _expect(
          firstLoadInEnglish || text.contains('arraste para cima'),
          'a tela de bloqueio do Flutter não apareceu; o que veio foi: $text',
        );
      },
    ),
    (
      name: 'o service worker registra, ativa e controla a página',
      run: () async {
        final script = await page.waitFor('o service worker ativar', () async {
          final value = await page.evaluate('''
            (async () => {
              if (!('serviceWorker' in navigator)) return null;
              const registration = await navigator.serviceWorker.getRegistration();
              if (!registration || !registration.active) return null;
              return registration.active.scriptURL;
            })()
          ''');
          return value as String?;
        });
        _expect(script.endsWith('/sw.js'), 'quem registrou foi $script, e não o nosso sw.js');

        // Registrado não é o mesmo que no comando: sem `clients.claim()` o
        // service worker só assume a página seguinte, e a primeira visita
        // ficaria sem ele — que é o caso que interessa aqui.
        final controlling = await page.waitFor('o service worker assumir a página', () async {
          final value = await page.evaluate('!!navigator.serviceWorker.controller');
          return value == true ? true : null;
        });
        _expect(controlling, 'registrou mas não assumiu a página');
      },
    ),
    (
      name: 'a escrita em armazenamento sobrevive ao recarregar',
      run: () async {
        const marker = 'portfolio-os.smoke';
        final written = DateTime.now().microsecondsSinceEpoch.toString();
        await page.evaluate("localStorage.setItem('$marker', '$written')");
        await page.reload(url);
        final read = await page.evaluate("localStorage.getItem('$marker')");
        _expect(read == written, 'gravou "$written" e depois do recarregar leu "$read"');
        await page.evaluate("localStorage.removeItem('$marker')");
      },
    ),
    (
      name: 'a preferência guardada volta aplicada depois do recarregar',
      run: () async {
        // Ponta a ponta pelo caminho de verdade: o valor é plantado no
        // formato do shared_preferences (prefixo `flutter.`, valor em JSON), e
        // quem tem de lê-lo é o app. Se o plugin não responder no navegador —
        // que foi o defeito — o site volta no idioma de antes e isto falha.
        // Plantado sempre no idioma oposto ao da primeira carga, senão a
        // verificação passaria de graça na máquina de quem já está nele.
        final planted = firstLoadInEnglish ? 'portuguese' : 'english';
        final expected = firstLoadInEnglish ? 'arraste para cima' : 'swipe up';
        await page.evaluate(
          "localStorage.setItem('flutter.portfolio_os.language', ${jsonEncode(jsonEncode(planted))})",
        );
        await page.reload(url);
        final text = await page.lockScreenText();
        _expect(
          text.contains(expected),
          'plantei "$planted" e o app abriu mostrando: $text',
        );
        await page.evaluate("localStorage.removeItem('flutter.portfolio_os.language')");
      },
    ),
    (
      // Por último porque junta o que apareceu em todas as cargas acima. Foi
      // por aqui que o defeito da persistência apareceu primeiro: uma
      // MissingPluginException que ninguém via, porque ninguém olhava.
      name: 'o arranque não solta erro no console',
      run: () async {
        _expect(page.problems.isEmpty, page.problems.join('\n    '));
      },
    ),
  ];
}

void _expect(bool condition, String complaint) {
  if (!condition) throw StateError(complaint);
}

Future<String> _get(Uri url) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(url);
    request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
    final response = await request.close();
    if (response.statusCode != 200) {
      throw StateError('$url respondeu ${response.statusCode}');
    }
    return response.transform(utf8.decoder).join();
  } finally {
    client.close();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// O navegador
// ═══════════════════════════════════════════════════════════════════════════

/// Um Chrome de mentira nenhuma, aberto sem interface e falado pelo protocolo
/// de depuração.
class Browser {
  Browser._(this._process, this._port, this._profile);

  final Process _process;
  final int _port;
  final Directory _profile;

  static Future<Browser> launch() async {
    final binary = _findChrome();
    final profile = await Directory.systemTemp.createTemp('smoke-chrome-');
    final process = await Process.start(binary, [
      '--headless=new',
      '--remote-debugging-port=0',
      '--user-data-dir=${profile.path}',
      '--no-first-run',
      '--no-default-browser-check',
      '--disable-extensions',
      '--disable-background-networking',
      // Sem GPU no runner, o WebGL cai para software. Sem ele, o carregador
      // do Flutter desce para o alvo JS e o alvo wasm nunca seria exercido.
      '--enable-unsafe-swiftshader',
      if (Platform.environment['CI'] == 'true') '--no-sandbox',
      '--window-size=430,900',
      'about:blank',
    ]);

    // O Chrome escreve a porta que escolheu neste arquivo, ao abrir.
    final portFile = File('${profile.path}/DevToolsActivePort');
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (DateTime.now().isBefore(deadline)) {
      if (portFile.existsSync()) {
        final lines = portFile.readAsLinesSync();
        if (lines.isNotEmpty && int.tryParse(lines.first) != null) {
          return Browser._(process, int.parse(lines.first), profile);
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    process.kill();
    throw StateError('o Chrome não abriu a porta de depuração em 30 s');
  }

  static String _findChrome() {
    final declared = Platform.environment['CHROME'];
    if (declared != null && declared.isNotEmpty) return declared;

    const candidates = [
      '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
      '/usr/bin/google-chrome',
      '/usr/bin/google-chrome-stable',
      '/usr/bin/chromium',
      '/usr/bin/chromium-browser',
      '/opt/google/chrome/chrome',
    ];
    for (final candidate in candidates) {
      if (File(candidate).existsSync()) return candidate;
    }
    throw StateError('nenhum Chrome encontrado; aponte um com a variável CHROME');
  }

  Future<Page> openPage() async {
    final targets = jsonDecode(await _get(Uri.parse('http://127.0.0.1:$_port/json/list')));
    final page = (targets as List).cast<Map<String, dynamic>>().firstWhere(
          (target) => target['type'] == 'page',
          orElse: () => throw StateError('o Chrome abriu sem nenhuma aba'),
        );
    final socket = await WebSocket.connect(page['webSocketDebuggerUrl'] as String);
    final opened = Page._(socket);
    opened._start();
    return opened;
  }

  Future<void> close() async {
    _process.kill();
    await _process.exitCode.timeout(const Duration(seconds: 10), onTimeout: () => 0);
    if (_profile.existsSync()) _profile.deleteSync(recursive: true);
  }
}

/// Uma aba, e as perguntas que dá para fazer a ela.
class Page {
  Page._(this._socket);

  final WebSocket _socket;
  final _pending = <int, Completer<Map<String, dynamic>>>{};
  var _nextId = 0;

  /// O que o navegador reclamou: exceção não capturada, `console.error`, rede
  /// que respondeu errado. Um arranque limpo não tem nenhuma.
  final problems = <String>[];

  void _start() {
    _socket.listen((dynamic raw) {
      final message = jsonDecode(raw as String) as Map<String, dynamic>;
      final id = message['id'] as int?;
      if (id != null) {
        _pending.remove(id)?.complete(message);
        return;
      }
      _note(message);
    });
  }

  void _note(Map<String, dynamic> event) {
    final params = (event['params'] as Map<String, dynamic>?) ?? const {};
    switch (event['method']) {
      case 'Runtime.exceptionThrown':
        final details = params['exceptionDetails'] as Map<String, dynamic>;
        final exception = details['exception'] as Map<String, dynamic>?;
        problems.add('exceção: ${exception?['description'] ?? details['text']}');
      case 'Runtime.consoleAPICalled':
        if (params['type'] != 'error') return;
        final args = (params['args'] as List).cast<Map<String, dynamic>>();
        problems.add('console.error: ${args.map((a) => a['value'] ?? a['description']).join(' ')}');
      case 'Log.entryAdded':
        final entry = params['entry'] as Map<String, dynamic>;
        if (entry['level'] != 'error') return;
        problems.add('${entry['source']}: ${entry['text']} ${entry['url'] ?? ''}'.trim());
    }
  }

  Future<Map<String, dynamic>> send(String method, [Map<String, Object?>? params]) async {
    final id = ++_nextId;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    _socket.add(jsonEncode({'id': id, 'method': method, 'params': params ?? const {}}));
    final reply = await completer.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () => throw TimeoutException('o Chrome não respondeu a $method'),
    );
    final error = reply['error'];
    if (error != null) throw StateError('$method: $error');
    return (reply['result'] as Map).cast<String, dynamic>();
  }

  Future<Object?> evaluate(String expression) async {
    final result = await send('Runtime.evaluate', {
      'expression': expression,
      'awaitPromise': true,
      'returnByValue': true,
    });
    final details = result['exceptionDetails'] as Map<String, dynamic>?;
    if (details != null) {
      final exception = details['exception'] as Map<String, dynamic>?;
      throw StateError('avaliação falhou: ${exception?['description'] ?? details['text']}');
    }
    return (result['result'] as Map<String, dynamic>)['value'];
  }

  Future<void> goto(String url) async {
    await send('Runtime.enable');
    await send('Log.enable');
    await send('Page.enable');
    await send('Page.navigate', {'url': url});
    await _settle();
  }

  Future<void> reload(String url) async {
    await send('Page.navigate', {'url': url});
    await _settle();
  }

  /// Espera o Flutter existir na página. Não basta o documento carregar: o
  /// motor chega depois, e é ele que desenha.
  Future<void> _settle() async {
    await waitFor('o Flutter montar dentro da moldura', () async {
      final value = await evaluate(
        "!!document.querySelector('#stage flutter-view, #stage flt-glass-pane, #stage canvas')",
      );
      return value == true ? true : null;
    });
  }

  /// O texto da tela de bloqueio, lido da árvore de acessibilidade.
  ///
  /// O Flutter desenha em canvas, então não há texto no DOM para ler — a não
  /// ser com a semântica ligada, que é o que o próprio site oferece a quem usa
  /// leitor de tela. Ligar aqui é usar a mesma porta: se o texto não aparecer
  /// por ela, também não aparece para quem precisa dela.
  Future<String> lockScreenText() async {
    await waitFor('a semântica do Flutter aparecer', () async {
      final ready = await evaluate('''
        (() => {
          const placeholder = document.querySelector('flt-semantics-placeholder');
          if (placeholder) placeholder.click();
          return !!document.querySelector('flt-semantics');
        })()
      ''');
      return ready == true ? true : null;
    });
    return await waitFor('a tela de bloqueio ter texto', () async {
      // O Flutter põe o texto de um grupo em `aria-label`, e não como filho:
      // ler só `innerText` traz o interruptor de plataforma e mais nada.
      final text = await evaluate('''
        (() => {
          const host = document.querySelector('flt-semantics-host');
          if (!host) return '';
          const labels = [...host.querySelectorAll('[aria-label]')]
            .map((node) => node.getAttribute('aria-label'));
          return (labels.join(' ') + ' ' + host.innerText).replace(/\\s+/g, ' ').trim();
        })()
      ''') as String?;
      return (text != null && text.length > 3) ? text : null;
    });
  }

  Future<T> waitFor<T extends Object>(
    String what,
    Future<T?> Function() probe, {
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final deadline = DateTime.now().add(timeout);
    Object? lastError;
    while (DateTime.now().isBefore(deadline)) {
      try {
        final value = await probe();
        if (value != null) return value;
      } catch (error) {
        lastError = error;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    throw TimeoutException('esperei $what por ${timeout.inSeconds} s${lastError == null ? '' : ' (último erro: $lastError)'}');
  }
}
