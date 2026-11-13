import 'package:domain/domain.dart';

abstract interface class PonudaRepository {
  Future<List<Ponuda>> ponude();

  Future<List<Univerzitet>> univerziteti();

  Future<Map<IdPonude, int>> zauzetaMesta();
}
