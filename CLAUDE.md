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

Sugestões de escopo novo vão para a seção de estacionamento, não para o código.

## Backend

A casca não tem backend, de propósito. Banco entra só com o ambiente de
demonstração, e pertence ao app demonstrado — não ao portfólio.
