import 'json.dart';
import 'prijava_dto.dart';

final class ProblemDto {
  const ProblemDto({
    required this.status,
    required this.code,
    required this.title,
    this.value,
    this.min,
    this.max,
    this.rok,
    this.jezik,
    this.nivo,
    this.nivoKorisnika,
    this.iz,
    this.u,
  });

  static const mediaType = 'application/problem+json';

  static String typeOf(String code) => 'tag:raf.rs,2026:erasmusgo/problem/$code';

  final int status;
  final String code;
  final String title;

  final int? value;

  final int? min;

  final int? max;

  final DateTime? rok;

  final String? jezik;
  final String? nivo;
  final String? nivoKorisnika;

  final StanjePrijaveDto? iz;
  final StanjePrijaveDto? u;

  Map<String, Object?> toJson() => {
    'type': typeOf(code),
    'title': title,
    'status': status,
    'code': code,
    'value': ?value,
    'min': ?min,
    'max': ?max,
    if (rok case final rok?) 'deadline': instantToJson(rok),
    'language': ?jezik,
    'level': ?nivo,
    'actualLevel': ?nivoKorisnika,
    if (iz case final iz?) 'from': iz.toJson(),
    if (u case final u?) 'to': u.toJson(),
  };

  factory ProblemDto.fromJson(Map<String, Object?> json) => ProblemDto(
    status: jsonInt(json, 'status'),
    code: jsonString(json, 'code'),
    title: jsonOptionalString(json, 'title') ?? '',
    value: jsonOptionalInt(json, 'value'),
    min: jsonOptionalInt(json, 'min'),
    max: jsonOptionalInt(json, 'max'),
    rok: jsonOptionalInstant(json, 'deadline'),
    jezik: jsonOptionalString(json, 'language'),
    nivo: jsonOptionalString(json, 'level'),
    nivoKorisnika: jsonOptionalString(json, 'actualLevel'),
    iz: json['from'] == null ? null : StanjePrijaveDto.fromJson(jsonObject(json['from'])),
    u: json['to'] == null ? null : StanjePrijaveDto.fromJson(jsonObject(json['to'])),
  );
}
