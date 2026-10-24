import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../podaci/lazni_podaci.dart';
import '../tekst/format.dart';
import '../tema/tema.dart';
import '../widgeti/isprekidana_linija.dart';
import '../widgeti/oznaka_drzave.dart';
import '../widgeti/oznaka_stanja.dart';
import '../widgeti/zaglavlje.dart';

enum _Prikaz { prijave, sacuvano }

class ProfilEkran extends StatefulWidget {
  const ProfilEkran({super.key});

  @override
  State<ProfilEkran> createState() => _ProfilEkranState();
}

class _ProfilEkranState extends State<ProfilEkran> {
  _Prikaz _prikaz = _Prikaz.prijave;

  Future<void> _otvori(String adresa) async {
    await context.push(adresa);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tekst = Theme.of(context).textTheme;
    final student = skladiste.student;
    final moje = skladiste.mojePrijave..sort((a, b) => b.napravljena.compareTo(a.napravljena));
    final sacuvane = [for (final id in skladiste.sacuvane) ?skladiste.ponuda(id)];
    final aktivno = aktivnePrijave(student.id, skladiste.svePrijave).length;
    final jePrijave = _prikaz == _Prikaz.prijave;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: BordoZaglavlje(
              dubinaPreklopa: 26,
              preklop: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _Statistika(student: student, aktivno: aktivno),
              ),
              child: _Zaglavlje(student: student, naUredi: () => _otvori('/profil/uredi')),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Prekidac(
                    izabran: _prikaz,
                    brojPrijava: moje.length,
                    brojSacuvanih: sacuvane.length,
                    onPromena: (prikaz) => setState(() => _prikaz = prikaz),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 14, 2, 10),
                    child: Text(
                      jePrijave
                          ? 'Dodirnite prijavu da vidite ceo sadržaj i akcije.'
                          : 'Ponude koje ste sačuvali da pogledate kasnije.',
                      style: tekst.bodySmall?.copyWith(color: Boje.sporedniTekst),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (jePrijave)
            _lista(
              prazno: 'Još nemate prijava. Izaberite ponudu na Početnoj.',
              kartice: [
                for (final prijava in moje)
                  _KarticaPrijave(
                    key: ValueKey(prijava.id),
                    prijava: prijava,
                    naDodir: () => _otvori('/profil/prijave/${prijava.id.vrednost}'),
                  ),
              ],
            )
          else
            _lista(
              prazno: 'Nemate sačuvanih ponuda. Sačuvajte ponudu dugmetom na njenom ekranu.',
              kartice: [for (final ponuda in sacuvane) _KarticaSacuvane(key: ValueKey(ponuda.id), ponuda: ponuda)],
            ),
        ],
      ),
    );
  }

  Widget _lista({required String prazno, required List<Widget> kartice}) {
    if (kartice.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            prazno,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Boje.sporedniTekst),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverList.separated(
        itemCount: kartice.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, indeks) => kartice[indeks],
      ),
    );
  }
}

class _Zaglavlje extends StatelessWidget {
  const _Zaglavlje({required this.student, required this.naUredi});

  final Student student;
  final VoidCallback naUredi;

  @override
  Widget build(BuildContext context) {
    final tekst = Theme.of(context).textTheme;
    final inicijali = '${student.ime.characters.first}${student.prezime.characters.first}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Semantics(
          header: true,
          child: Text('Profil', style: tekst.headlineSmall?.copyWith(color: Boje.bela)),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Semantics(
              button: true,
              label: 'Uredi profil',
              excludeSemantics: true,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: naUredi,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: Boje.bela, shape: BoxShape.circle),
                      child: Text(
                        inicijali,
                        style: tekst.headlineMedium?.copyWith(
                          color: Boje.bordo,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Boje.zuta,
                          shape: BoxShape.circle,
                          border: Border.all(color: Boje.bordo, width: 2),
                        ),
                        child: const Icon(Icons.edit, size: 13, color: Boje.naZutoj),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.punoIme, style: tekst.headlineSmall?.copyWith(color: Boje.bela)),
                  const SizedBox(height: 3),
                  Text(
                    '${student.fakultet}\n${student.smer} · ${student.godinaStudija}. godina',
                    style: tekst.bodySmall?.copyWith(color: Boje.bela.withValues(alpha: 0.88), fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Statistika extends StatelessWidget {
  const _Statistika({required this.student, required this.aktivno});

  final Student student;
  final int aktivno;

  @override
  Widget build(BuildContext context) {
    final jezik = student.znanjeJezika.entries.firstOrNull;
    const crta = SizedBox(height: 34, child: VerticalDivider(width: 1));
    return Material(
      elevation: 4,
      shadowColor: Boje.senka,
      borderRadius: BorderRadius.circular(18),
      color: Boje.bela,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            _Podatak(naslov: 'Prosek', vrednost: formatProsek(student.prosek)),
            crta,
            _Podatak(
              naslov: jezik == null ? 'Jezik' : velikoPrvo(nazivJezika(jezik.key)),
              vrednost: jezik == null ? '—' : jezik.value.oznaka,
            ),
            crta,
            _Podatak(naslov: 'Aktivne prijave', vrednost: '$aktivno/$najviseAktivnihPrijava'),
          ],
        ),
      ),
    );
  }
}

class _Podatak extends StatelessWidget {
  const _Podatak({required this.naslov, required this.vrednost});

