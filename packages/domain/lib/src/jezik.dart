import 'package:meta/meta.dart';


enum Jezik { engleski, nemacki, francuski, italijanski, spanski, portugalski, svedski }

enum NivoJezika {
  a1,
  a2,
  b1,
  b2,
  c1,
  c2;

  String get oznaka => name.toUpperCase();


  bool jeNajmanje(NivoJezika trazeni) => index >= trazeni.index;
}

@immutable
final class ZahtevJezika {
  const ZahtevJezika({required this.jezik, required this.nivo});

  final Jezik jezik;
  final NivoJezika nivo;

  @override
  bool operator ==(Object other) => other is ZahtevJezika && other.jezik == jezik && other.nivo == nivo;

  @override
  int get hashCode => Object.hash(jezik, nivo);

  @override
  String toString() => 'ZahtevJezika(${jezik.name} ${nivo.oznaka})';
}