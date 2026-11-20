part of 'sesija_bloc.dart';

enum RazlogOdjave { odjava, istekla, nedostupan, pogresnaAplikacija }

sealed class SesijaStanje extends Equatable {
  const SesijaStanje();

  @override
  List<Object?> get props => const [];

  @override
  String toString() => '$runtimeType';
}

final class SesijaNepoznata extends SesijaStanje {
  const SesijaNepoznata();
}

final class Odjavljen extends SesijaStanje {
  const Odjavljen({this.razlog});

  final RazlogOdjave? razlog;

  @override
  List<Object?> get props => [razlog];

  @override
  String toString() => 'Odjavljen(${razlog?.name})';
}

final class Prijavljen extends SesijaStanje {
  const Prijavljen(this.korisnik);

  final Korisnik korisnik;

  @override
  List<Object?> get props => [korisnik];

  @override
  String toString() => 'Prijavljen($korisnik)';
}
