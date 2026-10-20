import 'package:meta/meta.dart';

import '../identifikatori.dart';
import 'motivaciono_pismo.dart';
import 'stanje_prijave.dart';

@immutable
final class Prijava {
  const Prijava({
    required this.id,
    required this.idStudenta,
    required this.idPonude,
    required this.motivacionoPismo,
    required this.napravljena,
    this.napomena,
    this.stanje = const UPripremi(),
  });

  final IdPrijave id;

  final IdKorisnika idStudenta;

  final IdPonude idPonude;

  final MotivacionoPismo motivacionoPismo;

  final String? napomena;

  final StanjePrijave stanje;
  final DateTime napravljena;

  bool get jeAktivna => stanje.jeAktivna;

  Prijava copyWith({StanjePrijave? stanje, MotivacionoPismo? motivacionoPismo, String? napomena}) {
    return Prijava(
      id: id,
      idStudenta: idStudenta,
      idPonude: idPonude,
      motivacionoPismo: motivacionoPismo ?? this.motivacionoPismo,
      napomena: napomena ?? this.napomena,
      stanje: stanje ?? this.stanje,
      napravljena: napravljena,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Prijava &&
      other.id == id &&
      other.idStudenta == idStudenta &&
      other.idPonude == idPonude &&
      other.motivacionoPismo == motivacionoPismo &&
      other.napomena == napomena &&
      other.stanje == stanje &&
      other.napravljena == napravljena;

  @override
  int get hashCode => Object.hash(id, idStudenta, idPonude, motivacionoPismo, napomena, stanje, napravljena);

  @override
  String toString() => 'Prijava($id, $idPonude, $stanje)';
}