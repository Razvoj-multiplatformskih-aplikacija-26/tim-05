import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:use_cases/use_cases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:blocs/blocs.dart';

import '../tekst/format.dart';
import '../tekst/poruke_gresaka.dart';
import '../tema/tema.dart';
import '../widgeti/nije_pronadjeno.dart';
import '../widgeti/oznaka_drzave.dart';
import '../widgeti/oznaka_stanja.dart';
import '../widgeti/prikazi_stanja.dart';
import '../widgeti/zaglavlje.dart';

class MojaPrijavaEkran extends StatelessWidget {
  const MojaPrijavaEkran({super.key, required this.idPrijave});

  final IdPrijave idPrijave;

  static ProfilObavestenje? _obavestenje(ProfilStanje stanje) => switch (stanje) {
    ProfilSaPodacima(:final obavestenje) => obavestenje,
    ProfilUcitavanje() || ProfilGreska() => null,
  };

  static bool _mojaPoruka(ProfilStanje pre, ProfilStanje sad) => switch (_obavestenje(sad)) {
    null || ProfilSacuvan() => false,
    _ => true,
  };

  void _reaguj(BuildContext context, ProfilStanje stanje) {
    final obavestenje = _obavestenje(stanje);
    if (obavestenje == null) return;
    final podaci = switch (stanje) {
      ProfilSaPodacima(:final podaci) => podaci,
      ProfilUcitavanje() || ProfilGreska() => null,
    };
    final idPonude = podaci?.prijava(idPrijave)?.idPonude;
    final ponuda = idPonude == null ? null : podaci?.ponuda(idPonude);
    final semestar = ponuda == null ? 'isti semestar' : nazivSemestra(ponuda.semestar).toLowerCase();

    final String poruka;
    var uspeh = true;
    switch (obavestenje) {
      case PrijavaPovucena():
        poruka = 'Prijava je povučena.';
      case MestoPotvrdjeno(brojPovucenih: 0):
        poruka = 'Mesto je potvrđeno.';
      case MestoPotvrdjeno(:final brojPovucenih):
        poruka = 'Mesto je potvrđeno. Povučeno ostalih prijava za $semestar: $brojPovucenih.';
      case MestoOdbijeno():
        poruka = 'Mesto je odbijeno.';
      case PrijavaObrisana():
        poruka = 'Prijava je obrisana.';
      case ProfilSacuvan():
        return;
      case AkcijaOdbijena(:final greska):
        poruka = greska.poruka;
        uspeh = false;
      case AkcijaNeuspela():
        poruka = 'Radnja nije uspela. Proverite vezu i pokušajte ponovo.';
        uspeh = false;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(poruka)));
    context.read<ProfilBloc>().add(const ObavestenjeProfilaProcitano());

    if (uspeh) context.read<PonudeBloc>().add(const PonudeOsvezene());
    if (obavestenje is PrijavaObrisana) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProfilBloc>();
    return BlocConsumer<ProfilBloc, ProfilStanje>(
      listenWhen: _mojaPoruka,
      listener: _reaguj,
      builder: (context, stanje) => switch (stanje) {
        ProfilUcitavanje() => const EkranStanja(child: PrikazUcitavanja()),
        ProfilGreska() => EkranStanja(child: PrikazGreske(onPonovo: () => bloc.add(const ProfilZatrazen()))),
        ProfilSaPodacima(:final podaci, :final uToku) => _prikaz(context, podaci, uToku: uToku == idPrijave),
      },
    );
  }

  Widget _prikaz(BuildContext context, PregledPodataka podaci, {required bool uToku}) {
    final prijava = podaci.prijava(idPrijave);
    if (prijava == null) {
      final zatvaraSe = ModalRoute.of(context)?.isCurrent == false;
      return zatvaraSe ? const Scaffold() : const NijePronadjenoEkran();
    }
    final ponuda = podaci.ponuda(prijava.idPonude);
    if (ponuda == null) return const NijePronadjenoEkran();
    return _MojaPrijava(podaci: podaci, prijava: prijava, ponuda: ponuda, uToku: uToku);
  }
}

