import 'dart:async';
import 'dart:convert';

import 'package:api_client/api_client.dart';
import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

final kada = DateTime.utc(2026, 11, 10, 12);
final pismo = MotivacionoPismo.proveri('Želim da studiram u Milanu.').vrednostIliNull!;

Prijava prijava(StanjePrijave stanje) => Prijava(
  id: const IdPrijave('p-11'),
  idStudenta: const IdKorisnika('s-2'),
  idPonude: const IdPonude('po-1'),
  motivacionoPismo: pismo,
  napravljena: kada,
  stanje: stanje,
);

Map<String, Object?> prijavaJson(String vrsta, {String? odlucio, String? razlog}) => {
  'id': 'p-11',
  'studentId': 's-2',
  'offerId': 'po-1',
  'letter': pismo.tekst,
  'createdAt': '2026-11-10T12:00:00.000Z',
  'status': {'kind': vrsta, 'at': '2026-11-10T12:00:00.000Z', 'by': ?odlucio, 'reason': ?razlog},
};

http.Response jsonOdgovor(Object? telo, [int status = 200]) =>
    http.Response(jsonEncode(telo), status, headers: {'content-type': 'application/json; charset=utf-8'});

http.Response problem(int status, String kod, [Map<String, Object?> podaci = const {}]) => http.Response(
  jsonEncode({'type': 'x', 'title': 'x', 'status': status, 'code': kod, ...podaci}),
  status,
  headers: {'content-type': ProblemDto.mediaType},
);

ApiKlijent klijent(MockClient server, {TokenStore? tokeni, bool kolacic = false, Duration? cekanje}) => ApiKlijent(
  adresa: Uri.parse('http://localhost:8080'),
  tokeni: tokeni,
  httpKlijent: server,
  sesijaUKolacicu: kolacic,
  cekanje: cekanje ?? const Duration(seconds: 10),
);

Matcher kvar(VrstaKvara vrsta) => throwsA(isA<GreskaRepozitorijuma>().having((g) => g.vrsta, 'vrsta', vrsta));

