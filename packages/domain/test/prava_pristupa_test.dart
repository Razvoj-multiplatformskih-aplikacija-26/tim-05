import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'pomocno.dart';

const koordinatorBezUniverziteta = Korisnik(
  id: IdKorisnika('k-9'),
  korisnickoIme: 'koordinator.bez',
  uloga: Uloga.koordinator,
);

const koordinatorSaIdStudenta = Korisnik(
  id: IdKorisnika('s-1'),
  korisnickoIme: 'koordinator.isti.id',
  uloga: Uloga.koordinator,
  idUniverziteta: IdUniverziteta('u-polimi'),
);

void main() {
  group('PravaPristupa.jeVlasnik', () {
    test('student je vlasnik svoje prijave', () {
      expect(PravaPristupa.jeVlasnik(andrej, prijava()), isTrue);
    });

    test('student nije vlasnik tudje prijave', () {
      expect(PravaPristupa.jeVlasnik(luka, prijava()), isFalse);
    });

    test('koordinator nije vlasnik ni kad ima isti ID kao student', () {
      expect(PravaPristupa.jeVlasnik(koordinatorSaIdStudenta, prijava()), isFalse);
    });
  });

  group('PravaPristupa.mozeDaOdlucuje', () {
    test('koordinator univerziteta ponude moze', () {
      expect(PravaPristupa.mozeDaOdlucuje(koordinatorMilano, ponuda()), isTrue);
    });

    test('koordinator drugog univerziteta ne moze', () {
      expect(PravaPristupa.mozeDaOdlucuje(koordinatorBec, ponuda()), isFalse);
    });

    test('student ne moze', () {
      expect(PravaPristupa.mozeDaOdlucuje(andrej, ponuda()), isFalse);
    });

    test('koordinator bez univerziteta ne moze', () {
      expect(PravaPristupa.mozeDaOdlucuje(koordinatorBezUniverziteta, ponuda()), isFalse);
    });
  });
}
