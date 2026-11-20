enum VrstaKvara {
  nedostupno,

  nemaVeze,

  greskaServera,

  odbijeno,

  sesijaIstekla,
}

final class GreskaRepozitorijuma implements Exception {
  const GreskaRepozitorijuma(this.poruka, {this.vrsta = VrstaKvara.nedostupno, this.uzrok});

  final String poruka;
  final VrstaKvara vrsta;
  final Object? uzrok;

  @override
  String toString() => 'GreskaRepozitorijuma(${vrsta.name}): $poruka';
}