import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  const student = Korisnik(id: IdKorisnika('s-1'), korisnickoIme: 'student1', uloga: Uloga.student);
  const koordinator = Korisnik(
    id: IdKorisnika('k-polimi'),
    korisnickoIme: 'koordinator1',
    uloga: Uloga.koordinator,
    idUniverziteta: IdUniverziteta('u-polimi'),
  );

  test('student i koordinator prolaze kroz ugovor i JSON nepromenjeni', () {
    for (final korisnik in [student, koordinator]) {
      final kroz = KorisnikDto.fromJson(korisnik.toDto().toJson()).toDomain();

      expect(kroz, korisnik);
    }
  });

  test('uloga na mreži je tekst iz ugovora', () {
    expect(student.toDto().uloga, KorisnikDto.student);
    expect(koordinator.toDto().uloga, KorisnikDto.koordinator);
  });

  test('nepoznata uloga postaje FormatException, kao svako polje koje ne odgovara ugovoru', () {
    const dto = KorisnikDto(id: 'x', korisnickoIme: 'x', uloga: 'admin');

    expect(dto.toDomain, throwsFormatException);
  });

  test('koordinator bez univerziteta ili student sa univerzitetom se odbija', () {
    const bezUniverziteta = KorisnikDto(id: 'k', korisnickoIme: 'k', uloga: KorisnikDto.koordinator);
    const saUniverzitetom = KorisnikDto(
      id: 's',
      korisnickoIme: 's',
      uloga: KorisnikDto.student,
      idUniverziteta: 'u-polimi',
    );

    expect(bezUniverziteta.toDomain, throwsFormatException);
    expect(saUniverzitetom.toDomain, throwsFormatException);
  });
}