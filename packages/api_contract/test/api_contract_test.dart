import 'package:api_contract/api_contract.dart';
import 'package:test/test.dart';

void main() {
  group('prijava na sistem', () {
    test('zahtev za prijavu prolazi kroz JSON nepromenjen', () {
      const zahtev = PrijavljivanjeDto(korisnickoIme: 'student1', lozinka: 'tajna', kolacic: true);

      final procitan = PrijavljivanjeDto.fromJson(zahtev.toJson());

      expect(procitan.korisnickoIme, 'student1');
      expect(procitan.lozinka, 'tajna');
      expect(procitan.kolacic, isTrue);
    });

    test('bez polja cookie zahtev je za token u telu, kao sa telefona i desktopa', () {
      final procitan = PrijavljivanjeDto.fromJson({'username': 'student1', 'password': 'tajna'});

      expect(procitan.kolacic, isFalse);
    });

    test('zahtev bez lozinke ili sa lozinkom koja nije tekst se odbija', () {
      expect(() => PrijavljivanjeDto.fromJson({'username': 'student1'}), throwsFormatException);
      expect(() => PrijavljivanjeDto.fromJson({'username': 'student1', 'password': 42}), throwsFormatException);
    });
  });

  group('sesija', () {
    final istice = DateTime.utc(2026, 11, 12, 18, 30);

    test('sesija sa tokenom prolazi kroz JSON nepromenjena, vreme ostaje u UTC-u', () {
      final sesija = SesijaDto(
        korisnik: const KorisnikDto(
          id: 'k-polimi',
          korisnickoIme: 'koordinator1',
          uloga: KorisnikDto.koordinator,
          idUniverziteta: 'u-polimi',
        ),
        istice: istice,
        token: 'abc',
      );

      final procitana = SesijaDto.fromJson(sesija.toJson());

      expect(procitana.korisnik.id, 'k-polimi');
      expect(procitana.korisnik.uloga, KorisnikDto.koordinator);
      expect(procitana.korisnik.idUniverziteta, 'u-polimi');
      expect(procitana.istice, istice);
      expect(procitana.istice.isUtc, isTrue);
      expect(procitana.token, 'abc');
    });

    test('sesija iz kolačića nema token u telu, a student nema univerzitet', () {
      final json = SesijaDto(
        korisnik: const KorisnikDto(id: 's-1', korisnickoIme: 'student1', uloga: KorisnikDto.student),
        istice: istice,
      ).toJson();

      expect(json.containsKey('token'), isFalse);
      expect((json['user']! as Map<String, Object?>).containsKey('universityId'), isFalse);
    });

    test('stariji klijent čita sesiju koja nosi polje koje još ne zna', () {
      final odNovijegServera = {
        'user': {'id': 's-1', 'username': 'student1', 'role': 'student', 'displayName': 'Andrej'},
        'expiresAt': '2026-11-12T18:30:00.000Z',
        'refreshAfter': '2026-11-12T12:00:00.000Z',
      };

      final sesija = SesijaDto.fromJson(odNovijegServera);

      expect(sesija.korisnik.korisnickoIme, 'student1');
      expect(sesija.istice, istice);
    });

    test('vreme bez vremenske zone se odbija', () {
      final bezZone = {
        'user': {'id': 's-1', 'username': 'student1', 'role': 'student'},
        'expiresAt': '2026-11-12T18:30:00',
      };

      expect(() => SesijaDto.fromJson(bezZone), throwsFormatException);
    });
  });

  group('greška sa servera', () {
    test('Problem Details nosi tip, status i kod', () {
      const problem = ProblemDto(status: 401, code: KodoviGresaka.sesijaIstekla, title: 'Session expired');

      expect(problem.toJson(), {
        'type': 'tag:raf.rs,2026:erasmusgo/problem/session-expired',
        'title': 'Session expired',
        'status': 401,
        'code': 'session-expired',
      });
      final procitan = ProblemDto.fromJson(problem.toJson());
      expect((procitan.status, procitan.code), (401, 'session-expired'));
    });

    test('problem bez naslova se čita, a problem bez koda se odbija', () {
      expect(ProblemDto.fromJson({'status': 404, 'code': 'not-found'}).title, '');
      expect(() => ProblemDto.fromJson({'status': 404}), throwsFormatException);
    });
  });
}