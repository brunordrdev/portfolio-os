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

Medido, não estimado: os bytes são os do build comprimido em brotli, que é o
que o Cloudflare entrega. O tempo é derivado deles num perfil declarado —
**4G lento: 1,6 Mbit/s de descida (≈200 KB/s) e 150 ms de ida e volta**, o
mesmo que o Lighthouse chama de "Slow 4G". Refazer a medição:

```
flutter build web --release --wasm
brotli -c -q 11 build/web/main.dart.wasm | wc -c
```

O site tem duas "primeiras telas", e elas chegam em tempos muito diferentes:

| | antes | com `--wasm` | hoje |
|---|---|---|---|
| Texto da moldura (HTML, sem JavaScript) | 2,1 KB · **~0,2 s** | 2,1 KB · ~0,2 s | 2,1 KB · **~0,2 s** |
| Sistema utilizável, navegador moderno | 2 210 KB · ~11,2 s | 1 847 KB · ~9,4 s | **2 069 KB · ~10,3 s** |
| Sistema utilizável, navegador antigo | 2 812 KB · ~14,2 s | 2 211 KB · ~11,2 s | 2 433 KB · ~12,3 s |

O texto da moldura chega no primeiro pacote porque é HTML servido direto — é
o motivo de ele existir, e é o que um visitante em rede ruim lê enquanto o
resto carrega.

**O que mudou.** Passar a compilar com `--wasm` foi a única mudança que valeu
dinheiro. Ela produz os dois alvos — `dart2wasm` + `skwasm` para quem tem
WasmGC, `dart2js` + `canvaskit` para o resto — e o carregador escolhe: nada
quebra em navegador velho, e o moderno baixa 1,16 MB de motor em vez de 1,57
(variante Chromium) ou 2,18 (canvaskit genérico). Saiu também a dependência
`cupertino_icons`, que não era usada: os glifos são todos próprios. Foram 1,5 KB
e nenhum pixel de diferença nos vinte retratos.

**O que a fidelidade custou.** Embutir o Roboto para a pele Android são
220 KB em três pesos, e reverteu mais da metade do que o `--wasm` tinha
economizado. Vale saber que **todos pagam**: o Flutter web baixa as fontes do
manifesto antes do primeiro quadro, então quem fica no iOS — que usa a pilha
do sistema — carrega o Roboto do mesmo jeito. Se um dia essa conta apertar, o
caminho é carregar a fonte sob demanda, quando a pele Android for escolhida,
em vez de declará-la no manifesto.

**O que não vale a pena, e por quê.** O motor é 63% do que se baixa; o código
do app é 653 KB. Carregamento adiado dividiria o código do app, não o motor,
e a primeira tela precisa do motor inteiro — dividir o menor pedaço não
encurta a espera. Fonte não há: a tipografia é a pilha do sistema, e as duas
fontes de ícone que sobram somam 3,2 KB depois de sacudidas. Imagem também
não: os PNGs do manifesto não estão no caminho crítico.

Nada disso está no CI de propósito. Isto é medição, não infraestrutura: um
orçamento automatizado que ninguém lê vira mais um passo verde.

## Rodar

```
flutter pub get
flutter analyze --fatal-infos
flutter test
flutter run -d chrome
```
