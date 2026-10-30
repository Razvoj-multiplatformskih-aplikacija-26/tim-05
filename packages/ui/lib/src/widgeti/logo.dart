import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tema/tema.dart';

class Logo extends StatelessWidget {
  const Logo({super.key, this.velicina = 42});

  final double velicina;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: velicina,
        height: velicina,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Boje.bela.withValues(alpha: 0.85), width: 2),
        ),
        child: Transform.rotate(
          angle: math.pi / 4,
          child: Icon(Icons.flight, color: Boje.zuta, size: velicina * 0.58),
        ),
      ),
    );
  }
}