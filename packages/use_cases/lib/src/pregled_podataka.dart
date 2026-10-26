import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

final class PregledPodataka extends Equatable {
  const PregledPodataka({
    required this.student,
    required this.univerziteti,
    required this.ponude,
    required this.svePrijave,
    required this.sacuvane,
    required this.sada,
  });

  final Student student;
  final List<Univerzitet> univerziteti;
  final List<Ponuda> ponude;

  final List<Prijava> svePrijave;
  final Set<IdPonude> sacuvane;

  final DateTime sada;

  List<Prijava> get mojePrijave => [
    for (final p in svePrijave)
      if (p.idStudenta == student.id) p,
  ]..sort((a, b) => b.napravljena.compareTo(a.napravljena));

  Univerzitet univerzitet(IdUniverziteta id) => univerziteti.firstWhere((u) => u.id == id);

  Ponuda? ponuda(IdPonude id) => ponude.where((p) => p.id == id).firstOrNull;

  Prijava? prijava(IdPrijave id) => svePrijave.where((p) => p.id == id).firstOrNull;

  Prijava? mojaPrijavaZa(IdPonude idPonude) =>
      mojePrijave.where((p) => p.idPonude == idPonude && !p.stanje.jeKonacno).firstOrNull;

  bool jeSacuvana(IdPonude id) => sacuvane.contains(id);

  List<Ponuda> get sacuvanePonude => [for (final id in sacuvane) ?ponuda(id)];

  int slobodnaMesta(Ponuda ponuda) => preostalaMesta(ponuda, svePrijave);

  int get brojAktivnih => aktivnePrijave(student.id, svePrijave).length;

  ProveraUslova uslovi(Ponuda ponuda) => ProveraUslova(
    jezik: imaJezik(student, ponuda),
    prosek: imaProsek(student, ponuda),
    rok: rokNijeIstekao(ponuda, sada),
    mestoZaPrijavu: imaMestaZaNovuPrijavu(student, svePrijave),
    brojAktivnih: brojAktivnih,
    ishod: proveriUslove(student: student, ponuda: ponuda, svePrijave: svePrijave, sada: sada),
  );

  bool jeNova(Ponuda ponuda) => sada.difference(ponuda.objavljena).inDays < 7;

  bool mozeSePoslati(Prijava? prijava) => dozvoljenPrelaz(prijava?.stanje ?? const UPripremi(), Poslata(kada: sada));

  bool mozeSePovuci(Prijava prijava) =>
      prijava.stanje is! Prihvacena && dozvoljenPrelaz(prijava.stanje, Povucena(kada: sada));

  @override
  List<Object?> get props => [student, univerziteti, ponude, svePrijave, sacuvane, sada];
}

final class ProveraUslova {
  const ProveraUslova({
    required this.jezik,
    required this.prosek,
    required this.rok,
    required this.mestoZaPrijavu,
    required this.brojAktivnih,
    required this.ishod,
  });

  final bool jezik;
  final bool prosek;
  final bool rok;
  final bool mestoZaPrijavu;
  final int brojAktivnih;

  final Rezultat<Ponuda> ishod;

  bool get ispunjeni => ishod.jeUspeh;
}
