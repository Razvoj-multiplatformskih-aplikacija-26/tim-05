import 'package:domain/domain.dart';

class LaznoSkladiste {
  LaznoSkladiste({
    required this.korisnik,
    required this.student,
    required this.univerziteti,
    required this.ponude,
    required this.svePrijave,
    required this.sacuvane,
  });

  final Korisnik korisnik;

  Student student;
  final List<Univerzitet> univerziteti;
  final List<Ponuda> ponude;

  final List<Prijava> svePrijave;

  final Set<IdPonude> sacuvane;

  List<Prijava> get mojePrijave => [
    for (final p in svePrijave)
      if (p.idStudenta == korisnik.id) p,
  ];

  Univerzitet univerzitet(IdUniverziteta id) => univerziteti.firstWhere((u) => u.id == id);

  Ponuda? ponuda(IdPonude id) {
    for (final p in ponude) {
      if (p.id == id) return p;
    }
    return null;
  }

  Prijava? prijava(IdPrijave id) {
    for (final p in svePrijave) {
      if (p.id == id) return p;
    }
    return null;
  }

  Prijava? mojaPrijavaZa(IdPonude idPonude) {
    for (final p in svePrijave) {
      if (p.idStudenta == korisnik.id && p.idPonude == idPonude && !p.stanje.jeKonacno) return p;
    }
    return null;
  }

  bool jeSacuvana(IdPonude id) => sacuvane.contains(id);

  void sacuvaj(Prijava prijava) {
    final indeks = svePrijave.indexWhere((p) => p.id == prijava.id);
    if (indeks == -1) {
      svePrijave.add(prijava);
    } else {
      svePrijave[indeks] = prijava;
    }
  }

  void sacuvajSve(List<Prijava> prijave) {
    for (final p in prijave) {
      sacuvaj(p);
    }
  }

  void obrisi(IdPrijave id) => svePrijave.removeWhere((p) => p.id == id);

  void promeniSacuvanu(IdPonude id) {
    if (sacuvane.contains(id)) {
      sacuvane.remove(id);
    } else {
      sacuvane.add(id);
    }
  }
}
