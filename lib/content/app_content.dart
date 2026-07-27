import 'package:flutter/widgets.dart';

/// Todo o texto do site, nos dois idiomas.
///
/// Nenhuma string de tela mora em widget: uma frase escrita dentro de um
/// widget existe num idioma só, e a troca de idioma vira uma caçada. Aqui é
/// o mesmo princípio dos tokens de cor e da `PlatformSpec` — o que muda
/// conforme o visitante fica atrás de uma costura, num lugar só.
///
/// O português não é tradução do inglês: é a mesma coisa escrita de novo.

/// Um bloco de texto de uma tela de conteúdo.
sealed class ContentBlock {
  const ContentBlock(this.text);

  final String text;
}

/// Parágrafo corrido.
final class Prose extends ContentBlock {
  const Prose(super.text);
}

/// Cabeça de um item: cargo e empresa, ou nome de projeto.
final class ItemTitle extends ContentBlock {
  const ItemTitle(super.text);
}

/// Linha de apoio de um item: período e tecnologias.
final class ItemMeta extends ContentBlock {
  const ItemMeta(super.text);
}

/// Os nomes dos apps, na grade e na doca.
@immutable
class AppNames {
  const AppNames({
    required this.pen,
    required this.projects,
    required this.about,
    required this.experience,
    required this.resume,
    required this.settings,
    required this.phone,
    required this.email,
    required this.linkedin,
    required this.github,
  });

  final String pen;
  final String projects;
  final String about;
  final String experience;
  final String resume;
  final String settings;
  final String phone;
  final String email;
  final String linkedin;
  final String github;
}

/// O texto da tela de bloqueio.
@immutable
class LockText {
  const LockText({
    required this.greeting,
    required this.name,
    required this.role,
    required this.hint,
    required this.weekdays,
    required this.months,
    required this.dateTemplate,
  });

  final String greeting;
  final String name;
  final String role;
  final String hint;

  /// Segunda a domingo, na ordem de `DateTime.weekday`.
  final List<String> weekdays;
  final List<String> months;

  /// A ordem das partes muda de idioma: em português o dia vem antes do mês,
  /// em inglês vem depois. Por isso é molde, e não concatenação.
  final String dateTemplate;

  String dateLine(DateTime date) => dateTemplate
      .replaceFirst('{weekday}', weekdays[date.weekday - 1])
      .replaceFirst('{day}', '${date.day}')
      .replaceFirst('{month}', months[date.month - 1]);
}

@immutable
class AppContent {
  const AppContent({
    required this.language,
    required this.apps,
    required this.lock,
    required this.about,
    required this.experience,
    required this.resume,
    required this.projects,
  });

  /// Código do idioma, para teste e depuração.
  final String language;

  final AppNames apps;
  final LockText lock;

  final List<ContentBlock> about;
  final List<ContentBlock> experience;
  final List<ContentBlock> resume;

  /// Escrito e pronto. A tela de Projetos é de outro fim de semana.
  final List<ContentBlock> projects;

  /// Abre no idioma do visitante, como abre na plataforma e no tema dele.
  /// Qualquer variante de português abre em português; o resto, em inglês.
  static AppContent forLocale(Locale locale) =>
      locale.languageCode.toLowerCase() == 'pt' ? pt : en;

  // ═══════════════════════════════════════════════════════════════════════
  // Português
  // ═══════════════════════════════════════════════════════════════════════

