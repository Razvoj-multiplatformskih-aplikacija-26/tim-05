import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'formular_prijave_dogadjaj.dart';
part 'formular_prijave_stanje.dart';

final class FormularPrijaveBloc extends Bloc<FormularPrijaveDogadjaj, FormularPrijaveStanje> {
  FormularPrijaveBloc({required this.sacuvajPrijavu, required this.korisnik, this.idPonude, this.idPrijave})
    : assert(
        idPonude != null || idPrijave != null,
        'Formular je za novu prijavu (idPonude) ili za izmenu (idPrijave).',
      ),
      super(const FormularSpreman()) {
    on<CuvanjeZatrazeno>(
      (dogadjaj, emit) => _sacuvaj(emit, pismo: dogadjaj.pismo, napomena: dogadjaj.napomena, posalji: false),
    );
    on<SlanjeZatrazeno>(
      (dogadjaj, emit) => _sacuvaj(emit, pismo: dogadjaj.pismo, napomena: dogadjaj.napomena, posalji: true),
    );
  }

  final SacuvajPrijavu sacuvajPrijavu;
  final Korisnik korisnik;

  final IdPonude? idPonude;

  final IdPrijave? idPrijave;

  Future<void> _sacuvaj(
    Emitter<FormularPrijaveStanje> emit, {
    required MotivacionoPismo pismo,
    required String? napomena,
    required bool posalji,
  }) async {
    if (state is FormularUToku) return;
    emit(FormularUToku(posalji: posalji));
    try {
      final rezultat = await sacuvajPrijavu(
        ko: korisnik,
        idPonude: idPonude,
        idPrijave: idPrijave,
        pismo: pismo,
        napomena: napomena,
        posalji: posalji,
      );
      emit(switch (rezultat) {
        Uspeh(:final vrednost) => FormularSacuvan(vrednost, poslata: posalji),
        Neuspeh(:final greska) => FormularOdbijen(greska),
      });
    } on Exception catch (uzrok) {
      emit(FormularNeuspeo(uzrok));
    }
  }
}
