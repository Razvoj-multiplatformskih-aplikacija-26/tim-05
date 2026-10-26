import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'profil_dogadjaj.dart';
part 'profil_stanje.dart';

final class ProfilBloc extends Bloc<ProfilDogadjaj, ProfilStanje> {
  ProfilBloc({
    required this.ucitajPregled,
    required this.povuciPrijavu,
    required this.potvrdiMesto,
    required this.odbijMesto,
    required this.obrisiPrijavu,
    required this.sacuvajProfil,
    required this.korisnik,
  }) : super(const ProfilUcitavanje()) {
    on<ProfilZatrazen>((dogadjaj, emit) async {
      emit(const ProfilUcitavanje());
      await _ucitaj(emit);
    });
    on<ProfilOsvezen>((dogadjaj, emit) => _ucitaj(emit));
    on<PovlacenjeZatrazeno>(
      (dogadjaj, emit) => _izvrsi<Prijava>(
        emit,
        id: dogadjaj.id,
        akcija: () => povuciPrijavu(ko: korisnik, id: dogadjaj.id),
        uspeh: (_) => const PrijavaPovucena(),
      ),
    );
    on<PotvrdaMestaZatrazena>(
      (dogadjaj, emit) => _izvrsi<List<Prijava>>(
        emit,
        id: dogadjaj.id,
        akcija: () => potvrdiMesto(ko: korisnik, id: dogadjaj.id),
        uspeh: (izmenjene) => MestoPotvrdjeno(brojPovucenih: izmenjene.length - 1),
      ),
    );
    on<OdbijanjeMestaZatrazeno>(
      (dogadjaj, emit) => _izvrsi<Prijava>(
        emit,
        id: dogadjaj.id,
        akcija: () => odbijMesto(ko: korisnik, id: dogadjaj.id),
        uspeh: (_) => const MestoOdbijeno(),
      ),
    );
    on<BrisanjeZatrazeno>(
      (dogadjaj, emit) => _izvrsi<Prijava>(
        emit,
        id: dogadjaj.id,
        akcija: () => obrisiPrijavu(ko: korisnik, id: dogadjaj.id),
        uspeh: (_) => const PrijavaObrisana(),
      ),
    );
    on<ProfilIzmenjen>(
      (dogadjaj, emit) => _izvrsi<Student>(
        emit,
        akcija: () => sacuvajProfil(ko: korisnik, student: dogadjaj.student),
        uspeh: (_) => const ProfilSacuvan(),
      ),
    );
    on<PrikazProfilaPromenjen>((dogadjaj, emit) {
      if (state case final ProfilSaPodacima trenutno) emit(trenutno.copyWith(prikaz: dogadjaj.prikaz));
    });
    on<ObavestenjeProfilaProcitano>((dogadjaj, emit) {
      if (state case final ProfilSaPodacima trenutno when trenutno.obavestenje != null) {
        emit(trenutno.copyWith(obavestenje: () => null));
      }
    });
  }

  final UcitajPregled ucitajPregled;
  final PovuciPrijavu povuciPrijavu;
  final PotvrdiMesto potvrdiMesto;
  final OdbijMesto odbijMesto;
  final ObrisiPrijavu obrisiPrijavu;
  final SacuvajProfil sacuvajProfil;
  final Korisnik korisnik;

  Future<void> _ucitaj(Emitter<ProfilStanje> emit, {ProfilObavestenje? obavestenje}) async {
    try {
      final podaci = await ucitajPregled(korisnik);

      final prikaz = switch (state) {
        ProfilSaPodacima(:final prikaz) => prikaz,
        ProfilUcitavanje() || ProfilGreska() => PrikazProfila.prijave,
      };
      emit(
        podaci.mojePrijave.isEmpty
            ? ProfilPrazan(podaci: podaci, prikaz: prikaz, obavestenje: obavestenje)
            : ProfilUcitan(podaci: podaci, prikaz: prikaz, obavestenje: obavestenje),
      );
    } on Exception catch (uzrok) {
      emit(ProfilGreska(uzrok));
    }
  }

  Future<void> _izvrsi<T>(
    Emitter<ProfilStanje> emit, {
    IdPrijave? id,
    required Future<Rezultat<T>> Function() akcija,
    required ProfilObavestenje Function(T vrednost) uspeh,
  }) async {
    final trenutno = state;
    if (trenutno is! ProfilSaPodacima || trenutno.akcijaTraje) return;
    emit(trenutno.copyWith(uToku: () => id, cuvaSeProfil: id == null));
    try {
      switch (await akcija()) {
        case Uspeh(:final vrednost):
          await _ucitaj(emit, obavestenje: uspeh(vrednost));
        case Neuspeh(:final greska):
          _zavrsi(emit, AkcijaOdbijena(greska));
      }
    } on Exception catch (uzrok) {
      _zavrsi(emit, AkcijaNeuspela(uzrok));
    }
  }

  void _zavrsi(Emitter<ProfilStanje> emit, ProfilObavestenje obavestenje) {
    if (state case final ProfilSaPodacima trenutno) {
      emit(trenutno.copyWith(uToku: () => null, cuvaSeProfil: false, obavestenje: () => obavestenje));
    }
  }
}
