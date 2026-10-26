final class GreskaRepozitorijuma implements Exception {
  const GreskaRepozitorijuma(this.poruka, [this.uzrok]);

  final String poruka;
  final Object? uzrok;

  @override
  String toString() => 'GreskaRepozitorijuma: $poruka';
}
