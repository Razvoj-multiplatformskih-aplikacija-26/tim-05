import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'podaci/lazna_baza.dart';
import 'podaci/lazni_podaci.dart';


final class ZavisnostiBackoffice {
  ZavisnostiBackoffice({
    required this.korisnik,
    required this.sat,
    required PonudaRepository ponude,
    required PrijavaRepository prijave,
    required StudentRepository studenti,
    this.laznaBaza,
  }) : ucitajPregled = UcitajPregledKoordinatora(ponude: ponude, prijave: prijave, studenti: studenti, sat: sat),
       prihvatiPrijavu = PrihvatiPrijavu(ponude: ponude, prijave: prijave, sat: sat),
       staviNaListuCekanja = StaviNaListuCekanja(ponude: ponude, prijave: prijave, sat: sat),
       odbijPrijavu = OdbijPrijavu(ponude: ponude, prijave: prijave, sat: sat);

  factory ZavisnostiBackoffice.lazne({Sat sat = const SistemskiSat(), Duration? kasnjenje}) {
    final baza = kasnjenje == null ? LaznaBaza() : LaznaBaza(kasnjenje: kasnjenje);
    return ZavisnostiBackoffice(
      korisnik: pocetniKoordinator,
      sat: sat,
      ponude: baza,
      prijave: baza,
      studenti: baza,
      laznaBaza: baza,
    );
  }

  final Korisnik korisnik;
  final Sat sat;

  final UcitajPregledKoordinatora ucitajPregled;
  final PrihvatiPrijavu prihvatiPrijavu;
  final StaviNaListuCekanja staviNaListuCekanja;
  final OdbijPrijavu odbijPrijavu;

  final LaznaBaza? laznaBaza;
}
