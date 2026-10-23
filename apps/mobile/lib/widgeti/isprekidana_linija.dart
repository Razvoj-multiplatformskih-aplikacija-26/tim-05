import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tema/tema.dart';

class IsprekidanaLinija extends StatelessWidget {
  const IsprekidanaLinija({super.key}) : uspravna = false, duzina = double.infinity;

  const IsprekidanaLinija.uspravna({super.key, required this.duzina}) : uspravna = true;

  final bool uspravna;
  final double duzina;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: uspravna ? 1.5 : duzina,
      height: uspravna ? duzina : 1.5,
      child: CustomPaint(painter: _Crtice(uspravna: uspravna)),
    );
  }
}

class _Crtice extends CustomPainter {
  const _Crtice({required this.uspravna});

  final bool uspravna;

  static const _crtica = 5.0;
  static const _razmak = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final cetkica = Paint()
      ..color = Boje.ivica
      ..strokeWidth = 1.5;
    final ukupno = uspravna ? size.height : size.width;

    for (var pocetak = 0.0; pocetak < ukupno; pocetak += _crtica + _razmak) {
      final kraj = math.min(pocetak + _crtica, ukupno);
      if (uspravna) {
        canvas.drawLine(Offset(size.width / 2, pocetak), Offset(size.width / 2, kraj), cetkica);
      } else {
        canvas.drawLine(Offset(pocetak, size.height / 2), Offset(kraj, size.height / 2), cetkica);
      }
    }
  }

  @override
  bool shouldRepaint(_Crtice stara) => stara.uspravna != uspravna;
}
