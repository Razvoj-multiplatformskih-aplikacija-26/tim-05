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

  group('PravaPristupa.mozeDaVidi', () {
    final poslata = prijava(stanje: Poslata(kada: sada));

    test('student vidi svoju prijavu, i u pripremi', () {
      expect(PravaPristupa.mozeDaVidi(andrej, poslata, ponuda: ponuda()), isTrue);
      expect(PravaPristupa.mozeDaVidi(andrej, prijava(), ponuda: ponuda()), isTrue);
    });

    test('drugi student ne vidi tudju prijavu', () {
      expect(PravaPristupa.mozeDaVidi(luka, poslata, ponuda: ponuda()), isFalse);
    });

    test('koordinator vidi poslatu prijavu na ponudu svog univerziteta', () {
      expect(PravaPristupa.mozeDaVidi(koordinatorMilano, poslata, ponuda: ponuda()), isTrue);
    });

    test('koordinator ne vidi prijavu u pripremi ni prijavu na ponudu drugog univerziteta', () {
      expect(PravaPristupa.mozeDaVidi(koordinatorMilano, prijava(), ponuda: ponuda()), isFalse);
      expect(PravaPristupa.mozeDaVidi(koordinatorBec, poslata, ponuda: ponuda()), isFalse);
    });

    test('koordinator ne vidi prijavu kada mu se pokaze tudja ponuda', () {
      final naDruguPonudu = prijava(
        idPonude: 'po-2',
        stanje: Poslata(kada: sada),
      );
      expect(PravaPristupa.mozeDaVidi(koordinatorMilano, naDruguPonudu, ponuda: ponuda()), isFalse);
    });
  });

  group('PravaPristupa po aplikaciji', () {
    test('mobilnu aplikaciju koristi student, a backoffice koordinator', () {
      expect(PravaPristupa.koristiMobilnuAplikaciju(andrej), isTrue);
      expect(PravaPristupa.koristiBackoffice(andrej), isFalse);
      expect(PravaPristupa.koristiMobilnuAplikaciju(koordinatorMilano), isFalse);
      expect(PravaPristupa.koristiBackoffice(koordinatorMilano), isTrue);
    });
  });
}
