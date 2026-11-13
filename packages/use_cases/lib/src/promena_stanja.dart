import 'package:domain/domain.dart';

import 'ports/ponuda_repository.dart';
import 'ports/prijava_repository.dart';

const _pokusaji = 3;

Future<Rezultat<Prijava>> promeniPrijavu(
  PrijavaRepository prijave,
  IdPrijave id, {
  required Future<Rezultat<Prijava>> Function(Prijava trenutna) promena,
}) async {
  Rezultat<Prijava> ishod = const Neuspeh(NijePronadjeno());
  for (var pokusaj = 0; pokusaj < _pokusaji; pokusaj++) {
    final trenutna = await prijave.prijava(id);
    if (trenutna == null) return const Neuspeh(NijePronadjeno());
    switch (await promena(trenutna)) {
      case Neuspeh(:final greska):
        return Neuspeh(greska);
      case Uspeh(:final vrednost):
        ishod = await prijave.sacuvaj(vrednost, iz: trenutna.stanje);
        if (ishod case Neuspeh(greska: NedozvoljenPrelaz(:final iz))
            when iz.runtimeType != trenutna.stanje.runtimeType) {
          continue;
        }
        return ishod;
    }
  }
  return ishod;
}

Rezultat<Ponuda> vidljivaPonuda(Korisnik ko, Prijava prijava, List<Ponuda> ponude) {
  final ponuda = ponude.where((p) => p.id == prijava.idPonude).firstOrNull;
  if (ponuda == null || !PravaPristupa.mozeDaVidi(ko, prijava, ponuda: ponuda)) return const Neuspeh(NijePronadjeno());
  return Uspeh(ponuda);
}

Future<bool> smeDaVidi(Korisnik ko, Prijava prijava, PonudaRepository ponude) async {
  if (ko.uloga == Uloga.student) return PravaPristupa.jeVlasnik(ko, prijava);
  final ponuda = (await ponude.ponude()).where((p) => p.id == prijava.idPonude).firstOrNull;
  return ponuda != null && PravaPristupa.mozeDaVidi(ko, prijava, ponuda: ponuda);
}
