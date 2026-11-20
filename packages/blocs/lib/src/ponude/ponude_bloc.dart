import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'ponude_dogadjaj.dart';
part 'ponude_stanje.dart';

final class PonudeBloc extends Bloc<PonudeDogadjaj, PonudeStanje> {
  PonudeBloc({required this.ucitajPregled, required this.promeniSacuvanu, this._korisnik})
    : super(const PonudeUcitavanje()) {
    on<PonudeZatrazene>((dogadjaj, emit) async {
      final filteri = _trenutniFilteri();
      emit(const PonudeUcitavanje());
      await _ucitaj(emit, zapamceni: filteri);
    });
    on<PonudeKorisnikPromenjen>((dogadjaj, emit) async {
      _korisnik = dogadjaj.korisnik;
      final filteri = _trenutniFilteri();
      emit(const PonudeUcitavanje());
      await _ucitaj(emit, zapamceni: filteri);
    });
    on<PonudeOsvezene>((dogadjaj, emit) async {
      try {
        await _ucitaj(emit);
      } finally {
        dogadjaj.gotovo?.complete();
      }
    });
    on<FilteriPromenjeni>((dogadjaj, emit) {
      final trenutno = state;
      if (trenutno is PonudeUcitane) emit(trenutno.copyWith(filteri: dogadjaj.filteri));
    });
    on<SacuvanaPromenjena>(_onSacuvanaPromenjena);
    on<ObavestenjePonudaProcitano>((dogadjaj, emit) {
      final trenutno = state;
      if (trenutno is PonudeUcitane && trenutno.obavestenje != null) emit(trenutno.copyWith(obavestenje: () => null));
    });
  }

  final UcitajPregled ucitajPregled;
  final PromeniSacuvanu promeniSacuvanu;

  Korisnik? _korisnik;

  Korisnik? get korisnik => _korisnik;

  PonudeFilteri? _trenutniFilteri() => switch (state) {
    PonudeUcitane(:final filteri) => filteri,
    _ => null,
  };

  Future<void> _ucitaj(Emitter<PonudeStanje> emit, {PonudeFilteri? zapamceni, PonudeObavestenje? obavestenje}) async {
    final ko = _korisnik;
    try {
      final podaci = await ucitajPregled(ko);
      if (ko != _korisnik) return;
      final filteri = _trenutniFilteri() ?? zapamceni ?? const PonudeFilteri();
      emit(
        podaci.ponude.isEmpty
            ? const PonudePrazne()
            : PonudeUcitane(podaci: podaci, filteri: filteri, obavestenje: obavestenje),
      );
    } on Exception catch (uzrok) {
      if (ko == _korisnik) emit(PonudeGreska(uzrok));
    }
  }

  Future<void> _onSacuvanaPromenjena(SacuvanaPromenjena dogadjaj, Emitter<PonudeStanje> emit) async {
    final trenutno = state;
    final ko = _korisnik;
    if (trenutno is! PonudeUcitane || trenutno.cuvaSe != null || ko == null) return;
    final bilaSacuvana = trenutno.podaci.jeSacuvana(dogadjaj.idPonude);
    emit(trenutno.copyWith(cuvaSe: () => dogadjaj.idPonude, obavestenje: () => null));
    try {
      await promeniSacuvanu(ko: ko, idPonude: dogadjaj.idPonude);
    } on Exception catch (uzrok) {
      if (state case final PonudeUcitane posle) {
        emit(posle.copyWith(cuvaSe: () => null, obavestenje: () => CuvanjePonudeNeuspelo(uzrok)));
      }
      return;
    }
    await _ucitaj(emit, obavestenje: bilaSacuvana ? const PonudaUklonjena() : const PonudaSacuvana());
  }
}
