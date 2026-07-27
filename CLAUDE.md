# Regras deste repositório

Portfólio em forma de sistema operacional móvel. Flutter web, publicado em
brunordrdev.com. A tese do projeto é a troca **iOS ↔ Android**: o site demonstra
desenvolvimento cross-platform fazendo isso consigo mesmo.

Comentários em português. Identificadores em inglês.

---

## Regras duras — não violar

1. **Nenhuma tela contém `if (Platform.isIOS)` ou equivalente.**
   Tudo que muda entre plataformas vive atrás de `PlatformSpec`
   (`lib/core/platform/platform_spec.dart`). Se uma tela precisar saber a
   plataforma, **acrescente um membro à interface** — nunca uma exceção na tela.

2. **Um único ponto de troca.** É `PlatformController` em
   `lib/core/platform/platform_scope.dart`. Se virar a chave exigir encostar em
   código de tela, a costura vazou: conserte na costura.

3. **Nenhum hexadecimal solto em widget.** Cor entra por `AppTokens`
   (`lib/core/theme/tokens.dart`). Escrever `Color(0xFF...)` numa tela quebra o
   modo claro.

4. **Mudanças em `android_spec.dart` não podem exigir mudança em tela.**
   Se exigirem, o problema está na interface.

5. **Nada decorativo.** Se parece tocável, funciona. Sem bolinha de página falsa,
   sem bateria estática, sem notificação inventada, sem ícone que abre erro.

6. **Badge em um ícone só** — o projeto mais novo. Vermelho só significa alguma
   coisa se for escasso.

7. **Texto sobre papel de parede usa `onWallpaper` ou `onWallpaperMuted`,
   nunca `onTile`.** `onTile` é a cor do que é desenhado *dentro* de um
   ladrilho — o glifo e o número do selo. Os dois papéis pedem cores opostas
   no tema claro: o ladrilho é colorido e quer texto branco em cima; o papel
   de parede é claro e quer texto escuro. Um token só para os dois deixou os
   rótulos da tela inicial em 1,3:1 desde o primeiro commit, invisíveis no
   tema claro, sem nenhum teste reclamar.

   O piso é **4,5:1 para todo texto, sobre o papel de parede e sobre fundo
   liso, nos quatro modos**, medido no pixel real atrás de cada elemento —
   não na cor do token. Texto com alfa vale pelo que sobra depois de misturar
   com o fundo, e é por isso que aqui não se apaga texto com opacidade: quem
   precisa ser mais fraco usa `onWallpaperMuted`, que é cor própria e passa
   no piso. `test/contrast_test.dart` cobra isso e falha o CI.

   **O que a medição não vê.** Sobre o papel de parede ela lê o pixel de
   verdade, e é exata. Sobre fundo liso ela lê a cor do `Scaffold`, e uma
   tela pode desenhar um cartão por cima — no cartão embutido do iOS o fundo
   real é `surface`, não `background`. No tema claro isso a torna pessimista,
   que é seguro; no escuro, otimista, porque `surface` é mais claro que o
   fundo.

   **Gatilho:** enquanto a pior medição no escuro estiver em 5:1 ou acima, a
   folga cobre a diferença e a aproximação se paga. Se cair abaixo, a medição
   precisa passar a ler o fundo real de cada texto. O próprio teste cobra
   esse piso — não é um lembrete, é uma asserção. Hoje a pior está em 8,46:1.

8. **Acento tem dois papéis.** `accent` é a identidade e é seguro sobre o
   papel de parede — é o "olá" da tela de bloqueio. `accentOnSurface` é
   acento como texto sobre fundo liso. No tema escuro os dois são o mesmo
   valor; no claro, o segundo é mais escuro, porque o acento da identidade dá
   4,10:1 sobre a página e o piso é 4,5.

   Cabeçalho de seção não usa acento: usa `onWallpaperMuted`. Acento aponta
   para o que abre alguma coisa, e não para o que só organiza a lista.

---

## Estrutura

```
lib/app/         raiz e rotas (uma URL por app)
lib/core/        platform/ (a costura) e theme/ (tokens)
lib/features/    uma pasta por app do sistema
lib/shared/      widgets reutilizáveis
```

## Navegação

Grade de 6 = conteúdo (Minha Caneta, Projetos, Sobre, Experiência, Currículo,
Ajustes). Dock de 4 = contato (Telefone/WhatsApp, Email, LinkedIn, GitHub).
Uma página. Sem pastas na v1.

## Visual

Estilo A (escuro quente, acento âmbar `#E8A94E`) é a identidade e o padrão.
Estilo B é o modo claro. Abre conforme a preferência do sistema do visitante.
Ícones: família traçada própria, `viewBox` 24×24, traço 1.7, pontas arredondadas.
**Não clonar ícones da Apple.**

---

## Escopo da v1 — não expandir

**Entra:** tela de bloqueio com um gesto · tela inicial · transições com a curva
da plataforma · gesto de voltar nativo · URL por app · estado preservado ·
Ajustes (idioma PT/EN, tema) · PWA instalável · orçamento de performance ·
texto indexável na moldura web.

**Estacionado — não implementar mesmo se parecer fácil:** pele Android lapidada,
pastas, espanhol, gaveta de apps, central de notificações, widgets, múltiplas
páginas, backend na casca.

**Estacionado com gatilho — barra de busca do Android.** A pele Android pede
uma, e ela é fácil de desenhar. Só entra no dia em que buscar de verdade no
conteúdo do site: busca que não busca é enfeite, e enfeite é proibido pela
regra 5. O gatilho é existir conteúdo que valha procurar — hoje são seis telas
e uma delas é a própria busca.

**Estacionado — ícones da barra de status em Material Symbols.** Wifi e
bateria são desenhados pelo conjunto traçado próprio nas duas peles. Trocá-los
pelos do Material no Android daria pouca fidelidade e traria dependência de
fonte de ícone justo depois de a fonte de texto ter sido recortada para caber
no orçamento. O caminho barato, no dia em que valer: desenhar as versões
Android no próprio conjunto — mesmo `viewBox`, mesmo traço — e escolher entre
elas por um membro da costura. Sem dependência nova.

**Estacionado com gatilho:** o service worker é o do Flutter, e o próprio
Flutter avisa no build que ele está **depreciado e sai numa versão futura**.
Quando sair, o PWA deixa de ser instalável no Chrome sem que nada quebre em
teste — e será preciso escrever um próprio, com um `fetch` que responda
offline. O gatilho é o dia em que o aviso virar remoção: se o build parar de
gerar `flutter_service_worker.js`, é isso.

**Gatilho acionado — a divisão do acento aconteceu.** Ficava estacionado aqui
que `accent` se dividiria se algum dia fosse preciso acento vivo sobre
superfície no tema claro. Foi: a tela de Ajustes trouxe o link do repositório,
e o acento da identidade dá 4,10:1 sobre a página clara. Hoje são `accent` e
`accentOnSurface` — ver a regra dura nº 8.

Sugestões de escopo novo vão para a seção de estacionamento, não para o código.

## Backend

A casca não tem backend, de propósito. Banco entra só com o ambiente de
demonstração, e pertence ao app demonstrado — não ao portfólio.
