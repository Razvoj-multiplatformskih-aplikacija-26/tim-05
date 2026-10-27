import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:use_cases/use_cases.dart';

import '../tekst/format.dart';
import '../tekst/poruke_gresaka.dart';
import '../tema/tema.dart';
import '../widgeti/lista_uslova.dart';
import '../widgeti/nije_pronadjeno.dart';
import '../widgeti/oznaka_drzave.dart';
import '../widgeti/prikazi_stanja.dart';
import '../widgeti/zaglavlje.dart';

class FormularEkran extends StatelessWidget {
  const FormularEkran({super.key, this.idPonude, this.idPrijave})
    : assert(idPonude != null || idPrijave != null, 'Formular je za novu prijavu ili za izmenu.');

  static const kljucPisma = Key('motivaciono-pismo');

  final IdPonude? idPonude;
  final IdPrijave? idPrijave;

  void _posleCuvanja(BuildContext context, PonudeStanje stanje) {
    final formular = context.read<FormularPrijaveBloc>().state;
    if (stanje is! PonudeUcitane || formular is! FormularSacuvan) return;
    if (stanje.podaci.prijava(formular.prijava.id) != formular.prijava) return;
    final poruka = switch ((formular.poslata, idPrijave)) {
      (true, _) => 'Prijava je poslata. Čeka odluku koordinatora.',
      (false, null) => 'Prijava je sačuvana u pripremi.',
      (false, _) => 'Izmene su sačuvane.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(poruka)));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PonudeBloc>();
    return BlocConsumer<PonudeBloc, PonudeStanje>(
      listenWhen: (pre, sad) => sad is PonudeUcitane,
      listener: _posleCuvanja,
      builder: (context, stanje) {
        switch (stanje) {
          case PonudeUcitavanje():
            return const EkranStanja(child: PrikazUcitavanja());
          case PonudeGreska():
            return EkranStanja(child: PrikazGreske(onPonovo: () => bloc.add(const PonudeZatrazene())));
          case PonudePrazne():
            return const NijePronadjenoEkran();
          case PonudeUcitane(:final podaci):
            final postojeca = idPrijave == null ? null : podaci.prijava(idPrijave!);
            if (idPrijave != null && postojeca == null) return const NijePronadjenoEkran();
            final ponuda = podaci.ponuda(idPonude ?? postojeca!.idPonude);
            if (ponuda == null) return const NijePronadjenoEkran();
            return _Formular(podaci: podaci, ponuda: ponuda, postojeca: postojeca);
        }
      },
    );
  }
}

class _Formular extends StatefulWidget {
  const _Formular({required this.podaci, required this.ponuda, required this.postojeca});

  final PregledPodataka podaci;
  final Ponuda ponuda;
  final Prijava? postojeca;

  @override
  State<_Formular> createState() => _FormularState();
}

class _FormularState extends State<_Formular> {
  final _kljucForme = GlobalKey<FormState>();
  late final _pismo = TextEditingController(text: widget.postojeca?.motivacionoPismo.tekst ?? '');
  late final _napomena = TextEditingController(text: widget.postojeca?.napomena ?? '');

  bool _poslednjeSlanje = false;

  @override
  void dispose() {
    _pismo.dispose();
    _napomena.dispose();
    super.dispose();
  }

  bool get _menjaPoslatu => !widget.podaci.mozeSePoslati(widget.postojeca);

  String? _proveriPismo(String? unos) => MotivacionoPismo.proveri(unos ?? '').greskaIliNull?.poruka;

  String? get _napomenaIliNull {
    final tekst = _napomena.text.trim();
    return tekst.isEmpty ? null : tekst;
  }

  void _poruka(String tekst, {SnackBarAction? akcija}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tekst), action: akcija));

  void _zatrazi({required bool posalji}) {
    if (!mounted || !_kljucForme.currentState!.validate()) return;
    final pismo = MotivacionoPismo.proveri(_pismo.text).vrednostIliNull!;
    _poslednjeSlanje = posalji;
    final bloc = context.read<FormularPrijaveBloc>();
    bloc.add(
      posalji
          ? SlanjeZatrazeno(pismo: pismo, napomena: _napomenaIliNull)
          : CuvanjeZatrazeno(pismo: pismo, napomena: _napomenaIliNull),
    );
  }

  void _reaguj(BuildContext context, FormularPrijaveStanje stanje) {
    switch (stanje) {
      case FormularSacuvan():
        context.read<PonudeBloc>().add(const PonudeOsvezene());
        context.read<ProfilBloc>().add(const ProfilOsvezen());
      case FormularOdbijen(:final greska):
        _poruka(greska.poruka);
      case FormularNeuspeo():
        _poruka(
          'Prijava nije sačuvana.',
          akcija: SnackBarAction(
            label: 'Pokušaj ponovo',
            onPressed: () => _zatrazi(posalji: _poslednjeSlanje),
          ),
        );
      case FormularSpreman() || FormularUToku():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FormularPrijaveBloc, FormularPrijaveStanje>(
      listener: _reaguj,
      builder: (context, stanje) => _ekran(context, uToku: stanje is FormularUToku || stanje is FormularSacuvan),
    );
  }

  Widget _ekran(BuildContext context, {required bool uToku}) {
    final ponuda = widget.ponuda;
    final podaci = widget.podaci;
    final univerzitet = podaci.univerzitet(ponuda.idUniverziteta);
    final student = podaci.student;
    final postojeca = widget.postojeca;
    final stanje = postojeca?.stanje ?? const UPripremi();
    final tekst = Theme.of(context).textTheme;
    final sporedni = tekst.bodySmall?.copyWith(color: Boje.sporedniTekst, fontSize: 12);

    return PopScope(
      canPop: !uToku,
      child: Scaffold(
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
                        DugmeZaglavlja(
                          ikona: Icons.close,
                          opis: 'Zatvori',
                          onPressed: uToku ? null : () => context.pop(),
                        ),
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
                      enabled: !uToku,
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
                      enabled: !uToku,
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
                      ProveraPreSlanja(ponuda: ponuda, student: student, uslovi: podaci.uslovi(ponuda)),
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
                ? FilledButton(
                    onPressed: uToku ? null : () => _zatrazi(posalji: false),
                    child: const Text('Sačuvaj izmene'),
                  )
                : Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: OutlinedButton(
                          onPressed: uToku ? null : () => _zatrazi(posalji: false),
                          child: const Text('Sačuvaj'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 5,
                        child: FilledButton(
                          onPressed: uToku ? null : () => _zatrazi(posalji: true),
                          child: const Text('Pošalji prijavu'),
                        ),
                      ),
                    ],
                  ),
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
