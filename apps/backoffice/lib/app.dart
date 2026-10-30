import 'package:blocs/blocs.dart';
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

  final ZavisnostiBackoffice zavisnosti;

  @override
  State<BackofficeAplikacija> createState() => _BackofficeAplikacijaState();
}

class _BackofficeAplikacijaState extends State<BackofficeAplikacija> {
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
      child: BlocProvider(
        create: (_) => KoordinatorBloc(
          ucitajPregled: zavisnosti.ucitajPregled,
          prihvatiPrijavu: zavisnosti.prihvatiPrijavu,
          staviNaListuCekanja: zavisnosti.staviNaListuCekanja,
          odbijPrijavu: zavisnosti.odbijPrijavu,
          korisnik: zavisnosti.korisnik,
        )..add(const PrijaveZatrazene()),
        child: MaterialApp.router(
          title: 'ErasmusGo · Backoffice',
          debugShowCheckedModeBanner: false,
          theme: AppTema.svetla(),
          locale: BackofficeAplikacija.jezik,
          supportedLocales: const [BackofficeAplikacija.jezik],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: _ruter,
        ),
      ),
    );
  }
}
