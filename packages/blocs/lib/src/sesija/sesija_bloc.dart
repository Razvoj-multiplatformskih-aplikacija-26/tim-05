import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'sesija_dogadjaj.dart';
part 'sesija_stanje.dart';


final class SesijaBloc extends Bloc<SesijaDogadjaj, SesijaStanje> {
  SesijaBloc({
    required this.obnoviSesiju,
    required this.odjaviSe,
    required this.dozvoljen,
    required Stream<void> istekle,
  }) : super(const SesijaNepoznata()) {
    on<ObnovaSesijeZatrazena>(_obnovi);
    on<SesijaZapoceta>(_zapocni);
    on<OdjavaZatrazena>((dogadjaj, emit) async {
      await _odjaviTiho();
      emit(const Odjavljen(razlog: RazlogOdjave.odjava));
    });
    on<SesijaIstekla>((dogadjaj, emit) {
      if (state is Prijavljen) emit(const Odjavljen(razlog: RazlogOdjave.istekla));
    });
    _istekle = istekle.listen((_) => add(const SesijaIstekla()));
  }

  final ObnoviSesiju obnoviSesiju;
  final OdjaviSe odjaviSe;

  final bool Function(Korisnik korisnik) dozvoljen;

  late final StreamSubscription<void> _istekle;

  Future<void> _obnovi(ObnovaSesijeZatrazena dogadjaj, Emitter<SesijaStanje> emit) async {
    try {
      final korisnik = await obnoviSesiju();
      if (korisnik == null) return emit(const Odjavljen());
      add(SesijaZapoceta(korisnik));
    } on GreskaRepozitorijuma {
      emit(const Odjavljen(razlog: RazlogOdjave.nedostupan));
    } on Exception catch (uzrok, trag) {
      addError(uzrok, trag);
      emit(const Odjavljen());
    }
  }

  Future<void> _zapocni(SesijaZapoceta dogadjaj, Emitter<SesijaStanje> emit) async {
    if (dozvoljen(dogadjaj.korisnik)) return emit(Prijavljen(dogadjaj.korisnik));
    await _odjaviTiho();
    emit(const Odjavljen(razlog: RazlogOdjave.pogresnaAplikacija));
  }

  Future<void> _odjaviTiho() async {
    try {
      await odjaviSe();
    } on Exception catch (uzrok, trag) {
      addError(uzrok, trag);
    }
  }

  @override
  Future<void> close() async {
    await _istekle.cancel();
    return super.close();
  }
}