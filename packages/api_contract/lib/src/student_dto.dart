import 'json.dart';

final class StudentDto {
  const StudentDto({
    required this.id,
    required this.ime,
    required this.prezime,
    required this.brojIndeksa,
    required this.email,
    required this.fakultet,
    required this.smer,
    required this.godinaStudija,
    required this.prosekStotih,
    required this.znanjeJezika,
  });

  final String id;
  final String ime;
  final String prezime;
  final String brojIndeksa;
  final String email;
  final String fakultet;
  final String smer;
  final int godinaStudija;
  final int prosekStotih;
  final Map<String, String> znanjeJezika;

  Map<String, Object?> toJson() => {
    'id': id,
    'firstName': ime,
    'lastName': prezime,
    'indexNumber': brojIndeksa,
    'email': email,
    'faculty': fakultet,
    'program': smer,
    'year': godinaStudija,
    'average': prosekStotih,
    'languages': znanjeJezika,
  };

  factory StudentDto.fromJson(Map<String, Object?> json) => StudentDto(
    id: jsonString(json, 'id'),
    ime: jsonString(json, 'firstName'),
    prezime: jsonString(json, 'lastName'),
    brojIndeksa: jsonString(json, 'indexNumber'),
    email: jsonString(json, 'email'),
    fakultet: jsonString(json, 'faculty'),
    smer: jsonString(json, 'program'),
    godinaStudija: jsonInt(json, 'year'),
    prosekStotih: jsonInt(json, 'average'),
    znanjeJezika: {
      for (final MapEntry(:key, :value) in jsonObject(json['languages']).entries)
        key: switch (value) {
          final String nivo => nivo,
          _ => throw FormatException('Expected "languages.$key" to be a string', json),
        },
    },
  );
}
