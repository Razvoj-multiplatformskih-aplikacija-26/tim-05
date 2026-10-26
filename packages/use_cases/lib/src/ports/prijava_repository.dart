import 'package:domain/domain.dart';

abstract interface class PrijavaRepository {
  Future<List<Prijava>> svePrijave();

  Future<void> sacuvaj(List<Prijava> prijave);

  Future<void> obrisi(IdPrijave id);
}
