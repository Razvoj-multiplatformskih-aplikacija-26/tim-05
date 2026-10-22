import '../identifikatori.dart';
import '../ponuda/ponuda.dart';
import '../prijava/prijava.dart';
import '../prijava/stanje_prijave.dart';

int preostalaMesta(Ponuda ponuda, List<Prijava> svePrijave) {
  final zauzeto = svePrijave
      .where((p) => p.idPonude == ponuda.id && (p.stanje is Prihvacena || p.stanje is Potvrdjena))
      .length;
  final preostalo = ponuda.brojMesta - zauzeto;
  return preostalo > 0 ? preostalo : 0;
}

List<Prijava> aktivnePrijave(IdKorisnika idStudenta, List<Prijava> svePrijave) => [
  for (final prijava in svePrijave)
    if (prijava.idStudenta == idStudenta && prijava.jeAktivna) prijava,
];
