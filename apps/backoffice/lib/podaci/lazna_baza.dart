import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'lazni_podaci.dart';

final class LaznaBaza implements PonudaRepository, PrijavaRepository, StudentRepository {
  LaznaBaza({this.kasnjenje = const Duration(milliseconds: 400)})
    : _univerziteti = List.of(pocetniUniverziteti),
      _ponude = List.of(pocetnePonude),
      _prijave = List.of(pocetnePrijave),
      _studenti = {for (final student in pocetniStudenti) student.id: student};

  final Duration kasnjenje;

  final List<Univerzitet> _univerziteti;
  final List<Ponuda> _ponude;
  final List<Prijava> _prijave;
  final Map<IdKorisnika, Student> _studenti;
  final Map<IdKorisnika, Set<IdPonude>> _sacuvane = {};

  int neuspesniZahtevi = 0;

  Future<void> _zahtev() async {
    await Future<void>.delayed(kasnjenje);
    if (neuspesniZahtevi > 0) {
      neuspesniZahtevi--;
      throw const GreskaRepozitorijuma('Simuliran prekid veze');
    }
  }

  @override
  Future<List<Ponuda>> ponude() async {
    await _zahtev();
    return List.unmodifiable(_ponude);
  }

  @override
  Future<List<Univerzitet>> univerziteti() async {
    await _zahtev();
    return List.unmodifiable(_univerziteti);
  }

  @override
  Future<List<Prijava>> svePrijave() async {
    await _zahtev();
    return List.unmodifiable(_prijave);
  }

  @override
  Future<void> sacuvaj(List<Prijava> prijave) async {
    await _zahtev();
    for (final prijava in prijave) {
      final indeks = _prijave.indexWhere((p) => p.id == prijava.id);
      if (indeks == -1) {
        _prijave.add(prijava);
      } else {
        _prijave[indeks] = prijava;
      }
    }
  }

  @override
  Future<void> obrisi(IdPrijave id) async {
    await _zahtev();
    _prijave.removeWhere((p) => p.id == id);
  }

  @override
  Future<Student> student(IdKorisnika id) async {
    await _zahtev();
    final student = _studenti[id];
    if (student == null) throw const GreskaRepozitorijuma('Student nije pronađen');
    return student;
  }

  @override
  Future<void> sacuvajStudenta(Student student) async {
    await _zahtev();
    _studenti[student.id] = student;
  }

  @override
  Future<Set<IdPonude>> sacuvanePonude(IdKorisnika idStudenta) async {
    await _zahtev();
    return Set.unmodifiable(_sacuvane[idStudenta] ?? const <IdPonude>{});
  }

  @override
  Future<void> promeniSacuvanu(IdKorisnika idStudenta, IdPonude idPonude) async {
    await _zahtev();
    final sacuvane = _sacuvane.putIfAbsent(idStudenta, () => {});
    if (!sacuvane.remove(idPonude)) sacuvane.add(idPonude);
  }
}