void main() {
  group('odgovor servera → ono što dobija use case', () {
    test('zakasneli koordinator: 409 no-free-places postaje ista greška domena kao na klijentu', () async {
      final server = MockClient((zahtev) async => problem(409, KodoviGresaka.nemaSlobodnihMesta));

      final rezultat = await HttpPrijavaRepository(klijent(server)).sacuvaj(
        prijava(Prihvacena(odlucio: const IdKorisnika('k-polimi'), kada: kada)),
        iz: Poslata(kada: kada),
      );

      expect(rezultat, const Neuspeh<Prijava>(NemaSlobodnihMesta()));
    });

    test('pravilo sa granicom: 422 too-many-applications max 3 postaje PrevisePrijava(3)', () async {
      final server = MockClient((zahtev) async => problem(422, KodoviGresaka.previsePrijava, {'max': 3}));

      final rezultat = await HttpPrijavaRepository(klijent(server)).napravi(prijava(Poslata(kada: kada)));

      expect(rezultat, const Neuspeh<Prijava>(PrevisePrijava(3)));
    });

    test('stara verzija: nepoznat kôd sa servera je kvar „odbijeno", a ne pad', () async {
      final server = MockClient((zahtev) async => problem(422, 'too-many-applications-per-country', {'max': 2}));

      expect(HttpPrijavaRepository(klijent(server)).napravi(prijava(Poslata(kada: kada))), kvar(VrstaKvara.odbijeno));
    });

    test('server ne radi: kvar „nemaVeze"', () async {
      final server = MockClient((zahtev) async => throw http.ClientException('Connection refused', zahtev.url));

      expect(HttpPonudaRepository(klijent(server)).ponude(), kvar(VrstaKvara.nemaVeze));
    });

    test('server ne odgovara: posle zadatog vremena kvar „nemaVeze", ekran ne čeka bez kraja', () async {
      final nikad = Completer<http.Response>();
      final server = MockClient((zahtev) => nikad.future);

      expect(
        HttpPonudaRepository(klijent(server, cekanje: const Duration(milliseconds: 50))).ponude(),
        kvar(VrstaKvara.nemaVeze),
      );
    });

    test('5xx i odgovor koji ne odgovara ugovoru: kvar „greskaServera"', () async {
      final petsto = MockClient((zahtev) async => problem(500, KodoviGresaka.greskaServera));
      final nijeUgovor = MockClient(
        (zahtev) async => jsonOdgovor([
          {'id': 'po-1'},
        ]),
      );

      expect(HttpPonudaRepository(klijent(petsto)).ponude(), kvar(VrstaKvara.greskaServera));
      expect(HttpPonudaRepository(klijent(nijeUgovor)).ponude(), kvar(VrstaKvara.greskaServera));
    });

    test('401 session-expired: tok isteklih prijava javi, a poziv je kvar „sesijaIstekla"', () async {
      final server = MockClient((zahtev) async => problem(401, KodoviGresaka.sesijaIstekla));
      final api = klijent(server);
      final istekle = <void>[];
      api.istekle.listen(istekle.add);

      await expectLater(
        HttpPrijavaRepository(api).prijaveStudenta(const IdKorisnika('s-2')),
        kvar(VrstaKvara.sesijaIstekla),
      );
      await Future<void>.delayed(Duration.zero);

      expect(istekle, hasLength(1));
    });

    test('tuđa ili nepostojeća prijava (404) je null, kao u lažnoj bazi', () async {
      final server = MockClient((zahtev) async => problem(404, KodoviGresaka.nijePronadjeno));

      expect(await HttpPrijavaRepository(klijent(server)).prijava(const IdPrijave('p-2')), isNull);
    });
  });

  group('šta klijent šalje', () {
    test('telefon i desktop šalju token kao Bearer; pregledač ne šalje zaglavlje (kolačić šalje pregledač)', () async {
      final zaglavlja = <String?>[];
      final server = MockClient((zahtev) async {
        zaglavlja.add(zahtev.headers['Authorization']);
        return jsonOdgovor(<Object?>[]);
      });
      final tokeni = MemoryTokenStore();
      await tokeni.write('token-studenta');

      await HttpPrijavaRepository(klijent(server, tokeni: tokeni)).prijaveStudenta(const IdKorisnika('s-2'));
      await HttpPrijavaRepository(klijent(server, tokeni: tokeni, kolacic: true))
          .prijaveStudenta(const IdKorisnika('s-2'));

      expect(zaglavlja, ['Bearer token-studenta', null]);
    });

    test(
      'ruta se bira po akciji: odbijanje mesta, povlačenje, prihvatanje, lista čekanja, odbijanje, izmena',
      () async {
        final zahtevi = <(String, Map<String, Object?>?)>[];
        final server = MockClient((zahtev) async {
          zahtevi.add((zahtev.url.path, zahtev.body.isEmpty ? null : jsonDecode(zahtev.body) as Map<String, Object?>));
          return jsonOdgovor(prijavaJson('withdrawn'));
        });
        final repo = HttpPrijavaRepository(klijent(server));
        const k = IdKorisnika('k-polimi');

        await repo.sacuvaj(
          prijava(Povucena(kada: kada)),
          iz: Prihvacena(odlucio: k, kada: kada),
        );
        await repo.sacuvaj(
          prijava(Povucena(kada: kada)),
          iz: Poslata(kada: kada),
        );
        await repo.sacuvaj(
          prijava(Prihvacena(odlucio: k, kada: kada)),
          iz: Poslata(kada: kada),
        );
        await repo.sacuvaj(
          prijava(NaListiCekanja(odlucio: k, kada: kada)),
          iz: Poslata(kada: kada),
        );
        await repo.sacuvaj(
          prijava(Odbijena(odlucio: k, kada: kada, razlog: 'Popunjeno.')),
          iz: Poslata(kada: kada),
        );
        await repo.sacuvaj(prijava(Poslata(kada: kada)), iz: const UPripremi());

        expect(zahtevi.map((z) => z.$1), [
          '/api/v1/applications/p-11/place-decline',
          '/api/v1/applications/p-11/withdrawal',
          '/api/v1/applications/p-11/acceptance',
          '/api/v1/applications/p-11/waitlist',
          '/api/v1/applications/p-11/rejection',
          '/api/v1/applications/p-11/revision',
        ]);
        expect(zahtevi[4].$2, {'reason': 'Popunjeno.'});
        expect(zahtevi[5].$2, {'letter': pismo.tekst, 'submit': true});
      },
    );
        test('izmena već poslate prijave nije novo slanje: submit: false', () async {
      Map<String, Object?>? telo;
      final server = MockClient((zahtev) async {
        telo = jsonDecode(zahtev.body) as Map<String, Object?>;
        return jsonOdgovor(prijavaJson('submitted'));
      });

      await HttpPrijavaRepository(klijent(server)).sacuvaj(
        prijava(Poslata(kada: kada)),
        iz: Poslata(kada: kada),
      );

      expect(telo, {'letter': pismo.tekst, 'submit': false});
    });

    test('nova prijava ne šalje studenta ni id: to određuje server', () async {
      Map<String, Object?>? telo;
      final server = MockClient((zahtev) async {
        telo = jsonDecode(zahtev.body) as Map<String, Object?>;
        return jsonOdgovor(prijavaJson('draft'), 201);
      });

      final rezultat = await HttpPrijavaRepository(klijent(server)).napravi(prijava(const UPripremi()));

      expect(telo, {'offerId': 'po-1', 'letter': pismo.tekst, 'submit': false});
      expect(rezultat.vrednostIliNull?.stanje, isA<UPripremi>());
    });
  });

  group('ponude: broj zauzetih mesta stiže uz ponudu', () {
    test('ponude i zauzeta mesta iz istog odgovora', () async {
      final server = MockClient(
        (zahtev) async => jsonOdgovor([
          {
            'id': 'po-1',
            'universityId': 'u-polimi',
            'field': 'Računarstvo',
            'semester': {'kind': 'winter', 'academicYear': '2027/28'},
            'places': 4,
            'takenPlaces': 2,
            'deadline': '2027-01-04T22:59:00.000Z',
            'minAverage': 800,
            'language': {'language': 'english', 'level': 'B2'},
            'description': 'Opis.',
            'publishedBy': 'k-polimi',
            'publishedAt': '2026-11-09T23:00:00.000Z',
          },
        ]),
      );
      final repo = HttpPonudaRepository(klijent(server));

      expect((await repo.ponude()).single.minimalniProsek, 8.0);
      expect(await repo.zauzetaMesta(), {const IdPonude('po-1'): 2});
    });
  });

  group('prijava na sistem', () {
    Map<String, Object?> sesija({String? token}) => {
      'user': {'id': 's-1', 'username': 'student1', 'role': 'student'},
      'expiresAt': '2026-11-16T22:00:00.000Z',
      'token': ?token,
    };

    test('uspešna prijava sačuva token; pogrešna lozinka daje null, bez kvara', () async {
      final server = MockClient((zahtev) async {
        final telo = jsonDecode(zahtev.body) as Map<String, Object?>;
        if (telo['password'] != 'erasmus-demo') return problem(401, KodoviGresaka.pogresniPodaciZaPrijavu);
        return jsonOdgovor(sesija(token: 'novi-token'), 201);
      });
      final tokeni = MemoryTokenStore();
      final sesije = HttpSesijaRepository(klijent(server, tokeni: tokeni));

      final pogresna = await sesije.prijavi(korisnickoIme: 'student1', lozinka: 'x');
      final dobra = await sesije.prijavi(korisnickoIme: 'student1', lozinka: 'erasmus-demo');

      expect(pogresna, isNull);
      expect(dobra?.korisnickoIme, 'student1');
      expect(await tokeni.read(), 'novi-token');
    });

    test('pregledač traži kolačić (cookie: true) i ne čuva token', () async {
      Map<String, Object?>? telo;
      final server = MockClient((zahtev) async {
        telo = jsonDecode(zahtev.body) as Map<String, Object?>;
        return jsonOdgovor(sesija(), 201);
      });
      final tokeni = MemoryTokenStore();

      await HttpSesijaRepository(klijent(server, tokeni: tokeni, kolacic: true))
          .prijavi(korisnickoIme: 'a', lozinka: 'b');

      expect(telo?['cookie'], isTrue);
      expect(await tokeni.read(), isNull);
    });

    test('bez sačuvanog tokena na uređaju niko nije prijavljen, bez poziva serveru', () async {
      var pozivi = 0;
      final server = MockClient((zahtev) async {
        pozivi++;
        return jsonOdgovor(sesija());
      });

      expect(await HttpSesijaRepository(klijent(server)).trenutni(), isNull);
      expect(pozivi, 0);
    });

    test('istekao sačuvan token: null i token se briše', () async {
      final server = MockClient((zahtev) async => problem(401, KodoviGresaka.sesijaIstekla));
      final tokeni = MemoryTokenStore();
      await tokeni.write('stari-token');

      expect(await HttpSesijaRepository(klijent(server, tokeni: tokeni)).trenutni(), isNull);
      expect(await tokeni.read(), isNull);
    });

    test('odjava briše token i kada server nije dostupan', () async {
      final server = MockClient((zahtev) async => throw http.ClientException('Connection refused', zahtev.url));
      final tokeni = MemoryTokenStore();
      await tokeni.write('token');

      await expectLater(HttpSesijaRepository(klijent(server, tokeni: tokeni)).odjavi(), kvar(VrstaKvara.nemaVeze));

      expect(await tokeni.read(), isNull);
    });
  });
}