final class KonfiguracijaServera {
  const KonfiguracijaServera({required this.host, required this.port, required this.adresaBaze, this.demoLozinka});

  factory KonfiguracijaServera.izOkruzenja(Map<String, String> okruzenje) => KonfiguracijaServera(
    host: okruzenje['HOST'] ?? '127.0.0.1',
    port: int.parse(okruzenje['PORT'] ?? '8080'),
    adresaBaze:
        okruzenje['DATABASE_URL'] ??
        (throw StateError('DATABASE_URL nije postavljen. Kopirajte .env.example u .env u korenu repozitorijuma.')),
    demoLozinka: okruzenje['DEMO_PASSWORD'],
  );

  final String host;
  final int port;
  final String adresaBaze;
  final String? demoLozinka;
}