  static const AppContent pt = AppContent(
    language: 'pt',
    apps: AppNames(
      // Nome próprio do produto: não se traduz.
      pen: 'Minha Caneta',
      projects: 'Projetos',
      about: 'Sobre',
      experience: 'Experiência',
      resume: 'Currículo',
      settings: 'Ajustes',
      phone: 'Telefone',
      email: 'Email',
      linkedin: 'LinkedIn',
      github: 'GitHub',
    ),
    lock: LockText(
      greeting: 'olá',
      name: 'me chamo Bruno',
      role: 'desenvolvedor mobile',
      hint: 'arraste para cima',
      weekdays: [
        'segunda-feira',
        'terça-feira',
        'quarta-feira',
        'quinta-feira',
        'sexta-feira',
        'sábado',
        'domingo',
      ],
      months: [
        'janeiro',
        'fevereiro',
        'março',
        'abril',
        'maio',
        'junho',
        'julho',
        'agosto',
        'setembro',
        'outubro',
        'novembro',
        'dezembro',
      ],
      dateTemplate: '{weekday}, {day} de {month} · Aracaju',
    ),
    about: [
      Prose(
        'Sou o único desenvolvedor de quatro aplicativos em produção usados '
        'por mais de cem empresas no Brasil — três em Flutter, um em Kotlin '
        'nativo para gestão de armazém. Os backends em Java e SQL Server por '
        'trás deles também são meus. Funcionalidade, publicação na loja, '
        'monitoramento de falha e o bug de produção na pior hora possível: '
        'tudo meu.',
      ),
      Prose(
        'Cheguei aqui de lado. Entrei na empresa em 2023 no suporte técnico, '
        'atendendo as empresas que usavam nosso software. Dois anos ouvindo '
        'exatamente como as coisas quebram foram melhor treino que qualquer '
        'curso — a gente aprende um domínio rápido quando alguém precisa dele '
        'funcionando antes da loja abrir. Passei para mobile no começo de '
        '2025.',
      ),
      Prose(
        'Ser o único desenvolvedor me ensinou mais sobre produção do que um '
        'time teria ensinado, principalmente porque não havia para quem '
        'escalar. Também me mostrou o que eu não sei, que é a metade mais '
        'útil.',
      ),
      Prose(
        'Fora do trabalho, publico meus próprios produtos e curso engenharia '
        'de software. Moro em Aracaju, no litoral do Nordeste, e estou aberto '
        'a trabalho remoto com times internacionais.',
      ),
    ],
    experience: [
      ItemTitle('Alltomatize Sistemas — Desenvolvedor Mobile'),
      ItemMeta(
        'jan 2025 — hoje · Flutter, Dart, Kotlin, Java, SQL Server, Firebase',
      ),
      Prose(
        'Cuido de todo o portfólio mobile da empresa: quatro aplicativos em '
        'produção, usados por mais de cem clientes empresariais. Eles formam '
        'uma cadeia — o app de armazém diz o que existe, os de força de vendas '
        'vendem, o de logística entrega. Quebra um elo e o próximo continua '
        'operando em cima de uma mentira.',
      ),
      Prose(
        'O de força de vendas é o que tira meu sono. Ele é offline-first: o '
        'pedido nasce e vive no SQLite do celular do vendedor até sincronizar. '
        'Ou seja, é ao mesmo tempo onde a receita acontece e o único lugar '
        'onde o dado existe antes do sync. Se o de armazém cai, um processo '
        'para. Se esse cai na hora errada, o pedido se perde.',
      ),
      Prose(
        'A coisa mais difícil que resolvi lá foi o saldo de desconto do '
        'vendedor — dinheiro real, que sai da comissão dele. Ele divergia em '
        'silêncio: sem crash, sem exceção, sem log, e nunca reproduzia em '
        'bancada. Só disparava em combinações — duplicar um pedido, trocar o '
        'cliente, excluir; misturar desconto e acréscimo no mesmo pedido.',
      ),
      Prose(
        'O conserto não foi achar a fórmula errada. A matemática estava certa. '
        'O modelo de dados é que tinha jogado fora a informação de que a '
        'matemática precisava: o pedido guardava só o preço líquido, então '
        'depois do fato não dava para distinguir desconto de condição de '
        'pagamento, desconto manual e preço de política comercial. Parei de '
        'recalcular o saldo a cada ponto de entrada e passei a persistir a '
        'origem do preço. Quatro bugs distintos morreram de uma vez, porque '
        'sempre tinham sido o mesmo bug.',
      ),
      Prose(
        'Também configurei o Firebase Crashlytics direito, incluindo falha na '
        'inicialização a frio — a que ninguém vê até um cliente ligar; '
        'refatorei as funções centrais de SQL Server no módulo de contas a '
        'receber do produto principal; e construí uma ferramenta interna de '
        'triagem para o suporte, com busca por palavra-chave e pontuação IDF, '
        'que eles usam até hoje.',
      ),
      ItemTitle('Alltomatize Sistemas — Analista de Suporte Técnico'),
      ItemMeta('mai 2023 — jan 2025'),
      Prose(
        'Primeiro contato das empresas que rodavam nosso software. Aprendi a '
        'regra de negócio do jeito rápido: explicada por quem precisava dela '
        'funcionando na hora. Promovido a desenvolvedor mobile no começo de '
        '2025.',
      ),
    ],
    resume: [Prose('Engenharia de Software, Cruzeiro do Sul — 2026 a 2030.')],
    projects: [
      ItemTitle('Minha Caneta'),
      ItemMeta('2026 · Flutter, Riverpod, Supabase, RevenueCat, Cloudflare R2'),
      Prose(
        'Aplicativo iOS para quem usa caneta emagrecedora — GLP-1, tipo '
        'Mounjaro e Ozempic — registrar doses, acompanhar peso e seguir a '
        'evolução do protocolo. Feito para o mercado brasileiro por quem faz o '
        'mesmo tratamento.',
      ),
      Prose('Em análise na App Store, com preço localizado em quatro lojas.'),
      ItemTitle('Operon'),
      ItemMeta('2026 · Flutter Web, Go, PostgreSQL'),
      Prose(
        'Software B2B para logística de entrega e montagem, feito para uma '
        'rede de móveis com onze filiais.',
      ),
      Prose(
        'Antes dele, a operação inteira rodava no WhatsApp: pedido repassado '
        'por mensagem para entregador e montador, e comprovação de entrega era '
        'foto de assinatura no chat. Nada era pesquisável, nada era auditável, '
        'e nada sobrevivia a um celular perdido.',
      ),
    ],
  );

