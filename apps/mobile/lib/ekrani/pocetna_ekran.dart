import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';


import '../widgeti/kartica_ponude.dart';
import '../widgeti/kontrole_laznih_podataka.dart';
import '../widgeti/logo.dart';
import '../widgeti/zaglavlje.dart';

class PocetnaEkran extends StatelessWidget {
  const PocetnaEkran({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PonudeBloc>();
    return BlocBuilder<PonudeBloc, PonudeStanje>(
      builder: (context, stanje) => switch (stanje) {
        PonudeUcitavanje() => const EkranStanja(child: PrikazUcitavanja()),
        PonudeGreska() => EkranStanja(child: PrikazGreske(onPonovo: () => bloc.add(const PonudeZatrazene()))),
        PonudePrazne() => EkranStanja(
          child: PrikazPraznog(
            ikona: Icons.travel_explore,
            poruka: 'Trenutno nema objavljenih ponuda.',
            dugme: 'Osveži',
            onPritisak: () => bloc.add(const PonudeZatrazene()),
          ),
        ),
        final PonudeUcitane ucitane => _Ponude(stanje: ucitane),
      },
    );
  }
}

class _Ponude extends StatefulWidget {
  const _Ponude({required this.stanje});

  final PonudeUcitane stanje;

  @override
  State<_Ponude> createState() => _PonudeState();
}

class _PonudeState extends State<_Ponude> {
  late final _pretraga = TextEditingController(text: widget.stanje.filteri.upit);

  @override
  void dispose() {
    _pretraga.dispose();
    super.dispose();
  }

  PonudeFilteri get _filteri => widget.stanje.filteri;

  void _promeni(PonudeFilteri filteri) => context.read<PonudeBloc>().add(FilteriPromenjeni(filteri));

