import 'package:domain/domain.dart';

import 'ports/ponuda_repository.dart';
import 'ports/prijava_repository.dart';
import 'ports/student_repository.dart';
import 'sat.dart';

Prijava? _nadji(List<Prijava> prijave, IdPrijave id) => prijave.where((p) => p.id == id).firstOrNull;

Ponuda? _ponuda(List<Ponuda> ponude, IdPonude id) => ponude.where((p) => p.id == id).firstOrNull;

final class SacuvajPrijavu {
  const SacuvajPrijavu({required this.ponude, required this.prijave, required this.studenti, required this.sat});

  final PonudaRepository ponude;
  final PrijavaRepository prijave;
  final StudentRepository studenti;
  final Sat sat;

  Future<Rezultat<Prijava>> call({
    required Korisnik ko,
    IdPonude? idPonude,
    IdPrijave? idPrijave,
    required MotivacionoPismo pismo,
    String? napomena,
    bool posalji = false,
  }) async {
    final sve = await prijave.svePrijave();
    final sada = sat.sada();

    final Prijava prijava;
    if (idPrijave != null) {
      final postojeca = _nadji(sve, idPrijave);
      if (postojeca == null) return const Neuspeh(NijePronadjeno());
      final izmena = izmeniPrijavu(postojeca, ko: ko, motivacionoPismo: pismo, napomena: napomena);
      if (izmena case Neuspeh(:final greska)) return Neuspeh(greska);
      prijava = izmena.vrednostIliNull!;
    } else if (idPonude != null) {
      prijava = Prijava(
        id: IdPrijave('p-${sada.microsecondsSinceEpoch}'),
        idStudenta: ko.id,
        idPonude: idPonude,
        motivacionoPismo: pismo,
        napomena: napomena,
        napravljena: sada,
      );
    } else {
      return const Neuspeh(NijePronadjeno());
    }

    var zaCuvanje = prijava;
    if (posalji) {
      final svePonude = await ponude.ponude();
      final ponuda = _ponuda(svePonude, prijava.idPonude);
      if (ponuda == null) return const Neuspeh(NijePronadjeno());
      final student = await studenti.student(ko.id);
      final slanje = posaljiPrijavu(
        prijava,
        ko: ko,
        student: student,
        ponuda: ponuda,
        svePrijave: sve,
        sada: sada,
        ponude: svePonude,
      );
      if (slanje case Neuspeh(:final greska)) return Neuspeh(greska);
      zaCuvanje = slanje.vrednostIliNull!;
    }

    await prijave.sacuvaj([zaCuvanje]);
    return Uspeh(zaCuvanje);
  }
}

final class PovuciPrijavu {
  const PovuciPrijavu({required this.prijave, required this.sat});

  final PrijavaRepository prijave;
  final Sat sat;

  Future<Rezultat<Prijava>> call({required Korisnik ko, required IdPrijave id}) async {
    final prijava = _nadji(await prijave.svePrijave(), id);
    if (prijava == null) return const Neuspeh(NijePronadjeno());
    final rezultat = povuciPrijavu(prijava, ko: ko, sada: sat.sada());
    if (rezultat case Uspeh(:final vrednost)) await prijave.sacuvaj([vrednost]);
    return rezultat;
  }
}

final class PotvrdiMesto {
  const PotvrdiMesto({required this.ponude, required this.prijave, required this.sat});

  final PonudaRepository ponude;
  final PrijavaRepository prijave;
  final Sat sat;

  Future<Rezultat<List<Prijava>>> call({required Korisnik ko, required IdPrijave id}) async {
    final sve = await prijave.svePrijave();
    final prijava = _nadji(sve, id);
    if (prijava == null) return const Neuspeh(NijePronadjeno());
    final svePonude = await ponude.ponude();
    final ponuda = _ponuda(svePonude, prijava.idPonude);
    if (ponuda == null) return const Neuspeh(NijePronadjeno());
    final rezultat = potvrdiMesto(
      prijava,
      ko: ko,
      ponuda: ponuda,
      ponude: svePonude,
      svePrijave: sve,
      sada: sat.sada(),
    );
    if (rezultat case Uspeh(:final vrednost)) await prijave.sacuvaj(vrednost);
    return rezultat;
  }
}

final class OdbijMesto {
  const OdbijMesto({required this.prijave, required this.sat});

  final PrijavaRepository prijave;
  final Sat sat;

  Future<Rezultat<Prijava>> call({required Korisnik ko, required IdPrijave id}) async {
    final prijava = _nadji(await prijave.svePrijave(), id);
    if (prijava == null) return const Neuspeh(NijePronadjeno());
    final rezultat = odbijMesto(prijava, ko: ko, sada: sat.sada());
    if (rezultat case Uspeh(:final vrednost)) await prijave.sacuvaj([vrednost]);
    return rezultat;
  }
}

final class ObrisiPrijavu {
  const ObrisiPrijavu({required this.prijave});

  final PrijavaRepository prijave;

  Future<Rezultat<Prijava>> call({required Korisnik ko, required IdPrijave id}) async {
    final prijava = _nadji(await prijave.svePrijave(), id);
    if (prijava == null) return const Neuspeh(NijePronadjeno());
    final rezultat = obrisiPrijavu(prijava, ko: ko);
    if (rezultat case Uspeh()) await prijave.obrisi(id);
    return rezultat;
  }
}

final class PromeniSacuvanu {
  const PromeniSacuvanu({required this.studenti});

  final StudentRepository studenti;

  Future<void> call({required Korisnik ko, required IdPonude idPonude}) => studenti.promeniSacuvanu(ko.id, idPonude);
}

final class SacuvajProfil {
  const SacuvajProfil({required this.studenti});

  final StudentRepository studenti;

  Future<Rezultat<Student>> call({required Korisnik ko, required Student student}) async {
    if (student.id != ko.id) return const Neuspeh(NemaPravo());
    await studenti.sacuvajStudenta(student);
    return Uspeh(student);
  }
}
