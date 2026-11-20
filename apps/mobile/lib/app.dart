import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import 'router.dart';
import 'zavisnosti.dart';

class ErasmusAplikacija extends StatefulWidget {
  const ErasmusAplikacija({super.key, required this.zavisnosti});

  static const jezik = Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');

  final ZavisnostiAplikacije zavisnosti;

  @override
  State<ErasmusAplikacija> createState() => _ErasmusAplikacijaState();
}

class _ErasmusAplikacijaState extends State<ErasmusAplikacija> {
  late final SesijaBloc _sesija = SesijaBloc(
    obnoviSesiju: widget.zavisnosti.obnoviSesiju,
    odjaviSe: widget.zavisnosti.odjaviSe,
    dozvoljen: PravaPristupa.koristiMobilnuAplikaciju,
    istekle: widget.zavisnosti.istekleSesije,
  )..add(const ObnovaSesijeZatrazena());
  late final GoRouter _ruter = napraviRuter();

  bool _profilNapravljen = false;

  @override
  void dispose() {
    _ruter.dispose();
    _sesija.close();
    super.dispose();
  }

  static Korisnik? _korisnik(SesijaStanje sesija) => switch (sesija) {
    Prijavljen(:final korisnik) => korisnik,
    SesijaNepoznata() || Odjavljen() => null,
  };

  @override
  Widget build(BuildContext context) {
    final zavisnosti = widget.zavisnosti;
    return RepositoryProvider.value(
      value: zavisnosti,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _sesija),
          BlocProvider(
            create: (_) =>
                PonudeBloc(ucitajPregled: zavisnosti.ucitajPregled, promeniSacuvanu: zavisnosti.promeniSacuvanu),
          ),
          BlocProvider(
            create: (_) {
              _profilNapravljen = true;
              final profil = ProfilBloc(
                ucitajPregled: zavisnosti.ucitajPregled,
                povuciPrijavu: zavisnosti.povuciPrijavu,
                potvrdiMesto: zavisnosti.potvrdiMesto,
                odbijMesto: zavisnosti.odbijMesto,
                obrisiPrijavu: zavisnosti.obrisiPrijavu,
                sacuvajProfil: zavisnosti.sacuvajProfil,
                korisnik: _korisnik(_sesija.state),
              );
              if (_sesija.state is! SesijaNepoznata) profil.add(const ProfilZatrazen());
              return profil;
            },
          ),
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener<SesijaBloc, SesijaStanje>(
              listenWhen: (pre, sad) =>
                  sad is! SesijaNepoznata && (pre is SesijaNepoznata || _korisnik(pre) != _korisnik(sad)),
              listener: (context, sesija) {
                final korisnik = _korisnik(sesija);
                context.read<PonudeBloc>().add(PonudeKorisnikPromenjen(korisnik));
                if (_profilNapravljen) context.read<ProfilBloc>().add(ProfilKorisnikPromenjen(korisnik));
              },
            ),
            BlocListener<SesijaBloc, SesijaStanje>(
              listenWhen: (pre, sad) => pre is Prijavljen && sad is Odjavljen && sad.razlog == RazlogOdjave.istekla,
              listener: (context, sesija) => _ruter.push('/login'),
            ),
            BlocListener<PonudeBloc, PonudeStanje>(
              listenWhen: (pre, sad) =>
                  sad is PonudeUcitane &&
                  (sad.obavestenje is PonudaSacuvana || sad.obavestenje is PonudaUklonjena) &&
                  (pre is! PonudeUcitane || pre.obavestenje != sad.obavestenje),
              listener: (context, _) => context.read<ProfilBloc>().add(const ProfilOsvezen()),
            ),
          ],
          child: MaterialApp.router(
            title: 'ErasmusGo',
            debugShowCheckedModeBanner: false,
            theme: AppTema.svetla(),
            locale: ErasmusAplikacija.jezik,
            supportedLocales: const [ErasmusAplikacija.jezik],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: _ruter,
          ),
        ),
      ),
    );
  }
}
