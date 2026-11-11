import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

extension KorisnikUDto on Korisnik {
  KorisnikDto toDto() => KorisnikDto(
    id: id.vrednost,
    korisnickoIme: korisnickoIme,
    uloga: uloga.toDto(),
    idUniverziteta: idUniverziteta?.vrednost,
  );
}

extension UlogaUDto on Uloga {
  String toDto() => switch (this) {
    Uloga.student => KorisnikDto.student,
    Uloga.koordinator => KorisnikDto.koordinator,
  };
}

extension KorisnikDtoUDomen on KorisnikDto {
  /// [FormatException] kada uloga nije poznata ili kada se uloga i univerzitet ne slažu,
  Korisnik toDomain() {
    final uloga = ulogaIzDto(this.uloga);
    if ((uloga == Uloga.koordinator) != (idUniverziteta != null)) {
      throw FormatException('Koordinator ima univerzitet, a student nema', idUniverziteta);
    }
    return Korisnik(
      id: IdKorisnika(id),
      korisnickoIme: korisnickoIme,
      uloga: uloga,
      idUniverziteta: switch (idUniverziteta) {
        final String id => IdUniverziteta(id),
        null => null,
      },
    );
  }
}

Uloga ulogaIzDto(String uloga) => switch (uloga) {
  KorisnikDto.student => Uloga.student,
  KorisnikDto.koordinator => Uloga.koordinator,
  _ => throw FormatException('Nepoznata uloga', uloga),
};