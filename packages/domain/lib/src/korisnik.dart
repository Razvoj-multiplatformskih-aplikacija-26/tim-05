import 'package:meta/meta.dart';

import 'identifikatori.dart';

enum Uloga { student, koordinator }

@immutable
final class Korisnik {
  const Korisnik({required this.id, required this.korisnickoIme, required this.uloga, this.idUniverziteta});

  final IdKorisnika id;
  final String korisnickoIme;
  final Uloga uloga;

  final IdUniverziteta? idUniverziteta;

  bool get jeKoordinator => uloga == Uloga.koordinator;

  @override
  bool operator ==(Object other) =>
      other is Korisnik &&
      other.id == id &&
      other.korisnickoIme == korisnickoIme &&
      other.uloga == uloga &&
      other.idUniverziteta == idUniverziteta;

  @override
  int get hashCode => Object.hash(id, korisnickoIme, uloga, idUniverziteta);

  @override
  String toString() => 'Korisnik($korisnickoIme, ${uloga.name})';
}
