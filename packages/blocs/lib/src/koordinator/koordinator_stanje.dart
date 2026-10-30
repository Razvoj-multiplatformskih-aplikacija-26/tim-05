part of 'koordinator_bloc.dart';

enum AkcijaKoordinatora { prihvati, listaCekanja, odbij }

enum FilterStanja {
  poslate,
  listaCekanja,
  prihvacene,
  potvrdjene,
  odbijene,
  povucene;

  bool odgovara(StanjePrijave stanje) => switch (this) {
    FilterStanja.poslate => stanje is Poslata,
    FilterStanja.listaCekanja => stanje is NaListiCekanja,
    FilterStanja.prihvacene => stanje is Prihvacena,
    FilterStanja.potvrdjene => stanje is Potvrdjena,
    FilterStanja.odbijene => stanje is Odbijena,
    FilterStanja.povucene => stanje is Povucena,
  };
}

final class FilteriPrijava extends Equatable {
  const FilteriPrijava({this.ponuda, this.stanje});

  final IdPonude? ponuda;
  final FilterStanja? stanje;

  bool odgovara(Prijava prijava) {
    final stanje = this.stanje;
    if (ponuda != null && prijava.idPonude != ponuda) return false;
    return stanje == null || stanje.odgovara(prijava.stanje);
  }

  FilteriPrijava copyWith({IdPonude? Function()? ponuda, FilterStanja? Function()? stanje}) => FilteriPrijava(
    ponuda: ponuda == null ? this.ponuda : ponuda(),
    stanje: stanje == null ? this.stanje : stanje(),
  );

  @override
  List<Object?> get props => [ponuda, stanje];
}

sealed class KoordinatorStanje extends Equatable {
  const KoordinatorStanje();

  @override
  List<Object?> get props => const [];

  @override
  String toString() => '$runtimeType';
}

final class KoordinatorUcitavanje extends KoordinatorStanje {
  const KoordinatorUcitavanje();
}

final class KoordinatorGreska extends KoordinatorStanje {
  const KoordinatorGreska(this.uzrok);

  final Object uzrok;

  @override
  List<Object?> get props => [uzrok];

  @override
  String toString() => 'KoordinatorGreska($uzrok)';
}

final class KoordinatorPrazno extends KoordinatorStanje {
  const KoordinatorPrazno({required this.podaci});

  final PregledKoordinatora podaci;

  @override
  List<Object?> get props => [podaci];
}

final class KoordinatorUcitano extends KoordinatorStanje {
  const KoordinatorUcitano({
    required this.podaci,
    this.akcije = const {},
    this.kursor = 0,
    this.izabrana,
    this.uToku,
    this.osvezava = false,
    this.filteri = const FilteriPrijava(),
    this.obavestenje,
  });

  final PregledKoordinatora podaci;

  final Map<IdPrijave, Set<AkcijaKoordinatora>> akcije;

  final int kursor;

  final IdPrijave? izabrana;

  final IdPrijave? uToku;

  final bool osvezava;

  final FilteriPrijava filteri;
  final KoordinatorObavestenje? obavestenje;

  List<Prijava> get prijave => [
    for (final prijava in podaci.prijave)
      if (filteri.odgovara(prijava)) prijava,
  ];

  bool prikazana(IdPrijave id) => prijave.any((p) => p.id == id);

  int broj(FilterStanja stanje) => podaci.prijave
      .where((p) => (filteri.ponuda == null || p.idPonude == filteri.ponuda) && stanje.odgovara(p.stanje))
      .length;

  Prijava? get izabranaPrijava => izabrana == null ? null : podaci.prijava(izabrana!);

  Prijava? get prijavaPodKursorom {
    final prikazane = prijave;
    return prikazane.isEmpty ? null : prikazane[ogranici(kursor)];
  }

  bool get akcijaTraje => uToku != null;

  bool get zauzet => akcijaTraje || osvezava;

  Set<AkcijaKoordinatora> akcijeZa(Prijava prijava) => akcije[prijava.id] ?? const {};

  bool dozvoljeno(AkcijaKoordinatora akcija) {
    final prijava = izabranaPrijava;
    return !zauzet && prijava != null && akcijeZa(prijava).contains(akcija);
  }

  int ogranici(int indeks) {
    final broj = prijave.length;
    return broj == 0 ? 0 : indeks.clamp(0, broj - 1);
  }

  KoordinatorUcitano copyWith({
    PregledKoordinatora? podaci,
    Map<IdPrijave, Set<AkcijaKoordinatora>>? akcije,
    int? kursor,
    IdPrijave? Function()? izabrana,
    IdPrijave? Function()? uToku,
    bool? osvezava,
    FilteriPrijava? filteri,
    KoordinatorObavestenje? Function()? obavestenje,
  }) => KoordinatorUcitano(
    podaci: podaci ?? this.podaci,
    akcije: akcije ?? this.akcije,
    kursor: kursor ?? this.kursor,
    izabrana: izabrana == null ? this.izabrana : izabrana(),
    uToku: uToku == null ? this.uToku : uToku(),
    osvezava: osvezava ?? this.osvezava,
    filteri: filteri ?? this.filteri,
    obavestenje: obavestenje == null ? this.obavestenje : obavestenje(),
  );

  @override
  List<Object?> get props => [podaci, akcije, kursor, izabrana, uToku, osvezava, filteri, obavestenje];

  @override
  String toString() => [
    'KoordinatorUcitano(${prijave.length} od ${podaci.prijave.length} prijava, kursor $kursor',
    if (izabrana case final id?) ', izabrana ${id.vrednost}',
    if (uToku case final id?) ', u toku ${id.vrednost}',
    if (osvezava) ', osvežava',
    if (filteri != const FilteriPrijava()) ', filter',
    if (obavestenje case final o?) ', ${o.runtimeType}',
    ')',
  ].join();
}

sealed class KoordinatorObavestenje extends Equatable {
  const KoordinatorObavestenje();

  @override
  List<Object?> get props => const [];
}

final class OdlukaSacuvana extends KoordinatorObavestenje {
  const OdlukaSacuvana(this.prijava);

  final Prijava prijava;

  @override
  List<Object?> get props => [prijava];
}

final class PodaciOsvezeni extends KoordinatorObavestenje {
  const PodaciOsvezeni();
}

final class OdlukaOdbijena extends KoordinatorObavestenje {
  const OdlukaOdbijena(this.greska);

  final GreskaDomena greska;

  @override
  List<Object?> get props => [greska];
}

final class OdlukaNeuspela extends KoordinatorObavestenje {
  const OdlukaNeuspela(this.uzrok);

  final Object uzrok;

  @override
  List<Object?> get props => [uzrok];
}