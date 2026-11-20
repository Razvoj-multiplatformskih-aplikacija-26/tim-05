import 'package:domain/domain.dart';

import 'ports/sesija_repository.dart';

final class PrijaviSe {
  const PrijaviSe({required this.sesije});

  final SesijaRepository sesije;

  Future<Korisnik?> call({required String korisnickoIme, required String lozinka}) =>
      sesije.prijavi(korisnickoIme: korisnickoIme.trim(), lozinka: lozinka);
}

final class ObnoviSesiju {
  const ObnoviSesiju({required this.sesije});

  final SesijaRepository sesije;

  Future<Korisnik?> call() => sesije.trenutni();
}

final class OdjaviSe {
  const OdjaviSe({required this.sesije});

  final SesijaRepository sesije;

  Future<void> call() => sesije.odjavi();
}