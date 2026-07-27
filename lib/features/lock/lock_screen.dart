import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/platform/platform_scope.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/app_glyph.dart';
import '../../shared/widgets/home_indicator.dart';
import '../../shared/widgets/minute_clock.dart';
import '../../shared/widgets/status_bar.dart';
import '../../shared/widgets/wallpaper.dart';

/// Nomes em português, sem depender de dados de locale. Quando Ajustes
/// ganhar PT/EN, esta lista vira a versão portuguesa de uma tabela.
const List<String> _weekdays = [
  'segunda-feira',
  'terça-feira',
  'quarta-feira',
  'quinta-feira',
  'sexta-feira',
  'sábado',
  'domingo',
];

const List<String> _months = [
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
];

/// Pilha serifada do sistema. Sem fonte nova para baixar.
const List<String> _serif = ['Georgia', 'Times New Roman', 'Times', 'serif'];

String _dateLine(DateTime date) =>
    '${_weekdays[date.weekday - 1]}, ${date.day} de ${_months[date.month - 1]}';

/// A tela de bloqueio.
///
/// Destrava por três caminhos: arrastar para cima, tocar em qualquer lugar e
/// teclado. O arrasto é o gesto da casa, mas no desktop muita gente não tenta
/// arrastar — e teclado não é conveniência, é acessibilidade.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  /// Distância que já conta como intenção de abrir, mesmo devagar.
  static const double _dragDistance = 48;

  /// Velocidade de arremesso para cima que abre sem precisar da distância.
  static const double _flingVelocity = -180;

  // Não pode ser `const`: LogicalKeyboardKey redefine `==`.
  static final Set<LogicalKeyboardKey> _openKeys = {
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.arrowUp,
  };

  double _dragged = 0;
  bool _opening = false;

  void _open() {
    // Toque e arrasto podem chegar quase juntos; abrir duas vezes empilharia
    // rotas iguais.
    if (_opening) return;
    _opening = true;
    context.go(Routes.home);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (!_openKeys.contains(event.logicalKey)) return KeyEventResult.ignored;
    _open();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final spec = context.platform;
    final tokens = context.tokens;
    final now = clock.now();

    // O Scaffold existe pelo Material que ele traz: sem um Material acima,
    // todo Text herda o estilo de erro do framework — vermelho, monoespaçado
    // e sublinhado em amarelo duplo. O fundo é transparente porque quem
    // pinta aqui é o papel de parede.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Wallpaper(
        child: Focus(
          autofocus: true,
          onKeyEvent: _onKey,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _open,
            onVerticalDragStart: (_) => _dragged = 0,
            onVerticalDragUpdate: (details) =>
                _dragged += details.primaryDelta ?? 0,
            onVerticalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < _flingVelocity || _dragged < -_dragDistance) {
                _open();
              }
            },
            child: Column(
              children: [
                const StatusBar(),
                const SizedBox(height: 30),
                MinuteClock(
                  builder: (context, time) => Text(
                    clockText(time),
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontSize: 52,
                      fontWeight: FontWeight.w300,
                      fontFamilyFallback: spec.fontFallback,
                      height: 1.05,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_dateLine(now)} · Aracaju',
                  style: TextStyle(
                    color: tokens.textPrimary.withValues(alpha: 0.62),
                    fontSize: 13,
                    fontFamilyFallback: spec.fontFallback,
                  ),
                ),
                const Spacer(),
                Text(
                  'olá',
                  style: TextStyle(
                    color: tokens.accent,
                    fontSize: 44,
                    fontStyle: FontStyle.italic,
                    fontFamilyFallback: _serif,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'me chamo Bruno',
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    fontFamilyFallback: spec.fontFallback,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'desenvolvedor mobile',
                  style: TextStyle(
                    color: tokens.textPrimary.withValues(alpha: 0.58),
                    fontSize: 12,
                    fontFamilyFallback: spec.fontFallback,
                  ),
                ),
                const Spacer(),
                IconTheme(
                  data: IconThemeData(
                    color: tokens.textPrimary.withValues(alpha: 0.7),
                    size: 20,
                  ),
                  child: AppGlyph(AppGlyphs.arrowUp),
                ),
                const SizedBox(height: 6),
                Text(
                  'arraste para cima',
                  style: TextStyle(
                    color: tokens.textPrimary.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontFamilyFallback: spec.fontFallback,
                  ),
                ),
                const SizedBox(height: 18),
                const HomeIndicator(),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
