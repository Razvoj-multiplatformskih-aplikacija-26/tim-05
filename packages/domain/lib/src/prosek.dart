import 'greske.dart';
import 'rezultat.dart';

abstract final class Prosek {
  static const najmanje = 6.0;
  static const najvise = 10.0;

  
  static Rezultat<double> proveri(String unos) {
    final broj = double.tryParse(unos.trim().replaceAll(',', '.'));
    if (broj == null) return const Neuspeh(ProsekNijeBroj());
    if (broj < najmanje || broj > najvise) return const Neuspeh(ProsekVanOpsega());
    return Uspeh(broj);
  }
}