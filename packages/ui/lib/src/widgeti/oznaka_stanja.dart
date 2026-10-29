import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../tekst/format.dart';
import '../tema/tema.dart';

class OznakaStanja extends StatelessWidget {
  const OznakaStanja({super.key, required this.stanje});

  final StanjePrijave stanje;

  @override
  Widget build(BuildContext context) {
    final boje = bojeStanja(stanje);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: boje.pozadina, borderRadius: BorderRadius.circular(10)),
      child: Text(
        nazivStanja(stanje),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: boje.tekst, letterSpacing: 0),
      ),
    );
  }
}
