import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'prijavljivanje_dogadjaj.dart';
part 'prijavljivanje_stanje.dart';

final class PrijavljivanjeBloc extends Bloc<PrijavljivanjeDogadjaj, PrijavljivanjeStanje> {
  PrijavljivanjeBloc({required this.prijaviSe}) : super(const PrijavljivanjeSpremno()) {
    on<PrijavljivanjeZatrazeno>((dogadjaj, emit) async {
      if (state is PrijavljivanjeUToku) return;
      emit(const PrijavljivanjeUToku());
      try {
        final korisnik = await prijaviSe(korisnickoIme: dogadjaj.korisnickoIme, lozinka: dogadjaj.lozinka);
        emit(korisnik == null ? const PrijavljivanjeOdbijeno() : PrijavljivanjeUspelo(korisnik));
      } on Exception catch (uzrok) {
        emit(PrijavljivanjeNeuspelo(uzrok));
      }
    });
  }

  final PrijaviSe prijaviSe;
}
