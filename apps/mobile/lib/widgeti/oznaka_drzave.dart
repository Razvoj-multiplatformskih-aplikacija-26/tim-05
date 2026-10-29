import 'package:flutter/material.dart';
import 'package:ui/ui.dart';


class OznakaDrzave extends StatelessWidget {
  const OznakaDrzave({super.key, required this.oznaka, this.velicina = 44, this.naBordo = false});

  final String oznaka;
  final double velicina;

  final bool naBordo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: velicina,
      height: velicina,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: naBordo ? Boje.bela : Boje.bordoSvetla, shape: BoxShape.circle),
      child: Text(
        oznaka,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontSize: velicina * 0.32,
          fontWeight: FontWeight.w700,
          color: naBordo ? Boje.bordo : Boje.naBordoSvetloj,
        ),
      ),
    );
  }
}
