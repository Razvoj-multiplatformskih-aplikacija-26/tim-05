import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/zavisnosti.dart';
import 'package:ui/ui.dart';

import 'pomocno.dart';

void main() {
  testWidgets('Početna prikazuje učitavanje, grešku, prazan prikaz i podatke', (tester) async {
    postaviTelefon(tester);
    final zavisnosti = ZavisnostiAplikacije.lazne(kasnjenje: const Duration(seconds: 1));
    final baza = zavisnosti.laznaBaza!;
    baza.neuspesniZahtevi = 1;

    await otvoriAplikaciju(tester, zavisnosti);
    expect(find.byType(PrikazUcitavanja), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text(PrikazGreske.naslov), findsOneWidget);

    baza.prazneListePonuda = 1;
    await tester.tap(find.text('Pokušaj ponovo'));
    await tester.pump();
    expect(find.byType(PrikazUcitavanja), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Trenutno nema objavljenih ponuda.'), findsOneWidget);

    await tester.tap(find.text('Osveži'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Najnovije ponude'), findsOneWidget);
  });
}
