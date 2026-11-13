import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

final class PraznaBaza implements PonudaRepository, PrijavaRepository, StudentRepository {
  PraznaBaza({required this._student});

  Student _student;
  final _prijave = <Prijava>[];
  final _sacuvane = <IdPonude>{};

  @override
  Future<List<Ponuda>> ponude() async => const [];

  @override
  Future<List<Univerzitet>> univerziteti() async => const [];

  @override
  Future<Map<IdPonude, int>> zauzetaMesta() async => const {};

  @override
  Future<Prijava?> prijava(IdPrijave id) async => _prijave.where((p) => p.id == id).firstOrNull;

  @override
  Future<List<Prijava>> prijaveStudenta(IdKorisnika idStudenta) async =>
      List.unmodifiable(_prijave.where((p) => p.idStudenta == idStudenta));

  @override
  Future<List<Prijava>> prijaveNaPonudeUniverziteta(IdUniverziteta idUniverziteta) async => const [];

  @override
  Future<Rezultat<Prijava>> napravi(Prijava nova) async {
    _prijave.add(nova);
    return Uspeh(nova);
  }

  @override
  Future<Rezultat<Prijava>> sacuvaj(Prijava nova, {required StanjePrijave iz}) async {
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
    for (final prijava in [potvrdjena, ...povucene]) {
      _prijave
        ..removeWhere((p) => p.id == prijava.id)
        ..add(prijava);
    }
    return Uspeh([potvrdjena, ...povucene]);
  }

  @override
  Future<void> obrisi(IdPrijave id) async {
    _prijave.removeWhere((p) => p.id == id);
  }

  @override
  Future<Student> student(IdKorisnika id) async => _student;

  @override
  Future<void> sacuvajStudenta(Student student) async {
    _student = student;
  }

  @override
  Future<Set<IdPonude>> sacuvanePonude(IdKorisnika idStudenta) async => Set.unmodifiable(_sacuvane);

  @override
  Future<void> promeniSacuvanu(IdKorisnika idStudenta, IdPonude idPonude) async {
    if (!_sacuvane.remove(idPonude)) _sacuvane.add(idPonude);
  }
}
