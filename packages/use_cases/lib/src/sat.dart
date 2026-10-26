abstract interface class Sat {
  DateTime sada();
}

final class SistemskiSat implements Sat {
  const SistemskiSat();

  @override
  DateTime sada() => DateTime.now();
}

final class FiksniSat implements Sat {
  const FiksniSat(this.trenutak);

  final DateTime trenutak;

  @override
  DateTime sada() => trenutak;
}
