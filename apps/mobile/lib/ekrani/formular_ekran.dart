import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../podaci/lazni_podaci.dart';
import '../tekst/format.dart';
import '../tekst/poruke_gresaka.dart';
import '../tema/tema.dart';
import '../widgeti/lista_uslova.dart';
import '../widgeti/nije_pronadjeno.dart';
import '../widgeti/oznaka_drzave.dart';
import '../widgeti/zaglavlje.dart';

class FormularEkran extends StatefulWidget {
  const FormularEkran({super.key, required this.idPonude, this.idPrijave});

  static const kljucPisma = Key('motivaciono-pismo');

  final IdPonude idPonude;
  final IdPrijave? idPrijave;

  @override
  State<FormularEkran> createState() => _FormularEkranState();
}

class _FormularEkranState extends State<FormularEkran> {
  final _kljucForme = GlobalKey<FormState>();
  late final Prijava? _postojeca = widget.idPrijave == null ? null : skladiste.prijava(widget.idPrijave!);
  late final _pismo = TextEditingController(text: _postojeca?.motivacionoPismo.tekst ?? '');
  late final _napomena = TextEditingController(text: _postojeca?.napomena ?? '');

  @override
  void dispose() {
    _pismo.dispose();
    _napomena.dispose();
    super.dispose();
  }

  bool get _menjaPoslatu => !dozvoljenPrelaz(_postojeca?.stanje ?? const UPripremi(), Poslata(kada: DateTime.now()));

  String? _proveriPismo(String? unos) => MotivacionoPismo.proveri(unos ?? '').greskaIliNull?.poruka;

  String? get _napomenaIliNull {
    final tekst = _napomena.text.trim();
    return tekst.isEmpty ? null : tekst;
  }

