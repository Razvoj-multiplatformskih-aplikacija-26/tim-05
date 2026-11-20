import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import 'router.dart';
import 'zavisnosti.dart';

class BackofficeAplikacija extends StatefulWidget {
  const BackofficeAplikacija({super.key, required this.zavisnosti});

  static const jezik = Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');

  static const porukaPogresneAplikacije = 'Backoffice je za koordinatore partnerskih univerziteta.';

  final ZavisnostiBackoffice zavisnosti;

  @override
  State<BackofficeAplikacija> createState() => _BackofficeAplikacijaState();
}

class _BackofficeAplikacijaState extends State<BackofficeAplikacija> {
  late final SesijaBloc _sesija = SesijaBloc(
    obnoviSesiju: widget.zavisnosti.obnoviSesiju,
    odjaviSe: widget.zavisnosti.odjaviSe,
    dozvoljen: PravaPristupa.koristiBackoffice,
    istekle: widget.zavisnosti.istekleSesije,
  )..add(const ObnovaSesijeZatrazena());

  @override
  void dispose() {
    _sesija.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zavisnosti = widget.zavisnosti;
    return RepositoryProvider.value(
      value: zavisnosti,
      child: BlocProvider.value(
        value: _sesija,
        child: BlocBuilder<SesijaBloc, SesijaStanje>(
          builder: (context, sesija) => switch (sesija) {
            SesijaNepoznata() => _aplikacija(
              key: const ValueKey('sesija-nepoznata'),
              pocetni: const Scaffold(body: PrikazUcitavanja()),
            ),
            Odjavljen(:final razlog) => _aplikacija(
              key: ValueKey('odjavljen ${razlog?.name}'),
              pocetni: EkranPrijavljivanja(
                naslov: 'ErasmusGo · Backoffice',
                prijaviSe: zavisnosti.prijaviSe,
                razlog: razlog,
                porukaPogresneAplikacije: BackofficeAplikacija.porukaPogresneAplikacije,
                naUspeh: (korisnik) => _sesija.add(SesijaZapoceta(korisnik)),
              ),
            ),
            Prijavljen(:final korisnik) => _PrijavljenBackoffice(
              key: ValueKey(korisnik.id),
              koordinator: korisnik,
              zavisnosti: zavisnosti,
            ),
          },
        ),
      ),
    );
  }
}

class _PrijavljenBackoffice extends StatefulWidget {
  const _PrijavljenBackoffice({super.key, required this.koordinator, required this.zavisnosti});

  final Korisnik koordinator;
  final ZavisnostiBackoffice zavisnosti;

  @override
  State<_PrijavljenBackoffice> createState() => _PrijavljenBackofficeState();
}

class _PrijavljenBackofficeState extends State<_PrijavljenBackoffice> {
  late final GoRouter _ruter = napraviRuter();

  @override
  void dispose() {
    _ruter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zavisnosti = widget.zavisnosti;
    return BlocProvider(
      create: (_) => KoordinatorBloc(
        ucitajPregled: zavisnosti.ucitajPregled,
        prihvatiPrijavu: zavisnosti.prihvatiPrijavu,
        staviNaListuCekanja: zavisnosti.staviNaListuCekanja,
        odbijPrijavu: zavisnosti.odbijPrijavu,
        korisnik: widget.koordinator,
      )..add(const PrijaveZatrazene()),
      child: _aplikacija(ruter: _ruter),
    );
  }
}

Widget _aplikacija({Key? key, Widget? pocetni, GoRouter? ruter}) {
  const prevodi = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
  if (ruter != null) {
    return MaterialApp.router(
      key: key,
      title: 'ErasmusGo · Backoffice',
      debugShowCheckedModeBanner: false,
      theme: AppTema.svetla(),
      locale: BackofficeAplikacija.jezik,
      supportedLocales: const [BackofficeAplikacija.jezik],
      localizationsDelegates: prevodi,
      routerConfig: ruter,
    );
  }
  return MaterialApp(
    key: key,
    title: 'ErasmusGo · Backoffice',
    debugShowCheckedModeBanner: false,
    theme: AppTema.svetla(),
    locale: BackofficeAplikacija.jezik,
    supportedLocales: const [BackofficeAplikacija.jezik],
    localizationsDelegates: prevodi,
    onGenerateInitialRoutes: (_) => [MaterialPageRoute<void>(builder: (_) => pocetni!)],
    onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => pocetni!),
  );
}
