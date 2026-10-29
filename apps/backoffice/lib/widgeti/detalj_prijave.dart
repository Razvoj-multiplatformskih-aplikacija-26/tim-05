import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';


class DetaljPrijave extends StatelessWidget {
  const DetaljPrijave({
    super.key,
    required this.prijava,
    required this.podaci,
    required this.onZatvori,
    this.onPrihvati,
    this.onListaCekanja,
    this.onOdbij,
    this.akcijaTraje = false,
  });

  final Prijava prijava;
  final PregledKoordinatora podaci;
  final VoidCallback onZatvori;
  final VoidCallback? onPrihvati;
  final VoidCallback? onListaCekanja;
  final VoidCallback? onOdbij;

  final bool akcijaTraje;

  static String opisStanja(StanjePrijave stanje) => switch (stanje) {
    UPripremi() => 'Student još popunjava prijavu.',
    Poslata(:final kada) => 'Poslata ${formatDatum(kada)} Čeka odluku koordinatora.',
    NaListiCekanja(:final kada) => 'Na listi čekanja od ${formatDatum(kada)}',
    Prihvacena(:final kada) => 'Prihvaćena ${formatDatum(kada)} Čeka da student potvrdi mesto.',
    Odbijena(:final kada, :final razlog) => 'Odbijena ${formatDatum(kada)}${razlog.isEmpty ? '' : ' Razlog: $razlog'}',
    Potvrdjena(:final kada) => 'Student je potvrdio mesto ${formatDatum(kada)}',
    Povucena(:final kada) => 'Student je povukao prijavu ${formatDatum(kada)}',
  };

  @override
  Widget build(BuildContext context) {
    final tekst = Theme.of(context).textTheme;
    final sporedno = tekst.bodyMedium?.copyWith(color: Boje.sporedniTekst);
    final student = podaci.student(prijava.idStudenta);
    final ponuda = podaci.ponuda(prijava.idPonude);
    final jezik = ponuda.zahtevJezika;
    final napomena = prijava.napomena;
    final prihvati = onPrihvati;
    final listaCekanja = onListaCekanja;
    final odbij = onOdbij;
    final nemaOdluka = prihvati == null && listaCekanja == null && odbij == null;
    return Semantics(
      container: true,
      label: 'Detalj prijave',
      child: Material(
        color: Boje.pozadina,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(student?.punoIme ?? 'Nepoznat student', style: tekst.headlineSmall),
                    ),
                  ),
                  IconButton(tooltip: 'Zatvori detalj (Esc)', onPressed: onZatvori, icon: const Icon(Icons.close)),
                ],
              ),
            ),
            if (student != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text('${student.brojIndeksa} · ${student.smer}', style: sporedno),
              ),
            Expanded(
              child: SelectionArea(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    Align(alignment: Alignment.centerLeft, child: OznakaStanja(stanje: prijava.stanje)),
                    const SizedBox(height: 8),
                    Text(opisStanja(prijava.stanje), style: sporedno),
                    const SizedBox(height: 20),
                    _Polje(naziv: 'Ponuda', vrednost: '${ponuda.oblast}, ${nazivSemestra(ponuda.semestar)}'),
                    if (student != null) ...[
                      _Polje(
                        naziv: 'Prosek',
                        vrednost:
                            '${formatProsek(student.prosek)} (traži se najmanje ${formatProsek(ponuda.minimalniProsek)})',
                        ispunjen: podaci.imaProsek(prijava),
                      ),
                      _Polje(
                        naziv: 'Jezik',
                        vrednost:
                            '${velikoPrvo(nazivJezika(jezik.jezik))} ${student.nivoZa(jezik.jezik)?.oznaka ?? '—'} '
                            '(traži se ${opisZahtevaJezika(jezik)})',
                        ispunjen: podaci.imaJezik(prijava),
                      ),
                      _Polje(naziv: 'Godina studija', vrednost: '${student.godinaStudija}.'),
                      _Polje(naziv: 'Fakultet', vrednost: student.fakultet),
                      _Polje(naziv: 'E-pošta', vrednost: student.email),
                    ],
                    _Polje(naziv: 'Prijava napravljena', vrednost: formatDatum(prijava.napravljena)),
                    _Polje(naziv: 'Motivaciono pismo', vrednost: prijava.motivacionoPismo.tekst),
                    if (napomena != null && napomena.isNotEmpty) _Polje(naziv: 'Napomena', vrednost: napomena),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (nemaOdluka) Text('U ovom stanju koordinator više ne odlučuje o prijavi.', style: sporedno),
                  if (prihvati != null)
                    _DugmeAkcije(
                      naziv: 'Prihvati',
                      precica: 'P',
                      ikona: Icons.check,
                      onPressed: akcijaTraje ? null : prihvati,
                    ),
                  if (listaCekanja != null) ...[
                    const SizedBox(height: 8),
                    _DugmeAkcije(
                      naziv: 'Lista čekanja',
                      precica: 'L',
                      ikona: Icons.schedule,
                      onPressed: akcijaTraje ? null : listaCekanja,
                      tonalno: true,
                    ),
                  ],
                  if (odbij != null) ...[
                    const SizedBox(height: 8),
                    _DugmeAkcije(
                      naziv: 'Odbij',
                      precica: 'O',
                      ikona: Icons.close,
                      onPressed: akcijaTraje ? null : odbij,
                      tonalno: true,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Polje extends StatelessWidget {
  const _Polje({required this.naziv, required this.vrednost, this.ispunjen});

  final String naziv;
  final String vrednost;

  final bool? ispunjen;

  @override
  Widget build(BuildContext context) {
    final tekst = Theme.of(context).textTheme;
    final ispunjen = this.ispunjen;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(naziv, style: tekst.labelMedium?.copyWith(color: Boje.sporedniTekst)),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(vrednost, style: tekst.bodyLarge)),
                if (ispunjen != null)
                  Icon(
                    ispunjen ? Icons.check_circle : Icons.cancel,
                    size: 18,
                    color: ispunjen ? Boje.uspeh : Boje.greska,
                    semanticLabel: ispunjen ? 'ispunjava uslov' : 'ne ispunjava uslov',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DugmeAkcije extends StatelessWidget {
  const _DugmeAkcije({
    required this.naziv,
    required this.precica,
    required this.ikona,
    required this.onPressed,
    this.tonalno = false,
  });

  final String naziv;
  final String precica;
  final IconData ikona;
  final VoidCallback? onPressed;
  final bool tonalno;

  @override
  Widget build(BuildContext context) {
    final dete = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(ikona, size: 20),
        const SizedBox(width: 8),
        Flexible(child: Text(naziv, textAlign: TextAlign.center)),
        const SizedBox(width: 10),
        ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Boje.sporedniTekst.withValues(alpha: 0.6)),
            ),
            child: Text(precica, style: Theme.of(context).textTheme.labelSmall),
          ),
        ),
      ],
    );
    return Tooltip(
      message: '$naziv ($precica)',
      child: MergeSemantics(
        child: Semantics(
          hint: 'Prečica $precica',
          child: tonalno
              ? FilledButton.tonal(onPressed: onPressed, child: dete)
              : FilledButton(onPressed: onPressed, child: dete),
        ),
      ),
    );
  }
}