import 'package:domain/domain.dart';

import 'ports/ponuda_repository.dart';
import 'ports/prijava_repository.dart';
import 'promena_stanja.dart';
import 'sat.dart';

final class PrihvatiPrijavu {
  const PrihvatiPrijavu({required this.ponude, required this.prijave, required this.sat});

  final PonudaRepository ponude;
  final PrijavaRepository prijave;
  final Sat sat;

  Future<Rezultat<Prijava>> call({required Korisnik ko, required IdPrijave id}) => promeniPrijavu(
    prijave,
    id,
    promena: (prijava) async {
      final vidljiva = vidljivaPonuda(ko, prijava, await ponude.ponude());
      if (vidljiva case Neuspeh(:final greska)) return Neuspeh(greska);
      final ponuda = vidljiva.vrednostIliNull!;
      return prihvatiPrijavu(
        prijava,
        ko: ko,
        ponuda: ponuda,
        svePrijave: await prijave.prijaveNaPonudeUniverziteta(ponuda.idUniverziteta),
        sada: sat.sada(),
      );
    },
  );
}

final class StaviNaListuCekanja {
  const StaviNaListuCekanja({required this.ponude, required this.prijave, required this.sat});

  final PonudaRepository ponude;
  final PrijavaRepository prijave;
  final Sat sat;

  Future<Rezultat<Prijava>> call({required Korisnik ko, required IdPrijave id}) => promeniPrijavu(
    prijave,
    id,
    promena: (prijava) async {
      final vidljiva = vidljivaPonuda(ko, prijava, await ponude.ponude());
      if (vidljiva case Neuspeh(:final greska)) return Neuspeh(greska);
      return staviNaListuCekanja(prijava, ko: ko, ponuda: vidljiva.vrednostIliNull!, sada: sat.sada());
    },
  );
}

final class OdbijPrijavu {
  const OdbijPrijavu({required this.ponude, required this.prijave, required this.sat});

  final PonudaRepository ponude;
  final PrijavaRepository prijave;
  final Sat sat;

  Future<Rezultat<Prijava>> call({required Korisnik ko, required IdPrijave id, required String razlog}) =>
      promeniPrijavu(
        prijave,
        id,
        promena: (prijava) async {
          final vidljiva = vidljivaPonuda(ko, prijava, await ponude.ponude());
          if (vidljiva case Neuspeh(:final greska)) return Neuspeh(greska);
          return odbijPrijavu(prijava, ko: ko, ponuda: vidljiva.vrednostIliNull!, razlog: razlog, sada: sat.sada());
        },
      );
}
