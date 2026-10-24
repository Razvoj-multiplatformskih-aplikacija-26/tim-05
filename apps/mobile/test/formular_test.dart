import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/ekrani/formular_ekran.dart';
import 'package:mobile/tema/tema.dart';

void main() {
  Widget formular() {
    return MaterialApp(
      theme: AppTema.svetla(),
      home: const FormularEkran(idPonude: IdPonude('po-6')),
    );
  }

  testWidgets('predugačko motivaciono pismo prikazuje poruku na srpskom', (tester) async {
    await tester.pumpWidget(formular());
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
    await tester.ensureVisible(find.byKey(FormularEkran.kljucPisma));
    await tester.enterText(find.byKey(FormularEkran.kljucPisma), 'đ' * MotivacionoPismo.najvise);
    await tester.pump();

    expect(find.textContaining('može imati najviše'), findsNothing);
  });
}
