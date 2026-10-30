import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:domain/domain.dart' as domen;
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'koordinator_dogadjaj.dart';
part 'koordinator_stanje.dart';

final class KoordinatorBloc extends Bloc<KoordinatorDogadjaj, KoordinatorStanje> {
  KoordinatorBloc({
    required this.ucitajPregled,
    required this.prihvatiPrijavu,
    required this.staviNaListuCekanja,
    required this.odbijPrijavu,
    required this.korisnik,
  }) : super(const KoordinatorUcitavanje()) {
    on<PrijaveZatrazene>((dogadjaj, emit) async {
      emit(const KoordinatorUcitavanje());
      await _ucitaj(emit);
    });
    on<PrijaveOsvezene>((dogadjaj, emit) => _ucitaj(emit));
    on<PrijavaIzabrana>((dogadjaj, emit) {
      final trenutno = state;
      if (trenutno is! KoordinatorUcitano) return;
      final id = dogadjaj.id;
      if (id == null) {
        emit(trenutno.copyWith(izabrana: () => null));
        return;
      }
      final indeks = trenutno.prijave.indexWhere((p) => p.id == id);
      if (indeks < 0) return;
      emit(trenutno.copyWith(izabrana: () => id, kursor: indeks));
    });
    on<KursorPomeren>((dogadjaj, emit) {
      final trenutno = state;
      if (trenutno is KoordinatorUcitano) {
        emit(trenutno.copyWith(kursor: trenutno.ogranici(trenutno.kursor + dogadjaj.pomak)));
      }
    });
    on<KursorPostavljen>((dogadjaj, emit) {
      final trenutno = state;
      if (trenutno is KoordinatorUcitano) emit(trenutno.copyWith(kursor: trenutno.ogranici(dogadjaj.indeks)));
    });
    on<KursorAktiviran>((dogadjaj, emit) {
      final trenutno = state;
      final prijava = trenutno is KoordinatorUcitano ? trenutno.prijavaPodKursorom : null;
      if (trenutno is KoordinatorUcitano && prijava != null) emit(trenutno.copyWith(izabrana: () => prijava.id));
    });
    on<PrihvatanjeZatrazeno>(
      (dogadjaj, emit) => _izvrsi(emit, dogadjaj.id, () => prihvatiPrijavu(ko: korisnik, id: dogadjaj.id)),
    );
    on<ListaCekanjaZatrazena>(
      (dogadjaj, emit) => _izvrsi(emit, dogadjaj.id, () => staviNaListuCekanja(ko: korisnik, id: dogadjaj.id)),
    );
    on<OdbijanjeZatrazeno>(
      (dogadjaj, emit) =>
          _izvrsi(emit, dogadjaj.id, () => odbijPrijavu(ko: korisnik, id: dogadjaj.id, razlog: dogadjaj.razlog)),
    );
    on<ObavestenjeKoordinatoraProcitano>((dogadjaj, emit) {
      final trenutno = state;
      if (trenutno is KoordinatorUcitano && trenutno.obavestenje != null) {
        emit(trenutno.copyWith(obavestenje: () => null));
      }
    });
  }

  final UcitajPregledKoordinatora ucitajPregled;
  final PrihvatiPrijavu prihvatiPrijavu;
  final StaviNaListuCekanja staviNaListuCekanja;
  final OdbijPrijavu odbijPrijavu;

  final Korisnik korisnik;

  Future<void> _ucitaj(Emitter<KoordinatorStanje> emit, {KoordinatorObavestenje? obavestenje}) async {
    try {
      final podaci = await ucitajPregled(korisnik);
      final pre = state;
      if (podaci.jePrazno) {
        emit(KoordinatorPrazno(podaci: podaci));
        return;
      }
      final ucitano = KoordinatorUcitano(
        podaci: podaci,
        akcije: _akcijeZa(podaci),
        obavestenje: obavestenje,
        izabrana: pre is KoordinatorUcitano && pre.izabrana != null && podaci.prijava(pre.izabrana!) != null
            ? pre.izabrana
            : null,
      );
      emit(ucitano.copyWith(kursor: ucitano.ogranici(pre is KoordinatorUcitano ? pre.kursor : 0)));
    } on Exception catch (uzrok) {
      emit(KoordinatorGreska(uzrok));
    }
  }

  Future<void> _izvrsi(
    Emitter<KoordinatorStanje> emit,
    IdPrijave id,
    Future<Rezultat<Prijava>> Function() akcija,
  ) async {
    final trenutno = state;
    if (trenutno is! KoordinatorUcitano || trenutno.akcijaTraje) return;
    emit(trenutno.copyWith(uToku: () => id, obavestenje: () => null));
    try {
      switch (await akcija()) {
        case Uspeh(:final vrednost):
          await _ucitaj(emit, obavestenje: OdlukaSacuvana(vrednost));
        case Neuspeh(:final greska):
          _zavrsi(emit, OdlukaOdbijena(greska));
      }
    } on Exception catch (uzrok) {
      _zavrsi(emit, OdlukaNeuspela(uzrok));
    }
  }

  void _zavrsi(Emitter<KoordinatorStanje> emit, KoordinatorObavestenje obavestenje) {
    if (state case final KoordinatorUcitano trenutno) {
      emit(trenutno.copyWith(uToku: () => null, obavestenje: () => obavestenje));
    }
  }

  Map<IdPrijave, Set<AkcijaKoordinatora>> _akcijeZa(PregledKoordinatora podaci) => {
    for (final prijava in podaci.prijave)
      prijava.id: {
        if (domen
            .prihvatiPrijavu(
              prijava,
              ko: korisnik,
              ponuda: podaci.ponuda(prijava.idPonude),
              svePrijave: podaci.prijave,
              sada: podaci.sada,
            )
            .jeUspeh)
          AkcijaKoordinatora.prihvati,
        if (domen
            .staviNaListuCekanja(prijava, ko: korisnik, ponuda: podaci.ponuda(prijava.idPonude), sada: podaci.sada)
            .jeUspeh)
          AkcijaKoordinatora.listaCekanja,
        if (domen
            .odbijPrijavu(prijava, ko: korisnik, ponuda: podaci.ponuda(prijava.idPonude), razlog: '', sada: podaci.sada)
            .jeUspeh)
          AkcijaKoordinatora.odbij,
      },
  };
}
