import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/ekrani/formular_ekran.dart';
import 'package:mobile/tema/tema.dart';
import 'package:mobile/zavisnosti.dart';

void main() {
  Widget formular() {
    final zavisnosti = ZavisnostiAplikacije.lazne(kasnjenje: Duration.zero);
    const idPonude = IdPonude('po-6');
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
            create: (_) => FormularPrijaveBloc(
              sacuvajPrijavu: zavisnosti.sacuvajPrijavu,
              korisnik: zavisnosti.korisnik,
              idPonude: idPonude,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTema.svetla(),
          home: const FormularEkran(idPonude: idPonude),
        ),
      ),
    );
  }

  testWidgets('predugačko motivaciono pismo prikazuje poruku na srpskom', (tester) async {
    await tester.pumpWidget(formular());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(FormularEkran.kljucPisma));
    await tester.enterText(find.byKey(FormularEkran.kljucPisma), 'đ' * (MotivacionoPismo.najvise + 1));
    await tester.pump();

    expect(
      find.text('Motivaciono pismo može imati najviše ${MotivacionoPismo.najvise} znakova (sada ima 1501).'),
      findsOneWidget,
    );
  });

  testWidgets('pismo od tačno 1500 znakova je ispravno', (tester) async {
    await tester.pumpWidget(formular());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(FormularEkran.kljucPisma));
    await tester.enterText(find.byKey(FormularEkran.kljucPisma), 'đ' * MotivacionoPismo.najvise);
    await tester.pump();

    expect(find.textContaining('može imati najviše'), findsNothing);
  });
}