  void _poruka(String tekst) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tekst)));

  Prijava? _prijavaIzForme() {
    if (!_kljucForme.currentState!.validate()) return null;
    final pismo = MotivacionoPismo.proveri(_pismo.text).vrednostIliNull!;
    final postojeca = _postojeca;

    if (postojeca == null) {
      final sada = DateTime.now();
      return Prijava(
        id: IdPrijave('p-${sada.microsecondsSinceEpoch}'),
        idStudenta: skladiste.korisnik.id,
        idPonude: widget.idPonude,
        motivacionoPismo: pismo,
        napomena: _napomenaIliNull,
        napravljena: sada,
      );
    }

    final izmena = izmeniPrijavu(
      postojeca,
      ko: skladiste.korisnik,
      motivacionoPismo: pismo,
      napomena: _napomenaIliNull,
    );
    if (izmena case Neuspeh(:final greska)) {
      _poruka(greska.poruka);
      return null;
    }
    return izmena.vrednostIliNull;
  }

  void _sacuvaj() {
    final prijava = _prijavaIzForme();
    if (prijava == null) return;
    skladiste.sacuvaj(prijava);
    _poruka(_postojeca == null ? 'Prijava je sačuvana u pripremi.' : 'Izmene su sačuvane.');
    context.pop();
  }

  void _posalji(Ponuda ponuda) {
    final prijava = _prijavaIzForme();
    if (prijava == null) return;
    final rezultat = posaljiPrijavu(
      prijava,
      ko: skladiste.korisnik,
      student: skladiste.student,
      ponuda: ponuda,
      svePrijave: skladiste.svePrijave,
      sada: DateTime.now(),
    );
    switch (rezultat) {
      case Uspeh(:final vrednost):
        skladiste.sacuvaj(vrednost);
        _poruka('Prijava je poslata. Čeka odluku koordinatora.');
        context.pop();
      case Neuspeh(:final greska):
        _poruka(greska.poruka);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ponuda = skladiste.ponuda(widget.idPonude);
    if (ponuda == null) return const NijePronadjenoEkran();

    final univerzitet = skladiste.univerzitet(ponuda.idUniverziteta);
    final student = skladiste.student;
    final postojeca = _postojeca;
    final stanje = postojeca?.stanje ?? const UPripremi();
    final tekst = Theme.of(context).textTheme;
    final sporedni = tekst.bodySmall?.copyWith(color: Boje.sporedniTekst, fontSize: 12);

    return Scaffold(
      body: Form(
        key: _kljucForme,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            BordoZaglavlje(
              razmakDole: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      DugmeZaglavlja(ikona: Icons.close, opis: 'Zatvori', onPressed: () => context.pop()),
                      const SizedBox(width: 12),
                      Semantics(
                        header: true,
                        child: Text(
                          postojeca == null ? 'Prijava' : 'Izmena prijave',
                          style: tekst.headlineSmall?.copyWith(color: Boje.bela),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _Destinacija(univerzitet: univerzitet, ponuda: ponuda, stanje: stanje),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Korak(broj: 1, naslov: 'Podaci iz profila'),
                  Text('Popunjeno automatski.', style: sporedni),
                  const SizedBox(height: 10),
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(color: Boje.siviBlok, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        _RedPodatka(naziv: 'Ime i prezime', vrednost: student.punoIme),
                        _RedPodatka(naziv: 'Broj indeksa', vrednost: student.brojIndeksa),
                        _RedPodatka(naziv: 'Fakultet', vrednost: student.fakultet),
                        _RedPodatka(naziv: 'Smer i godina', vrednost: '${student.smer} · ${student.godinaStudija}.'),
                        _RedPodatka(naziv: 'Prosek', vrednost: formatProsek(student.prosek)),
                        for (final jezik in student.znanjeJezika.entries)
                          _RedPodatka(
                            naziv: '${velikoPrvo(nazivJezika(jezik.key))} jezik',
                            vrednost: jezik.value.oznaka,
                          ),
                        _RedPodatka(naziv: 'E-pošta', vrednost: student.email, poslednji: true),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline, size: 14, color: Boje.sporedniTekst),
                        const SizedBox(width: 6),
                        Text('Ovi podaci se menjaju na Profilu.', style: sporedni),
                      ],
                    ),
                  ),
                  const _Korak(broj: 2, naslov: 'Motivacija'),
                  Text('Zašto baš ovaj univerzitet i šta očekujete od razmene.', style: sporedni),
                  const SizedBox(height: 10),
                  TextFormField(
                    key: FormularEkran.kljucPisma,
                    controller: _pismo,
                    minLines: 5,
                    maxLines: 10,
                    maxLength: MotivacionoPismo.najvise,
                    maxLengthEnforcement: MaxLengthEnforcement.none,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Motivaciono pismo *', alignLabelWithHint: true),
                    validator: _proveriPismo,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _napomena,
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Napomena',
                      hintText: 'Nije obavezna. Na primer, poseban zahtev ili pitanje.',
                      alignLabelWithHint: true,
                    ),
                  ),
                  if (!_menjaPoslatu) ...[
                    const _Korak(broj: 3, naslov: 'Provera pre slanja'),
                    const SizedBox(height: 6),
                    ProveraPreSlanja(
                      ponuda: ponuda,
                      student: student,
                      svePrijave: skladiste.svePrijave,
                      sada: DateTime.now(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Boje.pozadina,
          border: Border(top: BorderSide(color: Boje.ivica)),
        ),
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: _menjaPoslatu
              ? FilledButton(onPressed: _sacuvaj, child: const Text('Sačuvaj izmene'))
              : Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: OutlinedButton(onPressed: _sacuvaj, child: const Text('Sačuvaj')),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: FilledButton(onPressed: () => _posalji(ponuda), child: const Text('Pošalji prijavu')),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Destinacija extends StatelessWidget {
  const _Destinacija({required this.univerzitet, required this.ponuda, required this.stanje});

  final Univerzitet univerzitet;
  final Ponuda ponuda;
  final StanjePrijave stanje;

  @override
  Widget build(BuildContext context) {
    final tekst = Theme.of(context).textTheme;
    final boje = stanje is UPripremi ? (pozadina: Boje.zuta, tekst: Boje.naZutoj) : bojeStanja(stanje);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Boje.bela.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          OznakaDrzave(oznaka: univerzitet.oznakaDrzave, velicina: 38, naBordo: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(univerzitet.grad, style: tekst.titleLarge?.copyWith(color: Boje.bela, fontSize: 17)),
                Text(
                  '${univerzitet.naziv} · ${nazivSemestra(ponuda.semestar)}',
                  style: tekst.bodySmall?.copyWith(color: Boje.bela.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: boje.pozadina, borderRadius: BorderRadius.circular(10)),
            child: Text(nazivStanja(stanje), style: tekst.labelSmall?.copyWith(color: boje.tekst)),
          ),
        ],
      ),
    );
  }
}

class _Korak extends StatelessWidget {
  const _Korak({required this.broj, required this.naslov});

  final int broj;
  final String naslov;

  @override
  Widget build(BuildContext context) {
    final tekst = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 20, 2, 4),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Boje.bordo, shape: BoxShape.circle),
              child: Text('$broj', style: tekst.labelMedium?.copyWith(color: Boje.bela)),
            ),
            const SizedBox(width: 8),
            Text(naslov, style: tekst.titleLarge?.copyWith(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class _RedPodatka extends StatelessWidget {
  const _RedPodatka({required this.naziv, required this.vrednost, this.poslednji = false});

  final String naziv;
  final String vrednost;
  final bool poslednji;

  @override
  Widget build(BuildContext context) {
    final tekst = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: poslednji ? null : const Border(bottom: BorderSide(color: Boje.siviBlokLinija)),
      ),
      child: Row(
        children: [
          Text(naziv, style: tekst.bodyMedium?.copyWith(color: Boje.sporedniTekst, fontSize: 13.5)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(vrednost, textAlign: TextAlign.end, style: tekst.titleSmall?.copyWith(fontSize: 13.5)),
          ),
        ],
      ),
    );
  }
}
