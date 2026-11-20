import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'test_baza.dart';
import 'use_cases_test.dart' show andrej, ponuda, prijava, sat, student;

final class SamoUzPrijavu implements PrijavaRepository, StudentRepository {
  @override
  dynamic noSuchMethod(Invocation poziv) => throw StateError('Poziv bez prijave: ${poziv.memberName}');
}

void main() {
  test('bez prijave UcitajPregled cita samo javni deo: ponude, univerzitete i zauzeta mesta', () async {
    final baza = TestBaza(
      student: student,
      ponude: [ponuda()],
      prijave: [
        prijava(
          stanje: Prihvacena(odlucio: const IdKorisnika('k-1'), kada: sat.sada()),
        ),
      ],
    );
    final zabranjeno = SamoUzPrijavu();

    final pregled = await UcitajPregled(ponude: baza, prijave: zabranjeno, studenti: zabranjeno, sat: sat)(null);
    final milano = pregled.ponude.single;

    expect(pregled.student, isNull);
    expect(pregled.mojePrijave, isEmpty);
    expect(pregled.sacuvane, isEmpty);
    expect(pregled.slobodnaMesta(milano), 1);
    expect(pregled.uslovi(milano), isNull);
    expect(pregled.mojaPrijavaZa(milano.id), isNull);
    expect(pregled.brojAktivnih, 0);
  });

  test('sa prijavom isti use case vraca i studenta i uslove', () async {
    final baza = TestBaza(student: student, ponude: [ponuda()]);

    final pregled = await UcitajPregled(ponude: baza, prijave: baza, studenti: baza, sat: sat)(andrej);

    expect(pregled.student, student);
    expect(pregled.uslovi(pregled.ponude.single)?.ispunjeni, isTrue);
  });
}
