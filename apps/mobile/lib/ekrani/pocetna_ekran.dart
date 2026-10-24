import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../podaci/lazni_podaci.dart';
import '../tekst/format.dart';
import '../tema/tema.dart';
import '../widgeti/kartica_ponude.dart';
import '../widgeti/logo.dart';
import '../widgeti/zaglavlje.dart';

class PocetnaEkran extends StatefulWidget {
  const PocetnaEkran({super.key});

  @override
  State<PocetnaEkran> createState() => _PocetnaEkranState();
}

class _PocetnaEkranState extends State<PocetnaEkran> {
  final _pretraga = TextEditingController();
  String _upit = '';
  String? _drzava;
  VrstaSemestra? _semestar;
  String? _oblast;
  Jezik? _jezik;

  @override
  void dispose() {
    _pretraga.dispose();
    super.dispose();
  }

  List<Ponuda> _filtrirane() {
    final upit = _upit.trim().toLowerCase();
    return [
      for (final ponuda in skladiste.ponude)
        if (_odgovara(ponuda, upit)) ponuda,
    ]..sort((a, b) => b.objavljena.compareTo(a.objavljena));
  }

  bool _odgovara(Ponuda ponuda, String upit) {
    final univerzitet = skladiste.univerzitet(ponuda.idUniverziteta);
    if (_drzava != null && univerzitet.drzava != _drzava) return false;
    if (_semestar != null && ponuda.semestar.vrsta != _semestar) return false;
    if (_oblast != null && ponuda.oblast != _oblast) return false;
    if (_jezik != null && ponuda.zahtevJezika.jezik != _jezik) return false;
    if (upit.isEmpty) return true;
    final tekst = '${univerzitet.naziv} ${univerzitet.grad} ${univerzitet.drzava} ${ponuda.oblast}'.toLowerCase();
    return tekst.contains(upit);
  }

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
    required void Function(T?) postavi,
  }) async {
    if (trenutno != null) {
      setState(() => postavi(null));
      return;
    }
    final izbor = await _izaberi(naslov, opcije, naziv);
    if (izbor != null && mounted) setState(() => postavi(izbor));
  }

  Future<void> _otvori(Ponuda ponuda) async {
    await context.push('/ponude/${ponuda.id.vrednost}');
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tekst = Theme.of(context).textTheme;
    final ponude = _filtrirane();
    final sada = DateTime.now();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: BordoZaglavlje(
              dubinaPreklopa: 26,
              preklop: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _pretragaPolje()),
              child: _Pozdrav(ime: skladiste.student.ime),
            ),
          ),
          SliverToBoxAdapter(child: _filteri()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Semantics(header: true, child: Text('Najnovije ponude', style: tekst.titleLarge)),
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
                    univerzitet: skladiste.univerzitet(ponuda.idUniverziteta),
                    preostaloMesta: preostalaMesta(ponuda, skladiste.svePrijave),
                    jeNova: sada.difference(ponuda.objavljena).inDays < 7,
                    onTap: () => _otvori(ponuda),
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
        onChanged: (unos) => setState(() => _upit = unos),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Pretraži univerzitet ili grad',
          prefixIcon: const Icon(Icons.search, color: Boje.bordo),
          border: bezIvice,
          enabledBorder: bezIvice,
          focusedBorder: bezIvice,
          suffixIcon: _upit.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Obriši pretragu',
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() {
                    _pretraga.clear();
                    _upit = '';
                  }),
                ),
        ),
      ),
    );
  }

  Widget _filteri() {
    final drzave = {for (final u in skladiste.univerziteti) u.drzava}.toList()..sort();
    final oblasti = {for (final p in skladiste.ponude) p.oblast}.toList()..sort();
    final jezici = {for (final p in skladiste.ponude) p.zahtevJezika.jezik}.toList();
    String semestar(VrstaSemestra v) => v == VrstaSemestra.zimski ? 'Zimski' : 'Letnji';
    String jezik(Jezik j) => velikoPrvo(nazivJezika(j));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          _Filter(
            ikona: Icons.public,
            naziv: 'Država',
            izabrano: _drzava,
            onTap: () => _promeniFilter(
              trenutno: _drzava,
              naslov: 'Država',
              opcije: drzave,
              naziv: (d) => d,
              postavi: (v) => _drzava = v,
            ),
          ),
          const SizedBox(width: 8),
          _Filter(
            ikona: Icons.calendar_month_outlined,
            naziv: 'Semestar',
            izabrano: _semestar == null ? null : semestar(_semestar!),
            onTap: () => _promeniFilter(
              trenutno: _semestar,
              naslov: 'Semestar',
              opcije: VrstaSemestra.values,
              naziv: semestar,
              postavi: (v) => _semestar = v,
            ),
          ),
          const SizedBox(width: 8),
          _Filter(
            ikona: Icons.school_outlined,
            naziv: 'Smer',
            izabrano: _oblast,
            onTap: () => _promeniFilter(
              trenutno: _oblast,
              naslov: 'Smer',
              opcije: oblasti,
              naziv: (o) => o,
              postavi: (v) => _oblast = v,
            ),
          ),
          const SizedBox(width: 8),
          _Filter(
            ikona: Icons.translate,
            naziv: 'Jezik',
            izabrano: _jezik == null ? null : jezik(_jezik!),
            onTap: () => _promeniFilter(
              trenutno: _jezik,
              naslov: 'Jezik',
              opcije: jezici,
              naziv: jezik,
              postavi: (v) => _jezik = v,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pozdrav extends StatelessWidget {
  const _Pozdrav({required this.ime});

  final String ime;

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
