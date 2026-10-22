import '../korisnik.dart';
import '../ponuda/ponuda.dart';
import 'prijava.dart';

abstract final class PravaPristupa {
  static bool jeVlasnik(Korisnik korisnik, Prijava prijava) =>
      korisnik.uloga == Uloga.student && prijava.idStudenta == korisnik.id;

  static bool mozeDaOdlucuje(Korisnik korisnik, Ponuda ponuda) =>
      korisnik.jeKoordinator && korisnik.idUniverziteta == ponuda.idUniverziteta;
}