  // ═══════════════════════════════════════════════════════════════════════
  // English
  // ═══════════════════════════════════════════════════════════════════════

  static const AppContent en = AppContent(
    language: 'en',
    apps: AppNames(
      pen: 'Minha Caneta',
      projects: 'Projects',
      about: 'About',
      experience: 'Experience',
      resume: 'Résumé',
      settings: 'Settings',
      phone: 'Phone',
      email: 'Email',
      linkedin: 'LinkedIn',
      github: 'GitHub',
    ),
    lock: LockText(
      greeting: 'hello',
      name: 'my name is Bruno',
      role: 'mobile developer',
      hint: 'swipe up',
      weekdays: [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ],
      months: [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ],
      dateTemplate: '{weekday}, {month} {day} · Aracaju',
    ),
    about: [
      Prose(
        "I'm the only developer on four production apps used by more than a "
        'hundred companies across Brazil — three in Flutter, one in native '
        'Kotlin for warehouse management. I maintain the Java and SQL Server '
        'backends behind them too. Features, releases, crash monitoring, and '
        'the production bug at the worst possible hour: all mine.',
      ),
      Prose(
        'I got here sideways. I joined the company in 2023 on technical '
        'support, answering the businesses that ran our software. Two years of '
        'hearing exactly how things break turned out to be better training '
        'than any course — you learn a domain fast when someone needs it '
        'working before their store opens. I moved to mobile in early 2025.',
      ),
      Prose(
        'Being the only developer taught me more about production than a team '
        'would have, mostly because there was nobody to escalate to. It also '
        "taught me what I don't know, which is the more useful half.",
      ),
      Prose(
        "Outside work I ship my own products, and I'm studying software "
        "engineering. I live in Aracaju, on the northeast coast of Brazil, and "
        "I'm open to remote work with international teams.",
      ),
    ],
    experience: [
      ItemTitle('Alltomatize Sistemas — Mobile Developer'),
      ItemMeta(
        'Jan 2025 — present · Flutter, Dart, Kotlin, Java, SQL Server, '
        'Firebase',
      ),
      Prose(
        "I own the company's entire mobile portfolio: four apps in production, "
        'used by more than a hundred business clients. They form a chain — the '
        'warehouse app says what exists, the sales-force apps sell it, the '
        'logistics app delivers it. Break one link and the next one keeps '
        'operating on a lie.',
      ),
      Prose(
        "The sales-force app is the one that keeps me up. It's offline-first: "
        'an order is born and lives in SQLite on the salesperson\'s phone until '
        "it syncs. So it's both where the revenue happens and the only place "
        'the data exists before syncing. If the warehouse app goes down, a '
        'process stops. If this one goes down at the wrong moment, an order is '
        'gone.',
      ),
      Prose(
        "The hardest thing I've fixed there was the seller's discount balance "
        '— real money, taken out of their own commission. It was drifting, '
        'silently: no crash, no exception, no log, and it never reproduced on '
        'the bench. It only fired on combinations — duplicate an order, swap '
        'the client, delete it; mix a discount and a surcharge on the same '
        'order.',
      ),
      Prose(
        "The fix wasn't finding the wrong formula. The math was right. The "
        'data model had thrown away the information the math needed: orders '
        'stored only the net price, so after the fact there was no way to tell '
        'a payment-term discount from a manual one from the commercial policy. '
        'I stopped recalculating the balance at every entry point and started '
        'persisting where the price came from. Four separate bugs closed at '
        'once, because they had always been the same bug.',
      ),
      Prose(
        'I also set up Firebase Crashlytics properly, including cold-start '
        'crashes — the ones nobody sees until a client calls; refactored the '
        'core SQL Server functions in the accounts-receivable module of the '
        'main product; and built an internal triage tool for the support team, '
        'using keyword search with IDF scoring, which they still use.',
      ),
      ItemTitle('Alltomatize Sistemas — Technical Support Analyst'),
      ItemMeta('May 2023 — Jan 2025'),
      Prose(
        'First point of contact for the companies running our software. I '
        'learned the business rules the fast way: explained to me by people '
        'who needed them working immediately. Promoted to mobile development '
        'in early 2025.',
      ),
    ],
    resume: [Prose('Software Engineering, Cruzeiro do Sul — 2026 to 2030.')],
    projects: [
      ItemTitle('Minha Caneta'),
      ItemMeta('2026 · Flutter, Riverpod, Supabase, RevenueCat, Cloudflare R2'),
      Prose(
        'An iOS app for people on GLP-1 weight-loss medication — Mounjaro, '
        'Ozempic and the like — to log doses, track weight and follow their '
        'protocol over time. Built for the Brazilian market by someone on the '
        'same treatment.',
      ),
      Prose(
        'Currently in App Store review, with localized pricing across four '
        'storefronts.',
      ),
      ItemTitle('Operon'),
      ItemMeta('2026 · Flutter Web, Go, PostgreSQL'),
      Prose(
        'B2B software for delivery and assembly logistics, built for a '
        'furniture retail chain running eleven branches.',
      ),
      Prose(
        'Before it, the whole operation ran on WhatsApp: orders forwarded to '
        'drivers and assemblers by message, and proof of delivery was a photo '
        'of a signature in a chat. Nothing was searchable, nothing was '
        'auditable, and nothing survived a phone being lost.',
      ),
    ],
  );
}

/// Leva o conteúdo do idioma em uso para baixo na árvore.
class ContentScope extends InheritedWidget {
  const ContentScope({super.key, required this.content, required super.child});

  final AppContent content;

  static AppContent of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ContentScope>();
    assert(scope != null, 'Nenhum ContentScope acima deste widget.');
    return scope!.content;
  }

  @override
  bool updateShouldNotify(ContentScope oldWidget) =>
      content != oldWidget.content;
}

extension ContentScopeExtension on BuildContext {
  /// O texto do idioma em uso.
  AppContent get content => ContentScope.of(this);
}
