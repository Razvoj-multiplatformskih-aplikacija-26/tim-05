import 'dart:async';

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
    this._korisnik,
  }) : super(const ProfilUcitavanje()) {
    on<ProfilZatrazen>((dogadjaj, emit) => _ucitajIspocetka(emit));
    on<ProfilKorisnikPromenjen>((dogadjaj, emit) {
      _korisnik = dogadjaj.korisnik;
      return _ucitajIspocetka(emit);
    });
    on<ProfilOsvezen>((dogadjaj, emit) async {
      try {
        await _ucitaj(emit);
      } finally {
        dogadjaj.gotovo?.complete();
      }
    });
    on<PovlacenjeZatrazeno>(
      (dogadjaj, emit) => _izvrsi<Prijava>(
        emit,
        id: dogadjaj.id,
        akcija: (ko) => povuciPrijavu(ko: ko, id: dogadjaj.id),
        uspeh: (_) => const PrijavaPovucena(),
      ),
    );
    on<PotvrdaMestaZatrazena>(
      (dogadjaj, emit) => _izvrsi<List<Prijava>>(
        emit,
        id: dogadjaj.id,
        akcija: (ko) => potvrdiMesto(ko: ko, id: dogadjaj.id),
        uspeh: (izmenjene) => MestoPotvrdjeno(brojPovucenih: izmenjene.length - 1),
      ),
    );
    on<OdbijanjeMestaZatrazeno>(
      (dogadjaj, emit) => _izvrsi<Prijava>(
        emit,
        id: dogadjaj.id,
        akcija: (ko) => odbijMesto(ko: ko, id: dogadjaj.id),
        uspeh: (_) => const MestoOdbijeno(),
      ),
    );
    on<BrisanjeZatrazeno>(
      (dogadjaj, emit) => _izvrsi<Prijava>(
        emit,
        id: dogadjaj.id,
        akcija: (ko) => obrisiPrijavu(ko: ko, id: dogadjaj.id),
        uspeh: (_) => const PrijavaObrisana(),
      ),
    );
    on<ProfilIzmenjen>(
      (dogadjaj, emit) => _izvrsi<Student>(
        emit,
        akcija: (ko) => sacuvajProfil(ko: ko, student: dogadjaj.student),
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

  Korisnik? _korisnik;

  Korisnik? get korisnik => _korisnik;

  Future<void> _ucitajIspocetka(Emitter<ProfilStanje> emit) async {
    if (_korisnik == null) return emit(const ProfilBezPrijave());
    emit(const ProfilUcitavanje());
    await _ucitaj(emit);
  }

  Future<void> _ucitaj(Emitter<ProfilStanje> emit, {ProfilObavestenje? obavestenje}) async {
    final ko = _korisnik;
    if (ko == null) return emit(const ProfilBezPrijave());
    try {
      final podaci = await ucitajPregled(ko);
      if (ko != _korisnik) return;

      final prikaz = switch (state) {
        ProfilSaPodacima(:final prikaz) => prikaz,
        ProfilUcitavanje() || ProfilGreska() || ProfilBezPrijave() => PrikazProfila.prijave,
      };
      emit(
        podaci.mojePrijave.isEmpty
            ? ProfilPrazan(podaci: podaci, prikaz: prikaz, obavestenje: obavestenje)
            : ProfilUcitan(podaci: podaci, prikaz: prikaz, obavestenje: obavestenje),
      );
    } on Exception catch (uzrok) {
      if (ko == _korisnik) emit(ProfilGreska(uzrok));
    }
  }


  Future<void> _izvrsi<T>(
    Emitter<ProfilStanje> emit, {
    IdPrijave? id,
    required Future<Rezultat<T>> Function(Korisnik ko) akcija,
    required ProfilObavestenje Function(T vrednost) uspeh,
  }) async {
    final trenutno = state;
    final ko = _korisnik;
    if (trenutno is! ProfilSaPodacima || trenutno.akcijaTraje || ko == null) return;
    emit(trenutno.copyWith(uToku: () => id, cuvaSeProfil: id == null));
    try {
      switch (await akcija(ko)) {
        case Uspeh(:final vrednost):
          await _ucitaj(emit, obavestenje: uspeh(vrednost));
        case Neuspeh(:final greska):
          await _ucitaj(emit, obavestenje: AkcijaOdbijena(greska));
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
