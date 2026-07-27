import 'package:flutter/widgets.dart';

/// Uma borda lateral da tela.
enum ScreenEdge { left, right }

/// Identidade do selo na árvore.
///
/// O selo muda de forma entre as peles — cápsula com número de um lado,
/// ponto do outro — e sem uma chave só o teste teria de saber qual pele está
/// olhando para achá-lo. A chave é o que permite perguntar "o selo responde
/// ao toque?" sem perguntar antes "que selo é este?".
const Key appBadgeKey = ValueKey('appBadge');

/// As medidas da grade da tela inicial.
///
/// Vão juntas de propósito. Recuo, calha, vão entre fileiras, lado do
/// ladrilho e distância até o rótulo formam um ritmo, e ritmo se ajusta
/// inteiro: cinco membros soltos deixariam alguém apertar a calha sem
/// apertar o vão, que é como uma grade fica desafinada.
///
/// É aqui que a troca de pele deixa de ser só desenho e vira respiração — a
/// springboard do iOS é apertada, o launcher do Android é arejado.
@immutable
class GridMetrics {
  const GridMetrics({
    required this.topInset,
    required this.gutter,
    required this.rowGap,
    required this.tileSize,
    required this.labelGap,
  });

  /// Entre a barra de status e a primeira fileira.
  final double topInset;

  /// Da borda da tela até a primeira coluna.
  final double gutter;

  /// Entre uma fileira e a seguinte.
  final double rowGap;

  /// O lado do ladrilho.
  final double tileSize;

  /// Do pé do ladrilho até o rótulo.
  final double labelGap;
}

/// Como a página que sai se transforma enquanto o dedo arrasta de volta.
///
/// É descrição, não desenho: a costura diz o quanto encolher, arredondar e
/// deslocar, e a rota de movimento aplica. Assim a pele não precisa saber que
/// existe uma rota, e a rota não precisa saber em que plataforma está.
@immutable
class BackDrag {
  const BackDrag({
    required this.scale,
    required this.cornerRadius,
    required this.offset,
  });

  /// 1 é do tamanho da tela; menor encolhe em torno do centro.
  final double scale;

  /// Quanto os cantos arredondam enquanto ela encolhe.
  final double cornerRadius;

  /// Para onde ela escorrega — no Material, para longe da borda arrastada.
  final Offset offset;
}

/// Contrato único do que muda entre um sistema e outro.
///
/// Nenhuma tela deste projeto pergunta em qual plataforma está rodando: ela
/// pede à `PlatformSpec` ativa. Quando uma tela precisar de um comportamento
/// que difere entre os dois sistemas, o caminho é **acrescentar um membro
/// aqui** — nunca abrir uma exceção dentro da tela.
abstract class PlatformSpec {
  /// Uma spec não guarda estado: são só respostas. O construtor const deixa
  /// cada pele existir como uma instância única no programa inteiro.
  const PlatformSpec();

  // --- Identidade ---------------------------------------------------------

  /// Chave estável da plataforma, usada em testes e persistência.
  String get id;

  /// Nome mostrado ao visitante quando ele vira a chave.
  String get label;

  // --- Forma --------------------------------------------------------------

  /// Arredondamento do ladrilho de um ícone de lado `size`.
  BorderRadius iconRadius(double size);

  /// Arredondamento de painéis, cartões e folhas.
  double get surfaceRadius;

  // --- Movimento ----------------------------------------------------------

  /// Tempo de abertura de um app.
  Duration get openDuration;

  /// Tempo de fechamento de um app.
  Duration get closeDuration;

  /// Curva de abertura de um app.
  Curve get openCurve;

  /// Curva de fechamento de um app.
  Curve get closeCurve;

  // --- Tipografia ---------------------------------------------------------

  /// Pilha de fontes do sistema, na ordem de preferência.
  List<String> get fontFallback;

  /// Corpo do rótulo abaixo do ícone.
  double get appLabelSize;

  /// Peso do rótulo abaixo do ícone.
  FontWeight get appLabelWeight;

  // --- Moldura do sistema -------------------------------------------------

  /// O cromo da base: a peça que a plataforma desenha embaixo de tudo, com
  /// a folga que ela reserva em volta.
  ///
  /// Era um booleano, e o booleano mentia: "tem indicador de home" só faz
  /// pergunta sobre o iOS, e a resposta do Android era não por falta de
  /// vocabulário, não por não ter nada ali. As duas plataformas desenham
  /// alguma coisa na base; o que muda é a forma — e o quanto de tela elas
  /// tiram junto. O iOS reserva cerca de 34 na base; o Android, 16.
  ///
  /// A folga vem embutida porque peça e espaço são a mesma decisão: entregar
  /// só a peça foi o que deixou as telas chumbando o espaço em volta dela.
  Widget bottomChrome();

