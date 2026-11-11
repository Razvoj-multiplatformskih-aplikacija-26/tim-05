import 'dart:convert';

final class KonfiguracijaServera {
  const KonfiguracijaServera({
    required this.host,
    required this.port,
    required this.adresaBaze,
    required this.dozvoljenaPorekla,
    required this.tajnaZaTokene,
    this.trajanjeSesije = const Duration(hours: 8),
    this.bezbedanKolacic = false,
    this.demoLozinka,
  });

  factory KonfiguracijaServera.izOkruzenja(Map<String, String> okruzenje) => KonfiguracijaServera(
    host: okruzenje['HOST'] ?? '127.0.0.1',
    port: int.parse(okruzenje['PORT'] ?? '8080'),
    adresaBaze:
        okruzenje['DATABASE_URL'] ??
        (throw StateError('DATABASE_URL nije postavljen. Kopirajte .env.example u .env u korenu repozitorijuma.')),
    dozvoljenaPorekla: [
      for (final poreklo in (okruzenje['CORS_ORIGINS'] ?? 'http://localhost:8081').split(','))
        if (poreklo.trim().isNotEmpty) poreklo.trim(),
    ],
    tajnaZaTokene: _tajnaZaTokene(okruzenje['JWT_SECRET']),
    trajanjeSesije: Duration(minutes: int.parse(okruzenje['SESSION_TTL_MINUTES'] ?? '480')),
    bezbedanKolacic: okruzenje['COOKIE_SECURE'] == 'true',
    demoLozinka: okruzenje['DEMO_PASSWORD'],
  );

  final String host;
  final int port;
  final String adresaBaze;

  final List<String> dozvoljenaPorekla;

  final String tajnaZaTokene;

  final Duration trajanjeSesije;

  final bool bezbedanKolacic;

  final String? demoLozinka;
}

String _tajnaZaTokene(String? tajna) => switch (tajna) {
  null => throw StateError('JWT_SECRET nije postavljen. Kopirajte .env.example u .env u korenu repozitorijuma.'),
  final tajna when utf8.encode(tajna).length < 32 => throw StateError('JWT_SECRET mora imati bar 32 bajta.'),
  final tajna => tajna,
};