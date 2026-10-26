import 'package:domain/domain.dart';

abstract interface class StudentRepository {
  Future<Student> student(IdKorisnika id);

  Future<void> sacuvajStudenta(Student student);

  Future<Set<IdPonude>> sacuvanePonude(IdKorisnika idStudenta);

  Future<void> promeniSacuvanu(IdKorisnika idStudenta, IdPonude idPonude);
}