  /// Altura da barra de status no topo.
  double get systemChromeHeight;

  /// De quais bordas laterais o gesto de voltar pode nascer. É a única coisa
  /// que muda entre as plataformas nesse gesto: o resto — acompanhar o dedo,
  /// desistir antes da metade, assentar com a curva de fechar — é igual.
  Set<ScreenEdge> get backGestureEdges;

  // --- Componentes --------------------------------------------------------

  /// Envolve `child` com a resposta de toque da plataforma.
  Widget tappable({
    required Widget child,
    required VoidCallback onTap,
    BorderRadius? radius,
  });

  /// Chave liga/desliga da plataforma.
  Widget switchControl({
    required bool value,
    required ValueChanged<bool> onChanged,
  });

  /// Como esta plataforma marca um app que tem novidade.
  ///
  /// Não é o tamanho do selo: é o selo inteiro. O iOS conta quantas — uma
  /// cápsula com número —, e o Android só avisa que há — um ponto, sem
  /// número. Delegar a medida teria deixado a forma chumbada, e a forma é
  /// justamente o que muda.
  ///
  /// `tileSize` entra porque o selo se dimensiona em relação ao ladrilho que
  /// ele marca, e o ladrilho da doca não é o da grade.
  Widget appBadge({required int count, required double tileSize});

  /// O ritmo da grade da tela inicial.
  GridMetrics get grid;

  /// A doca: como os quatro canais de contato se apoiam no papel de parede.
  ///
  /// No iOS eles vivem dentro de um contêiner fosco; no Android ficam soltos
  /// sobre o papel de parede, sem cápsula e sem desfoque. É estilo de
  /// plataforma, e até este membro existir ele estava escrito dentro da tela
  /// inicial — que é o tipo de vazamento que a costura existe para impedir.
  Widget dock({required Widget child});

  /// A moldura física do aparelho, desenhada por cima de tudo.
  ///
  /// É o cromo que não é do sistema operacional e sim do vidro em volta
  /// dele: o canto arredondado da tela, a borda e o recorte da câmera. É a
  /// diferença que se vê antes de ler qualquer coisa — pílula centralizada
  /// de um lado, furo redondo do outro.
  Widget deviceFrame();

  /// Cabeçalho de uma tela de app, como sliver.
  ///
  /// É a diferença de plataforma mais visível do sistema: no iOS um título
  /// grande que encolhe ao rolar e um chevron de voltar; no Android a barra
  /// superior do Material, com o título alinhado à esquerda. As cores vêm de
  /// fora porque quem conhece os tokens é a tela, não a pele.
  Widget screenHeader({
    required String title,
    required VoidCallback onBack,
    required Color background,
    required Color foreground,
  });

  /// Uma seção de lista de ajustes.
  ///
  /// No iOS, um cartão embutido com o título acima em maiúsculas pequenas e
  /// separadores recuados; no Android, um cabeçalho no acento e linhas de
  /// borda a borda com divisores do Material. É a lista onde as duas
  /// linguagens de projeto mais se afastam.
  ///
  /// Ao contrário de `screenHeader`, as cores não vêm por parâmetro: são
  /// muitas, e os widgets devolvidos aqui leem os tokens do contexto.
  Widget settingsSection({required String header, required List<Widget> rows});

  /// Uma opção escolhível dentro de uma seção.
  ///
  /// No iOS a escolha é uma marca de conferido à direita; no Android é o
  /// botão de rádio do Material à esquerda. Cada plataforma tem uma resposta
  /// para "uma entre várias", e as duas estão aqui.
  Widget settingsOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  });

  /// Como a página que sai se transforma durante o arrasto de voltar.
  ///
  /// `progress` é 1 com o app aberto e 0 com ele fechado.
  ///
  /// Devolver nulo significa "sem transformação própria": a página segue
  /// encolhendo de volta para o ladrilho que a abriu, que é o movimento que o
  /// projeto já tinha. O Material 3 tem resposta própria — a página encolhe
  /// no lugar, arredonda e escorrega — e é ela que este membro descreve.
  BackDrag? backDrag({required double progress, required ScreenEdge edge});

  /// Rota de página com a transição da plataforma.
  Route<T> pageRoute<T>({
    required WidgetBuilder builder,
    required RouteSettings settings,
  });
}
