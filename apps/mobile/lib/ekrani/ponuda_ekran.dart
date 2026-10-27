import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:use_cases/use_cases.dart';

import '../tekst/format.dart';
import '../tekst/poruke_gresaka.dart';
import '../tema/tema.dart';
import '../widgeti/isprekidana_linija.dart';
import '../widgeti/lista_uslova.dart';
import '../widgeti/nije_pronadjeno.dart';
import '../widgeti/prikazi_stanja.dart';
import '../widgeti/zaglavlje.dart';

class PonudaEkran extends StatelessWidget {
  const PonudaEkran({super.key, required this.idPonude});

  final IdPonude idPonude;

  static bool _imaPoruku(PonudeStanje pre, PonudeStanje sad) => sad is PonudeUcitane && sad.obavestenje != null;

  void _reaguj(BuildContext context, PonudeStanje stanje) {
    if (stanje is! PonudeUcitane) return;
    final obavestenje = stanje.obavestenje;
    final poruka = switch (obavestenje) {
      PonudaSacuvana() => 'Ponuda je sačuvana.',
      PonudaUklonjena() => 'Ponuda je uklonjena iz sačuvanih.',
      CuvanjePonudeNeuspelo() => 'Čuvanje ponude nije uspelo.',
      null => null,
    };
    if (poruka == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(poruka)));
    context.read<PonudeBloc>().add(const ObavestenjePonudaProcitano());
    if (obavestenje is PonudaSacuvana || obavestenje is PonudaUklonjena) {
      context.read<ProfilBloc>().add(const ProfilOsvezen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PonudeBloc>();
    return BlocConsumer<PonudeBloc, PonudeStanje>(
      listenWhen: _imaPoruku,
      listener: _reaguj,
      builder: (context, stanje) => switch (stanje) {
        PonudeUcitavanje() => const EkranStanja(child: PrikazUcitavanja()),
        PonudeGreska() => EkranStanja(child: PrikazGreske(onPonovo: () => bloc.add(const PonudeZatrazene()))),
        PonudePrazne() => const NijePronadjenoEkran(),
        PonudeUcitane(:final podaci, :final cuvaSe) => switch (podaci.ponuda(idPonude)) {
          null => const NijePronadjenoEkran(),
          final Ponuda ponuda => _Ponuda(podaci: podaci, ponuda: ponuda, cuvaSe: cuvaSe == ponuda.id),
        },
      },
    );
  }
}

class _Ponuda extends StatelessWidget {
  const _Ponuda({required this.podaci, required this.ponuda, required this.cuvaSe});

  final PregledPodataka podaci;
  final Ponuda ponuda;
  final bool cuvaSe;

  void _otvori(BuildContext context, String deo) {
    final ovde = GoRouterState.of(context).matchedLocation;
    context.push('$ovde/$deo');
  }

