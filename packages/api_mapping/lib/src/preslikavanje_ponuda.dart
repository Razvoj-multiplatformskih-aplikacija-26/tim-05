import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

int prosekUStote(double prosek) => (prosek * 100).round();

double prosekIzStotih(int stotih) => stotih / 100;

extension UniverzitetUDto on Univerzitet {
  UniverzitetDto toDto() =>
      UniverzitetDto(id: id.vrednost, naziv: naziv, grad: grad, drzava: drzava, oznakaDrzave: oznakaDrzave);
}

extension UniverzitetDtoUDomen on UniverzitetDto {
  Univerzitet toDomain() =>
      Univerzitet(id: IdUniverziteta(id), naziv: naziv, grad: grad, drzava: drzava, oznakaDrzave: oznakaDrzave);
}

extension JezikUDto on Jezik {
  String toDto() => switch (this) {
    Jezik.engleski => 'english',
    Jezik.nemacki => 'german',
    Jezik.francuski => 'french',
    Jezik.italijanski => 'italian',
    Jezik.spanski => 'spanish',
    Jezik.portugalski => 'portuguese',
    Jezik.svedski => 'swedish',
  };
}

Jezik jezikIzDto(String jezik) => switch (jezik) {
  'english' => Jezik.engleski,
  'german' => Jezik.nemacki,
  'french' => Jezik.francuski,
  'italian' => Jezik.italijanski,
  'spanish' => Jezik.spanski,
  'portuguese' => Jezik.portugalski,
  'swedish' => Jezik.svedski,
  _ => throw FormatException('Nepoznat jezik', jezik),
};

extension NivoJezikaUDto on NivoJezika {
  String toDto() => oznaka;
}

NivoJezika nivoIzDto(String nivo) => NivoJezika.values.firstWhere(
  (n) => n.oznaka == nivo,
  orElse: () => throw FormatException('Nepoznat nivo jezika', nivo),
);

extension ZahtevJezikaUDto on ZahtevJezika {
  ZahtevJezikaDto toDto() => ZahtevJezikaDto(jezik: jezik.toDto(), nivo: nivo.toDto());
}

extension ZahtevJezikaDtoUDomen on ZahtevJezikaDto {
  ZahtevJezika toDomain() => ZahtevJezika(jezik: jezikIzDto(jezik), nivo: nivoIzDto(nivo));
}

extension SemestarUDto on Semestar {
  SemestarDto toDto() => SemestarDto(
    vrsta: switch (vrsta) {
      VrstaSemestra.zimski => SemestarDto.zimski,
      VrstaSemestra.letnji => SemestarDto.letnji,
    },
    akademskaGodina: akademskaGodina,
  );
}

extension SemestarDtoUDomen on SemestarDto {
  Semestar toDomain() => Semestar(
    vrsta: switch (vrsta) {
      SemestarDto.zimski => VrstaSemestra.zimski,
      SemestarDto.letnji => VrstaSemestra.letnji,
      _ => throw FormatException('Nepoznata vrsta semestra', vrsta),
    },
    akademskaGodina: akademskaGodina,
  );
}

extension PonudaUDto on Ponuda {
  PonudaDto toDto({required int zauzeto}) => PonudaDto(
    id: id.vrednost,
    idUniverziteta: idUniverziteta.vrednost,
    oblast: oblast,
    semestar: semestar.toDto(),
    brojMesta: brojMesta,
    zauzetaMesta: zauzeto,
    rok: rok,
    minimalniProsekStotih: prosekUStote(minimalniProsek),
    zahtevJezika: zahtevJezika.toDto(),
    opis: opis,
    napomena: napomena,
    objavio: objavio.vrednost,
    objavljena: objavljena,
  );
}

extension PonudaDtoUDomen on PonudaDto {
  Ponuda toDomain() => Ponuda(
    id: IdPonude(id),
    idUniverziteta: IdUniverziteta(idUniverziteta),
    oblast: oblast,
    semestar: semestar.toDomain(),
    brojMesta: brojMesta,
    rok: rok.toLocal(),
    minimalniProsek: prosekIzStotih(minimalniProsekStotih),
    zahtevJezika: zahtevJezika.toDomain(),
    opis: opis,
    napomena: napomena,
    objavio: IdKorisnika(objavio),
    objavljena: objavljena.toLocal(),
  );
}

Map<IdPonude, int> zauzetaMestaIz(List<PonudaDto> ponude) => {
  for (final ponuda in ponude) IdPonude(ponuda.id): ponuda.zauzetaMesta,
};
