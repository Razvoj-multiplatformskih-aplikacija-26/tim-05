import 'package:api_client/api_client.dart';
import 'package:use_cases/use_cases.dart';

import 'podaci/lazna_baza.dart';
import 'podaci/lazne_sesije.dart';
import 'podaci/lazni_podaci.dart';
import 'podaci/prazna_baza.dart';

final class ZavisnostiAplikacije {
  ZavisnostiAplikacije({
    required this.sat,
    required PonudaRepository ponude,
    required PrijavaRepository prijave,
    required StudentRepository studenti,
    required SesijaRepository sesije,
    this.laznaBaza,
    this.lazneSesije,
  }) : ucitajPregled = UcitajPregled(ponude: ponude, prijave: prijave, studenti: studenti, sat: sat),
       sacuvajPrijavu = SacuvajPrijavu(ponude: ponude, prijave: prijave, studenti: studenti, sat: sat),
       povuciPrijavu = PovuciPrijavu(ponude: ponude, prijave: prijave, sat: sat),
       potvrdiMesto = PotvrdiMesto(ponude: ponude, prijave: prijave, sat: sat),
       odbijMesto = OdbijMesto(ponude: ponude, prijave: prijave, sat: sat),
       obrisiPrijavu = ObrisiPrijavu(ponude: ponude, prijave: prijave),
       promeniSacuvanu = PromeniSacuvanu(studenti: studenti),
       sacuvajProfil = SacuvajProfil(studenti: studenti),
       prijaviSe = PrijaviSe(sesije: sesije),
       obnoviSesiju = ObnoviSesiju(sesije: sesije),
       odjaviSe = OdjaviSe(sesije: sesije),
       istekleSesije = sesije.istekle;

  factory ZavisnostiAplikacije.server({
    required Uri adresa,
    required TokenStore tokeni,
    Sat sat = const SistemskiSat(),
  }) {
    final api = ApiKlijent(adresa: adresa, tokeni: tokeni);
    return ZavisnostiAplikacije(
      sat: sat,
      ponude: HttpPonudaRepository(api),
      prijave: HttpPrijavaRepository(api),
      studenti: HttpStudentRepository(api),
      sesije: HttpSesijaRepository(api),
    );
  }

  factory ZavisnostiAplikacije.lazne({Sat sat = const SistemskiSat(), Duration? kasnjenje, bool prijavljen = true}) {
    final baza = kasnjenje == null ? LaznaBaza() : LaznaBaza(kasnjenje: kasnjenje);
    final sesije = LazneSesije(prijavljen: prijavljen ? pocetniKorisnik : null);
    return ZavisnostiAplikacije(
      sat: sat,
      ponude: baza,
      prijave: baza,
      studenti: baza,
      sesije: sesije,
      laznaBaza: baza,
      lazneSesije: sesije,
    );
  }

  factory ZavisnostiAplikacije.prazne({Sat sat = const SistemskiSat()}) {
    final baza = PraznaBaza(student: pocetniStudent);
    return ZavisnostiAplikacije(
      sat: sat,
      ponude: baza,
      prijave: baza,
      studenti: baza,
      sesije: LazneSesije(prijavljen: pocetniKorisnik),
    );
  }

  final Sat sat;

  final UcitajPregled ucitajPregled;
  final SacuvajPrijavu sacuvajPrijavu;
  final PovuciPrijavu povuciPrijavu;
  final PotvrdiMesto potvrdiMesto;
  final OdbijMesto odbijMesto;
  final ObrisiPrijavu obrisiPrijavu;
  final PromeniSacuvanu promeniSacuvanu;
  final SacuvajProfil sacuvajProfil;

  final PrijaviSe prijaviSe;
  final ObnoviSesiju obnoviSesiju;
  final OdjaviSe odjaviSe;

  final Stream<void> istekleSesije;

  final LaznaBaza? laznaBaza;
  final LazneSesije? lazneSesije;
}
