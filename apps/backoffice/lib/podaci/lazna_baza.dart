import 'package:domain/domain.dart';
import 'package:domain/domain.dart' as domen;
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
  Future<Map<IdPonude, int>> zauzetaMesta() async {
    await _zahtev();
    return {for (final ponuda in _ponude) ponuda.id: domen.zauzetaMesta(ponuda, _prijave)};
  }

  @override
  Future<Prijava?> prijava(IdPrijave id) async {
    await _zahtev();
    return _prijave.where((p) => p.id == id).firstOrNull;
  }

  @override
  Future<List<Prijava>> prijaveStudenta(IdKorisnika idStudenta) async {
    await _zahtev();
    return List.unmodifiable(_prijave.where((p) => p.idStudenta == idStudenta));
  }

  @override
  Future<List<Prijava>> prijaveNaPonudeUniverziteta(IdUniverziteta idUniverziteta) async {
    await _zahtev();
    final ponude = {
      for (final ponuda in _ponude)
        if (ponuda.idUniverziteta == idUniverziteta) ponuda.id,
    };
    return List.unmodifiable(_prijave.where((p) => ponude.contains(p.idPonude) && p.stanje is! UPripremi));
  }

  @override
  Future<Rezultat<Prijava>> napravi(Prijava nova) async {
    await _zahtev();
    _prijave.add(nova);
    return Uspeh(nova);
  }

  @override
  Future<Rezultat<Prijava>> sacuvaj(Prijava nova, {required StanjePrijave iz}) async {
    await _zahtev();
    return _upisi(nova, iz: iz);
  }

  @override
  Future<Rezultat<List<Prijava>>> potvrdiMesto(Prijava potvrdjena, {required List<Prijava> povucene}) async {
    await _zahtev();
    final trenutna = _prijave.where((p) => p.id == potvrdjena.id).firstOrNull;
    if (trenutna == null) return const Neuspeh(NijePronadjeno());
    if (trenutna.stanje is! Prihvacena) return Neuspeh(NedozvoljenPrelaz(iz: trenutna.stanje, u: potvrdjena.stanje));
    for (final prijava in [potvrdjena, ...povucene]) {
      _prijave[_prijave.indexWhere((p) => p.id == prijava.id)] = prijava;
    }
    return Uspeh([potvrdjena, ...povucene]);
  }

  Rezultat<Prijava> _upisi(Prijava nova, {required StanjePrijave iz}) {
    final indeks = _prijave.indexWhere((p) => p.id == nova.id);
    if (indeks == -1) return const Neuspeh(NijePronadjeno());
    final trenutna = _prijave[indeks];
    if (trenutna.stanje.runtimeType != iz.runtimeType) {
      return Neuspeh(NedozvoljenPrelaz(iz: trenutna.stanje, u: nova.stanje));
    }
    _prijave[indeks] = nova;
    return Uspeh(nova);
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
