import 'json.dart';

final class StanjePrijaveDto {
  const StanjePrijaveDto({required this.vrsta, this.odlucio, this.kada, this.razlog});

  static const uPripremi = 'draft';
  static const poslata = 'submitted';
  static const naListiCekanja = 'waitlisted';
  static const prihvacena = 'accepted';
  static const odbijena = 'rejected';
  static const potvrdjena = 'confirmed';
  static const povucena = 'withdrawn';

  final String vrsta;
  final String? odlucio;
  final DateTime? kada;
  final String? razlog;

  Map<String, Object?> toJson() => {
    'kind': vrsta,
    'by': ?odlucio,
    if (kada case final kada?) 'at': instantToJson(kada),
    'reason': ?razlog,
  };

  factory StanjePrijaveDto.fromJson(Map<String, Object?> json) => StanjePrijaveDto(
    vrsta: jsonString(json, 'kind'),
    odlucio: jsonOptionalString(json, 'by'),
    kada: jsonOptionalInstant(json, 'at'),
    razlog: jsonOptionalString(json, 'reason'),
  );
}

final class PrijavaDto {
  const PrijavaDto({
    required this.id,
    required this.idStudenta,
    required this.idPonude,
    required this.motivacionoPismo,
    required this.napravljena,
    required this.stanje,
    this.napomena,
  });

  final String id;
  final String idStudenta;
  final String idPonude;
  final String motivacionoPismo;
  final String? napomena;
  final DateTime napravljena;
  final StanjePrijaveDto stanje;

  Map<String, Object?> toJson() => {
    'id': id,
    'studentId': idStudenta,
    'offerId': idPonude,
    'letter': motivacionoPismo,
    'note': ?napomena,
    'createdAt': instantToJson(napravljena),
    'status': stanje.toJson(),
  };

  factory PrijavaDto.fromJson(Map<String, Object?> json) => PrijavaDto(
    id: jsonString(json, 'id'),
    idStudenta: jsonString(json, 'studentId'),
    idPonude: jsonString(json, 'offerId'),
    motivacionoPismo: jsonString(json, 'letter'),
    napomena: jsonOptionalString(json, 'note'),
    napravljena: jsonInstant(json, 'createdAt'),
    stanje: StanjePrijaveDto.fromJson(jsonObject(json['status'])),
  );
}


final class NovaPrijavaDto {
  const NovaPrijavaDto({required this.idPonude, required this.motivacionoPismo, this.napomena, this.posalji = false});

  final String idPonude;
  final String motivacionoPismo;
  final String? napomena;
  final bool posalji;

  Map<String, Object?> toJson() => {
    'offerId': idPonude,
    'letter': motivacionoPismo,
    'note': ?napomena,
    'submit': posalji,
  };

  factory NovaPrijavaDto.fromJson(Map<String, Object?> json) => NovaPrijavaDto(
    idPonude: jsonString(json, 'offerId'),
    motivacionoPismo: jsonString(json, 'letter'),
    napomena: jsonOptionalString(json, 'note'),
    posalji: json['submit'] == true,
  );
}

final class IzmenaPrijaveDto {
  const IzmenaPrijaveDto({required this.motivacionoPismo, this.napomena, this.posalji = false});

  final String motivacionoPismo;
  final String? napomena;
  final bool posalji;

  Map<String, Object?> toJson() => {'letter': motivacionoPismo, 'note': ?napomena, 'submit': posalji};

  factory IzmenaPrijaveDto.fromJson(Map<String, Object?> json) => IzmenaPrijaveDto(
    motivacionoPismo: jsonString(json, 'letter'),
    napomena: jsonOptionalString(json, 'note'),
    posalji: json['submit'] == true,
  );
}

final class OdbijanjeDto {
  const OdbijanjeDto({required this.razlog});

  final String razlog;

  Map<String, Object?> toJson() => {'reason': razlog};

  factory OdbijanjeDto.fromJson(Map<String, Object?> json) => OdbijanjeDto(razlog: jsonString(json, 'reason'));
}
