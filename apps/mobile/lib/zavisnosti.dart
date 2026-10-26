import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'podaci/lazna_baza.dart';
import 'podaci/lazni_podaci.dart';
import 'podaci/prazna_baza.dart';

final class ZavisnostiAplikacije {
  ZavisnostiAplikacije({
    required this.korisnik,
    required this.sat,
    required PonudaRepository ponude,
    required PrijavaRepository prijave,
    required StudentRepository studenti,
    this.laznaBaza,
  }) : ucitajPregled = UcitajPregled(ponude: ponude, prijave: prijave, studenti: studenti, sat: sat),
       sacuvajPrijavu = SacuvajPrijavu(ponude: ponude, prijave: prijave, studenti: studenti, sat: sat),
       povuciPrijavu = PovuciPrijavu(prijave: prijave, sat: sat),
       potvrdiMesto = PotvrdiMesto(ponude: ponude, prijave: prijave, sat: sat),
       odbijMesto = OdbijMesto(prijave: prijave, sat: sat),
       obrisiPrijavu = ObrisiPrijavu(prijave: prijave),
       promeniSacuvanu = PromeniSacuvanu(studenti: studenti),
       sacuvajProfil = SacuvajProfil(studenti: studenti);

  factory ZavisnostiAplikacije.lazne({Sat sat = const SistemskiSat(), Duration? kasnjenje}) {
    final baza = kasnjenje == null ? LaznaBaza() : LaznaBaza(kasnjenje: kasnjenje);
    return ZavisnostiAplikacije(
      korisnik: pocetniKorisnik,
      sat: sat,
      ponude: baza,
      prijave: baza,
      studenti: baza,
      laznaBaza: baza,
    );
  }

  factory ZavisnostiAplikacije.prazne({Sat sat = const SistemskiSat()}) {
    final baza = PraznaBaza(student: pocetniStudent);
    return ZavisnostiAplikacije(korisnik: pocetniKorisnik, sat: sat, ponude: baza, prijave: baza, studenti: baza);
  }

  final Korisnik korisnik;
  final Sat sat;

  final UcitajPregled ucitajPregled;
  final SacuvajPrijavu sacuvajPrijavu;
  final PovuciPrijavu povuciPrijavu;
  final PotvrdiMesto potvrdiMesto;
  final OdbijMesto odbijMesto;
  final ObrisiPrijavu obrisiPrijavu;
  final PromeniSacuvanu promeniSacuvanu;
  final SacuvajProfil sacuvajProfil;

  final LaznaBaza? laznaBaza;
}
