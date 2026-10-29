import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';


import '../widgeti/zaglavlje.dart';

class UrediProfilEkran extends StatelessWidget {
  const UrediProfilEkran({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProfilBloc>();
    return BlocBuilder<ProfilBloc, ProfilStanje>(
      buildWhen: (pre, sad) => pre.runtimeType != sad.runtimeType,
      builder: (context, stanje) => switch (stanje) {
        ProfilUcitavanje() => const EkranStanja(child: PrikazUcitavanja()),
        ProfilGreska() => EkranStanja(child: PrikazGreske(onPonovo: () => bloc.add(const ProfilZatrazen()))),
        ProfilSaPodacima(:final podaci) => _Forma(pocetni: podaci.student),
      },
    );
  }
}

class _Forma extends StatefulWidget {
  const _Forma({required this.pocetni});

  final Student pocetni;

  @override
  State<_Forma> createState() => _FormaState();
}

class _FormaState extends State<_Forma> {
  late final Student _pocetni = widget.pocetni;
  late final _ime = TextEditingController(text: _pocetni.ime);
  late final _prezime = TextEditingController(text: _pocetni.prezime);
  late final _email = TextEditingController(text: _pocetni.email);
  late final _fakultet = TextEditingController(text: _pocetni.fakultet);
  late final _smer = TextEditingController(text: _pocetni.smer);
  late final _indeks = TextEditingController(text: _pocetni.brojIndeksa);
  late final _prosek = TextEditingController(text: formatProsek(_pocetni.prosek));

  final _kljucForme = GlobalKey<FormState>();

  late int _godina;
  late Map<Jezik, NivoJezika> _jezici;

  @override
  void dispose() {
    _ime.dispose();
    _prezime.dispose();
    _email.dispose();
    _fakultet.dispose();
    _smer.dispose();
    _indeks.dispose();
    _prosek.dispose();
    super.dispose();
  }

  void _sacuvaj() {
    final forma = _kljucForme.currentState!;
    if (!forma.validate()) return;
    forma.save();
    context.read<ProfilBloc>().add(
      ProfilIzmenjen(
        Student(
          id: _pocetni.id,
          ime: _ime.text.trim(),
          prezime: _prezime.text.trim(),
          brojIndeksa: _indeks.text.trim(),
          email: _email.text.trim(),
          fakultet: _fakultet.text.trim(),
          smer: _smer.text.trim(),
          godinaStudija: _godina,
          prosek: Prosek.proveri(_prosek.text).vrednostIliNull!,
          znanjeJezika: _jezici,
        ),
      ),
    );
  }

  static bool _cuvaSe(ProfilStanje stanje) => stanje is ProfilSaPodacima && stanje.cuvaSeProfil;

  static bool _odgovor(ProfilStanje pre, ProfilStanje sad) =>
      _cuvaSe(pre) && !_cuvaSe(sad) && sad is ProfilSaPodacima && sad.obavestenje != null;

