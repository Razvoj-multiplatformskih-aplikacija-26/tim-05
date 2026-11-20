import 'dart:async';

import 'package:api_client/api_client.dart';
import 'package:backoffice/app.dart';
import 'package:backoffice/podaci/lazni_podaci.dart';
import 'package:backoffice/widgeti/tabela_prijava.dart';
import 'package:backoffice/zavisnosti.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ui/ui.dart';

import 'pomocno.dart';

Future<void> ulogujSe(WidgetTester tester, String korisnickoIme) async {
  await tester.enterText(find.widgetWithText(TextField, 'Korisničko ime'), korisnickoIme);
  await tester.enterText(find.widgetWithText(TextField, 'Lozinka'), 'erasmus-demo');
  await tester.tap(find.widgetWithText(FilledButton, 'Uloguj se'));
  await smiri(tester);
}

void main() {
  testWidgets('bez prijave samo ekran za prijavu; koordinator posle prijave vidi prijave', (tester) async {
    postaviProzor(tester, sirina: 1440);
    await otvoriBackoffice(tester, zavisnosti: ZavisnostiBackoffice.lazne(sat: sat, prijavljen: null));

    expect(find.byType(EkranPrijavljivanja), findsOneWidget);
    expect(find.byType(TabelaPrijava), findsNothing);

    await ulogujSe(tester, 'koordinator1');
    expect(find.byType(TabelaPrijava), findsOneWidget);
  });

  testWidgets('student u backoffice-u: poruka zasto, i ostaje odjavljen', (tester) async {
    postaviProzor(tester, sirina: 1440);
    await otvoriBackoffice(tester, zavisnosti: ZavisnostiBackoffice.lazne(sat: sat, prijavljen: null));

    await ulogujSe(tester, 'student1');

    expect(find.text(BackofficeAplikacija.porukaPogresneAplikacije), findsOneWidget);
    expect(find.byType(TabelaPrijava), findsNothing);
    expect(
      tester.element(find.byType(EkranPrijavljivanja)).read<SesijaBloc>().state,
      const Odjavljen(razlog: RazlogOdjave.pogresnaAplikacija),
    );
  });

  testWidgets('zapamcena prijava: odmah prijave, bez forme; odjava vraca na prijavu', (tester) async {
    postaviProzor(tester, sirina: 1440);
    await otvoriBackoffice(tester);
    expect(find.byType(TabelaPrijava), findsOneWidget);

    await tester.tap(find.byTooltip('Odjavi se'));
    await smiri(tester);

    expect(find.byType(EkranPrijavljivanja), findsOneWidget);
    expect(find.text(porukaSesijaIstekla), findsNothing);
  });

  testWidgets('istekla prijava: ekran za prijavu sa porukom', (tester) async {
    postaviProzor(tester, sirina: 1440);
    final zavisnosti = lazneZavisnosti();
    await otvoriBackoffice(tester, zavisnosti: zavisnosti);

    zavisnosti.lazneSesije!.istekni();
    await smiri(tester);

    expect(find.byType(EkranPrijavljivanja), findsOneWidget);
    expect(find.text(porukaSesijaIstekla), findsOneWidget);
  });

  testWidgets('precica R osvezava podatke sa servera', (tester) async {
    postaviProzor(tester, sirina: 1440);
    await otvoriBackoffice(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
    await smiri(tester);

    expect(find.text('Podaci su osveženi.'), findsOneWidget);
  });

  testWidgets('server ne radi: „Nema veze sa serverom." (isti api_client kao uz server), bez cekanja bez kraja', (
    tester,
  ) async {
    postaviProzor(tester, sirina: 1440);
    final nemaServera = MockClient((_) async => throw http.ClientException('Connection refused'));
    final tokeni = MemoryTokenStore();
    await tokeni.write('zapamcen-token');
    final api = ApiKlijent(adresa: Uri.parse('http://localhost:8080'), tokeni: tokeni, httpKlijent: nemaServera);
    final zavisnosti = ZavisnostiBackoffice(
      sat: sat,
      ponude: HttpPonudaRepository(api),
      prijave: HttpPrijavaRepository(api),
      studenti: HttpStudentRepository(api),
      sesije: HttpSesijaRepository(api),
    );

    await otvoriBackoffice(tester, zavisnosti: zavisnosti);

    expect(find.byType(EkranPrijavljivanja), findsOneWidget);
    expect(find.text(porukaNemaVeze), findsOneWidget);
    expect(find.byType(PrikazUcitavanja), findsNothing);
  });

  testWidgets('zakasneli klijent: prijava je u medjuvremenu odbijena, pa prihvatanje daje razlog '
      'i tabela pokazuje novo stanje', (tester) async {
    postaviProzor(tester, sirina: 1440);
    final zavisnosti = lazneZavisnosti();
    await otvoriBackoffice(tester, zavisnosti: zavisnosti);

    await tester.tap(find.text('Andrej Aleksić'));
    await smiri(tester);
    final bloc = tester.element(find.byType(TabelaPrijava)).read<KoordinatorBloc>();
    final prijava = (bloc.state as KoordinatorUcitano).izabranaPrijava!;
    expect(find.text('Prihvati'), findsOneWidget);

    final odbijena = Odbijena(odlucio: pocetniKoordinator.id, kada: sat.sada(), razlog: 'Odlučeno u drugom prozoru.');
    unawaited(zavisnosti.laznaBaza!.sacuvaj(prijava.copyWith(stanje: odbijena), iz: prijava.stanje));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await smiri(tester);

    expect(find.text(NedozvoljenPrelaz(iz: odbijena, u: odbijena).poruka), findsOneWidget);
    expect((bloc.state as KoordinatorUcitano).izabranaPrijava?.stanje, odbijena);
    expect(find.text('Prihvati'), findsNothing);
  });
}
