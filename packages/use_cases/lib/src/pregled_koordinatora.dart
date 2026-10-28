import 'package:domain/domain.dart';
import 'package:domain/domain.dart' as domen;
import 'package:equatable/equatable.dart';

final class PregledKoordinatora extends Equatable {
  const PregledKoordinatora({
    required this.univerzitet,
    required this.ponude,
    required this.prijave,
    required this.studenti,
    required this.sada,
  });

  final Univerzitet univerzitet;

  final List<Ponuda> ponude;

  final List<Prijava> prijave;

  final Map<IdKorisnika, Student> studenti;

  final DateTime sada;

  bool get jePrazno => prijave.isEmpty;

  Ponuda ponuda(IdPonude id) => ponude.firstWhere((p) => p.id == id);

  Prijava? prijava(IdPrijave id) => prijave.where((p) => p.id == id).firstOrNull;

  Student? student(IdKorisnika id) => studenti[id];

  int slobodnaMesta(Ponuda ponuda) => preostalaMesta(ponuda, prijave);

  int brojPrijava(Ponuda ponuda) => prijave.where((p) => p.idPonude == ponuda.id).length;

  bool imaProsek(Prijava prijava) {
    final student = studenti[prijava.idStudenta];
    return student != null && domen.imaProsek(student, ponuda(prijava.idPonude));
  }

  bool imaJezik(Prijava prijava) {
    final student = studenti[prijava.idStudenta];
    return student != null && domen.imaJezik(student, ponuda(prijava.idPonude));
  }

  @override
  List<Object?> get props => [univerzitet, ponude, prijave, studenti, sada];
}