  void _reaguj(BuildContext context, ProfilStanje stanje) {
    final obavestenje = stanje is ProfilSaPodacima ? stanje.obavestenje : null;
    final poruka = switch (obavestenje) {
      ProfilSacuvan() => 'Profil je sačuvan.',
      AkcijaOdbijena(:final greska) => greska.poruka,
      _ => 'Profil nije sačuvan. Proverite vezu i pokušajte ponovo.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(poruka)));
    context.read<ProfilBloc>().add(const ObavestenjeProfilaProcitano());
    if (obavestenje is ProfilSacuvan) {
      context.read<PonudeBloc>().add(const PonudeOsvezene());
      context.pop();
    }
  }

  Future<void> _dodajJezik(FormFieldState<Map<Jezik, NivoJezika>> polje) async {
    final trenutni = polje.value!;
    final preostali = [
      for (final j in Jezik.values)
        if (!trenutni.containsKey(j)) j,
    ];
    final izbor = await showModalBottomSheet<Jezik>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final jezik in preostali)
              ListTile(title: Text(velikoPrvo(nazivJezika(jezik))), onTap: () => Navigator.pop(context, jezik)),
          ],
        ),
      ),
    );
    if (izbor != null && polje.mounted) polje.didChange({...polje.value!, izbor: NivoJezika.values.first});
  }

  @override
  Widget build(BuildContext context) {
    final tekst = Theme.of(context).textTheme;
    final inicijali = '${_pocetni.ime.characters.first}${_pocetni.prezime.characters.first}';

    return BlocListener<ProfilBloc, ProfilStanje>(
      listenWhen: _odgovor,
      listener: _reaguj,
      child: BlocBuilder<ProfilBloc, ProfilStanje>(
        buildWhen: (pre, sad) => _cuvaSe(pre) != _cuvaSe(sad),
        builder: (context, stanje) {
          final cuva = _cuvaSe(stanje);
          return PopScope(
            canPop: !cuva,
            child: Scaffold(
              body: Form(
                key: _kljucForme,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    BordoZaglavlje(
                      razmakDole: 10,
                      dubinaPreklopa: 38,
                      preklop: Center(
                        child: Container(
                          width: 84,
                          height: 84,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Boje.bela,
                            shape: BoxShape.circle,
                            border: Border.all(color: Boje.pozadina, width: 4),
                          ),
                          child: Text(
                            inicijali,
                            style: tekst.headlineMedium?.copyWith(
                              color: Boje.bordo,
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          DugmeZaglavlja(
                            ikona: Icons.arrow_back,
                            opis: 'Nazad',
                            onPressed: cuva ? null : () => context.pop(),
                          ),
                          const SizedBox(width: 12),
                          Semantics(
                            header: true,
                            child: Text(
                              'Uredi profil',
                              style: tekst.headlineSmall?.copyWith(color: Boje.bela, fontSize: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _Naslov('Lični podaci'),
                          Row(
                            children: [
                              Expanded(
                                child: _Polje(kontroler: _ime, naziv: 'Ime'),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _Polje(kontroler: _prezime, naziv: 'Prezime'),
                              ),
                            ],
                          ),
                          _Polje(kontroler: _email, naziv: 'E-pošta', tastatura: TextInputType.emailAddress),
                          const _Naslov('Studije'),
                          _Polje(kontroler: _fakultet, naziv: 'Fakultet'),
                          _Polje(kontroler: _smer, naziv: 'Smer'),
                          _Polje(kontroler: _indeks, naziv: 'Broj indeksa'),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 2, 4, 6),
                            child: Text(
                              'Godina studija',
                              style: tekst.labelMedium?.copyWith(
                                color: Boje.sporedniTekst,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          FormField<int>(
                            initialValue: _pocetni.godinaStudija,
                            onSaved: (godina) => _godina = godina!,
                            builder: (polje) => Row(
                              children: [
                                for (final godina in [1, 2, 3, 4]) ...[
                                  if (godina > 1) const SizedBox(width: 8),
                                  Expanded(
                                    child: _Godina(
                                      godina: godina,
                                      izabrana: polje.value == godina,
                                      onTap: () => polje.didChange(godina),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const _Naslov('Uslovi za prijave'),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TextFormField(
                              controller: _prosek,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Prosek', hintText: 'npr. 8,74'),
                              validator: (unos) => Prosek.proveri(unos ?? '').greskaIliNull?.poruka,
                            ),
                          ),
                          FormField<Map<Jezik, NivoJezika>>(
                            initialValue: Map.of(_pocetni.znanjeJezika),
                            onSaved: (jezici) => _jezici = jezici!,
                            builder: (polje) {
                              final jezici = polje.value!;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final jezik in jezici.keys.toList())
                                    Padding(
                                      key: ValueKey(jezik),
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: DropdownButtonFormField<NivoJezika>(
                                              initialValue: jezici[jezik],
                                              decoration: InputDecoration(
                                                labelText: '${velikoPrvo(nazivJezika(jezik))} jezik',
                                              ),
                                              items: [
                                                for (final nivo in NivoJezika.values)
                                                  DropdownMenuItem(value: nivo, child: Text(nivo.oznaka)),
                                              ],
                                              onChanged: (nivo) {
                                                if (nivo != null) polje.didChange({...jezici, jezik: nivo});
                                              },
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'Ukloni jezik',
                                            onPressed: () => polje.didChange({...jezici}..remove(jezik)),
                                            icon: const Icon(Icons.close, color: Boje.sporedniTekst),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (jezici.length < Jezik.values.length)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton.icon(
                                        onPressed: () => _dodajJezik(polje),
                                        icon: const Icon(Icons.add),
                                        label: const Text('Dodaj jezik'),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                            child: Text(
                              'Prosek i nivo jezika koriste se za proveru uslova ponuda.',
                              style: tekst.bodySmall?.copyWith(color: Boje.sporedniTekst, fontSize: 12),
                            ),
                          ),
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
                  child: Row(
                    children: [
                      Expanded(
                        flex: 7,
                        child: OutlinedButton(
                          onPressed: cuva ? null : () => context.pop(),
                          child: const Text('Otkaži'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 10,
                        child: FilledButton(onPressed: cuva ? null : _sacuvaj, child: const Text('Sačuvaj izmene')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Polje extends StatelessWidget {
  const _Polje({required this.kontroler, required this.naziv, this.tastatura = TextInputType.text});

  final TextEditingController kontroler;
  final String naziv;
  final TextInputType tastatura;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: kontroler,
        keyboardType: tastatura,
        textCapitalization: tastatura == TextInputType.text ? TextCapitalization.words : TextCapitalization.none,
        decoration: InputDecoration(labelText: naziv),
      ),
    );
  }
}

class _Godina extends StatelessWidget {
  const _Godina({required this.godina, required this.izabrana, required this.onTap});

  final int godina;
  final bool izabrana;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final oblik = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: izabrana ? Boje.bordo : Boje.ivica, width: 1.5),
    );
    return Semantics(
      selected: izabrana,
      button: true,
      label: '$godina. godina',
      excludeSemantics: true,
      child: Material(
        color: izabrana ? Boje.bordo : Boje.bela,
        shape: oblik,
        child: InkWell(
          customBorder: oblik,
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Center(
              child: Text(
                '$godina.',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: izabrana ? Boje.bela : Boje.sporedniTekst, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
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
        child: Text(tekst, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Boje.bordo, fontSize: 15)),
      ),
    );
  }
}
