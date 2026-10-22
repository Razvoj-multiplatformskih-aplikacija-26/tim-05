import 'package:meta/meta.dart';

import '../identifikatori.dart';
import '../jezik.dart';
import 'semestar.dart';

@immutable
final class Ponuda {
  const Ponuda({
    required this.id,
    required this.idUniverziteta,
    required this.oblast,
    required this.semestar,
    required this.brojMesta,
    required this.rok,
    required this.minimalniProsek,
    required this.zahtevJezika,
    required this.opis,
    required this.objavio,
    required this.objavljena,
    this.napomena,
  });

  final IdPonude id;
  final IdUniverziteta idUniverziteta;

  final String oblast;
  final Semestar semestar;

  final int brojMesta;

  final DateTime rok;

  final double minimalniProsek;

  final ZahtevJezika zahtevJezika;

  final String opis;

  final String? napomena;

  final IdKorisnika objavio;
  final DateTime objavljena;

  @override
  bool operator ==(Object other) => other is Ponuda && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Ponuda($id, ${semestar.vrsta.name} ${semestar.akademskaGodina})';
}
