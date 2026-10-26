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
  Future<List<Prijava>> svePrijave() async => List.unmodifiable(_prijave);

  @override
  Future<void> sacuvaj(List<Prijava> prijave) async {
    for (final prijava in prijave) {
      _prijave
        ..removeWhere((p) => p.id == prijava.id)
        ..add(prijava);
    }
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