  final String naslov;
  final String vrednost;

  @override
  Widget build(BuildContext context) {
    final tekst = Theme.of(context).textTheme;
    return Expanded(
      child: MergeSemantics(
        child: Column(
          children: [
            Text(vrednost, style: tekst.titleLarge),
            const SizedBox(height: 1),
            Text(
              naslov,
              style: tekst.labelSmall?.copyWith(color: Boje.sporedniTekst, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _Prekidac extends StatelessWidget {
  const _Prekidac({
    required this.izabran,
    required this.brojPrijava,
    required this.brojSacuvanih,
    required this.onPromena,
  });

  final _Prikaz izabran;
  final int brojPrijava;
  final int brojSacuvanih;
  final ValueChanged<_Prikaz> onPromena;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Boje.prekidac, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          _deo(context, _Prikaz.prijave, 'Moje prijave', brojPrijava),
          _deo(context, _Prikaz.sacuvano, 'Sačuvano', brojSacuvanih),
        ],
      ),
    );
  }

  Widget _deo(BuildContext context, _Prikaz prikaz, String naziv, int broj) {
    final jeIzabran = prikaz == izabran;
    final stil = Theme.of(context).textTheme.labelLarge
        ?.copyWith(fontSize: 13.5, color: jeIzabran ? Boje.bordo : Boje.sporedniTekst);
    return Expanded(
      child: Semantics(
        selected: jeIzabran,
        button: true,
        child: Material(
          color: jeIzabran ? Boje.bela : Boje.prekidac,
          elevation: jeIzabran ? 1 : 0,
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: () => onPromena(prikaz),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '$naziv  '),
                    TextSpan(
                      text: '$broj',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: stil,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KarticaPrijave extends StatelessWidget {
  const _KarticaPrijave({super.key, required this.prijava, required this.naDodir});

  final Prijava prijava;
  final VoidCallback naDodir;

  (String, DateTime?) _opis() => switch (prijava.stanje) {
    UPripremi() => ('Napravljena ', prijava.napravljena),
    Poslata(:final kada) => ('Poslato ', kada),
    NaListiCekanja(:final kada) => ('Na listi od ', kada),
    Prihvacena() => ('Potvrdi mesto →', null),
    Odbijena(:final kada) => ('Odbijeno ', kada),
    Potvrdjena(:final kada) => ('Potvrđeno ', kada),
    Povucena(:final kada) => ('Povučeno ', kada),
  };

  @override
  Widget build(BuildContext context) {
    final ponuda = skladiste.ponuda(prijava.idPonude);
    if (ponuda == null) return const SizedBox.shrink();
    final univerzitet = skladiste.univerzitet(ponuda.idUniverziteta);
    final tekst = Theme.of(context).textTheme;
    final sporedni = tekst.bodySmall?.copyWith(color: Boje.sporedniTekst, fontSize: 12);
    final (opis, datum) = _opis();

    return Card(
      child: InkWell(
        onTap: naDodir,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  OznakaDrzave(oznaka: univerzitet.oznakaDrzave, velicina: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(univerzitet.grad, style: tekst.titleLarge?.copyWith(fontSize: 17)),
                        Text(univerzitet.naziv, style: sporedni?.copyWith(fontSize: 12.5)),
                      ],
                    ),
                  ),
                  OznakaStanja(stanje: prijava.stanje),
                ],
              ),
              const SizedBox(height: 10),
              const IsprekidanaLinija(),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(child: Text(nazivSemestra(ponuda.semestar), style: sporedni)),
                  if (datum == null)
                    Text(
                      opis,
                      style: sporedni?.copyWith(color: Boje.bordo, fontWeight: FontWeight.w700),
                    )
                  else
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: opis),
                          TextSpan(
                            text: formatKratakDatum(datum),
                            style: const TextStyle(color: Boje.tekst, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      style: sporedni,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KarticaSacuvane extends StatelessWidget {
  const _KarticaSacuvane({super.key, required this.ponuda});

  final Ponuda ponuda;

  @override
  Widget build(BuildContext context) {
    final univerzitet = skladiste.univerzitet(ponuda.idUniverziteta);
    final tekst = Theme.of(context).textTheme;
    final sporedni = tekst.bodySmall?.copyWith(color: Boje.sporedniTekst, fontSize: 12);
    final slobodno = preostalaMesta(ponuda, skladiste.svePrijave);

    return Card(
      child: InkWell(
        onTap: () => context.go('/ponude/${ponuda.id.vrednost}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              OznakaDrzave(oznaka: univerzitet.oznakaDrzave, velicina: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(univerzitet.grad, style: tekst.titleLarge?.copyWith(fontSize: 17)),
                    Text(univerzitet.naziv, style: sporedni?.copyWith(fontSize: 12.5)),
                    const SizedBox(height: 3),
                    Text('Rok ${formatKratakDatum(ponuda.rok)} · ${brojMesta(slobodno)} slobodno', style: sporedni),
                  ],
                ),
              ),
              const Icon(Icons.bookmark, color: Boje.zuta),
            ],
          ),
        ),
      ),
    );
  }
}
