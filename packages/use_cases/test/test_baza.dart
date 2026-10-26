import 'package:domain/domain.dart';
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

  void _proveri() {
    if (greskaSledecegZahteva) {
      greskaSledecegZahteva = false;
      throw const GreskaRepozitorijuma('Simulirani prekid veze');
    }
  }

  List<Prijava> get prijave => List.unmodifiable(_prijave);

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
  Future<List<Prijava>> svePrijave() async {
    _proveri();
    return List.of(_prijave);
  }

  @override
  Future<void> sacuvaj(List<Prijava> prijave) async {
    _proveri();
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
