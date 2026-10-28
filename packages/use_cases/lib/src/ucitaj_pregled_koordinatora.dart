import 'package:domain/domain.dart';

import 'greska_repozitorijuma.dart';
import 'ports/ponuda_repository.dart';
import 'ports/prijava_repository.dart';
import 'ports/student_repository.dart';
import 'pregled_koordinatora.dart';
import 'sat.dart';

final class UcitajPregledKoordinatora {
  const UcitajPregledKoordinatora({
    required this.ponude,
    required this.prijave,
    required this.studenti,
    required this.sat,
  });

  final PonudaRepository ponude;
  final PrijavaRepository prijave;
  final StudentRepository studenti;
  final Sat sat;

  Future<PregledKoordinatora> call(Korisnik ko) async {
    final odgovori = await Future.wait<Object>([ponude.ponude(), ponude.univerziteti(), prijave.svePrijave()]);
    final svePonude = odgovori[0] as List<Ponuda>;
    final univerziteti = odgovori[1] as List<Univerzitet>;
    final svePrijave = odgovori[2] as List<Prijava>;

    final univerzitet = univerziteti.where((u) => u.id == ko.idUniverziteta).firstOrNull;

    if (univerzitet == null) throw const GreskaRepozitorijuma('Univerzitet koordinatora nije pronadjen');

    final mojePonude = [
      for (final ponuda in svePonude)
        if (ponuda.idUniverziteta == univerzitet.id) ponuda,
    ];
    
    final idPonuda = {for (final ponuda in mojePonude) ponuda.id};
    final prijaveNaPonude = [
      for (final prijava in svePrijave)
        if (idPonuda.contains(prijava.idPonude) && prijava.stanje is! UPripremi) prijava,
    ];

    final idStudenata = {for (final prijava in prijaveNaPonude) prijava.idStudenta}.toList();
    final listaStudenata = await Future.wait([for (final id in idStudenata) studenti.student(id)]);
    final studentiPoId = {for (final student in listaStudenata) student.id: student};

    int redPonude(Prijava p) => mojePonude.indexWhere((ponuda) => ponuda.id == p.idPonude);
    double prosek(Prijava p) => studentiPoId[p.idStudenta]?.prosek ?? 0;
    prijaveNaPonude.sort((a, b) {
      final poPonudi = redPonude(a).compareTo(redPonude(b));
      return poPonudi != 0 ? poPonudi : prosek(b).compareTo(prosek(a));
    });

    return PregledKoordinatora(
      univerzitet: univerzitet,
      ponude: mojePonude,
      prijave: List.unmodifiable(prijaveNaPonude),
      studenti: Map.unmodifiable(studentiPoId),
      sada: sat.sada(),
    );
  }
}
