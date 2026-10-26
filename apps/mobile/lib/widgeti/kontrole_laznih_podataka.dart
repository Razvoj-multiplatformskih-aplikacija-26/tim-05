import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../podaci/lazna_baza.dart';
import '../tema/tema.dart';
import '../zavisnosti.dart';

enum _Akcija { greska, prazno, ucitaj }


class KontroleLaznihPodataka extends StatelessWidget {
  const KontroleLaznihPodataka({super.key, required this.naPrazanOdgovor, required this.naPonovnoUcitavanje});

  final void Function(LaznaBaza baza) naPrazanOdgovor;

  final VoidCallback naPonovnoUcitavanje;

  void _javi(BuildContext context, String poruka) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(poruka)));

  @override
  Widget build(BuildContext context) {
    final baza = context.read<ZavisnostiAplikacije>().laznaBaza;
    if (baza == null) return const SizedBox.shrink();
    return PopupMenuButton<_Akcija>(
      tooltip: 'Lazni podaci',
      icon: const Icon(Icons.bug_report_outlined, color: Boje.bela),
      onSelected: (akcija) {
        switch (akcija) {
          case _Akcija.greska:
            baza.neuspesniZahtevi = 1;
            _javi(context, 'Sledeci zahtev nece uspeti.');
          case _Akcija.prazno:
            naPrazanOdgovor(baza);
            _javi(context, 'Sledeci odgovor bice prazan.');
          case _Akcija.ucitaj:
            naPonovnoUcitavanje();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _Akcija.greska,
          child: ListTile(leading: Icon(Icons.cloud_off_outlined), title: Text('Greska sledeceg zahteva')),
        ),
        PopupMenuItem(
          value: _Akcija.prazno,
          child: ListTile(leading: Icon(Icons.inbox_outlined), title: Text('Prazan sledeci odgovor')),
        ),
        PopupMenuItem(
          value: _Akcija.ucitaj,
          child: ListTile(leading: Icon(Icons.refresh), title: Text('Ponovo ucitaj')),
        ),
      ],
    );
  }
}
