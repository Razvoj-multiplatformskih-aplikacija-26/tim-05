@Tags(['db'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:api_contract/api_contract.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:relic/relic.dart' show IOAdapter, RelicServer;
import 'package:server/server.dart';
import 'package:test/test.dart';

late Pool<void> baza;
late RelicServer server;
late Uri adresa;
late String demoLozinka;
late String tajna;

const trajanje = Duration(hours: 1);
const dozvoljenoPoreklo = 'http://localhost:8081';

Uri putanja(String p) => adresa.replace(path: p);

Future<http.Response> prijavi(String korisnickoIme, String lozinka, {bool kolacic = false}) => http.post(
  putanja(ApiPutanje.sesije),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode(PrijavljivanjeDto(korisnickoIme: korisnickoIme, lozinka: lozinka, kolacic: kolacic).toJson()),
);

Future<String> tokenZa(String korisnickoIme) async =>
    SesijaDto.fromJson(jsonDecode((await prijavi(korisnickoIme, demoLozinka)).body) as Map<String, Object?>).token!;

Future<http.Response> trenutna(Map<String, String> zaglavlja) =>
    http.get(putanja(ApiPutanje.trenutnaSesija), headers: zaglavlja);

Map<String, String> bearer(String token) => {'Authorization': 'Bearer $token'};

String kodIz(http.Response odgovor) => (jsonDecode(odgovor.body) as Map<String, Object?>)['code']! as String;

/// Ista migracija kao u `compose.yaml`, ali nad posebnom bazom `erasmus_test`, da testovi ne diraju demo podatke.
Future<void> migrirajDbmate(Uri adresaBaze) async {
  final uCompose = adresaBaze.replace(host: 'db', port: 5432, path: '/erasmus_test');
  final rezultat = await Process.run('docker', [
    'compose',
    'run',
    '--rm',
    '-e',
    'DATABASE_URL=$uCompose',
    'migrate',
  ], workingDirectory: '../..');
  if (rezultat.exitCode != 0) throw StateError('dbmate nije uspeo: ${rezultat.stderr}');
}

void main() {
  setUpAll(() async {
    final konfiguracija = KonfiguracijaServera.izOkruzenja(serverEnvironment());
    demoLozinka = konfiguracija.demoLozinka!;
    tajna = konfiguracija.tajnaZaTokene;
    final admin = Pool<void>.withUrl(konfiguracija.adresaBaze);
    await admin.execute('DROP DATABASE IF EXISTS erasmus_test WITH (FORCE)');
    await admin.execute('CREATE DATABASE erasmus_test');
    await admin.close();
    baza = Pool<void>.withUrl(Uri.parse(konfiguracija.adresaBaze).replace(path: '/erasmus_test').toString());
    await migrirajDbmate(Uri.parse(konfiguracija.adresaBaze));
    await upisiPocetnePodatke(baza, sada: DateTime.now(), demoLozinka: demoLozinka);
    final sesije = RukovaociSesija(nalozi: SkladisteNaloga(baza), tajna: tajna, trajanje: trajanje);
    server = RelicServer(() => IOAdapter.bind(InternetAddress.loopbackIPv4, port: 0));
    await server.mountAndStart(napraviHandler(sesije, dozvoljenaPorekla: const [dozvoljenoPoreklo]));
    adresa = Uri.parse('http://localhost:${server.port}');
  });

  tearDownAll(() async {
    await server.close();
    await baza.close();
  });

  group('prijava lozinkom', () {
    test('ispravna lozinka daje 201, korisnika i token koji važi koliko je podešeno', () async {
      final pre = DateTime.now().toUtc();

      final odgovor = await prijavi('student1', demoLozinka);

      expect(odgovor.statusCode, 201);
      final sesija = SesijaDto.fromJson(jsonDecode(odgovor.body) as Map<String, Object?>);
      expect(sesija.korisnik.id, 's-1');
      expect(sesija.korisnik.uloga, KorisnikDto.student);
      expect(sesija.korisnik.idUniverziteta, isNull);
      expect(sesija.token, isNotNull);
      expect(sesija.istice.difference(pre.add(trajanje)).inSeconds.abs(), lessThan(5));
    });

    test('token je potpisan HS256 i nosi id, korisničko ime, ulogu i univerzitet, a ne lozinku', () async {
      final token = await tokenZa('koordinator1');

      final jwt = JWT.verify(token, SecretKey(tajna));

      expect(JWT.decode(token).header?['alg'], 'HS256');
      final podaci = jwt.payload as Map<String, Object?>;
      expect(podaci['sub'], 'k-polimi');
      expect(podaci['name'], 'koordinator1');
      expect(podaci['role'], 'koordinator');
      expect(podaci['university'], 'u-polimi');
      expect(podaci['exp'], isA<int>());
      expect(token, isNot(contains(demoLozinka)));
      expect(utf8.decode(base64Url.decode(base64Url.normalize(token.split('.')[1]))), isNot(contains(demoLozinka)));
    });

    test('pogrešna lozinka, nepostojeći nalog i korisnik bez lozinke dobijaju isti odgovor', () async {
      final odgovori = [
        await prijavi('student1', 'pogresna'),
        await prijavi('nepostoji', demoLozinka),
        await prijavi('ana.jovanovic', demoLozinka),
      ];

      expect(odgovori.map((o) => o.statusCode), everyElement(401));
      expect(odgovori.map(kodIz), everyElement(KodoviGresaka.pogresniPodaciZaPrijavu));
    });

    test('telo koje nije JSON objekat, bez lozinke ili sa pogrešnim tipom sadržaja se odbija pre provere', () async {
      final bezLozinke = await http.post(
        putanja(ApiPutanje.sesije),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': 'student1'}),
      );
      final nijeObjekat = await http.post(
        putanja(ApiPutanje.sesije),
        headers: {'Content-Type': 'application/json'},
        body: '[1, 2]',
      );
      final nijeJson = await http.post(
        putanja(ApiPutanje.sesije),
        headers: {'Content-Type': 'text/plain'},
        body: 'student1',
      );

      expect([bezLozinke.statusCode, nijeObjekat.statusCode, nijeJson.statusCode], [400, 400, 415]);
      expect(
        [kodIz(bezLozinke), kodIz(nijeObjekat), kodIz(nijeJson)],
        [KodoviGresaka.losZahtev, KodoviGresaka.losZahtev, KodoviGresaka.nepodrzanTipSadrzaja],
      );
      expect(nijeJson.headers['content-type'], startsWith(ProblemDto.mediaType));
    });
  });

  group('token pri svakom pozivu', () {
    test('sa važećim tokenom server zna ko poziva, samo iz tokena', () async {
      final odgovor = await trenutna(bearer(await tokenZa('student2')));

      expect(odgovor.statusCode, 200);
      final sesija = SesijaDto.fromJson(jsonDecode(odgovor.body) as Map<String, Object?>);
      expect(sesija.korisnik.id, 's-2');
      expect(sesija.token, isNull);
    });

    test('bez tokena 401 sign-in-required i WWW-Authenticate: Bearer', () async {
      final odgovor = await trenutna(const {});

      expect(odgovor.statusCode, 401);
      expect(kodIz(odgovor), KodoviGresaka.potrebnaPrijava);
      expect(odgovor.headers['www-authenticate'], 'Bearer');
    });

    test('istekao, lažan, tuđim ključem potpisan ili HS512 token daje 401 session-expired', () async {
      final istekao = JWT({
        'name': 'student1',
        'role': 'student',
        'exp': DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      }, subject: 's-1').sign(SecretKey(tajna), noIssueAt: true);
      final tudjiKljuc = JWT(const {
        'name': 'koordinator1',
        'role': 'koordinator',
        'university': 'u-polimi',
      }, subject: 'k-polimi').sign(SecretKey('neki-drugi-kljuc-od-bar-32-bajta-!!'), expiresIn: trajanje);
      final drugiAlgoritam = JWT(const {
        'name': 'student1',
        'role': 'student',
      }, subject: 's-1').sign(SecretKey(tajna), algorithm: JWTAlgorithm.HS512, expiresIn: trajanje);
      final nepoznataUloga = JWT(const {
        'name': 'student1',
        'role': 'admin',
      }, subject: 's-1').sign(SecretKey(tajna), expiresIn: trajanje);

      final odgovori = [
        for (final token in [istekao, 'nije.jwt.token', tudjiKljuc, drugiAlgoritam, nepoznataUloga])
          await trenutna(bearer(token)),
      ];

      expect(odgovori.map((o) => o.statusCode), everyElement(401));
      expect(odgovori.map(kodIz), everyElement(KodoviGresaka.sesijaIstekla));
    });
  });

  group('pregledač: HttpOnly kolačić', () {
    test('prijava sa cookie: true ne vraća token u telu, nego ga postavlja u HttpOnly kolačić', () async {
      final odgovor = await prijavi('koordinator1', demoLozinka, kolacic: true);

      expect(odgovor.statusCode, 201);
      expect(SesijaDto.fromJson(jsonDecode(odgovor.body) as Map<String, Object?>).token, isNull);
      final kolacic = odgovor.headers['set-cookie']!;
      expect(kolacic, startsWith('${ApiKolacici.sesija}='));
      expect(kolacic.toLowerCase(), allOf(contains('httponly'), contains('samesite=lax'), contains('path=/')));
      expect(kolacic, contains('Max-Age=${trajanje.inSeconds}'));
      expect(kolacic.toLowerCase(), isNot(contains('secure;')));
    });

    test('isti kolačić u sledećem pozivu daje prijavljenog korisnika', () async {
      final prijava = await prijavi('koordinator1', demoLozinka, kolacic: true);
      final parKolacica = prijava.headers['set-cookie']!.split(';').first;

      final odgovor = await trenutna({'Cookie': parKolacica});

      expect(odgovor.statusCode, 200);
      expect(SesijaDto.fromJson(jsonDecode(odgovor.body) as Map<String, Object?>).korisnik.idUniverziteta, 'u-polimi');
    });

    test('odjava vraća 204 i kolačić sa Max-Age=0, a bez prijave odjava nije moguća', () async {
      final odjava = await http.delete(putanja(ApiPutanje.trenutnaSesija), headers: bearer(await tokenZa('student1')));
      final bezPrijave = await http.delete(putanja(ApiPutanje.trenutnaSesija));

      expect(odjava.statusCode, 204);
      expect(odjava.headers['set-cookie'], allOf(startsWith('${ApiKolacici.sesija}=;'), contains('Max-Age=0')));
      expect(bezPrijave.statusCode, 401);
    });
  });

  group('drugo poreklo (CORS)', () {
    test('preflight sa dozvoljenog porekla dobija 204 i dozvolu sa kolačićem', () async {
      final zahtev = http.Request('OPTIONS', putanja(ApiPutanje.sesije))
        ..headers.addAll({
          'Origin': dozvoljenoPoreklo,
          'Access-Control-Request-Method': 'POST',
          'Access-Control-Request-Headers': 'content-type',
        });

      final odgovor = await http.Response.fromStream(await zahtev.send());

      expect(odgovor.statusCode, 204);
      expect(odgovor.headers['access-control-allow-origin'], dozvoljenoPoreklo);
      expect(odgovor.headers['access-control-allow-credentials'], 'true');
      expect(odgovor.headers['access-control-allow-headers'], contains('Authorization'));
    });

    test('odgovor dozvoljenom poreklu nosi Allow-Origin baš tog porekla, nikad *', () async {
      final odgovor = await http.get(putanja(ApiPutanje.zdravlje), headers: {'Origin': dozvoljenoPoreklo});

      expect(odgovor.headers['access-control-allow-origin'], dozvoljenoPoreklo);
      expect(odgovor.headers['vary'], 'Origin');
    });

    test('nedozvoljeno poreklo ne dobija dozvolu, a izmena sa njega se odbija sa 403', () async {
      final citanje = await http.get(putanja(ApiPutanje.zdravlje), headers: {'Origin': 'http://evil.example'});
      final izmena = await http.post(
        putanja(ApiPutanje.sesije),
        headers: {'Origin': 'http://evil.example', 'Content-Type': 'application/json'},
        body: jsonEncode(PrijavljivanjeDto(korisnickoIme: 'student1', lozinka: demoLozinka).toJson()),
      );

      expect(citanje.headers.containsKey('access-control-allow-origin'), isFalse);
      expect(izmena.statusCode, 403);
    });
  });

  test('nepoznata ruta daje 404 not-found kao Problem Details', () async {
    final odgovor = await http.get(putanja('/api/v1/nema'));

    expect(odgovor.statusCode, 404);
    expect(kodIz(odgovor), KodoviGresaka.nijePronadjeno);
    expect(odgovor.headers['content-type'], startsWith(ProblemDto.mediaType));
  });
}