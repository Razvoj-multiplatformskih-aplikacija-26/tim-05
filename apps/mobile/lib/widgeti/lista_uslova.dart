import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:use_cases/use_cases.dart';

import '../tekst/format.dart';
import '../tema/tema.dart';

class ListaUslova extends StatelessWidget {
  const ListaUslova({super.key, required this.ponuda, required this.student, required this.uslovi});

  final Ponuda ponuda;
  final Student student;
  final ProveraUslova uslovi;

  @override
  Widget build(BuildContext context) {
    final nivo = student.nivoZa(ponuda.zahtevJezika.jezik);
    final aktivno = uslovi.brojAktivnih;
    final rokOtvoren = uslovi.rok;

    return Card(
      child: Column(
        children: [
          _Uslov(
            ikona: Icons.translate,
            naslov: 'Jezik',
            vrednost: '${opisZahtevaJezika(ponuda.zahtevJezika)} ili više',
            ispunjen: uslovi.jezik,
            oznaka: nivo == null ? 'Nemate' : 'Imate ${nivo.oznaka}',
          ),
          const Divider(indent: 14, endIndent: 14),
          _Uslov(
            ikona: Icons.bar_chart,
            naslov: 'Minimalni prosek',
            vrednost: formatProsek(ponuda.minimalniProsek),
            ispunjen: uslovi.prosek,
            oznaka: 'Imate ${formatProsek(student.prosek)}',
          ),
          const Divider(indent: 14, endIndent: 14),
          _Uslov(
            ikona: Icons.event_outlined,
            naslov: 'Rok za prijavu',
            vrednost: formatDatum(ponuda.rok),
            ispunjen: rokOtvoren,
            oznaka: rokOtvoren ? 'Otvoreno' : 'Isteklo',
          ),
          const Divider(indent: 14, endIndent: 14),
          _Uslov(
            ikona: Icons.assignment_outlined,
            naslov: 'Aktivne prijave',
            vrednost: '$aktivno od najviše $najviseAktivnihPrijava',
            ispunjen: uslovi.mestoZaPrijavu,
            oznaka: '$aktivno/$najviseAktivnihPrijava',
          ),
        ],
      ),
    );
  }
}

class _Uslov extends StatelessWidget {
  const _Uslov({
    required this.ikona,
    required this.naslov,
    required this.vrednost,
    required this.ispunjen,
    required this.oznaka,
  });

  final IconData ikona;
  final String naslov;
  final String vrednost;
  final bool ispunjen;
  final String oznaka;

  @override
  Widget build(BuildContext context) {
    final tekst = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: Boje.bordoSvetla, borderRadius: BorderRadius.circular(10)),
              child: Icon(ikona, color: Boje.bordo, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(naslov, style: tekst.bodySmall?.copyWith(color: Boje.sporedniTekst)),
                  Text(vrednost, style: tekst.titleSmall),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ispunjen ? Boje.uspehPozadina : Boje.greskaPozadina,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${ispunjen ? '✓' : '✗'} $oznaka',
                style: tekst.labelSmall?.copyWith(color: ispunjen ? Boje.uspeh : Boje.greska),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProveraPreSlanja extends StatelessWidget {
  const ProveraPreSlanja({super.key, required this.ponuda, required this.student, required this.uslovi});

  final Ponuda ponuda;
  final Student student;
  final ProveraUslova uslovi;

  @override
  Widget build(BuildContext context) {
    final zahtev = ponuda.zahtevJezika;
    final nivo = student.nivoZa(zahtev.jezik);
    final imaProsekUslov = uslovi.prosek;
    final imaJezikUslov = uslovi.jezik;
    final aktivno = uslovi.brojAktivnih;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Boje.bela,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Boje.ivica),
      ),
      child: Column(
        children: [
          _Pravilo(
            ispunjeno: imaProsekUslov,
            tekst:
                'Prosek ${formatProsek(student.prosek)} ${imaProsekUslov ? '≥' : '<'} ${formatProsek(ponuda.minimalniProsek)}',
          ),
          _Pravilo(
            ispunjeno: imaJezikUslov,
            tekst:
                '${velikoPrvo(nazivJezika(zahtev.jezik))} ${nivo?.oznaka ?? '—'} ${imaJezikUslov ? '≥' : '<'} ${zahtev.nivo.oznaka}',
          ),
          _Pravilo(
            ispunjeno: uslovi.mestoZaPrijavu,
            tekst: 'Aktivne prijave: $aktivno od najviše $najviseAktivnihPrijava',
          ),
          _Pravilo(ispunjeno: uslovi.rok, tekst: 'Rok za prijavu: ${formatDatum(ponuda.rok)}'),
        ],
      ),
    );
  }
}

class _Pravilo extends StatelessWidget {
  const _Pravilo({required this.ispunjeno, required this.tekst});

  final bool ispunjeno;
  final String tekst;

  @override
  Widget build(BuildContext context) {
    final stil = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(
            ispunjeno ? '✓' : '✗',
            style: stil?.copyWith(color: ispunjeno ? Boje.uspeh : Boje.greska, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(tekst, style: stil?.copyWith(fontSize: 13))),
        ],
      ),
    );
  }
}
