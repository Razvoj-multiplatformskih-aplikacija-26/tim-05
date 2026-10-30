import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:blocs/blocs.dart';
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
  late final GoRouter _ruter = napraviRuter();

  @override
  void dispose() {
    _ruter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zavisnosti = widget.zavisnosti;
    return RepositoryProvider.value(
      value: zavisnosti,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => PonudeBloc(
              ucitajPregled: zavisnosti.ucitajPregled,
              promeniSacuvanu: zavisnosti.promeniSacuvanu,
              korisnik: zavisnosti.korisnik,
            )..add(const PonudeZatrazene()),
          ),
          BlocProvider(
            create: (_) => ProfilBloc(
              ucitajPregled: zavisnosti.ucitajPregled,
              povuciPrijavu: zavisnosti.povuciPrijavu,
              potvrdiMesto: zavisnosti.potvrdiMesto,
              odbijMesto: zavisnosti.odbijMesto,
              obrisiPrijavu: zavisnosti.obrisiPrijavu,
              sacuvajProfil: zavisnosti.sacuvajProfil,
              korisnik: zavisnosti.korisnik,
            )..add(const ProfilZatrazen()),
          ),
        ],
        // Sačuvane ponude prikazuje i profil (kartica „Sačuvano"), iz ProfilBloc-a. Kad PonudeBloc sačuva ili
        // ukloni ponudu, profil se osvežava ovde, iznad rutera, jer ovaj listener postoji dok aplikacija radi.
        // Ranije je to radio ekran Ponuda, pa ako se izašlo pre kraja čuvanja, nije imao ko da javi profilu.
        child: BlocListener<PonudeBloc, PonudeStanje>(
          listenWhen: (pre, sad) =>
              sad is PonudeUcitane &&
              (sad.obavestenje is PonudaSacuvana || sad.obavestenje is PonudaUklonjena) &&
              (pre is! PonudeUcitane || pre.obavestenje != sad.obavestenje),
          listener: (context, _) => context.read<ProfilBloc>().add(const ProfilOsvezen()),
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