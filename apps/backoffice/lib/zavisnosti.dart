import 'package:api_client/api_client.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'podaci/lazna_baza.dart';
import 'podaci/lazne_sesije.dart';
import 'podaci/lazni_podaci.dart';

final class ZavisnostiBackoffice {
  ZavisnostiBackoffice({
    required this.sat,
    required PonudaRepository ponude,
    required PrijavaRepository prijave,
    required StudentRepository studenti,
    required SesijaRepository sesije,
    this.laznaBaza,
    this.lazneSesije,
  }) : ucitajPregled = UcitajPregledKoordinatora(ponude: ponude, prijave: prijave, studenti: studenti, sat: sat),
       prihvatiPrijavu = PrihvatiPrijavu(ponude: ponude, prijave: prijave, sat: sat),
       staviNaListuCekanja = StaviNaListuCekanja(ponude: ponude, prijave: prijave, sat: sat),
       odbijPrijavu = OdbijPrijavu(ponude: ponude, prijave: prijave, sat: sat),
       prijaviSe = PrijaviSe(sesije: sesije),
       obnoviSesiju = ObnoviSesiju(sesije: sesije),
       odjaviSe = OdjaviSe(sesije: sesije),
       istekleSesije = sesije.istekle;

  factory ZavisnostiBackoffice.server({
    required Uri adresa,
    required TokenStore tokeni,
    Sat sat = const SistemskiSat(),
  }) {
    final api = ApiKlijent(adresa: adresa, tokeni: tokeni);
    return ZavisnostiBackoffice(
      sat: sat,
      ponude: HttpPonudaRepository(api),
      prijave: HttpPrijavaRepository(api),
      studenti: HttpStudentRepository(api),
      sesije: HttpSesijaRepository(api),
    );
  }

  factory ZavisnostiBackoffice.lazne({
    Sat sat = const SistemskiSat(),
    Duration? kasnjenje,
    Korisnik? prijavljen = pocetniKoordinator,
  }) {
    final baza = kasnjenje == null ? LaznaBaza() : LaznaBaza(kasnjenje: kasnjenje);
    final sesije = LazneSesije(prijavljen: prijavljen);
    return ZavisnostiBackoffice(
      sat: sat,
      ponude: baza,
      prijave: baza,
      studenti: baza,
      sesije: sesije,
      laznaBaza: baza,
      lazneSesije: sesije,
    );
  }

  final Sat sat;

  final UcitajPregledKoordinatora ucitajPregled;
  final PrihvatiPrijavu prihvatiPrijavu;
  final StaviNaListuCekanja staviNaListuCekanja;
  final OdbijPrijavu odbijPrijavu;

  final PrijaviSe prijaviSe;
  final ObnoviSesiju obnoviSesiju;
  final OdjaviSe odjaviSe;

  final Stream<void> istekleSesije;

  final LaznaBaza? laznaBaza;
  final LazneSesije? lazneSesije;
}
