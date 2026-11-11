import 'json.dart';

final class ProblemDto {
  const ProblemDto({required this.status, required this.code, required this.title});

  static const mediaType = 'application/problem+json';

  static String typeOf(String code) => 'tag:raf.rs,2026:erasmusgo/problem/$code';

  final int status;
  final String code;
  final String title;

  Map<String, Object?> toJson() => {'type': typeOf(code), 'title': title, 'status': status, 'code': code};

  factory ProblemDto.fromJson(Map<String, Object?> json) => ProblemDto(
    status: jsonInt(json, 'status'),
    code: jsonString(json, 'code'),
    title: jsonOptionalString(json, 'title') ?? '',
  );
}