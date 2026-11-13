import 'package:domain/domain.dart';
import 'package:domain/domain.dart' as domen;
import 'package:use_cases/use_cases.dart';

final class TestBaza implements PonudaRepository, PrijavaRepository, StudentRepository {
  TestBaza({required this._student, List<Ponuda> ponude = const [], List<Prijava> prijave = const []})
    : _ponude = List.of(ponude),
      _prijave = List.of(prijave);

  Student _student;
  final List<Ponuda> _ponude;
  final List<Prijava> _prijave;
  final _sacuvane = <IdPonude>{};

  bool greskaSledecegZahteva = false;

  void Function(TestBaza baza)? preSledecegUpisa;

  void _proveri() {
    if (greskaSledecegZahteva) {
      greskaSledecegZahteva = false;
      throw const GreskaRepozitorijuma('Simulirani prekid veze');
    }
  }

  List<Prijava> get prijave => List.unmodifiable(_prijave);

  void postavi(Prijava prijava) => _prijave[_prijave.indexWhere((p) => p.id == prijava.id)] = prijava;

  @override
  Future<List<Ponuda>> ponude() async {
    _proveri();
    return List.of(_ponude);
  }

  @override
  Future<List<Univerzitet>> univerziteti() async {
    _proveri();
    return const [
      Univerzitet(
        id: IdUniverziteta('u-polimi'),
        naziv: 'Politecnico di Milano',
        grad: 'Milano',
        drzava: 'Italija',
        oznakaDrzave: 'IT',
      ),
    ];
  }

  @override
  Future<Map<IdPonude, int>> zauzetaMesta() async {
    _proveri();
    return {for (final ponuda in _ponude) ponuda.id: domen.zauzetaMesta(ponuda, _prijave)};
  }

  @override
  Future<Prijava?> prijava(IdPrijave id) async {
    _proveri();
    return _prijave.where((p) => p.id == id).firstOrNull;
  }

  @override
  Future<List<Prijava>> prijaveStudenta(IdKorisnika idStudenta) async {
    _proveri();
    return [
      for (final p in _prijave)
        if (p.idStudenta == idStudenta) p,
    ];
  }

  @override
  Future<List<Prijava>> prijaveNaPonudeUniverziteta(IdUniverziteta idUniverziteta) async {
    _proveri();
    final ponude = {
      for (final ponuda in _ponude)
        if (ponuda.idUniverziteta == idUniverziteta) ponuda.id,
    };
    return [
      for (final p in _prijave)
        if (ponude.contains(p.idPonude) && p.stanje is! UPripremi) p,
    ];
  }

  @override
  Future<Rezultat<Prijava>> napravi(Prijava nova) async {
    _proveri();
    _prijave.add(nova);
    return Uspeh(nova);
  }

  @override
  Future<Rezultat<Prijava>> sacuvaj(Prijava nova, {required StanjePrijave iz}) async {
    _proveri();
    _preUpisa();
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
  Future<Rezultat<List<Prijava>>> potvrdiMesto(Prijava potvrdjena, {required List<Prijava> povucene}) async {
    _proveri();
    _preUpisa();
    final trenutna = _prijave.where((p) => p.id == potvrdjena.id).firstOrNull;
    if (trenutna == null) return const Neuspeh(NijePronadjeno());
    if (trenutna.stanje is! Prihvacena) return Neuspeh(NedozvoljenPrelaz(iz: trenutna.stanje, u: potvrdjena.stanje));
    for (final prijava in [potvrdjena, ...povucene]) {
      postavi(prijava);
    }
    return Uspeh([potvrdjena, ...povucene]);
  }

  void _preUpisa() {
    final akcija = preSledecegUpisa;
    preSledecegUpisa = null;
    akcija?.call(this);
  }

  @override
  Future<void> obrisi(IdPrijave id) async {
    _proveri();
    _prijave.removeWhere((p) => p.id == id);
  }

  @override
  Future<Student> student(IdKorisnika id) async {
    _proveri();
    return _student;
  }

  @override
  Future<void> sacuvajStudenta(Student student) async {
    _proveri();
    _student = student;
  }

  @override
  Future<Set<IdPonude>> sacuvanePonude(IdKorisnika idStudenta) async {
    _proveri();
    return Set.of(_sacuvane);
  }

  @override
  Future<void> promeniSacuvanu(IdKorisnika idStudenta, IdPonude idPonude) async {
    _proveri();
    if (!_sacuvane.remove(idPonude)) _sacuvane.add(idPonude);
  }
}