class _MojaPrijava extends StatelessWidget {
  const _MojaPrijava({required this.podaci, required this.prijava, required this.ponuda, required this.uToku});

  final PregledPodataka podaci;
  final Prijava prijava;
  final Ponuda ponuda;

  final bool uToku;

  Future<bool> _potvrdi(
    BuildContext context, {
    required String naslov,
    required String tekst,
    required String dugme,
  }) async {
    final odgovor = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(naslov),
        content: Text(tekst),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(dugme)),
        ],
      ),
    );
    return odgovor ?? false;
  }

  Future<void> _poslePotvrde(
    BuildContext context,
    ProfilDogadjaj dogadjaj, {
    required String naslov,
    required String tekst,
    required String dugme,
  }) async {
    final bloc = context.read<ProfilBloc>();
    if (await _potvrdi(context, naslov: naslov, tekst: tekst, dugme: dugme)) bloc.add(dogadjaj);
  }

  void _izmeni(BuildContext context) {
    final ovde = GoRouterState.of(context).matchedLocation;
    context.push('$ovde/izmena');
  }

  @override
  Widget build(BuildContext context) {
    final univerzitet = podaci.univerzitet(ponuda.idUniverziteta);
    final student = podaci.student;
    final stanje = prijava.stanje;
    final opis = '${univerzitet.naziv}, ${nazivSemestra(ponuda.semestar).toLowerCase()}';
    final mozeIzmenu = stanje.mozeSeMenjati;
    final mozePovlacenje = podaci.mozeSePovuci(prijava);
    final tekst = Theme.of(context).textTheme;
    final jezici = [
      for (final jezik in student.znanjeJezika.entries) '${nazivJezika(jezik.key)} ${jezik.value.oznaka}',
    ];

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          BordoZaglavlje(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DugmeZaglavlja(ikona: Icons.arrow_back, opis: 'Nazad', onPressed: () => context.pop()),
                    const SizedBox(width: 12),
                    Text('Moja prijava', style: tekst.headlineSmall?.copyWith(color: Boje.bela, fontSize: 20)),
                    const Spacer(),
                    if (stanje.mozeSeObrisati && !uToku)
                      DugmeZaglavlja(
                        ikona: Icons.delete_outline,
                        opis: 'Obriši prijavu',
                        onPressed: () => _poslePotvrde(
                          context,
                          BrisanjeZatrazeno(prijava.id),
                          naslov: 'Obrisati prijavu?',
                          tekst:
                              '$opis. Da li ste sigurni da želite da obrišete ovu prijavu? '
                              'Obrisana prijava se ne može vratiti.',
                          dugme: 'Obriši',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    OznakaDrzave(oznaka: univerzitet.oznakaDrzave, naBordo: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              univerzitet.grad,
                              style: tekst.headlineMedium?.copyWith(color: Boje.bela, fontSize: 24),
                            ),
                          ),
                          Text(
                            '${univerzitet.naziv} · ${nazivSemestra(ponuda.semestar)}',
                            style: tekst.bodySmall?.copyWith(color: Boje.bela.withValues(alpha: 0.85), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OznakaStanja(stanje: stanje),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (uToku)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(color: Boje.bordo),
                  ),
                if (stanje is Prihvacena)
                  _PonudjenoMesto(
                    semestar: nazivSemestra(ponuda.semestar).toLowerCase(),
                    onPrihvati: uToku
                        ? null
                        : () => _poslePotvrde(
                            context,
                            PotvrdaMestaZatrazena(prijava.id),
                            naslov: 'Prihvatiti mesto?',
                            tekst:
                                '$opis. Ako prihvatite ovo mesto, vaše ostale prijave za '
                                '${nazivSemestra(ponuda.semestar).toLowerCase()} biće povučene.',
                            dugme: 'Prihvati mesto',
                          ),
                    onOdbij: uToku
                        ? null
                        : () => _poslePotvrde(
                            context,
                            OdbijanjeMestaZatrazeno(prijava.id),
                            naslov: 'Odbiti ponuđeno mesto?',
                            tekst: '$opis. Prijava će biti povučena i mesto će dobiti drugi student.',
                            dugme: 'Odbij mesto',
                          ),
                  ),
                const _Naslov('Tok prijave'),
                _TokPrijave(koraci: _koraci(prijava)),
                const _Naslov('Sadržaj prijave'),
                _Odeljak(naslov: 'Motivaciono pismo', tekst: prijava.motivacionoPismo.tekst),
                const SizedBox(height: 8),
                _Odeljak(naslov: 'Napomena', tekst: prijava.napomena ?? '—'),
                const SizedBox(height: 8),
                _Odeljak(
                  naslov: 'Podaci iz profila',
                  tekst: [
                    student.punoIme,
                    student.brojIndeksa,
                    'prosek ${formatProsek(student.prosek)}',
                    ...jezici,
                  ].join(' · '),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: mozeIzmenu || mozePovlacenje
          ? DecoratedBox(
              decoration: const BoxDecoration(
                color: Boje.pozadina,
                border: Border(top: BorderSide(color: Boje.ivica)),
              ),
              child: SafeArea(
                minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    if (mozePovlacenje)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: uToku
                              ? null
                              : () => _poslePotvrde(
                                  context,
                                  PovlacenjeZatrazeno(prijava.id),
                                  naslov: 'Povući prijavu?',
                                  tekst: '$opis. Povučena prijava se ne može vratiti.',
                                  dugme: 'Povuci',
                                ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Boje.bela,
                            foregroundColor: Boje.opasnost,
                            side: const BorderSide(color: Boje.opasnostIvica, width: 1.5),
                          ),
                          child: const Text('Povuci prijavu'),
                        ),
                      ),
                    if (mozePovlacenje && mozeIzmenu) const SizedBox(width: 10),
                    if (mozeIzmenu)
                      Expanded(
                        child: FilledButton(
                          onPressed: uToku ? null : () => _izmeni(context),
                          child: Text(stanje is UPripremi ? 'Izmeni i pošalji' : 'Izmeni'),
                        ),
                      ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

enum _Vrsta { gotov, trenutni, sledeci }

typedef _Korak = ({String naziv, String? detalj, _Vrsta vrsta});

List<_Korak> _koraci(Prijava prijava) {
  final napravljena = (naziv: 'U pripremi', detalj: formatKratakDatum(prijava.napravljena), vrsta: _Vrsta.gotov);
  const poslata = (naziv: 'Poslata', detalj: null, vrsta: _Vrsta.gotov);
  const odluka = (naziv: 'Odluka koordinatora', detalj: null, vrsta: _Vrsta.sledeci);
  const mesto = (naziv: 'Potvrđeno mesto', detalj: null, vrsta: _Vrsta.sledeci);

  return switch (prijava.stanje) {
    UPripremi() => [
      (
        naziv: 'U pripremi',
        detalj: '${formatKratakDatum(prijava.napravljena)} · još nije poslata',
        vrsta: _Vrsta.trenutni,
      ),
      (naziv: 'Poslata', detalj: null, vrsta: _Vrsta.sledeci),
      odluka,
      mesto,
    ],
    Poslata(:final kada) => [
      napravljena,
      (naziv: 'Poslata', detalj: '${formatKratakDatum(kada)} · čeka odluku koordinatora', vrsta: _Vrsta.trenutni),
      odluka,
      mesto,
    ],
    NaListiCekanja(:final kada) => [
      napravljena,
      poslata,
      (naziv: 'Na listi čekanja', detalj: formatKratakDatum(kada), vrsta: _Vrsta.trenutni),
      mesto,
    ],
    Prihvacena(:final kada) => [
      napravljena,
      poslata,
      (naziv: 'Prihvaćena', detalj: '${formatKratakDatum(kada)} · čeka vašu odluku', vrsta: _Vrsta.trenutni),
      mesto,
    ],
    Odbijena(:final kada, :final razlog) => [
      napravljena,
      poslata,
      (naziv: 'Odbijena', detalj: '${formatKratakDatum(kada)} · $razlog', vrsta: _Vrsta.trenutni),
    ],
    Potvrdjena(:final kada) => [
      napravljena,
      poslata,
      (naziv: 'Prihvaćena', detalj: null, vrsta: _Vrsta.gotov),
      (naziv: 'Potvrđeno mesto', detalj: formatKratakDatum(kada), vrsta: _Vrsta.trenutni),
    ],
    Povucena(:final kada) => [
      napravljena,
      (naziv: 'Povučena', detalj: formatKratakDatum(kada), vrsta: _Vrsta.trenutni),
    ],
  };
}

class _TokPrijave extends StatelessWidget {
  const _TokPrijave({required this.koraci});

  final List<_Korak> koraci;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            for (final (indeks, korak) in koraci.indexed)
              _RedToka(korak: korak, poslednji: indeks == koraci.length - 1),
          ],
        ),
      ),
    );
  }
}

class _RedToka extends StatelessWidget {
  const _RedToka({required this.korak, required this.poslednji});

  final _Korak korak;
  final bool poslednji;

  @override
  Widget build(BuildContext context) {
    final tekst = Theme.of(context).textTheme;
    final sledeci = korak.vrsta == _Vrsta.sledeci;
    return MergeSemantics(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 18,
              child: Column(
                children: [
                  const SizedBox(height: 1),
                  _Tacka(vrsta: korak.vrsta),
                  if (!poslednji)
                    Expanded(child: Container(width: 2, color: korak.vrsta == _Vrsta.gotov ? Boje.bordo : Boje.ivica)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: poslednji ? 0 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      korak.naziv,
                      style: tekst.titleSmall?.copyWith(
                        fontSize: 13.5,
                        color: sledeci ? Boje.sporedniTekst : Boje.tekst,
                        fontWeight: sledeci ? FontWeight.w500 : FontWeight.w600,
                      ),
                    ),
                    if (korak.detalj case final detalj?)
                      Text(detalj, style: tekst.bodySmall?.copyWith(color: Boje.sporedniTekst, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tacka extends StatelessWidget {
  const _Tacka({required this.vrsta});

  final _Vrsta vrsta;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: vrsta == _Vrsta.gotov ? Boje.bordo : Boje.bela,
        border: Border.all(color: vrsta == _Vrsta.sledeci ? Boje.ivica : Boje.bordo, width: 2),
        boxShadow: vrsta == _Vrsta.trenutni ? const [BoxShadow(color: Boje.bordoSvetla, spreadRadius: 4)] : null,
      ),
    );
  }
}

class _Odeljak extends StatelessWidget {
  const _Odeljak({required this.naslov, required this.tekst});

  final String naslov;
  final String tekst;

  @override
  Widget build(BuildContext context) {
    final stil = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              naslov,
              style: stil.labelMedium?.copyWith(color: Boje.sporedniTekst, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 3),
            Text(tekst, style: stil.bodyMedium?.copyWith(fontSize: 13.5)),
          ],
        ),
      ),
    );
  }
}

class _PonudjenoMesto extends StatelessWidget {
  const _PonudjenoMesto({required this.semestar, required this.onPrihvati, required this.onOdbij});

  final String semestar;
  final VoidCallback? onPrihvati;
  final VoidCallback? onOdbij;

  @override
  Widget build(BuildContext context) {
    final tekst = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Boje.uspehPozadina,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Boje.uspehIvica),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ponuđeno vam je mesto!', style: tekst.titleLarge?.copyWith(color: Boje.uspehNaslov, fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            'Koordinator je prihvatio vašu prijavu. Ako prihvatite mesto, povlače se vaše ostale prijave za $semestar.',
            style: tekst.bodyMedium?.copyWith(color: Boje.uspehTekst, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onOdbij,
                  style: OutlinedButton.styleFrom(backgroundColor: Boje.bela, minimumSize: const Size(64, 48)),
                  child: const Text('Odbij'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: onPrihvati,
                  style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
                  child: const Text('Prihvati mesto'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Naslov extends StatelessWidget {
  const _Naslov(this.tekst);

  final String tekst;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
      child: Semantics(
        header: true,
        child: Text(tekst, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15.5)),
      ),
    );
  }
}
