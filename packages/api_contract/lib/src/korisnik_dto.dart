import 'json.dart';

final class KorisnikDto {
  const KorisnikDto({required this.id, required this.korisnickoIme, required this.uloga, this.idUniverziteta});

  static const student = 'student';
  static const koordinator = 'koordinator';

  final String id;
  final String korisnickoIme;
  final String uloga;
  final String? idUniverziteta;

  Map<String, Object?> toJson() => {
    'id': id,
    'username': korisnickoIme,
    'role': uloga,
    'universityId': ?idUniverziteta,
  };

  factory KorisnikDto.fromJson(Map<String, Object?> json) => KorisnikDto(
    id: jsonString(json, 'id'),
    korisnickoIme: jsonString(json, 'username'),
    uloga: jsonString(json, 'role'),
    idUniverziteta: jsonOptionalString(json, 'universityId'),
  );
}