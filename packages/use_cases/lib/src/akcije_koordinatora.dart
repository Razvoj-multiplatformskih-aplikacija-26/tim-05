import 'package:domain/domain.dart';

import 'ports/ponuda_repository.dart';
import 'ports/prijava_repository.dart';
import 'sat.dart';

Prijava? _nadji(List<Prijava> prijave, IdPrijave id) => prijave.where((p) => p.id == id).firstOrNull;

Ponuda? _ponuda(List<Ponuda> ponude, IdPonude id) => ponude.where((p) => p.id == id).firstOrNull;

final class PrihvatiPrijavu {
  const PrihvatiPrijavu({required this.ponude, required this.prijave, required this.sat});

  final PonudaRepository ponude;
  final PrijavaRepository prijave;
  final Sat sat;

  Future<Rezultat<Prijava>> call({required Korisnik ko, required IdPrijave id}) async {
    final sve = await prijave.svePrijave();
    final prijava = _nadji(sve, id);

    if (prijava == null) return const Neuspeh(NijePronadjeno());

    final ponuda = _ponuda(await ponude.ponude(), prijava.idPonude);

    if (ponuda == null) return const Neuspeh(NijePronadjeno());

    final rezultat = prihvatiPrijavu(prijava, ko: ko, ponuda: ponuda, svePrijave: sve, sada: sat.sada());

    if (rezultat case Uspeh(:final vrednost)) await prijave.sacuvaj([vrednost]);

    return rezultat;
  }
}

final class StaviNaListuCekanja {
  const StaviNaListuCekanja({required this.ponude, required this.prijave, required this.sat});

  final PonudaRepository ponude;
  final PrijavaRepository prijave;
  final Sat sat;

  Future<Rezultat<Prijava>> call({required Korisnik ko, required IdPrijave id}) async {
    final prijava = _nadji(await prijave.svePrijave(), id);

    if (prijava == null) return const Neuspeh(NijePronadjeno());

    final ponuda = _ponuda(await ponude.ponude(), prijava.idPonude);

    if (ponuda == null) return const Neuspeh(NijePronadjeno());

    final rezultat = staviNaListuCekanja(prijava, ko: ko, ponuda: ponuda, sada: sat.sada());

    if (rezultat case Uspeh(:final vrednost)) await prijave.sacuvaj([vrednost]);

    return rezultat;
  }
}

final class OdbijPrijavu {
  const OdbijPrijavu({required this.ponude, required this.prijave, required this.sat});

  final PonudaRepository ponude;
  final PrijavaRepository prijave;
  final Sat sat;

  Future<Rezultat<Prijava>> call({required Korisnik ko, required IdPrijave id, required String razlog}) async {
    final prijava = _nadji(await prijave.svePrijave(), id);

    if (prijava == null) return const Neuspeh(NijePronadjeno());

    final ponuda = _ponuda(await ponude.ponude(), prijava.idPonude);

    if (ponuda == null) return const Neuspeh(NijePronadjeno());

    final rezultat = odbijPrijavu(prijava, ko: ko, ponuda: ponuda, razlog: razlog, sada: sat.sada());

    if (rezultat case Uspeh(:final vrednost)) await prijave.sacuvaj([vrednost]);

    return rezultat;
  }
}
