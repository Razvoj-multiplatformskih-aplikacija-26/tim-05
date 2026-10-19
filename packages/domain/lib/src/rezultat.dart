import 'package:meta/meta.dart';

import 'greske.dart';

sealed class Rezultat<T> {
  const Rezultat();

  T? get vrednostIliNull => switch (this) {
    Uspeh(:final vrednost) => vrednost,
    Neuspeh() => null,
  };

  GreskaDomena? get greskaIliNull => switch (this) {
    Uspeh() => null,
    Neuspeh(:final greska) => greska,
  };

  bool get jeUspeh => this is Uspeh<T>;
}

@immutable
final class Uspeh<T> extends Rezultat<T> {
  const Uspeh(this.vrednost);

  final T vrednost;

  @override
  bool operator ==(Object other) => other is Uspeh<T> && other.vrednost == vrednost;

  @override
  int get hashCode => Object.hash(Uspeh, vrednost);

  @override
  String toString() => 'Uspeh($vrednost)';
}

@immutable
final class Neuspeh<T> extends Rezultat<T> {
  const Neuspeh(this.greska);

  final GreskaDomena greska;

  @override
  bool operator ==(Object other) => other is Neuspeh<T> && other.greska == greska;

  @override
  int get hashCode => Object.hash(Neuspeh, greska);

  @override
  String toString() => 'Neuspeh($greska)';
}