  @override
  Widget build(BuildContext context) {
    final univerzitet = podaci.univerzitet(ponuda.idUniverziteta);
    final postojeca = podaci.mojaPrijavaZa(ponuda.id);
    final uslovi = podaci.uslovi(ponuda);
    final slobodno = podaci.slobodnaMesta(ponuda);
    final sacuvana = podaci.jeSacuvana(ponuda.id);
    final tekst = Theme.of(context).textTheme;
    final belo = Boje.bela.withValues(alpha: 0.9);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          BordoZaglavlje(
            razmakDole: 18,
            dubinaPreklopa: 22,
            preklop: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _KljucniPodaci(
                mesta: '$slobodno / ${ponuda.brojMesta}',
                semestar: nazivSemestra(ponuda.semestar).split(' ').first,
                rok: formatKratakDatum(ponuda.rok),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DugmeZaglavlja(ikona: Icons.arrow_back, opis: 'Nazad', onPressed: () => context.pop()),
                    const Spacer(),
                    if (cuvaSe)
                      const SizedBox.square(
                        dimension: 40,
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Boje.zuta),
                        ),
                      )
                    else
                      DugmeZaglavlja(
                        ikona: sacuvana ? Icons.bookmark : Icons.bookmark_border,
                        boja: Boje.zuta,
                        opis: sacuvana ? 'Ukloni iz sačuvanih' : 'Sačuvaj ponudu',
                        onPressed: () => context.read<PonudeBloc>().add(SacuvanaPromenjena(ponuda.id)),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Boje.bela.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(univerzitet.oznakaDrzave, style: tekst.labelMedium?.copyWith(color: Boje.bela)),
                    ),
                    const SizedBox(width: 8),
                    Text(univerzitet.drzava, style: tekst.bodySmall?.copyWith(color: belo, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                Semantics(
                  header: true,
                  child: Text(univerzitet.grad, style: tekst.displaySmall?.copyWith(color: Boje.bela)),
                ),
                const SizedBox(height: 4),
                Text(univerzitet.naziv, style: tekst.bodyLarge?.copyWith(color: belo, fontSize: 15)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Naslov('O univerzitetu', prvi: true),
                _Okvir(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    child: Text(ponuda.opis, style: tekst.bodyMedium?.copyWith(height: 1.55)),
                  ),
                ),
                const _Naslov('Studije'),
                _Okvir(
                  child: Column(
                    children: [
                      _Red(ikona: Icons.school_outlined, naslov: 'Oblast', vrednost: ponuda.oblast),
                      const Divider(indent: 14, endIndent: 14),
                      _Red(
                        ikona: Icons.calendar_month_outlined,
                        naslov: 'Semestar',
                        vrednost: nazivSemestra(ponuda.semestar),
                      ),
                    ],
                  ),
                ),
                const _Naslov('Uslovi'),
                ListaUslova(ponuda: ponuda, student: podaci.student, uslovi: uslovi),
                if (ponuda.napomena case final napomena?) ...[
                  const _Naslov('Napomena'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Boje.napomenaPozadina,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Boje.napomenaIvica),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: Boje.naZutoj, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(napomena, style: tekst.bodyMedium?.copyWith(color: Boje.naZutoj, fontSize: 13.5)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  'Objavio koordinator · ${univerzitet.naziv} · ${formatDatum(ponuda.objavljena)}',
                  style: tekst.bodySmall?.copyWith(color: Boje.sporedniTekst, fontSize: 12),
                ),
                if (postojeca == null && uslovi.ishod.greskaIliNull != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Boje.greskaPozadina, borderRadius: BorderRadius.circular(16)),
                    child: Text(
                      'Ne možete se prijaviti: ${uslovi.ishod.greskaIliNull!.poruka}',
                      style: tekst.bodyMedium?.copyWith(color: Boje.greska),
                    ),
                  ),
                ],
                if (postojeca == null && uslovi.ispunjeni && slobodno == 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Boje.napomenaPozadina,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Boje.napomenaIvica),
                    ),
                    child: Text(
                      'Sva mesta su trenutno popunjena. Prijavu i dalje možete da pošaljete: '
                      'koordinator može da je stavi na listu čekanja, a mesto se oslobađa ako neko odustane.',
                      style: tekst.bodyMedium?.copyWith(color: Boje.naZutoj),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: postojeca != null
          ? _DugmeSaNatpisom(
              natpis: 'Moja prijava',
              ikona: Icons.description_outlined,
              onPressed: () => _otvori(context, 'moja/${postojeca.id.vrednost}'),
            )
          : _DugmeSaNatpisom(
              natpis: uslovi.ispunjeni ? 'Prijavi se' : 'Uslovi nisu ispunjeni',
              ikona: Icons.add,
              onPressed: uslovi.ispunjeni ? () => _otvori(context, 'prijava') : null,
            ),
    );
  }
}

class _KljucniPodaci extends StatelessWidget {
  const _KljucniPodaci({required this.mesta, required this.semestar, required this.rok});

  final String mesta;
  final String semestar;
  final String rok;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shadowColor: Boje.senka,
      color: Boje.bela,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: _Broj(naslov: 'MESTA', vrednost: mesta),
            ),
            const IsprekidanaLinija.uspravna(duzina: 36),
            Expanded(
              child: _Broj(naslov: 'SEMESTAR', vrednost: semestar),
            ),
            const IsprekidanaLinija.uspravna(duzina: 36),
            Expanded(
              child: _Broj(naslov: 'ROK', vrednost: rok),
            ),
          ],
        ),
      ),
    );
  }
}

class _Broj extends StatelessWidget {
  const _Broj({required this.naslov, required this.vrednost});

  final String naslov;
  final String vrednost;

  @override
  Widget build(BuildContext context) {
    final tekst = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Column(
        children: [
          Text(
            naslov,
            style: tekst.labelSmall?.copyWith(color: Boje.sporedniTekst, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 1),
          Text(vrednost, style: tekst.titleLarge?.copyWith(fontSize: 18), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Okvir extends StatelessWidget {
  const _Okvir({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Card(child: child),
  );
}

class _Red extends StatelessWidget {
  const _Red({required this.ikona, required this.naslov, required this.vrednost});

  final IconData ikona;
  final String naslov;
  final String vrednost;

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
          ],
        ),
      ),
    );
  }
}

class _Naslov extends StatelessWidget {
  const _Naslov(this.tekst, {this.prvi = false});

  final String tekst;
  final bool prvi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(2, prvi ? 4 : 20, 2, 10),
      child: Semantics(
        header: true,
        child: Text(tekst, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
      ),
    );
  }
}

class _DugmeSaNatpisom extends StatelessWidget {
  const _DugmeSaNatpisom({required this.natpis, required this.ikona, required this.onPressed});

  final String natpis;
  final IconData ikona;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final omoguceno = onPressed != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Boje.tekst, borderRadius: BorderRadius.circular(10)),
            child: Text(natpis, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Boje.bela)),
          ),
        ),
        const SizedBox(width: 10),
        FloatingActionButton(
          tooltip: natpis,
          onPressed: onPressed,
          backgroundColor: omoguceno ? null : Boje.ivica,
          foregroundColor: omoguceno ? null : Boje.sporedniTekst,
          elevation: omoguceno ? null : 0,
          child: Icon(ikona, size: 30),
        ),
      ],
    );
  }
}
