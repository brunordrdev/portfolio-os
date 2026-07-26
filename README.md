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

## Rodar

```
flutter pub get
flutter analyze --fatal-infos
flutter test
flutter run -d chrome
```
