import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'pomocno.dart';

Student kopija({double? prosek, Map<Jezik, NivoJezika>? jezici}) => Student(
  id: studentAndrej.id,
  ime: studentAndrej.ime,
  prezime: studentAndrej.prezime,
  brojIndeksa: studentAndrej.brojIndeksa,
  email: studentAndrej.email,
  fakultet: studentAndrej.fakultet,
  smer: studentAndrej.smer,
  godinaStudija: studentAndrej.godinaStudija,
  prosek: prosek ?? studentAndrej.prosek,
  znanjeJezika: jezici ?? Map.of(studentAndrej.znanjeJezika),
);

void main() {
  group('Student (jednakost po vrednosti)', () {
    test('isti podaci daju jednake studente', () {
      expect(kopija(), studentAndrej);
      expect(kopija().hashCode, studentAndrej.hashCode);
    });

    test('izmenjen prosek daje drugog studenta', () {
      expect(kopija(prosek: 9.2), isNot(studentAndrej));
    });

    test('izmenjen nivo jezika daje drugog studenta', () {
      expect(kopija(jezici: {Jezik.engleski: NivoJezika.c1}), isNot(studentAndrej));
    });
  });
}
