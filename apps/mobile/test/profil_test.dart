import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/ekrani/profil_ekran.dart';
import 'package:mobile/widgeti/prikazi_stanja.dart';
import 'package:mobile/zavisnosti.dart';

import 'pomocno.dart';

void main() {
  testWidgets('Profil prikazuje učitavanje, grešku, prazan prikaz i podatke', (tester) async {
    postaviTelefon(tester);
    final zavisnosti = ZavisnostiAplikacije.lazne(kasnjenje: const Duration(seconds: 1));
    final baza = zavisnosti.laznaBaza!;

    await otvoriAplikaciju(tester, zavisnosti);
    await tester.pump(const Duration(seconds: 2));

    baza.neuspesniZahtevi = 1;
    await tester.tap(find.text('Profil'));
    await tester.pump();
    expect(find.byType(PrikazUcitavanja), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text(PrikazGreske.naslov), findsOneWidget);

    baza.prazneListePrijava = 1;
    await tester.tap(find.text('Pokušaj ponovo'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Još nemate prijava. Izaberite ponudu na Početnoj.'), findsOneWidget);

    await tester.tap(find.byTooltip('Lažni podaci'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ponovo učitaj'));
    await tester.pump();
    expect(find.byType(PrikazUcitavanja), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(ProfilEkran), matching: find.text('Lisabon')), findsOneWidget);
  });
}
