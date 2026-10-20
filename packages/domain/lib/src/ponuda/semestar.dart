import 'package:meta/meta.dart';

enum VrstaSemestra { zimski, letnji }

@immutable
final class Semestar {
  const Semestar({required this.vrsta, required this.akademskaGodina});

  final VrstaSemestra vrsta;

  final String akademskaGodina;

  @override
  bool operator ==(Object other) =>
      other is Semestar && other.vrsta == vrsta && other.akademskaGodina == akademskaGodina;

  @override
  int get hashCode => Object.hash(vrsta, akademskaGodina);

  @override
  String toString() => 'Semestar(${vrsta.name} $akademskaGodina)';
}