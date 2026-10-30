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
    expect(find.text('Marko Petrović'), findsNWidgets(3)); // dva reda u tabeli i naslov detalja
    expect(find.text('Prihvati'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await smiri(tester);

    expect(find.text('Prijava je prihvaćena.'), findsOneWidget);
    expect(find.text('Prihvati'), findsNothing);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'prijave');
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

  testWidgets('uzak prozor: strelica i Enter otvaraju donji list, a Esc ga zatvara bez gubitka izbora', (tester) async {
    postaviProzor(tester, sirina: 600);
    await otvoriBackoffice(tester);
    expect(find.byType(ListaPrijava), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump(); // kursor je u Bloc-u: neka stigne novo stanje pre Enter-a
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await smiri(tester);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Prihvati'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await smiri(tester);
    expect(find.byType(BottomSheet), findsNothing);
    expect(
      tester.getSemantics(find.bySemanticsLabel(RegExp(r'^Marko Petrović, .*Poslata$'))),
      isSemantics(isSelected: true),
    );
  });

  testWidgets('uzak prozor: „Detalji" iz menija na desni klik otvara donji list', (tester) async {
    postaviProzor(tester, sirina: 600);
    await otvoriBackoffice(tester);

    await tester.tap(find.text('Andrej Aleksić'), buttons: kSecondaryButton);
    await smiri(tester);
    await tester.tap(find.text('Detalji'));
    await smiri(tester);

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Andrej Aleksić'), findsNWidgets(2)); // kartica i naslov u donjem listu
  });

  testWidgets('filteri po stanju i po ponudi sužavaju tabelu', (tester) async {
    postaviProzor(tester, sirina: 1440);
    await otvoriBackoffice(tester);

    await tester.tap(find.text('Odbijene (2)'));
    await smiri(tester);
    expect(find.text('Mina Đorđević'), findsOneWidget);
    expect(find.text('Milica Stojanović'), findsOneWidget);
    expect(find.text('Marko Petrović'), findsNothing);

    await tester.tap(find.text('Dizajn interakcije').first);
    await smiri(tester);
    expect(find.text('Mina Đorđević'), findsNothing);
    expect(find.text('Milica Stojanović'), findsOneWidget);
    expect(find.text('Odbijene (1)'), findsOneWidget);

    await tester.tap(find.text('Sva stanja'));
    await smiri(tester);
    expect(find.text('Luka Nikolić'), findsOneWidget);
    expect(find.text('Marko Petrović'), findsNothing);
  });

  testWidgets('dugme Osveži javlja kad su podaci osveženi', (tester) async {
    postaviProzor(tester, sirina: 1440);
    await otvoriBackoffice(tester);

    await tester.tap(find.byTooltip('Osveži'));
    await smiri(tester);
    expect(find.text('Podaci su osveženi.'), findsOneWidget);
  });

  testWidgets('link sa izabranom prijavom otvara je kad se podaci učitaju', (tester) async {
    postaviProzor(tester, sirina: 1440);
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/prijave?prijava=p-1';
    addTearDown(tester.binding.platformDispatcher.clearDefaultRouteNameTestValue);
    await otvoriBackoffice(tester);

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