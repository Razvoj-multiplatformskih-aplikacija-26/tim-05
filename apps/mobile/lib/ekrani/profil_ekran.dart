import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:use_cases/use_cases.dart';
import 'package:blocs/blocs.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import '../widgeti/isprekidana_linija.dart';
import '../widgeti/oznaka_drzave.dart';
import '../widgeti/zaglavlje.dart';
import '../widgeti/kontrole_laznih_podataka.dart';

class ProfilEkran extends StatelessWidget {
  const ProfilEkran({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProfilBloc>();
    return BlocBuilder<ProfilBloc, ProfilStanje>(
      builder: (context, stanje) => switch (stanje) {
        ProfilUcitavanje() => const EkranStanja(child: PrikazUcitavanja()),
        ProfilGreska() => EkranStanja(child: PrikazGreske(onPonovo: () => bloc.add(const ProfilZatrazen()))),
        final ProfilSaPodacima saPodacima => _Profil(stanje: saPodacima),
      },
    );
  }
}

class _Profil extends StatelessWidget {
  const _Profil({required this.stanje});

  final ProfilSaPodacima stanje;

  @override
  Widget build(BuildContext context) {
    final tekst = Theme.of(context).textTheme;
    final podaci = stanje.podaci;
    final student = podaci.student;
    final moje = podaci.mojePrijave;
    final sacuvane = podaci.sacuvanePonude;
    final jePrijave = stanje.prikaz == PrikazProfila.prijave;
    final bloc = context.read<ProfilBloc>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: BordoZaglavlje(
              dubinaPreklopa: 26,
              preklop: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _Statistika(student: student, aktivno: podaci.brojAktivnih),
              ),
              child: _Zaglavlje(
                student: student,
                naUredi: () => context.push('/profil/uredi'),
                meni: KontroleLaznihPodataka(
                  naPrazanOdgovor: (baza) => baza.prazneListePrijava = 1,
                  naPonovnoUcitavanje: () => bloc.add(const ProfilZatrazen()),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Prekidac(
                    izabran: stanje.prikaz,
                    brojPrijava: moje.length,
                    brojSacuvanih: sacuvane.length,
                    onPromena: (prikaz) => bloc.add(PrikazProfilaPromenjen(prikaz)),
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
              prazno: PrikazPraznog(
                ikona: Icons.description_outlined,
                poruka: 'Još nemate prijava. Izaberite ponudu na Početnoj.',
                dugme: 'Pogledaj ponude',
                onPritisak: () => context.go('/'),
              ),
              kartice: [
                for (final prijava in moje)
                  _KarticaPrijave(
                    key: ValueKey(prijava.id),
                    podaci: podaci,
                    prijava: prijava,
                    naDodir: () => context.push('/profil/prijave/${prijava.id.vrednost}'),
                  ),
              ],
            )
          else
            _lista(
              prazno: const PrikazPraznog(
                ikona: Icons.bookmark_border,
                poruka: 'Nemate sačuvanih ponuda. Sačuvajte ponudu dugmetom na njenom ekranu.',
              ),
              kartice: [
                for (final ponuda in sacuvane)
                  _KarticaSacuvane(
                    key: ValueKey(ponuda.id),
                    podaci: podaci,
                    ponuda: ponuda,
                    naDodir: () => context.push('/profil/sacuvane/${ponuda.id.vrednost}'),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _lista({required Widget prazno, required List<Widget> kartice}) {
    if (kartice.isEmpty) return SliverFillRemaining(hasScrollBody: false, child: prazno);
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
  const _Zaglavlje({required this.student, required this.naUredi, required this.meni});

  final Student student;
  final VoidCallback naUredi;
  final Widget meni;

  @override
  Widget build(BuildContext context) {
    final tekst = Theme.of(context).textTheme;
    final inicijali = '${student.ime.characters.first}${student.prezime.characters.first}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            Semantics(
              header: true,
              child: Text('Profil', style: tekst.headlineSmall?.copyWith(color: Boje.bela)),
            ),
            const Spacer(),
            meni,
          ],
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

  final PrikazProfila izabran;
  final int brojPrijava;
  final int brojSacuvanih;
  final ValueChanged<PrikazProfila> onPromena;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Boje.prekidac, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          _deo(context, PrikazProfila.prijave, 'Moje prijave', brojPrijava),
          _deo(context, PrikazProfila.sacuvano, 'Sačuvano', brojSacuvanih),
        ],
      ),
    );
  }

  Widget _deo(BuildContext context, PrikazProfila prikaz, String naziv, int broj) {
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
  const _KarticaPrijave({super.key, required this.podaci, required this.prijava, required this.naDodir});

  final PregledPodataka podaci;
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
    final ponuda = podaci.ponuda(prijava.idPonude);
    if (ponuda == null) return const SizedBox.shrink();
    final univerzitet = podaci.univerzitet(ponuda.idUniverziteta);
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
  const _KarticaSacuvane({super.key, required this.podaci, required this.ponuda, required this.naDodir});

  final PregledPodataka podaci;
  final Ponuda ponuda;
  final VoidCallback naDodir;

  @override
  Widget build(BuildContext context) {
    final univerzitet = podaci.univerzitet(ponuda.idUniverziteta);
    final tekst = Theme.of(context).textTheme;
    final sporedni = tekst.bodySmall?.copyWith(color: Boje.sporedniTekst, fontSize: 12);
    final slobodno = podaci.slobodnaMesta(ponuda);

    return Card(
      child: InkWell(
        onTap: naDodir,
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
