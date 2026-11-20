import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:use_cases/use_cases.dart' show PrijaviSe;

import '../tekst/poruke_kvara.dart';
import '../tema/tema.dart';
import 'logo.dart';


class EkranPrijavljivanja extends StatelessWidget {
  const EkranPrijavljivanja({
    super.key,
    required this.naslov,
    required this.prijaviSe,
    required this.naUspeh,
    required this.porukaPogresneAplikacije,
    this.razlog,
    this.appBar,
  });

  static const porukaPogresnihPodataka = 'Pogrešno korisničko ime ili lozinka.';

  final String naslov;
  final PrijaviSe prijaviSe;

  final void Function(Korisnik korisnik) naUspeh;
  final String porukaPogresneAplikacije;

  final RazlogOdjave? razlog;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PrijavljivanjeBloc(prijaviSe: prijaviSe),
      child: BlocListener<PrijavljivanjeBloc, PrijavljivanjeStanje>(
        listener: (context, stanje) {
          if (stanje case PrijavljivanjeUspelo(:final korisnik)) naUspeh(korisnik);
        },
        child: Scaffold(
          appBar: appBar,
          body: SafeArea(
            child: _Forma(naslov: naslov, razlog: razlog, porukaPogresneAplikacije: porukaPogresneAplikacije),
          ),
        ),
      ),
    );
  }
}

class _Forma extends StatefulWidget {
  const _Forma({required this.naslov, required this.porukaPogresneAplikacije, this.razlog});

  final String naslov;
  final String porukaPogresneAplikacije;
  final RazlogOdjave? razlog;

  @override
  State<_Forma> createState() => _FormaState();
}

class _FormaState extends State<_Forma> {
  final _korisnickoIme = TextEditingController();
  final _lozinka = TextEditingController();

  @override
  void dispose() {
    _korisnickoIme.dispose();
    _lozinka.dispose();
    super.dispose();
  }

  void _posalji() => context.read<PrijavljivanjeBloc>().add(
    PrijavljivanjeZatrazeno(korisnickoIme: _korisnickoIme.text, lozinka: _lozinka.text),
  );

  @override
  Widget build(BuildContext context) {
    final tekst = Theme.of(context).textTheme;
    final stanje = context.watch<PrijavljivanjeBloc>().state;
    final uToku = stanje is PrijavljivanjeUToku;
    final poruka = switch (stanje) {
      PrijavljivanjeOdbijeno() => EkranPrijavljivanja.porukaPogresnihPodataka,
      PrijavljivanjeNeuspelo(:final uzrok) => porukaKvara(uzrok),
      _ => switch (widget.razlog) {
        RazlogOdjave.pogresnaAplikacija => widget.porukaPogresneAplikacije,
        RazlogOdjave.istekla => porukaSesijaIstekla,
        RazlogOdjave.nedostupan => porukaNemaVeze,
        RazlogOdjave.odjava || null => null,
      },
    };
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Boje.bordo, shape: BoxShape.circle),
                    child: Padding(padding: EdgeInsets.all(10), child: Logo(velicina: 56)),
                  ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  header: true,
                  child: Text(widget.naslov, style: tekst.headlineSmall, textAlign: TextAlign.center),
                ),
                const SizedBox(height: 24),
                if (poruka != null) ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      poruka,
                      style: tekst.bodyMedium?.copyWith(color: Boje.greska),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _korisnickoIme,
                  enabled: !uToku,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.username],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Korisničko ime'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _lozinka,
                  enabled: !uToku,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _posalji(),
                  decoration: const InputDecoration(labelText: 'Lozinka'),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: uToku ? null : _posalji,
                  child: uToku
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, semanticsLabel: 'Prijava u toku'),
                        )
                      : const Text('Uloguj se'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}