import 'package:backoffice/app.dart';
import 'package:backoffice/podaci/lazni_podaci.dart';
import 'package:backoffice/zavisnosti.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:use_cases/use_cases.dart';


final sat = FiksniSat(DateTime(2026, 11, 1, 12));

ZavisnostiBackoffice lazneZavisnosti({Duration kasnjenje = Duration.zero}) =>
    ZavisnostiBackoffice.lazne(sat: sat, kasnjenje: kasnjenje);

ZavisnostiBackoffice bezPrijava() {
  final baza = _BazaBezPrijava();
  return ZavisnostiBackoffice(korisnik: pocetniKoordinator, sat: sat, ponude: baza, prijave: baza, studenti: baza);
}

void postaviProzor(WidgetTester tester, {required double sirina, double visina = 900}) {
  tester.view.physicalSize = Size(sirina * 2, visina * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

Future<void> otvoriBackoffice(WidgetTester tester, {ZavisnostiBackoffice? zavisnosti}) async {
  await tester.pumpWidget(BackofficeAplikacija(zavisnosti: zavisnosti ?? lazneZavisnosti()));
  await smiri(tester);
}

Future<void> smiri(WidgetTester tester) => tester.pumpAndSettle(const Duration(milliseconds: 100));

final class _BazaBezPrijava implements PonudaRepository, PrijavaRepository, StudentRepository {
  @override
  Future<List<Ponuda>> ponude() async => pocetnePonude;

  @override
  Future<List<Univerzitet>> univerziteti() async => pocetniUniverziteti;

  @override
  Future<List<Prijava>> svePrijave() async => const [];

  @override
  Future<void> sacuvaj(List<Prijava> prijave) async {}

  @override
  Future<void> obrisi(IdPrijave id) async {}

  @override
  Future<Student> student(IdKorisnika id) async => pocetniStudenti.firstWhere((s) => s.id == id);

  @override
  Future<void> sacuvajStudenta(Student student) async {}

  @override
  Future<Set<IdPonude>> sacuvanePonude(IdKorisnika idStudenta) async => const {};

  @override
  Future<void> promeniSacuvanu(IdKorisnika idStudenta, IdPonude idPonude) async {}
}