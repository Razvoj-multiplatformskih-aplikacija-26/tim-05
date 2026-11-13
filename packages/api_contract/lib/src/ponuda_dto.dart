import 'json.dart';

final class UniverzitetDto {
  const UniverzitetDto({
    required this.id,
    required this.naziv,
    required this.grad,
    required this.drzava,
    required this.oznakaDrzave,
  });

  final String id;
  final String naziv;
  final String grad;
  final String drzava;
  final String oznakaDrzave;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': naziv,
    'city': grad,
    'country': drzava,
    'countryCode': oznakaDrzave,
  };

  factory UniverzitetDto.fromJson(Map<String, Object?> json) => UniverzitetDto(
    id: jsonString(json, 'id'),
    naziv: jsonString(json, 'name'),
    grad: jsonString(json, 'city'),
    drzava: jsonString(json, 'country'),
    oznakaDrzave: jsonString(json, 'countryCode'),
  );
}

final class SemestarDto {
  const SemestarDto({required this.vrsta, required this.akademskaGodina});

  static const zimski = 'winter';
  static const letnji = 'summer';

  final String vrsta;
  final String akademskaGodina;

  Map<String, Object?> toJson() => {'kind': vrsta, 'academicYear': akademskaGodina};

  factory SemestarDto.fromJson(Map<String, Object?> json) =>
      SemestarDto(vrsta: jsonString(json, 'kind'), akademskaGodina: jsonString(json, 'academicYear'));
}

final class ZahtevJezikaDto {
  const ZahtevJezikaDto({required this.jezik, required this.nivo});

  final String jezik;
  final String nivo;

  Map<String, Object?> toJson() => {'language': jezik, 'level': nivo};

  factory ZahtevJezikaDto.fromJson(Map<String, Object?> json) =>
      ZahtevJezikaDto(jezik: jsonString(json, 'language'), nivo: jsonString(json, 'level'));
}


final class PonudaDto {
  const PonudaDto({
    required this.id,
    required this.idUniverziteta,
    required this.oblast,
    required this.semestar,
    required this.brojMesta,
    required this.zauzetaMesta,
    required this.rok,
    required this.minimalniProsekStotih,
    required this.zahtevJezika,
    required this.opis,
    required this.objavio,
    required this.objavljena,
    this.napomena,
  });

  final String id;
  final String idUniverziteta;
  final String oblast;
  final SemestarDto semestar;
  final int brojMesta;
  final int zauzetaMesta;
  final DateTime rok;
  final int minimalniProsekStotih;
  final ZahtevJezikaDto zahtevJezika;
  final String opis;
  final String? napomena;
  final String objavio;
  final DateTime objavljena;

  Map<String, Object?> toJson() => {
    'id': id,
    'universityId': idUniverziteta,
    'field': oblast,
    'semester': semestar.toJson(),
    'places': brojMesta,
    'takenPlaces': zauzetaMesta,
    'deadline': instantToJson(rok),
    'minAverage': minimalniProsekStotih,
    'language': zahtevJezika.toJson(),
    'description': opis,
    'note': ?napomena,
    'publishedBy': objavio,
    'publishedAt': instantToJson(objavljena),
  };

  factory PonudaDto.fromJson(Map<String, Object?> json) => PonudaDto(
    id: jsonString(json, 'id'),
    idUniverziteta: jsonString(json, 'universityId'),
    oblast: jsonString(json, 'field'),
    semestar: SemestarDto.fromJson(jsonObject(json['semester'])),
    brojMesta: jsonInt(json, 'places'),
    zauzetaMesta: jsonInt(json, 'takenPlaces'),
    rok: jsonInstant(json, 'deadline'),
    minimalniProsekStotih: jsonInt(json, 'minAverage'),
    zahtevJezika: ZahtevJezikaDto.fromJson(jsonObject(json['language'])),
    opis: jsonString(json, 'description'),
    napomena: jsonOptionalString(json, 'note'),
    objavio: jsonString(json, 'publishedBy'),
    objavljena: jsonInstant(json, 'publishedAt'),
  );
}
