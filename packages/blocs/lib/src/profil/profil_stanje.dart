part of 'profil_bloc.dart';

enum PrikazProfila { prijave, sacuvano }

sealed class ProfilStanje extends Equatable {
  const ProfilStanje();

  @override
  List<Object?> get props => const [];

  @override
  String toString() => '$runtimeType';
}

final class ProfilUcitavanje extends ProfilStanje {
  const ProfilUcitavanje();
}

final class ProfilGreska extends ProfilStanje {
  const ProfilGreska(this.uzrok);

  final Object uzrok;

  @override
  List<Object?> get props => [uzrok];

  @override
  String toString() => 'ProfilGreska($uzrok)';
}

sealed class ProfilSaPodacima extends ProfilStanje {
  const ProfilSaPodacima({
    required this.podaci,
    this.prikaz = PrikazProfila.prijave,
    this.uToku,
    this.cuvaSeProfil = false,
    this.obavestenje,
  });

  final PregledPodataka podaci;
  final PrikazProfila prikaz;

  final IdPrijave? uToku;

  final bool cuvaSeProfil;
  final ProfilObavestenje? obavestenje;

  bool get akcijaTraje => uToku != null || cuvaSeProfil;

  ProfilSaPodacima copyWith({
    PrikazProfila? prikaz,
    IdPrijave? Function()? uToku,
    bool? cuvaSeProfil,
    ProfilObavestenje? Function()? obavestenje,
  }) {
    final novPrikaz = prikaz ?? this.prikaz;
    final novoUToku = uToku == null ? this.uToku : uToku();
    final novoCuvanje = cuvaSeProfil ?? this.cuvaSeProfil;
    final novoObavestenje = obavestenje == null ? this.obavestenje : obavestenje();
    return switch (this) {
      ProfilPrazan() => ProfilPrazan(
        podaci: podaci,
        prikaz: novPrikaz,
        uToku: novoUToku,
        cuvaSeProfil: novoCuvanje,
        obavestenje: novoObavestenje,
      ),
      ProfilUcitan() => ProfilUcitan(
        podaci: podaci,
        prikaz: novPrikaz,
        uToku: novoUToku,
        cuvaSeProfil: novoCuvanje,
        obavestenje: novoObavestenje,
      ),
    };
  }

  @override
  List<Object?> get props => [podaci, prikaz, uToku, cuvaSeProfil, obavestenje];

  @override
  String toString() => [
    '$runtimeType(${podaci.mojePrijave.length} prijava, ${prikaz.name}',
    if (uToku case final id?) ', u toku ${id.vrednost}',
    if (cuvaSeProfil) ', čuva se profil',
    if (obavestenje case final o?) ', ${o.runtimeType}',
    ')',
  ].join();
}

final class ProfilPrazan extends ProfilSaPodacima {
  const ProfilPrazan({required super.podaci, super.prikaz, super.uToku, super.cuvaSeProfil, super.obavestenje});
}

final class ProfilUcitan extends ProfilSaPodacima {
  const ProfilUcitan({required super.podaci, super.prikaz, super.uToku, super.cuvaSeProfil, super.obavestenje});
}

sealed class ProfilObavestenje extends Equatable {
  const ProfilObavestenje();

  @override
  List<Object?> get props => const [];
}

final class PrijavaPovucena extends ProfilObavestenje {
  const PrijavaPovucena();
}

final class MestoPotvrdjeno extends ProfilObavestenje {
  const MestoPotvrdjeno({required this.brojPovucenih});

  final int brojPovucenih;

  @override
  List<Object?> get props => [brojPovucenih];
}

final class MestoOdbijeno extends ProfilObavestenje {
  const MestoOdbijeno();
}

final class PrijavaObrisana extends ProfilObavestenje {
  const PrijavaObrisana();
}

final class ProfilSacuvan extends ProfilObavestenje {
  const ProfilSacuvan();
}

final class AkcijaOdbijena extends ProfilObavestenje {
  const AkcijaOdbijena(this.greska);

  final GreskaDomena greska;

  @override
  List<Object?> get props => [greska];
}

final class AkcijaNeuspela extends ProfilObavestenje {
  const AkcijaNeuspela(this.uzrok);

  final Object uzrok;

  @override
  List<Object?> get props => [uzrok];
}
