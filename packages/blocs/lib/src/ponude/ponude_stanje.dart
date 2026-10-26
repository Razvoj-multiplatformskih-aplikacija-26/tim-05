part of 'ponude_bloc.dart';

sealed class PonudeStanje extends Equatable {
  const PonudeStanje();

  @override
  List<Object?> get props => const [];

  @override
  String toString() => '$runtimeType';
}

final class PonudeUcitavanje extends PonudeStanje {
  const PonudeUcitavanje();
}

final class PonudeGreska extends PonudeStanje {
  const PonudeGreska(this.uzrok);

  final Object uzrok;

  @override
  List<Object?> get props => [uzrok];

  @override
  String toString() => 'PonudeGreska($uzrok)';
}

final class PonudePrazne extends PonudeStanje {
  const PonudePrazne();
}

final class PonudeUcitane extends PonudeStanje {
  const PonudeUcitane({required this.podaci, this.filteri = const PonudeFilteri(), this.obavestenje});

  final PregledPodataka podaci;
  final PonudeFilteri filteri;
  final PonudeObavestenje? obavestenje;

  List<Ponuda> get filtrirane => [
    for (final ponuda in podaci.ponude)
      if (filteri.odgovara(ponuda, podaci.univerzitet(ponuda.idUniverziteta))) ponuda,
  ]..sort((a, b) => b.objavljena.compareTo(a.objavljena));

  List<String> get drzave => {for (final u in podaci.univerziteti) u.drzava}.toList()..sort();

  List<String> get oblasti => {for (final p in podaci.ponude) p.oblast}.toList()..sort();

  List<Jezik> get jezici => {for (final p in podaci.ponude) p.zahtevJezika.jezik}.toList();

  PonudeUcitane copyWith({PonudeFilteri? filteri, PonudeObavestenje? Function()? obavestenje}) => PonudeUcitane(
    podaci: podaci,
    filteri: filteri ?? this.filteri,
    obavestenje: obavestenje == null ? this.obavestenje : obavestenje(),
  );

  @override
  List<Object?> get props => [podaci, filteri, obavestenje];

  @override
  String toString() => 'PonudeUcitane(${podaci.ponude.length} ponuda, ${filtrirane.length} prikazano)';
}

final class PonudeFilteri extends Equatable {
  const PonudeFilteri({this.upit = '', this.drzava, this.semestar, this.oblast, this.jezik});

  final String upit;
  final String? drzava;
  final VrstaSemestra? semestar;
  final String? oblast;
  final Jezik? jezik;

  PonudeFilteri copyWith({
    String? upit,
    String? Function()? drzava,
    VrstaSemestra? Function()? semestar,
    String? Function()? oblast,
    Jezik? Function()? jezik,
  }) => PonudeFilteri(
    upit: upit ?? this.upit,
    drzava: drzava == null ? this.drzava : drzava(),
    semestar: semestar == null ? this.semestar : semestar(),
    oblast: oblast == null ? this.oblast : oblast(),
    jezik: jezik == null ? this.jezik : jezik(),
  );

  bool odgovara(Ponuda ponuda, Univerzitet univerzitet) {
    if (drzava != null && univerzitet.drzava != drzava) return false;
    if (semestar != null && ponuda.semestar.vrsta != semestar) return false;
    if (oblast != null && ponuda.oblast != oblast) return false;
    if (jezik != null && ponuda.zahtevJezika.jezik != jezik) return false;
    final trazeno = upit.trim().toLowerCase();
    if (trazeno.isEmpty) return true;
    return '${univerzitet.naziv} ${univerzitet.grad} ${univerzitet.drzava} ${ponuda.oblast}'.toLowerCase().contains(
      trazeno,
    );
  }

  @override
  List<Object?> get props => [upit, drzava, semestar, oblast, jezik];
}

sealed class PonudeObavestenje extends Equatable {
  const PonudeObavestenje();

  @override
  List<Object?> get props => const [];
}

final class CuvanjePonudeNeuspelo extends PonudeObavestenje {
  const CuvanjePonudeNeuspelo(this.uzrok);

  final Object uzrok;

  @override
  List<Object?> get props => [uzrok];
}
