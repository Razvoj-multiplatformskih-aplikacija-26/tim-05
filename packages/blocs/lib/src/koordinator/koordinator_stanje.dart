part of 'koordinator_bloc.dart';

enum AkcijaKoordinatora { prihvati, listaCekanja, odbij }

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
    this.obavestenje,
  });

  final PregledKoordinatora podaci;

  final Map<IdPrijave, Set<AkcijaKoordinatora>> akcije;

  final int kursor;

  final IdPrijave? izabrana;

  final IdPrijave? uToku;
  final KoordinatorObavestenje? obavestenje;

  List<Prijava> get prijave => podaci.prijave;

  Prijava? get izabranaPrijava => izabrana == null ? null : podaci.prijava(izabrana!);

  Prijava? get prijavaPodKursorom => prijave.isEmpty ? null : prijave[kursor];

  bool get akcijaTraje => uToku != null;

  Set<AkcijaKoordinatora> akcijeZa(Prijava prijava) => akcije[prijava.id] ?? const {};

  bool dozvoljeno(AkcijaKoordinatora akcija) {
    final prijava = izabranaPrijava;
    return !akcijaTraje && prijava != null && akcijeZa(prijava).contains(akcija);
  }

  int ogranici(int indeks) => prijave.isEmpty ? 0 : indeks.clamp(0, prijave.length - 1);

  KoordinatorUcitano copyWith({
    PregledKoordinatora? podaci,
    Map<IdPrijave, Set<AkcijaKoordinatora>>? akcije,
    int? kursor,
    IdPrijave? Function()? izabrana,
    IdPrijave? Function()? uToku,
    KoordinatorObavestenje? Function()? obavestenje,
  }) => KoordinatorUcitano(
    podaci: podaci ?? this.podaci,
    akcije: akcije ?? this.akcije,
    kursor: kursor ?? this.kursor,
    izabrana: izabrana == null ? this.izabrana : izabrana(),
    uToku: uToku == null ? this.uToku : uToku(),
    obavestenje: obavestenje == null ? this.obavestenje : obavestenje(),
  );

  @override
  List<Object?> get props => [podaci, akcije, kursor, izabrana, uToku, obavestenje];

  @override
  String toString() => [
    'KoordinatorUcitano(${prijave.length} prijava, kursor $kursor',
    if (izabrana case final id?) ', izabrana ${id.vrednost}',
    if (uToku case final id?) ', u toku ${id.vrednost}',
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