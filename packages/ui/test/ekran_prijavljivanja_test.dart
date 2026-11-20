import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

const student1 = Korisnik(id: IdKorisnika('s-1'), korisnickoIme: 'student1', uloga: Uloga.student);

final class Nalozi implements SesijaRepository {
  bool serverRadi = true;

  @override
  Future<Korisnik?> prijavi({required String korisnickoIme, required String lozinka}) async {
    if (!serverRadi) throw const GreskaRepozitorijuma('Server nije dostupan', vrsta: VrstaKvara.nemaVeze);
    return lozinka == 'erasmus-demo' ? student1 : null;
  }

  @override
  Future<Korisnik?> trenutni() async => null;

  @override
  Future<void> odjavi() async {}

  @override
  Stream<void> get istekle => const Stream.empty();
}

void main() {
  late Nalozi nalozi;
  Korisnik? prijavljen;

  setUp(() {
    nalozi = Nalozi();
    prijavljen = null;
  });

  Widget ekran({RazlogOdjave? razlog}) => MaterialApp(
    theme: AppTema.svetla(),
    home: EkranPrijavljivanja(
      naslov: 'Prijava na nalog',
      prijaviSe: PrijaviSe(sesije: nalozi),
      naUspeh: (korisnik) => prijavljen = korisnik,
      porukaPogresneAplikacije: 'Pogrešna aplikacija.',
      razlog: razlog,
    ),
  );

  Future<void> prijaviSe(WidgetTester tester, String lozinka) async {
    await tester.enterText(find.widgetWithText(TextField, 'Korisničko ime'), 'student1');
    await tester.enterText(find.widgetWithText(TextField, 'Lozinka'), lozinka);
    await tester.tap(find.widgetWithText(FilledButton, 'Uloguj se'));
    await tester.pumpAndSettle();
  }

  testWidgets('ispravna lozinka javlja korisnika aplikaciji', (tester) async {
    await tester.pumpWidget(ekran());
    await prijaviSe(tester, 'erasmus-demo');

    expect(prijavljen, student1);
  });

  testWidgets('pogrešna lozinka: poruka na srpskom, korisnik nije prijavljen', (tester) async {
    await tester.pumpWidget(ekran());
    await prijaviSe(tester, 'pogresna');

    expect(find.text(EkranPrijavljivanja.porukaPogresnihPodataka), findsOneWidget);
    expect(prijavljen, isNull);
  });

  testWidgets('server ne radi: „Nema veze sa serverom.", bez tehničkog teksta', (tester) async {
    nalozi.serverRadi = false;
    await tester.pumpWidget(ekran());
    await prijaviSe(tester, 'erasmus-demo');

    expect(find.text(porukaNemaVeze), findsOneWidget);
    expect(find.textContaining('GreskaRepozitorijuma'), findsNothing);
  });

  testWidgets('razlog iz sesije daje poruku: istekla prijava i pogrešna aplikacija', (tester) async {
    await tester.pumpWidget(ekran(razlog: RazlogOdjave.istekla));
    expect(find.text(porukaSesijaIstekla), findsOneWidget);

    await tester.pumpWidget(ekran(razlog: RazlogOdjave.pogresnaAplikacija));
    expect(find.text('Pogrešna aplikacija.'), findsOneWidget);

    await tester.pumpWidget(ekran(razlog: RazlogOdjave.odjava));
    expect(find.text(porukaSesijaIstekla), findsNothing);
    expect(find.text('Pogrešna aplikacija.'), findsNothing);
  });

  testWidgets('PrikazGreske kaze da server nije dostupan', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PrikazGreske(
          uzrok: const GreskaRepozitorijuma('Server nije dostupan', vrsta: VrstaKvara.nemaVeze),
          onPonovo: () {},
        ),
      ),
    );

    expect(find.text(porukaNemaVeze), findsOneWidget);
    expect(find.text('Pokušaj ponovo'), findsOneWidget);
  });
}
