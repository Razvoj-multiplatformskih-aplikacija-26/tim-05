import 'package:domain/domain.dart';

import 'ports/ponuda_repository.dart';
import 'ports/prijava_repository.dart';
import 'ports/student_repository.dart';
import 'promena_stanja.dart';
import 'sat.dart';

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
    if (idPrijave != null) {
      return promeniPrijavu(
        prijave,
        idPrijave,
        promena: (postojeca) async {
          if (!await smeDaVidi(ko, postojeca, ponude)) return const Neuspeh(NijePronadjeno());
          final izmena = izmeniPrijavu(postojeca, ko: ko, motivacionoPismo: pismo, napomena: napomena);
          if (izmena case Neuspeh(:final greska)) return Neuspeh(greska);
          final izmenjena = izmena.vrednostIliNull!;
          return posalji ? _posalji(izmenjena, ko: ko, svePonude: await ponude.ponude()) : Uspeh(izmenjena);
        },
      );
    }
    if (idPonude == null) return const Neuspeh(NijePronadjeno());

    final sada = sat.sada();
    final nova = napraviPrijavu(
      id: IdPrijave('p-${sada.microsecondsSinceEpoch}'),
      ko: ko,
      idPonude: idPonude,
      motivacionoPismo: pismo,
      napomena: napomena,
      svePrijave: await prijave.prijaveStudenta(ko.id),
      sada: sada,
    );
    if (nova case Neuspeh(:final greska)) return Neuspeh(greska);
    var zaUpis = nova.vrednostIliNull!;
    if (posalji) {
      final slanje = await _posalji(zaUpis, ko: ko, svePonude: await ponude.ponude());
      if (slanje case Neuspeh(:final greska)) return Neuspeh(greska);
      zaUpis = slanje.vrednostIliNull!;
    }
    return prijave.napravi(zaUpis);
  }

  Future<Rezultat<Prijava>> _posalji(Prijava prijava, {required Korisnik ko, required List<Ponuda> svePonude}) async {
    final ponuda = _ponuda(svePonude, prijava.idPonude);
    if (ponuda == null) return const Neuspeh(NijePronadjeno());
    return posaljiPrijavu(
      prijava,
      ko: ko,
      student: await studenti.student(ko.id),
      ponuda: ponuda,
      svePrijave: await prijave.prijaveStudenta(ko.id),
      sada: sat.sada(),
      ponude: svePonude,
    );
  }
}

final class PovuciPrijavu {
  const PovuciPrijavu({required this.ponude, required this.prijave, required this.sat});

  final PonudaRepository ponude;
  final PrijavaRepository prijave;
  final Sat sat;

  Future<Rezultat<Prijava>> call({required Korisnik ko, required IdPrijave id}) => promeniPrijavu(
    prijave,
    id,
    promena: (prijava) async {
      if (!await smeDaVidi(ko, prijava, ponude)) return const Neuspeh(NijePronadjeno());
      return povuciPrijavu(prijava, ko: ko, sada: sat.sada());
    },
  );
}

final class PotvrdiMesto {
  const PotvrdiMesto({required this.ponude, required this.prijave, required this.sat});

  final PonudaRepository ponude;
  final PrijavaRepository prijave;
  final Sat sat;

  Future<Rezultat<List<Prijava>>> call({required Korisnik ko, required IdPrijave id}) async {
    final prijava = await prijave.prijava(id);
    if (prijava == null) return const Neuspeh(NijePronadjeno());
    final svePonude = await ponude.ponude();
    final vidljiva = vidljivaPonuda(ko, prijava, svePonude);
    if (vidljiva case Neuspeh(:final greska)) return Neuspeh(greska);
    final ponuda = vidljiva.vrednostIliNull!;
    final rezultat = potvrdiMesto(
      prijava,
      ko: ko,
      ponuda: ponuda,
      ponude: svePonude,
      svePrijave: await prijave.prijaveStudenta(prijava.idStudenta),
      sada: sat.sada(),
    );
    return switch (rezultat) {
      Uspeh(vrednost: [final potvrdjena, ...final povucene]) => prijave.potvrdiMesto(potvrdjena, povucene: povucene),
      Uspeh() => const Neuspeh(NijePronadjeno()),
      Neuspeh(:final greska) => Neuspeh(greska),
    };
  }
}

final class OdbijMesto {
  const OdbijMesto({required this.ponude, required this.prijave, required this.sat});

  final PonudaRepository ponude;
  final PrijavaRepository prijave;
  final Sat sat;

  Future<Rezultat<Prijava>> call({required Korisnik ko, required IdPrijave id}) => promeniPrijavu(
    prijave,
    id,
    promena: (prijava) async {
      if (!await smeDaVidi(ko, prijava, ponude)) return const Neuspeh(NijePronadjeno());
      return odbijMesto(prijava, ko: ko, sada: sat.sada());
    },
  );
}

final class ObrisiPrijavu {
  const ObrisiPrijavu({required this.ponude, required this.prijave});

  final PonudaRepository ponude;
  final PrijavaRepository prijave;

  Future<Rezultat<Prijava>> call({required Korisnik ko, required IdPrijave id}) async {
    final prijava = await prijave.prijava(id);
    if (prijava == null) return const Neuspeh(NijePronadjeno());
    if (!await smeDaVidi(ko, prijava, ponude)) return const Neuspeh(NijePronadjeno());
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
