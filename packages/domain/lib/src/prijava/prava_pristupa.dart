import '../korisnik.dart';
import '../ponuda/ponuda.dart';
import 'prijava.dart';
import 'stanje_prijave.dart';

abstract final class PravaPristupa {
  static bool jeVlasnik(Korisnik korisnik, Prijava prijava) =>
      korisnik.uloga == Uloga.student && prijava.idStudenta == korisnik.id;

  static bool mozeDaOdlucuje(Korisnik korisnik, Ponuda ponuda) =>
      korisnik.jeKoordinator && korisnik.idUniverziteta == ponuda.idUniverziteta;

  static bool mozeDaVidi(Korisnik korisnik, Prijava prijava, {required Ponuda ponuda}) => switch (korisnik.uloga) {
    Uloga.student => jeVlasnik(korisnik, prijava),
    Uloga.koordinator =>
      prijava.idPonude == ponuda.id && mozeDaOdlucuje(korisnik, ponuda) && prijava.stanje is! UPripremi,
  };

  static bool koristiMobilnuAplikaciju(Korisnik korisnik) => korisnik.uloga == Uloga.student;

  static bool koristiBackoffice(Korisnik korisnik) => korisnik.uloga == Uloga.koordinator;
}
