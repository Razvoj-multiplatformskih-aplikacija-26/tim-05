import 'package:meta/meta.dart';

import 'identifikatori.dart';
import 'jezik.dart';

@immutable
final class Student {
  const Student({
    required this.id,
    required this.ime,
    required this.prezime,
    required this.brojIndeksa,
    required this.email,
    required this.fakultet,
    required this.smer,
    required this.godinaStudija,
    required this.prosek,
    required this.znanjeJezika,
  });

  final IdKorisnika id;
  final String ime;
  final String prezime;
  final String brojIndeksa;
  final String email;
  final String fakultet;
  final String smer;
  final int godinaStudija;

  final double prosek;

  final Map<Jezik, NivoJezika> znanjeJezika;

  String get punoIme => '$ime $prezime';

  NivoJezika? nivoZa(Jezik jezik) => znanjeJezika[jezik];

  @override
  bool operator ==(Object other) =>
      other is Student &&
      other.id == id &&
      other.ime == ime &&
      other.prezime == prezime &&
      other.brojIndeksa == brojIndeksa &&
      other.email == email &&
      other.fakultet == fakultet &&
      other.smer == smer &&
      other.godinaStudija == godinaStudija &&
      other.prosek == prosek &&
      _istaZnanja(other.znanjeJezika, znanjeJezika);

  @override
  int get hashCode => Object.hash(
    id,
    ime,
    prezime,
    brojIndeksa,
    email,
    fakultet,
    smer,
    godinaStudija,
    prosek,
    Object.hashAllUnordered(znanjeJezika.entries.map((e) => Object.hash(e.key, e.value))),
  );

  @override
  String toString() => 'Student($punoIme, $brojIndeksa)';
}

bool _istaZnanja(Map<Jezik, NivoJezika> a, Map<Jezik, NivoJezika> b) {
  if (a.length != b.length) return false;
  for (final MapEntry(:key, :value) in a.entries) {
    if (b[key] != value) return false;
  }
  return true;
}
