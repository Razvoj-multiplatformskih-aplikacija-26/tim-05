import 'package:meta/meta.dart';
import 'jezik.dart';

sealed class GreskaDomena {
  const GreskaDomena();
}



final class PismoPrazno extends GreskaDomena {
  const PismoPrazno();
}

@immutable
final class PismoPredugacko extends GreskaDomena {
  const PismoPredugacko(this.duzina);

  final int duzina;

  @override
  bool operator ==(Object other) => other is PismoPredugacko && other.duzina == duzina;

  @override
  int get hashCode => Object.hash(PismoPredugacko, duzina);

  @override
  String toString() => 'PismoPredugacko($duzina)';
}


@immutable
final class RokIstekao extends GreskaDomena {
  const RokIstekao(this.rok);

  final DateTime rok;

  @override
  bool operator ==(Object other) => other is RokIstekao && other.rok == rok;

  @override
  int get hashCode => Object.hash(RokIstekao, rok);

  @override
  String toString() => 'RokIstekao($rok)';
}

@immutable
final class NedovoljanProsek extends GreskaDomena {
  const NedovoljanProsek({required this.trazeni, required this.studentov});

  final double trazeni;
  final double studentov;

  @override
  bool operator ==(Object other) =>
      other is NedovoljanProsek && other.trazeni == trazeni && other.studentov == studentov;

  @override
  int get hashCode => Object.hash(NedovoljanProsek, trazeni, studentov);

  @override
  String toString() => 'NedovoljanProsek(trazeni: $trazeni, studentov: $studentov)';
}

@immutable
final class NedovoljanJezik extends GreskaDomena {
  const NedovoljanJezik({required this.trazeni, this.studentov});

  final ZahtevJezika trazeni;

  final NivoJezika? studentov;

  @override
  bool operator ==(Object other) =>
      other is NedovoljanJezik && other.trazeni == trazeni && other.studentov == studentov;

  @override
  int get hashCode => Object.hash(NedovoljanJezik, trazeni, studentov);

  @override
  String toString() => 'NedovoljanJezik(trazeni: $trazeni, studentov: ${studentov?.oznaka})';
}

@immutable
final class PrevisePrijava extends GreskaDomena {
  const PrevisePrijava(this.najvise);

  final int najvise;

  @override
  bool operator ==(Object other) => other is PrevisePrijava && other.najvise == najvise;

  @override
  int get hashCode => Object.hash(PrevisePrijava, najvise);

  @override
  String toString() => 'PrevisePrijava($najvise)';
}


final class NemaSlobodnihMesta extends GreskaDomena {
  const NemaSlobodnihMesta();
}


final class NemaPravo extends GreskaDomena {
  const NemaPravo();
}

final class NijePronadjeno extends GreskaDomena {
  const NijePronadjeno();
}