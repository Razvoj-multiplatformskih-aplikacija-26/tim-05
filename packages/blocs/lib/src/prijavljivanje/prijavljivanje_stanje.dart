part of 'prijavljivanje_bloc.dart';

sealed class PrijavljivanjeStanje extends Equatable {
  const PrijavljivanjeStanje();

  @override
  List<Object?> get props => const [];

  @override
  String toString() => '$runtimeType';
}

final class PrijavljivanjeSpremno extends PrijavljivanjeStanje {
  const PrijavljivanjeSpremno();
}

final class PrijavljivanjeUToku extends PrijavljivanjeStanje {
  const PrijavljivanjeUToku();
}

final class PrijavljivanjeUspelo extends PrijavljivanjeStanje {
  const PrijavljivanjeUspelo(this.korisnik);

  final Korisnik korisnik;

  @override
  List<Object?> get props => [korisnik];
}

final class PrijavljivanjeOdbijeno extends PrijavljivanjeStanje {
  const PrijavljivanjeOdbijeno();
}

final class PrijavljivanjeNeuspelo extends PrijavljivanjeStanje {
  const PrijavljivanjeNeuspelo(this.uzrok);

  final Object uzrok;

  @override
  List<Object?> get props => [uzrok];
}
