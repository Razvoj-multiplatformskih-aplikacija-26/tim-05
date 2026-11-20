import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import '../zavisnosti.dart';

Future<bool> osigurajPrijavu(BuildContext context) async =>
    context.read<SesijaBloc>().state is Prijavljen || (await context.push<bool>('/login') ?? false);

class PrijavljivanjeEkran extends StatelessWidget {
  const PrijavljivanjeEkran({super.key});

  static const porukaPogresneAplikacije = 'Aplikacija je za studente. Koordinatori koriste backoffice.';

  @override
  Widget build(BuildContext context) {
    final sesija = context.read<SesijaBloc>();
    return BlocConsumer<SesijaBloc, SesijaStanje>(
      listenWhen: (pre, sad) => sad is Prijavljen,
      listener: (context, _) => context.pop(true),
      builder: (context, stanje) => EkranPrijavljivanja(
        naslov: 'Prijava na nalog',
        appBar: AppBar(),
        prijaviSe: context.read<ZavisnostiAplikacije>().prijaviSe,
        razlog: switch (stanje) {
          Odjavljen(:final razlog) => razlog,
          SesijaNepoznata() || Prijavljen() => null,
        },
        porukaPogresneAplikacije: porukaPogresneAplikacije,
        naUspeh: (korisnik) => sesija.add(SesijaZapoceta(korisnik)),
      ),
    );
  }
}
