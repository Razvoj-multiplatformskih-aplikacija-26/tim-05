import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

extension StanjePrijaveUDto on StanjePrijave {
  StanjePrijaveDto toDto() => switch (this) {
    UPripremi() => const StanjePrijaveDto(vrsta: StanjePrijaveDto.uPripremi),
    Poslata(:final kada) => StanjePrijaveDto(vrsta: StanjePrijaveDto.poslata, kada: kada),
    NaListiCekanja(:final odlucio, :final kada) => StanjePrijaveDto(
      vrsta: StanjePrijaveDto.naListiCekanja,
      odlucio: odlucio.vrednost,
      kada: kada,
    ),
    Prihvacena(:final odlucio, :final kada) => StanjePrijaveDto(
      vrsta: StanjePrijaveDto.prihvacena,
      odlucio: odlucio.vrednost,
      kada: kada,
    ),
    Odbijena(:final odlucio, :final kada, :final razlog) => StanjePrijaveDto(
      vrsta: StanjePrijaveDto.odbijena,
      odlucio: odlucio.vrednost,
      kada: kada,
      razlog: razlog,
    ),
    Potvrdjena(:final kada) => StanjePrijaveDto(vrsta: StanjePrijaveDto.potvrdjena, kada: kada),
    Povucena(:final kada) => StanjePrijaveDto(vrsta: StanjePrijaveDto.povucena, kada: kada),
  };
}

extension StanjePrijaveDtoUDomen on StanjePrijaveDto {
  StanjePrijave toDomain() => switch (this) {
    StanjePrijaveDto(vrsta: StanjePrijaveDto.uPripremi) => const UPripremi(),
    StanjePrijaveDto(vrsta: StanjePrijaveDto.poslata, :final kada?) => Poslata(kada: kada.toLocal()),
    StanjePrijaveDto(vrsta: StanjePrijaveDto.naListiCekanja, :final odlucio?, :final kada?) => NaListiCekanja(
      odlucio: IdKorisnika(odlucio),
      kada: kada.toLocal(),
    ),
    StanjePrijaveDto(vrsta: StanjePrijaveDto.prihvacena, :final odlucio?, :final kada?) => Prihvacena(
      odlucio: IdKorisnika(odlucio),
      kada: kada.toLocal(),
    ),
    StanjePrijaveDto(vrsta: StanjePrijaveDto.odbijena, :final odlucio?, :final kada?, :final razlog?) => Odbijena(
      odlucio: IdKorisnika(odlucio),
      kada: kada.toLocal(),
      razlog: razlog,
    ),
    StanjePrijaveDto(vrsta: StanjePrijaveDto.potvrdjena, :final kada?) => Potvrdjena(kada: kada.toLocal()),
    StanjePrijaveDto(vrsta: StanjePrijaveDto.povucena, :final kada?) => Povucena(kada: kada.toLocal()),
    _ => throw FormatException('Nepoznato ili nepotpuno stanje prijave', vrsta),
  };
}

extension PrijavaUDto on Prijava {
  PrijavaDto toDto() => PrijavaDto(
    id: id.vrednost,
    idStudenta: idStudenta.vrednost,
    idPonude: idPonude.vrednost,
    motivacionoPismo: motivacionoPismo.tekst,
    napomena: napomena,
    napravljena: napravljena,
    stanje: stanje.toDto(),
  );

  NovaPrijavaDto toNovaDto() => NovaPrijavaDto(
    idPonude: idPonude.vrednost,
    motivacionoPismo: motivacionoPismo.tekst,
    napomena: napomena,
    posalji: stanje is Poslata,
  );

  IzmenaPrijaveDto toIzmenaDto() =>
      IzmenaPrijaveDto(motivacionoPismo: motivacionoPismo.tekst, napomena: napomena, posalji: stanje is Poslata);
}

extension PrijavaDtoUDomen on PrijavaDto {
  Prijava toDomain() => Prijava(
    id: IdPrijave(id),
    idStudenta: IdKorisnika(idStudenta),
    idPonude: IdPonude(idPonude),
    motivacionoPismo: switch (MotivacionoPismo.proveri(motivacionoPismo)) {
      Uspeh(:final vrednost) => vrednost,
      Neuspeh(:final greska) => throw FormatException('Ugovor je doneo pismo koje domen odbija', greska),
    },
    napomena: napomena,
    napravljena: napravljena.toLocal(),
    stanje: stanje.toDomain(),
  );
}
