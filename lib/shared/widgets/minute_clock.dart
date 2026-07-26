import 'dart:async';

import 'package:flutter/widgets.dart';

/// Hora do relógio, com dois dígitos em cada lado.
String clockText(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';

/// Reconstrói o filho na virada de cada minuto, com a hora real.
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
    _now = DateTime.now();
    _scheduleNextTick();
  }

  void _scheduleNextTick() {
    final now = DateTime.now();
    final nextMinute = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    ).add(const Duration(minutes: 1));

    _timer = Timer(nextMinute.difference(now), () {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
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
