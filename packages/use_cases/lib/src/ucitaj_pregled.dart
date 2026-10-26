import 'package:domain/domain.dart';

import 'ports/ponuda_repository.dart';
import 'ports/prijava_repository.dart';
import 'ports/student_repository.dart';
import 'pregled_podataka.dart';
import 'sat.dart';

final class UcitajPregled {
  const UcitajPregled({required this.ponude, required this.prijave, required this.studenti, required this.sat});

  final PonudaRepository ponude;
  final PrijavaRepository prijave;
  final StudentRepository studenti;

  final Sat sat;

  Future<PregledPodataka> call(Korisnik ko) async {
    final odgovori = await Future.wait<Object>([
      ponude.ponude(),
      ponude.univerziteti(),
      prijave.svePrijave(),
      studenti.student(ko.id),
      studenti.sacuvanePonude(ko.id),
    ]);
    return PregledPodataka(
      ponude: odgovori[0] as List<Ponuda>,
      univerziteti: odgovori[1] as List<Univerzitet>,
      svePrijave: odgovori[2] as List<Prijava>,
      student: odgovori[3] as Student,
      sacuvane: odgovori[4] as Set<IdPonude>,
      sada: sat.sada(),
    );
  }
}
