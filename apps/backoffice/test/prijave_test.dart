import 'package:backoffice/app.dart';
import 'package:backoffice/widgeti/lista_prijava.dart';
import 'package:backoffice/widgeti/tabela_prijava.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

import 'pomocno.dart';


void main() {
  testWidgets('samo tastatura: strelica, Enter, pa prečica P prihvata prijavu', (tester) async {
    postaviProzor(tester, sirina: 1440);
    await otvoriBackoffice(tester);
    expect(find.byType(TabelaPrijava), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await smiri(tester);
    expect(find.text('Marko Petrović'), findsNWidgets(3));
    expect(find.text('Prihvati'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await smiri(tester);

    expect(find.text('Prijava je prihvaćena.'), findsOneWidget);
    expect(find.text('Prihvati'), findsNothing);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'tabela prijava');
  });

  testWidgets('prečica O odbija izabranu prijavu, uz razlog iz dijaloga', (tester) async {
    postaviProzor(tester, sirina: 1440);
    await otvoriBackoffice(tester);

    await tester.tap(find.text('Andrej Aleksić'));
    await smiri(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyO);
    await smiri(tester);
    expect(find.text('Odbiti prijavu?'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Mesta su popunjena.');
    await tester.tap(find.text('Odbij prijavu'));
    await smiri(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Prijava je odbijena.'), findsOneWidget);
    expect(find.textContaining('Razlog: Mesta su popunjena.'), findsOneWidget);
  });

  testWidgets('kad su mesta popunjena, prečica P ne radi ništa', (tester) async {
    postaviProzor(tester, sirina: 1440);
    await otvoriBackoffice(tester);

    await tester.tap(find.text('Ana Jovanović').at(1));
    await smiri(tester);
    expect(find.text('Prihvati'), findsNothing);
    expect(find.text('Odbij'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await smiri(tester);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('desni klik na red otvara meni samo sa dozvoljenim odlukama', (tester) async {
    postaviProzor(tester, sirina: 1440);
    await otvoriBackoffice(tester);

    await tester.tap(find.text('Andrej Aleksić'), buttons: kSecondaryButton);
    await smiri(tester);
    expect(find.text('Prihvati (P)'), findsOneWidget);
    expect(find.text('Detalji'), findsOneWidget);

    await tester.tap(find.text('Prihvati (P)'));
    await smiri(tester);
    expect(find.text('Prijava je prihvaćena.'), findsOneWidget);

    // Sada je prihvaćena: meni nudi samo detalje.
    await tester.tap(find.text('Andrej Aleksić'), buttons: kSecondaryButton);
    await smiri(tester);
    expect(find.text('Prihvati (P)'), findsNothing);
    expect(find.text('Odbij (O)'), findsNothing);
    expect(find.text('Detalji'), findsOneWidget);
  });

  testWidgets('prozor uži od 840 piksela prikazuje listu i čuva izbor', (tester) async {
    postaviProzor(tester, sirina: 1440);
    await otvoriBackoffice(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await smiri(tester);

    postaviProzor(tester, sirina: 600);
    await smiri(tester);
    expect(find.byType(ListaPrijava), findsOneWidget);
    expect(find.byType(TabelaPrijava), findsNothing);
    expect(
      tester.getSemantics(find.bySemanticsLabel(RegExp(r'^Marko Petrović, .*Poslata$'))),
      isSemantics(isSelected: true),
    );

    postaviProzor(tester, sirina: 1440);
    await smiri(tester);
    expect(find.byType(TabelaPrijava), findsOneWidget);
    expect(find.text('Prihvati'), findsOneWidget);
  });

  testWidgets('link sa izabranom prijavom otvara je kad se podaci učitaju', (tester) async {
    postaviProzor(tester, sirina: 1440);
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/prijave?prijava=p-1';
    addTearDown(tester.binding.platformDispatcher.clearDefaultRouteNameTestValue);
    await otvoriBackoffice(tester);

    // Ime je i u redu tabele i u naslovu otvorenog detalja.
    expect(find.text('Andrej Aleksić'), findsNWidgets(2));
    expect(find.text('Odbij'), findsOneWidget);
  });

  testWidgets('ekran prikazuje učitavanje, grešku, pa podatke posle „Pokušaj ponovo"', (tester) async {
    postaviProzor(tester, sirina: 1440);
    final zavisnosti = lazneZavisnosti(kasnjenje: const Duration(milliseconds: 400));
    zavisnosti.laznaBaza!.neuspesniZahtevi = 1;
    await tester.pumpWidget(BackofficeAplikacija(zavisnosti: zavisnosti));
    await tester.pump();
    expect(find.byType(PrikazUcitavanja), findsOneWidget);

    await smiri(tester);
    expect(find.text(PrikazGreske.naslov), findsOneWidget);

    await tester.tap(find.text('Pokušaj ponovo'));
    await smiri(tester);
    expect(find.byType(TabelaPrijava), findsOneWidget);
  });

  testWidgets('bez prijava ekran prikazuje prazno stanje', (tester) async {
    postaviProzor(tester, sirina: 1440);
    await otvoriBackoffice(tester, zavisnosti: bezPrijava());

    expect(find.text('Na ponude vašeg univerziteta još nije stigla nijedna prijava.'), findsOneWidget);
  });
}