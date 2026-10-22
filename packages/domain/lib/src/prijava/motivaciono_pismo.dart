import 'package:characters/characters.dart';
import 'package:meta/meta.dart';

import '../greske.dart';
import '../rezultat.dart';

@immutable
final class MotivacionoPismo {
  const MotivacionoPismo._(this.tekst);

  static const najvise = 1500;

  final String tekst;

  int get duzina => tekst.characters.length;

  static Rezultat<MotivacionoPismo> proveri(String unos) {
    final tekst = unos.trim();
    if (tekst.isEmpty) return const Neuspeh(PismoPrazno());
    final duzina = tekst.characters.length;
    if (duzina > najvise) return Neuspeh(PismoPredugacko(duzina));
    return Uspeh(MotivacionoPismo._(tekst));
  }

  @override
  bool operator ==(Object other) => other is MotivacionoPismo && other.tekst == tekst;

  @override
  int get hashCode => tekst.hashCode;

  @override
  String toString() => 'MotivacionoPismo($duzina znakova)';
}
