# portfolio_os

Portfólio em forma de sistema operacional móvel. Flutter web, em
[brunordrdev.com](https://brunordrdev.com).

A tese é a troca **iOS ↔ Android**: em vez de afirmar que sei desenvolvimento
cross-platform, o site faz isso consigo mesmo. Uma chave troca a pele do sistema
inteiro — forma dos ícones, curvas de animação, resposta ao toque, tipografia,
rota de página — e nenhuma tela participa da troca.

---

## A decisão de arquitetura: a camada `PlatformSpec`

### O problema

A maneira natural de escrever isso é a errada:

```dart
// não existe neste repositório
borderRadius: BorderRadius.circular(Platform.isIOS ? size * 0.225 : size * 0.5),
```

Funciona no primeiro ícone. O custo vem depois. Cada diferença nova é mais um
`if` numa tela nova, e o conhecimento de "como o iOS se comporta" vaza para
dezenas de arquivos que deveriam estar cuidando de conteúdo. Quando a segunda
pele finalmente for lapidada, o trabalho não é escrever a pele: é caçar os `if`
espalhados. E o desfecho provável é que a segunda pele nunca seja escrita, e o
projeto vire um app iOS com um interruptor decorativo — exatamente a afirmação
que o site existe para não fazer.

### A solução

Toda diferença entre plataformas vive atrás de uma interface:
[`lib/core/platform/platform_spec.dart`](lib/core/platform/platform_spec.dart).

```dart
abstract class PlatformSpec {
  BorderRadius iconRadius(double size);
  Duration get openDuration;
  Curve get openCurve;
  FontWeight get appLabelWeight;
  Widget tappable({required Widget child, required VoidCallback onTap, ...});
  Route<T> pageRoute<T>({required WidgetBuilder builder, ...});
  // ...
}
```

Duas implementações — `IOSSpec` e `AndroidSpec` — e um controlador que decide
qual está ativa: `PlatformController`, em
[`platform_scope.dart`](lib/core/platform/platform_scope.dart). A tela pergunta
`context.platform` e recebe respostas, nunca a identidade de quem responde.

A pele Android existe desde o primeiro dia, crua de propósito. Não é pendência:
é o que mantém a interface honesta. Um membro novo em `PlatformSpec` exige uma
resposta nas duas peles, e é isso que impede a segunda de virar ficção.

As cores seguem o mesmo desenho, um degrau abaixo: nenhum widget escreve
`Color(0xFF...)`. Cor entra por `AppTokens`
([`tokens.dart`](lib/core/theme/tokens.dart)), porque um hexadecimal solto numa
tela sobrevive à troca de tema e quebra o modo claro.

### O critério de aceite

A troca de plataforma acontece **num único ponto**: `PlatformController`.

Na prática, três coisas precisam continuar verdadeiras:

1. Nenhuma tela contém `Platform.isIOS`, `defaultTargetPlatform` ou equivalente.
   Se uma tela precisa saber a plataforma, o certo é acrescentar um membro à
   interface — nunca abrir uma exceção na tela.
2. Mudar `android_spec.dart` não exige mudar nenhuma tela. Se exigir, o problema
   está na interface, não na pele.
3. Virar a chave não encosta em código de tela. Se encostar, a costura vazou, e
   o conserto é na costura.

Nenhum dos três é honra: os três são verificados a cada push.

**O primeiro é um passo do CI**, chamado `Verificar a costura`, em
[`.github/workflows/ci.yml`](.github/workflows/ci.yml). Ele roda depois do
`analyze` e antes dos testes, e **falha o build** se `Platform.` ou
`defaultTargetPlatform` aparecerem em qualquer lugar de `lib/` fora de
`lib/core/platform/`:

```
grep -rnE 'Platform\.|defaultTargetPlatform' lib --include='*.dart' \
  | grep -v '^lib/core/platform/'
```

O esperado é nenhum resultado. Um `analyze` limpo não pega esse vazamento —
`Platform.isIOS` numa tela compila sem reclamação, e é justamente por isso que
a checagem existe em separado. Hoje `defaultTargetPlatform` aparece uma única
vez no projeto inteiro: em `platform_scope.dart`, na detecção inicial.

**Os outros dois são os testes.**
[`test/app_icon_test.dart`](test/app_icon_test.dart) monta o mesmo widget nas
quatro combinações (iOS/Android × escuro/claro) e verifica que ele funciona nas
quatro — inclusive a área de toque, que é o que quebra em silêncio quando a
forma muda. [`test/platform_scope_test.dart`](test/platform_scope_test.dart)
cobre a troca em si e a detecção inicial.

---

## Estrutura

```
lib/app/         raiz e rotas (uma URL por app)
lib/core/        platform/ (a costura) e theme/ (tokens)
lib/features/    uma pasta por app do sistema
lib/shared/      widgets reutilizáveis
```

## Orçamento de performance

Medido no fio, não estimado. Os números abaixo são os bytes que **saíram do
servidor** para um navegador de verdade, lidos do traço de rede do Chrome e
conferidos com `curl` contra o endereço publicado — não são o build comprimido
aqui na máquina. A diferença entre as duas coisas não é pequena, e está
explicada logo abaixo. O tempo é derivado dos bytes num perfil declarado —
**4G lento: 1,6 Mbit/s de descida (≈200 KB/s) e 150 ms de ida e volta**, o
mesmo que o Lighthouse chama de "Slow 4G". Refazer a medição:

```
curl -s -o /dev/null -H 'Accept-Encoding: br' -w '%{size_download}\n' \
  https://portfolio-os-1rq.pages.dev/main.dart.wasm
```

O site tem duas "primeiras telas", e elas chegam em tempos muito diferentes:

| | de onde vem | bytes | tempo |
|---|---|---|---|
| Texto da moldura (HTML, sem JavaScript) | site | 5,4 KB | **~0,2 s** |
| Sistema utilizável — Chrome, Edge | site + CDN do Google | **2 117 KB** | ~10,6 s |
| Sistema utilizável — Safari, Firefox | site + CDN do Google | **3 102 KB** | ~15,5 s |

O texto da moldura chega no primeiro pacote porque é HTML servido direto — é
o motivo de ele existir, e é o que um visitante em rede ruim lê enquanto o
resto carrega. Ele dobrou de tamanho quando passou a trazer as duas línguas e
a prévia de compartilhamento; continua cabendo no primeiro pacote.

**Os cinco maiores, no caminho do Chrome:** o motor `skwasm.wasm` (1 179 KB,
do CDN do Google), `main.dart.wasm` (809 KB, do site), as três fontes Roboto
recortadas (77 KB), `icons/icon-192.png` (14 KB, que o Chrome busca no
carregamento por causa do manifesto) e `skwasm.js` (15 KB). Tudo o mais somado
não chega a 25 KB.

**Metade do peso não passa pelo site.** O carregador busca o motor em
`www.gstatic.com/flutter-canvaskit/<revisão>/`, e não na pasta `canvaskit/`
do build: 58% do que o Chrome baixa, 73% do que o Safari baixa. É byte que
não dá para comprimir melhor, hospedar mais perto nem cortar — e é a resposta
para a maior parte das perguntas de peso deste projeto.

**Quem pega qual alvo, e por quê.** `--wasm` compila os dois — `dart2wasm` +
`skwasm` e `dart2js` + `canvaskit` — e o carregador baixa **um só**: medido em
traço de rede, nunca os dois. A regra está no `flutter.js` e é mais estreita do
que parece: o alvo wasm exige WasmGC, e o renderizador `skwasm` exige, além
disso, WebGL e **motor de navegador Blink** — a lista do Flutter é
`{blink: true, gecko: false, webkit: false}`. Quer dizer: **Safari e Firefox
nunca pegam o alvo wasm**, nem os que suportam WasmGC. Eles baixam o canvaskit
genérico, que é o arquivo mais pesado da história toda (2 194 KB), e é por isso
que a linha deles é quase 1 MB mais cara. iPhone é Safari.

**A alavanca que existe nesse caminho, e o risco dela.** A lista de permissão
é configurável: `wasmAllowList: {webkit: true, gecko: true}` na chamada do
carregador colocaria Safari 18.2+ e Firefox 120+ no alvo wasm — 1 179 KB de
motor em vez de 2 194 KB, com o `main.dart.wasm` custando 33 KB a mais que o
`main.dart.js`. Economiza **~1 007 KB, um terço do caminho lento**, e quem não
tem WasmGC continua caindo no alvo antigo sozinho, por detecção de recurso. O
risco não é de compatibilidade, é de fidelidade: a lista do Flutter é política,
não capacidade, e eles não abençoaram o skwasm fora do Blink. Trocar sem olhar
pixel a pixel no Safari seria apostar a tela justo no público-alvo. Fica
decidido no dia em que houver um Safari de verdade para conferir.

**Dentro do que é nosso, não há o que cortar.** Um app padrão de
`flutter create`, compilado para o mesmo alvo JS, dá 428 KB comprimido. O nosso
dá 622 KB. A diferença — 194 KB — é tudo o que este projeto pesa acima do piso
do framework: 6% do caminho do Safari. Carregamento adiado dividiria esses
194 KB, e a primeira tela precisa de quase todos.

**A compressão do Cloudflare é mais fraca do que a daqui, e não dá para
mudar.** O `main.dart.wasm` sai daqui com 655 KB em `brotli -q 11` e chega ao
visitante com 809 KB: o Pages comprime sozinho, em nível baixo, e o nível não
se escolhe. Serviria mandar o arquivo já comprimido — **o Pages não serve
arquivo pré-comprimido**: `.br` irmão não é negociado, e a única saída seria
declarar `Content-Encoding: br` à mão no `_headers`, o que entrega brotli para
todo mundo sem negociar. Foram ~157 KB perseguidos e não existem. Está escrito
aqui para ninguém perseguir de novo.

**O que sai do deploy.** O build cospe 38 MB, e o visitante toca em 11
arquivos. A pasta `canvaskit/` inteira — 31 MB, dos quais 6 MB são tabelas de
símbolos de depuração — nunca é pedida, porque o motor vem do CDN. O CI a
apaga antes de publicar: o deploy é 6,6 MB. Se um dia o Flutter parar de usar
o CDN, quem reclama é a fumaça pós-deploy, que carrega o site publicado e cobra
o app montando.

Saiu também a dependência `cupertino_icons`, que não era usada: os glifos são
todos próprios. Foram 1,5 KB e nenhum pixel de diferença nos vinte retratos.

**A fonte, recortada.** O Roboto completo tem três mil caracteres e pesava
220 KB nos três pesos. Recortado para latim básico mais a acentuação do
português e a pontuação tipográfica que o conteúdo usa, pesa **67 KB** — 70%
a menos, e sobrou só 69 KB acima do melhor número que o projeto já teve. Não
foi preciso carregar sob demanda.

Os três pesos ficam: 300 é a hora grande da tela de bloqueio, 400 é o corpo,
500 são os rótulos. O 600 de alguns títulos resolve no 500, que é o vizinho
mais próximo declarado — não vale 22 KB para separar dois pesos que quase
ninguém distingue.

Recorte é aposta: uma letra de fora não some com aviso, vira quadradinho na
tela do visitante. `test/font_subset_test.dart` lê o `cmap` do arquivo e
confere que toda letra que o site escreve está lá dentro. Refazer o recorte:

```
python3 -m fontTools.subset Roboto-Regular.ttf   --unicodes='U+0020-007E,U+00A0,U+00AA,U+00B0,U+00B7,U+00BA,U+00C0-00FF,U+2013,U+2014,U+2018,U+2019,U+201C,U+201D,U+2022,U+2026'   --layout-features='*' --output-file=assets/fonts/Roboto-Regular.ttf
```

**O que não vale a pena, e por quê.** O motor é 58% do que o Chrome baixa e
73% do que o Safari baixa, e ele não é nosso. Carregamento adiado dividiria os
194 KB que são — e a primeira tela precisa de quase todos. Fonte não há mais o
que tirar: a tipografia é a pilha do sistema, e as duas fontes de ícone que
sobram somam 3,2 KB depois de sacudidas. Imagem quase não: o único PNG no
caminho crítico é o `icon-192` do manifesto, 14 KB que o Chrome busca sozinho
para a instalação — e é o preço de o site ser instalável.

O orçamento não está no CI de propósito. Isto é medição, não infraestrutura:
um número automatizado que ninguém lê vira mais um passo verde. O que **está**
no CI é o degrau seguinte, e por motivo oposto: `tool/smoke.dart` carrega o
endereço publicado num Chrome de verdade, depois do deploy, e cobra o que só
existe em execução — o service worker registrando e assumindo a página, a
preferência guardada voltando aplicada depois de um recarregar, o app montando
e desenhando, o HTML servido em inglês, e nenhum erro no console. Os dois
defeitos que este projeto já teve dessa classe estavam verdes em teste que lia
arquivo.

## Rodar

```
flutter pub get
flutter analyze --fatal-infos
flutter test
flutter run -d chrome
```

A fumaça precisa de um site de pé, então ela roda contra um endereço — o
publicado, ou um build local servido:

```
dart run tool/smoke.dart https://portfolio-os-1rq.pages.dev

flutter build web --release --wasm
(cd build/web && python3 -m http.server 8080) &
dart run tool/smoke.dart http://localhost:8080
```

Se ela reclamar de coisa que só acontece na sua máquina, desconfie do build
incremental antes de desconfiar do site: um `web_plugin_registrant.dart` velho
já deixou o `shared_preferences` de fora do pacote aqui, sem deixar de fora no
CI, que compila do zero. `flutter clean` resolve, e a fumaça confirma.
