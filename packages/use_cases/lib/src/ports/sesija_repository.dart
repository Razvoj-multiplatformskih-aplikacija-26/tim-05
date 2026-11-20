import 'package:domain/domain.dart';

abstract interface class SesijaRepository {
  Future<Korisnik?> prijavi({required String korisnickoIme, required String lozinka});

  Future<Korisnik?> trenutni();

  Future<void> odjavi();

  Stream<void> get istekle;
}