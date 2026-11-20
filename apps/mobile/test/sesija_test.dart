import 'dart:async';

import 'package:api_client/api_client.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/app.dart';
import 'package:mobile/ekrani/formular_ekran.dart';
import 'package:mobile/ekrani/pocetna_ekran.dart';
import 'package:mobile/ekrani/prijavljivanje_ekran.dart';
import 'package:mobile/podaci/lazne_sesije.dart';
import 'package:mobile/podaci/lazni_podaci.dart';
import 'package:mobile/widgeti/kartica_ponude.dart';
import 'package:mobile/widgeti/potrebna_prijava.dart';
import 'package:mobile/zavisnosti.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

import 'pomocno.dart';

Future<void> ulogujSe(WidgetTester tester, String korisnickoIme) async {
  await tester.enterText(find.widgetWithText(TextField, 'Korisničko ime'), korisnickoIme);
  await tester.enterText(find.widgetWithText(TextField, 'Lozinka'), 'erasmus-demo');
  await tester.tap(find.widgetWithText(FilledButton, 'Uloguj se'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('bez prijave: ponude su javne, a prijava na ponudu trazi prijavu na nalog', (tester) async {
    postaviTelefon(tester);
    await otvoriAplikaciju(tester, ZavisnostiAplikacije.lazne(kasnjenje: Duration.zero, prijavljen: false));
    await tester.pumpAndSettle();

    expect(find.text('Zdravo!'), findsOneWidget);
    expect(find.byType(KarticaPonude), findsWidgets);

    await tester.tap(find.byType(KarticaPonude).first);
    await tester.pumpAndSettle();
    expect(find.text('Aktivne prijave'), findsNothing);

    await tester.tap(find.byTooltip('Prijavi se'));
    await tester.pumpAndSettle();
    expect(find.byType(PrijavljivanjeEkran), findsOneWidget);

    await ulogujSe(tester, 'student1');
    expect(find.byType(PrijavljivanjeEkran), findsNothing);
    expect(find.text('Aktivne prijave'), findsOneWidget);
  });

  testWidgets('„Uloguj se" na pocetnom ekranu: forma, pa ponude studenta', (tester) async {
    postaviTelefon(tester);
    await tester.pumpWidget(
      ErasmusAplikacija(zavisnosti: ZavisnostiAplikacije.lazne(kasnjenje: Duration.zero, prijavljen: false)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Uloguj se'));
    await tester.pumpAndSettle();
    await ulogujSe(tester, 'student1');

    expect(find.text('Zdravo, ${pocetniStudent.ime}'), findsOneWidget);
  });

  testWidgets('koordinator na telefonu: poruka da je aplikacija za studente, bez prijave', (tester) async {
    postaviTelefon(tester);
    await otvoriAplikaciju(tester, ZavisnostiAplikacije.lazne(kasnjenje: Duration.zero, prijavljen: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text(PotrebnaPrijava.poruka), findsOneWidget);

    await tester.tap(find.text('Uloguj se'));
    await tester.pumpAndSettle();
    await ulogujSe(tester, 'koordinator1');

    expect(find.text(PrijavljivanjeEkran.porukaPogresneAplikacije), findsOneWidget);
    expect(
      tester.element(find.byType(PrijavljivanjeEkran)).read<SesijaBloc>().state,
      const Odjavljen(razlog: RazlogOdjave.pogresnaAplikacija),
    );
  });

  testWidgets('zapamcena prijava posle ponovnog pokretanja, pa odjava', (tester) async {
    postaviTelefon(tester);
    await tester.pumpWidget(ErasmusAplikacija(zavisnosti: ZavisnostiAplikacije.lazne(kasnjenje: Duration.zero)));
    await tester.pumpAndSettle();
    expect(find.text('Nastavi kao ${pocetniKorisnik.korisnickoIme}'), findsOneWidget);

    await tester.tap(find.text('Nastavi kao ${pocetniKorisnik.korisnickoIme}'));
    await tester.pumpAndSettle();
    expect(find.text('Zdravo, ${pocetniStudent.ime}'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Odjavi se'));
    await tester.pumpAndSettle();

    expect(find.text(PotrebnaPrijava.poruka), findsOneWidget);
    await tester.tap(find.text('Početna'));
    await tester.pumpAndSettle();
    expect(find.text('Zdravo!'), findsOneWidget);
  });

  testWidgets('istekla prijava: ekran za prijavu sa porukom, a podaci studenta nestaju', (tester) async {
    postaviTelefon(tester);
    final zavisnosti = ZavisnostiAplikacije.lazne(kasnjenje: Duration.zero);
    await otvoriAplikaciju(tester, zavisnosti);
    await tester.pumpAndSettle();
    expect(find.text('Zdravo, ${pocetniStudent.ime}'), findsOneWidget);

    zavisnosti.lazneSesije!.istekni();
    await tester.pumpAndSettle();
    expect(find.byType(PrijavljivanjeEkran), findsOneWidget);
    expect(find.text(porukaSesijaIstekla), findsOneWidget);

    await tester.tap(find.byTooltip('Nazad'));
    await tester.pumpAndSettle();
    expect(find.text('Zdravo!'), findsOneWidget);
  });

  testWidgets('server ne radi: ekran kaže da nema veze i nudi ponovni pokušaj (isti api_client kao uz server)', (
    tester,
  ) async {
    postaviTelefon(tester);
    final nemaServera = MockClient((_) async => throw http.ClientException('Connection refused'));
    final api = ApiKlijent(adresa: Uri.parse('http://localhost:8080'), httpKlijent: nemaServera);
    final zavisnosti = ZavisnostiAplikacije(
      sat: const SistemskiSat(),
      ponude: HttpPonudaRepository(api),
      prijave: HttpPrijavaRepository(api),
      studenti: HttpStudentRepository(api),
      sesije: HttpSesijaRepository(api),
    );

    await otvoriAplikaciju(tester, zavisnosti);
    await tester.pumpAndSettle();

    expect(find.text(porukaNemaVeze), findsOneWidget);
    expect(find.text('Pokušaj ponovo'), findsOneWidget);
    expect(find.byType(PrikazUcitavanja), findsNothing);
  });

  testWidgets('zakasneli klijent u formularu: razlog, pa ponovo učitani podaci', (tester) async {
    final zavisnosti = ZavisnostiAplikacije.lazne(kasnjenje: Duration.zero);
    final baza = zavisnosti.laznaBaza!;
    await otvoriAplikaciju(tester, zavisnosti);
    await tester.pumpAndSettle();

    final ponude = tester.element(find.byType(PocetnaEkran)).read<PonudeBloc>();
    final poslata = (ponude.state as PonudeUcitane).podaci.mojePrijave.firstWhere((p) => p.stanje is Poslata);
    unawaited(
      GoRouter.of(tester.element(find.byType(PocetnaEkran))).push('/profil/prijave/${poslata.id.vrednost}/izmena'),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(FormularEkran.kljucPisma));
    await tester.enterText(find.byKey(FormularEkran.kljucPisma), 'Dopunjeno motivaciono pismo.');

    final prihvacena = Prihvacena(odlucio: lazniKoordinator.id, kada: DateTime.now());
    unawaited(baza.sacuvaj(poslata.copyWith(stanje: prihvacena), iz: poslata.stanje));
    await tester.pump();

    await tester.ensureVisible(find.text('Sačuvaj izmene'));
    await tester.tap(find.text('Sačuvaj izmene'));
    await tester.pumpAndSettle();

    expect(find.text(const IzmenaNijeMoguca().poruka), findsOneWidget);
    final posle = (ponude.state as PonudeUcitane).podaci;
    expect(posle.prijava(poslata.id)?.stanje, prihvacena);
  });
}
