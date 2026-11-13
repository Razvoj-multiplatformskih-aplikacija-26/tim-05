import 'package:domain/domain.dart';

abstract interface class PrijavaRepository {
  Future<Prijava?> prijava(IdPrijave id);

  Future<List<Prijava>> prijaveStudenta(IdKorisnika idStudenta);

  Future<List<Prijava>> prijaveNaPonudeUniverziteta(IdUniverziteta idUniverziteta);

  Future<Rezultat<Prijava>> napravi(Prijava nova);

  Future<Rezultat<Prijava>> sacuvaj(Prijava nova, {required StanjePrijave iz});

  Future<Rezultat<List<Prijava>>> potvrdiMesto(Prijava potvrdjena, {required List<Prijava> povucene});

  Future<void> obrisi(IdPrijave id);
}
