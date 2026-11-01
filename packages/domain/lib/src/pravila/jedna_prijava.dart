import '../greske.dart';
import '../identifikatori.dart';
import '../korisnik.dart';
import '../prijava/motivaciono_pismo.dart';
import '../prijava/prijava.dart';
import '../rezultat.dart';


Prijava? nezavrsenaPrijava(IdKorisnika idStudenta, IdPonude idPonude, List<Prijava> svePrijave) => svePrijave
    .where((p) => p.idStudenta == idStudenta && p.idPonude == idPonude && !p.stanje.jeKonacno)
    .firstOrNull;

Rezultat<Prijava> napraviPrijavu({
  required IdPrijave id,
  required Korisnik ko,
  required IdPonude idPonude,
  required MotivacionoPismo motivacionoPismo,
  required List<Prijava> svePrijave,
  required DateTime sada,
  String? napomena,
}) {
  if (ko.uloga != Uloga.student) return const Neuspeh(NemaPravo());
  if (nezavrsenaPrijava(ko.id, idPonude, svePrijave) != null) return const Neuspeh(VecPostojiPrijava());
  return Uspeh(
    Prijava(
      id: id,
      idStudenta: ko.id,
      idPonude: idPonude,
      motivacionoPismo: motivacionoPismo,
      napomena: napomena,
      napravljena: sada,
    ),
  );
}
