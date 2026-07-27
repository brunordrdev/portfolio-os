import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';

/// Hora do relógio, com dois dígitos em cada lado.
String clockText(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';

/// Reconstrói o filho na virada de cada minuto, com a hora real.
///
/// A hora vem de `clock.now()` e não de `DateTime.now()`. Em produção dá na
/// mesma — é o relógio do sistema. Em teste, deixa congelar o tempo: sem
/// isso um retrato de tela guarda a hora em que foi tirado e reprova sozinho
/// no minuto seguinte.
///
/// O timer acerta o passo com o relógio em vez de disparar a cada minuto
/// corrido: assim o número muda quando o minuto muda, e não meio minuto
/// depois. Um timer por segundo seria trabalho jogado fora — o mostrador
/// não tem segundos.
class MinuteClock extends StatefulWidget {
  const MinuteClock({super.key, required this.builder});

  final Widget Function(BuildContext context, DateTime now) builder;

  @override
  State<MinuteClock> createState() => _MinuteClockState();
}

class _MinuteClockState extends State<MinuteClock> {
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = clock.now();
    _scheduleNextTick();
  }

  void _scheduleNextTick() {
    final now = clock.now();
    final nextMinute = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    ).add(const Duration(minutes: 1));

    _timer = Timer(nextMinute.difference(now), () {
      if (!mounted) return;
      setState(() => _now = clock.now());
      _scheduleNextTick();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _now);
}
