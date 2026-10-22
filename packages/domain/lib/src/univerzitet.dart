import 'package:meta/meta.dart';

import 'identifikatori.dart';

@immutable
final class Univerzitet {
  const Univerzitet({
    required this.id,
    required this.naziv,
    required this.grad,
    required this.drzava,
    required this.oznakaDrzave,
  });

  final IdUniverziteta id;
  final String naziv;
  final String grad;
  final String drzava;

  final String oznakaDrzave;

  @override
  bool operator ==(Object other) => other is Univerzitet && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Univerzitet($naziv, $grad)';
}
