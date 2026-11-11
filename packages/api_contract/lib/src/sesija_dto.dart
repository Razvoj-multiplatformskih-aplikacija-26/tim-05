import 'json.dart';
import 'korisnik_dto.dart';


final class PrijavljivanjeDto {
  const PrijavljivanjeDto({required this.korisnickoIme, required this.lozinka, this.kolacic = false});

  final String korisnickoIme;
  final String lozinka;
  final bool kolacic;

  Map<String, Object?> toJson() => {'username': korisnickoIme, 'password': lozinka, 'cookie': kolacic};

  factory PrijavljivanjeDto.fromJson(Map<String, Object?> json) => PrijavljivanjeDto(
    korisnickoIme: jsonString(json, 'username'),
    lozinka: jsonString(json, 'password'),
    kolacic: json['cookie'] == true,
  );
}

final class SesijaDto {
  const SesijaDto({required this.korisnik, required this.istice, this.token});

  final KorisnikDto korisnik;
  final DateTime istice;
  final String? token;

  Map<String, Object?> toJson() => {'user': korisnik.toJson(), 'expiresAt': instantToJson(istice), 'token': ?token};

  factory SesijaDto.fromJson(Map<String, Object?> json) => SesijaDto(
    korisnik: KorisnikDto.fromJson(jsonObject(json['user'])),
    istice: jsonInstant(json, 'expiresAt'),
    token: jsonOptionalString(json, 'token'),
  );
}