  Future<T?> _izaberi<T>(String naslov, List<T> opcije, String Function(T) naziv) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Semantics(header: true, child: Text(naslov, style: Theme.of(context).textTheme.titleLarge)),
            ),
            for (final opcija in opcije)
              ListTile(title: Text(naziv(opcija)), onTap: () => Navigator.pop(context, opcija)),
          ],
        ),
      ),
    );
  }

  Future<void> _promeniFilter<T>({
    required T? trenutno,
    required String naslov,
    required List<T> opcije,
    required String Function(T) naziv,
    required PonudeFilteri Function(T? izbor) postavi,
  }) async {
    if (trenutno != null) {
      _promeni(postavi(null));
      return;
    }
    final izbor = await _izaberi(naslov, opcije, naziv);
    if (izbor != null && mounted) _promeni(postavi(izbor));
  }

  @override
  Widget build(BuildContext context) {
    final tekst = Theme.of(context).textTheme;
    final podaci = widget.stanje.podaci;
    final ponude = widget.stanje.filtrirane;
    final bloc = context.read<PonudeBloc>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: BordoZaglavlje(
              dubinaPreklopa: 26,
              preklop: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _pretragaPolje()),
              child: _Pozdrav(
                ime: podaci.student.ime,
                meni: KontroleLaznihPodataka(
                  naPrazanOdgovor: (baza) => baza.prazneListePonuda = 1,
                  naPonovnoUcitavanje: () => bloc.add(const PonudeZatrazene()),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _filteriRed()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Semantics(header: true, child: Text('Najnovije ponude', style: tekst.titleLarge)),
                  ),
                  const SizedBox(width: 12),
                  Text('Ukupno: ${ponude.length}', style: tekst.bodySmall?.copyWith(color: Boje.sporedniTekst)),
                ],
              ),
            ),
          ),
          if (ponude.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Nema ponuda za izabranu pretragu.',
                  textAlign: TextAlign.center,
                  style: tekst.bodyLarge?.copyWith(color: Boje.sporedniTekst),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                itemCount: ponude.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, indeks) {
                  final ponuda = ponude[indeks];
                  return KarticaPonude(
                    key: ValueKey(ponuda.id),
                    ponuda: ponuda,
                    univerzitet: podaci.univerzitet(ponuda.idUniverziteta),
                    preostaloMesta: podaci.slobodnaMesta(ponuda),
                    jeNova: podaci.jeNova(ponuda),
                    onTap: () => context.push('/ponude/${ponuda.id.vrednost}'),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _pretragaPolje() {
    final bezIvice = OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none);
    return Material(
      elevation: 4,
      shadowColor: Boje.senka,
      borderRadius: BorderRadius.circular(16),
      color: Boje.bela,
      child: TextField(
        controller: _pretraga,
        onChanged: (unos) => _promeni(_filteri.copyWith(upit: unos)),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Pretraži univerzitet ili grad',
          prefixIcon: const Icon(Icons.search, color: Boje.bordo),
          border: bezIvice,
          enabledBorder: bezIvice,
          focusedBorder: bezIvice,
          suffixIcon: _filteri.upit.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Obriši pretragu',
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _pretraga.clear();
                    _promeni(_filteri.copyWith(upit: ''));
                  },
                ),
        ),
      ),
    );
  }

  Widget _filteriRed() {
    final stanje = widget.stanje;
    String semestar(VrstaSemestra v) => v == VrstaSemestra.zimski ? 'Zimski' : 'Letnji';
    String jezik(Jezik j) => velikoPrvo(nazivJezika(j));
    final filteri = _filteri;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          _Filter(
            ikona: Icons.public,
            naziv: 'Država',
            izabrano: filteri.drzava,
            onTap: () => _promeniFilter(
              trenutno: filteri.drzava,
              naslov: 'Država',
              opcije: stanje.drzave,
              naziv: (d) => d,
              postavi: (v) => _filteri.copyWith(drzava: () => v),
            ),
          ),
          const SizedBox(width: 8),
          _Filter(
            ikona: Icons.calendar_month_outlined,
            naziv: 'Semestar',
            izabrano: filteri.semestar == null ? null : semestar(filteri.semestar!),
            onTap: () => _promeniFilter(
              trenutno: filteri.semestar,
              naslov: 'Semestar',
              opcije: VrstaSemestra.values,
              naziv: semestar,
              postavi: (v) => _filteri.copyWith(semestar: () => v),
            ),
          ),
          const SizedBox(width: 8),
          _Filter(
            ikona: Icons.school_outlined,
            naziv: 'Smer',
            izabrano: filteri.oblast,
            onTap: () => _promeniFilter(
              trenutno: filteri.oblast,
              naslov: 'Smer',
              opcije: stanje.oblasti,
              naziv: (o) => o,
              postavi: (v) => _filteri.copyWith(oblast: () => v),
            ),
          ),
          const SizedBox(width: 8),
          _Filter(
            ikona: Icons.translate,
            naziv: 'Jezik',
            izabrano: filteri.jezik == null ? null : jezik(filteri.jezik!),
            onTap: () => _promeniFilter(
              trenutno: filteri.jezik,
              naslov: 'Jezik',
              opcije: stanje.jezici,
              naziv: jezik,
              postavi: (v) => _filteri.copyWith(jezik: () => v),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pozdrav extends StatelessWidget {
  const _Pozdrav({required this.ime, required this.meni});

  final String ime;
  final Widget meni;

  @override
  Widget build(BuildContext context) {
    final tekst = Theme.of(context).textTheme;
    final naziv = tekst.headlineSmall?.copyWith(color: Boje.bela, fontSize: 23, fontWeight: FontWeight.w700);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Logo(),
            const SizedBox(width: 10),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Erasmus'),
                  TextSpan(
                    text: 'Go',
                    style: TextStyle(color: Boje.bela.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              style: naziv,
            ),
            const Spacer(),
            meni,
          ],
        ),
        const SizedBox(height: 16),
        Text('Zdravo, $ime', style: tekst.bodyMedium?.copyWith(color: Boje.bela.withValues(alpha: 0.85))),
        const SizedBox(height: 4),
        Semantics(
          header: true,
          child: Text('Gde ideš sledećeg semestra?', style: tekst.headlineMedium?.copyWith(color: Boje.bela)),
        ),
      ],
    );
  }
}

class _Filter extends StatelessWidget {
  const _Filter({required this.ikona, required this.naziv, required this.izabrano, required this.onTap});

  final IconData ikona;
  final String naziv;

  final String? izabrano;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final jeIzabran = izabrano != null;
    final boja = jeIzabran ? Boje.bela : Boje.tekst;
    return Semantics(
      selected: jeIzabran,
      hint: jeIzabran ? 'Dodirnite da uklonite filter' : null,
      child: Material(
        color: jeIzabran ? Boje.bordo : Boje.bela,
        shape: StadiumBorder(side: BorderSide(color: jeIzabran ? Boje.bordo : Boje.ivica)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(ikona, size: 16, color: boja),
                const SizedBox(width: 6),
                Text(
                  jeIzabran ? '$izabrano ✕' : naziv,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: boja),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
