import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../podaci/lazni_podaci.dart';
import '../tekst/format.dart';
import '../tema/tema.dart';
import '../widgeti/zaglavlje.dart';

class UrediProfilEkran extends StatefulWidget {
  const UrediProfilEkran({super.key});

  @override
  State<UrediProfilEkran> createState() => _UrediProfilEkranState();
}

class _UrediProfilEkranState extends State<UrediProfilEkran> {
  final Student _pocetni = skladiste.student;
  late final _ime = TextEditingController(text: _pocetni.ime);
  late final _prezime = TextEditingController(text: _pocetni.prezime);
  late final _email = TextEditingController(text: _pocetni.email);
  late final _fakultet = TextEditingController(text: _pocetni.fakultet);
  late final _smer = TextEditingController(text: _pocetni.smer);
  late final _indeks = TextEditingController(text: _pocetni.brojIndeksa);
  late int _godina = _pocetni.godinaStudija;

  @override
  void dispose() {
    _ime.dispose();
    _prezime.dispose();
    _email.dispose();
    _fakultet.dispose();
    _smer.dispose();
    _indeks.dispose();
    super.dispose();
  }

  void _sacuvaj() {
    skladiste.student = Student(
      id: _pocetni.id,
      ime: _ime.text.trim(),
      prezime: _prezime.text.trim(),
      brojIndeksa: _indeks.text.trim(),
      email: _email.text.trim(),
      fakultet: _fakultet.text.trim(),
      smer: _smer.text.trim(),
      godinaStudija: _godina,
      prosek: _pocetni.prosek,
      znanjeJezika: _pocetni.znanjeJezika,
    );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil je sačuvan.')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final tekst = Theme.of(context).textTheme;
    final inicijali = '${_pocetni.ime.characters.first}${_pocetni.prezime.characters.first}';
    final jezik = _pocetni.znanjeJezika.entries.firstOrNull;

    return Scaffold(
      body: ListView(
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
                  style: tekst.headlineMedium?.copyWith(color: Boje.bordo, fontSize: 30, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            child: Row(
              children: [
                DugmeZaglavlja(ikona: Icons.arrow_back, opis: 'Nazad', onPressed: () => context.pop()),
                const SizedBox(width: 12),
                Semantics(
                  header: true,
                  child: Text('Uredi profil', style: tekst.headlineSmall?.copyWith(color: Boje.bela, fontSize: 20)),
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
                    style: tekst.labelMedium?.copyWith(color: Boje.sporedniTekst, fontWeight: FontWeight.w600),
                  ),
                ),
                Row(
                  children: [
                    for (final godina in [1, 2, 3, 4]) ...[
                      if (godina > 1) const SizedBox(width: 8),
                      Expanded(
                        child: _Godina(
                          godina: godina,
                          izabrana: _godina == godina,
                          onTap: () => setState(() => _godina = godina),
                        ),
                      ),
                    ],
                  ],
                ),
                const _Naslov('Uslovi za prijave'),
                Row(
                  children: [
                    Expanded(
                      child: _Prikaz(naziv: 'Prosek', vrednost: formatProsek(_pocetni.prosek)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Prikaz(
                        naziv: jezik == null ? 'Jezik' : '${velikoPrvo(nazivJezika(jezik.key))} jezik',
                        vrednost: jezik == null ? '—' : jezik.value.oznaka,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                  child: Text(
                    'Prosek i nivo jezika koriste se za proveru uslova ponuda i ne menjaju se ovde.',
                    style: tekst.bodySmall?.copyWith(color: Boje.sporedniTekst, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
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
                child: OutlinedButton(onPressed: () => context.pop(), child: const Text('Otkaži')),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 10,
                child: FilledButton(onPressed: _sacuvaj, child: const Text('Sačuvaj izmene')),
              ),
            ],
          ),
        ),
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

class _Prikaz extends StatelessWidget {
  const _Prikaz({required this.naziv, required this.vrednost});

  final String naziv;
  final String vrednost;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        initialValue: vrednost,
        readOnly: true,
        decoration: InputDecoration(
          labelText: naziv,
          suffixIcon: const Icon(Icons.lock_outline, size: 18, color: Boje.sporedniTekst),
        ),
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
