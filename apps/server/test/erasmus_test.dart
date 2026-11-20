@Tags(['db'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:api_contract/api_contract.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'package:relic/relic.dart' show IOAdapter, RelicServer;
import 'package:server/server.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';


const imeBaze = 'erasmus_test_teme';

late Pool<void> baza;
late RelicServer server;
late Uri adresa;
late String demoLozinka;

Uri putanja(String p) => adresa.replace(path: p);

Future<String> tokenZa(String korisnickoIme) async {
  final odgovor = await http.post(
    putanja(ApiPutanje.sesije),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(PrijavljivanjeDto(korisnickoIme: korisnickoIme, lozinka: demoLozinka).toJson()),
  );
  return SesijaDto.fromJson(jsonDecode(odgovor.body) as Map<String, Object?>).token!;
}

Map<String, String> kao(String token) => {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};

Future<http.Response> get(String token, String p) => http.get(putanja(p), headers: kao(token));

Future<http.Response> post(String token, String p, [Map<String, Object?>? telo]) =>
    http.post(putanja(p), headers: kao(token), body: telo == null ? null : jsonEncode(telo));

String kodIz(http.Response odgovor) => (jsonDecode(odgovor.body) as Map<String, Object?>)['code']! as String;

Map<String, Object?> objekat(http.Response odgovor) => jsonDecode(odgovor.body) as Map<String, Object?>;

List<Map<String, Object?>> lista(http.Response odgovor) => [
  for (final o in jsonDecode(odgovor.body) as List<Object?>) o! as Map<String, Object?>,
];

Future<Object?> jednaVrednost(String sql) async => (await baza.execute(sql)).single[0];

Future<void> migrirajDbmate(Uri adresaBaze) async {
  final uCompose = adresaBaze.replace(host: 'db', port: 5432, path: '/$imeBaze');
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
    final admin = Pool<void>.withUrl(konfiguracija.adresaBaze);
    await admin.execute('DROP DATABASE IF EXISTS $imeBaze WITH (FORCE)');
    await admin.execute('CREATE DATABASE $imeBaze');
    await admin.close();
    baza = Pool<void>.withUrl(Uri.parse(konfiguracija.adresaBaze).replace(path: '/$imeBaze').toString());
    await migrirajDbmate(Uri.parse(konfiguracija.adresaBaze));
    final sesije = RukovaociSesija(
      nalozi: SkladisteNaloga(baza),
      tajna: konfiguracija.tajnaZaTokene,
      trajanje: const Duration(hours: 1),
    );
    final erasmus = RukovaociErasmusa(skladiste: PostgresErasmus(baza), sat: const SistemskiSat());
    server = RelicServer(() => IOAdapter.bind(InternetAddress.loopbackIPv4, port: 0));
    await server.mountAndStart(napraviHandler(sesije, erasmus: erasmus, dozvoljenaPorekla: const []));
    adresa = Uri.parse('http://localhost:${server.port}');
  });

  setUp(() async {
    await baza.execute(
      'TRUNCATE sacuvane_ponude, prijave, znanje_jezika, studenti, ponude, korisnici, univerziteti CASCADE',
    );
    await upisiPocetnePodatke(baza, sada: DateTime.now(), demoLozinka: demoLozinka);
  });

  tearDownAll(() async {
    await server.close();
    await baza.close();
  });

  group('javno, bez prijave (README, zahtev 6)', () {
    test('ponude i univerziteti se vide bez tokena; ponuda nosi broj zauzetih mesta, ne prijave', () async {
      final ponude = lista(await http.get(putanja(ApiPutanje.ponude)));
      final univerziteti = lista(await http.get(putanja(ApiPutanje.univerziteti)));

      expect(ponude, hasLength(11));
      expect(univerziteti, hasLength(8));
      final po1 = ponude.firstWhere((p) => p['id'] == 'po-1');
      expect((po1['places'], po1['takenPlaces'], po1['minAverage']), (4, 2, 800));
      expect(po1.keys, isNot(contains('applications')));
    });

    test('sve ostalo traži prijavu: bez tokena 401', () async {
      final odgovori = [
        await http.get(putanja(ApiPutanje.prijava('p-1'))),
        await http.post(putanja(ApiPutanje.povlacenje('p-2'))),
        await http.get(putanja(ApiPutanje.prijaveStudenta('s-1'))),
      ];

      expect(odgovori.map((o) => o.statusCode), everyElement(401));
      expect(odgovori.map(kodIz), everyElement(KodoviGresaka.potrebnaPrijava));
    });
  });

  group('šta vidi koja uloga (stavka 2)', () {
    test('student dobija samo svoje prijave', () async {
      final odgovor = await get(await tokenZa('student1'), ApiPutanje.prijaveStudenta('s-1'));

      final prijave = lista(odgovor);
      expect(prijave, hasLength(10));
      expect(prijave.map((p) => p['studentId']), everyElement('s-1'));
    });

    test('koordinator dobija prijave na ponude svog univerziteta, bez prijava u pripremi', () async {
      final odgovor = await get(await tokenZa('koordinator1'), ApiPutanje.prijaveUniverziteta('u-polimi'));

      final prijave = lista(odgovor);
      expect(prijave.map((p) => p['offerId']).toSet(), {'po-1', 'po-10', 'po-11'});
      expect(prijave.map((p) => (p['status']! as Map<String, Object?>)['kind']), isNot(contains('draft')));
    });

    test('koordinator vidi profil studenta koji se prijavio kod njega, ali ne i ostalih', () async {
      final koordinator1 = await tokenZa('koordinator1');
      final koordinator2 = await tokenZa('koordinator2');

      final marko = await get(koordinator1, ApiPutanje.student('s-2'));
      final jovanaKodBolonje = await get(koordinator2, ApiPutanje.student('s-6'));

      expect(marko.statusCode, 200);
      expect(objekat(marko)['average'], 921);
      expect(jovanaKodBolonje.statusCode, 404);
    });
  });

  group('tuđ zapis i uloga (stavka 4)', () {
    test('drugi student ne vidi i ne menja tuđu prijavu: 404, prijava ostaje ista', () async {
      final student2 = await tokenZa('student2');

      final citanje = await get(student2, ApiPutanje.prijava('p-2'));
      final povlacenje = await post(student2, ApiPutanje.povlacenje('p-2'));
      final tudjaLista = await get(student2, ApiPutanje.prijaveStudenta('s-1'));

      expect([citanje.statusCode, povlacenje.statusCode, tudjaLista.statusCode], [404, 404, 404]);
      expect(await jednaVrednost("SELECT stanje FROM prijave WHERE id = 'p-2'"), 'poslata');
    });

    test('student koji pošalje akciju koordinatora mimo aplikacije dobija 403, i ništa se ne menja', () async {
      final student2 = await tokenZa('student2');

      final prihvatanje = await post(student2, ApiPutanje.prihvatanje('p-11'));
      final odbijanje = await post(student2, ApiPutanje.odbijanje('p-11'), const OdbijanjeDto(razlog: 'x').toJson());
      final listaKoordinatora = await get(student2, ApiPutanje.prijaveUniverziteta('u-polimi'));

      expect([prihvatanje.statusCode, odbijanje.statusCode, listaKoordinatora.statusCode], [403, 403, 403]);
      expect(kodIz(prihvatanje), KodoviGresaka.nemaPravo);
      expect(await jednaVrednost("SELECT stanje FROM prijave WHERE id = 'p-11'"), 'poslata');
    });

    test('koordinator drugog univerziteta ne vidi prijave za Milano: 404', () async {
      final koordinator2 = await tokenZa('koordinator2');

      final prihvatanje = await post(koordinator2, ApiPutanje.prihvatanje('p-11'));
      final lista = await get(koordinator2, ApiPutanje.prijaveUniverziteta('u-polimi'));

      expect([prihvatanje.statusCode, lista.statusCode], [404, 404]);
      expect(await jednaVrednost("SELECT stanje FROM prijave WHERE id = 'p-11'"), 'poslata');
    });

    test('koordinator svog univerziteta prihvata, stavlja na listu čekanja i odbija sa razlogom', () async {
      final koordinator1 = await tokenZa('koordinator1');

      final prihvacena = await post(koordinator1, ApiPutanje.prihvatanje('p-11'));
      final naListi = await post(koordinator1, ApiPutanje.listaCekanja('p-20'));
      final odbijena = await post(
        koordinator1,
        ApiPutanje.odbijanje('p-21'),
        const OdbijanjeDto(razlog: 'Prednost su imali studenti sa višim prosekom.').toJson(),
      );

      expect([prihvacena.statusCode, naListi.statusCode, odbijena.statusCode], [200, 200, 200]);
      expect((objekat(prihvacena)['status']! as Map<String, Object?>)['by'], 'k-polimi');
      expect((objekat(odbijena)['status']! as Map<String, Object?>)['reason'], startsWith('Prednost'));
      expect(await jednaVrednost("SELECT zauzeta_mesta FROM ponude WHERE id = 'po-1'"), 3);
    });
  });

  group('isto pravilo i isti kôd i mimo aplikacije (stavka 1)', () {
    test('pismo od 1501 znaka: 422 letter-too-long sa dužinom i granicom, ništa se ne upisuje', () async {
      final odgovor = await post(
        await tokenZa('student1'),
        ApiPutanje.prijave,
        NovaPrijavaDto(idPonude: 'po-8', motivacionoPismo: 'a' * 1501).toJson(),
      );

      expect(odgovor.statusCode, 422);
      expect(objekat(odgovor), containsPair('code', KodoviGresaka.pismoPredugacko));
      expect((objekat(odgovor)['value'], objekat(odgovor)['max']), (1501, 1500));
      expect(await jednaVrednost('SELECT count(*) FROM prijave'), 27);
    });

    test('četvrta aktivna prijava: 422 too-many-applications sa granicom 3', () async {
      final odgovor = await post(
        await tokenZa('student1'),
        ApiPutanje.prijave,
        const NovaPrijavaDto(idPonude: 'po-8', motivacionoPismo: 'Uppsala me zanima.', posalji: true).toJson(),
      );

      expect(odgovor.statusCode, 422);
      expect((kodIz(odgovor), objekat(odgovor)['max']), (KodoviGresaka.previsePrijava, 3));
    });

    test('nova prijava u pripremi: 201, id dodeljuje baza, student je iz tokena', () async {
      final odgovor = await post(
        await tokenZa('student2'),
        ApiPutanje.prijave,
        const NovaPrijavaDto(idPonude: 'po-8', motivacionoPismo: 'Uppsala me zanima.').toJson(),
      );

      expect(odgovor.statusCode, 201);
      final prijava = objekat(odgovor);
      expect(prijava['studentId'], 's-2');
      expect(prijava['id'], isNot(startsWith('p-')));
      expect((prijava['status']! as Map<String, Object?>)['kind'], StanjePrijaveDto.uPripremi);
    });
  });

  group('pravila koja zavise od drugih: konačno odlučuje baza, i kada pozivi stignu istovremeno', () {
    test('dva koordinatora istovremeno prihvataju poslednje mesto: prolazi tačno jedan', () async {
      await baza.execute("UPDATE ponude SET broj_mesta = 3 WHERE id = 'po-1'"); // 2 zauzeta, 1 slobodno
      final prvi = await tokenZa('koordinator1');
      final drugi = await tokenZa('koordinator1');

      final odgovori = await Future.wait([
        post(prvi, ApiPutanje.prihvatanje('p-11')),
        post(drugi, ApiPutanje.prihvatanje('p-13')),
      ]);

      expect(odgovori.map((o) => o.statusCode), unorderedEquals([200, 409]));
      expect(kodIz(odgovori.firstWhere((o) => o.statusCode == 409)), KodoviGresaka.nemaSlobodnihMesta);
      expect(await jednaVrednost("SELECT zauzeta_mesta FROM ponude WHERE id = 'po-1'"), 3);
      expect(
        await jednaVrednost("SELECT count(*) FROM prijave WHERE id IN ('p-11', 'p-13') AND stanje = 'prihvacena'"),
        1,
      );
    });

    test('ista prijava prihvaćena dva puta istovremeno: jednom 200, drugi put 409 invalid-transition', () async {
      final koordinator1 = await tokenZa('koordinator1');

      final odgovori = await Future.wait([
        post(koordinator1, ApiPutanje.prihvatanje('p-11')),
        post(koordinator1, ApiPutanje.prihvatanje('p-11')),
      ]);

      expect(odgovori.map((o) => o.statusCode), unorderedEquals([200, 409]));
      expect(kodIz(odgovori.firstWhere((o) => o.statusCode == 409)), KodoviGresaka.nedozvoljenPrelaz);
      expect(await jednaVrednost("SELECT zauzeta_mesta FROM ponude WHERE id = 'po-1'"), 3);
    });

    test('dve potvrde mesta za isti semestar istovremeno: potvrđeno je tačno jedno mesto', () async {
      await baza.execute(
        "UPDATE prijave SET stanje = 'prihvacena', stanje_kada = now(), odlucio = 'k-tuwien' WHERE id = 'p-2'",
      );
      await baza.execute("UPDATE ponude SET zauzeta_mesta = zauzeta_mesta + 1 WHERE id = 'po-4'");
      final telefon = await tokenZa('student1');
      final racunar = await tokenZa('student1');

      final odgovori = await Future.wait([
        post(telefon, ApiPutanje.potvrdaMesta('p-4')),
        post(racunar, ApiPutanje.potvrdaMesta('p-2')),
      ]);

      expect(odgovori.map((o) => o.statusCode), unorderedEquals([200, 409]));
      expect(
        await jednaVrednost(
          "SELECT count(*) FROM prijave WHERE id_studenta = 's-1' AND stanje = 'potvrdjena' "
          "AND vrsta_semestra = 'zimski' AND akademska_godina = '2027/28'",
        ),
        1,
      );
      expect(
        await jednaVrednost(
          "SELECT count(*) FROM prijave WHERE id_studenta = 's-1' AND vrsta_semestra = 'zimski' "
          "AND akademska_godina = '2027/28' AND stanje IN ('u_pripremi', 'poslata', 'na_listi_cekanja', 'prihvacena')",
        ),
        0,
      );
    });

    test('potvrda povlači ostale prijave za isti semestar i oslobađa mesta koja su one držale', () async {
      final odgovor = await post(await tokenZa('student1'), ApiPutanje.potvrdaMesta('p-4'));

      expect(odgovor.statusCode, 200);
      final promenjene = lista(odgovor);
      expect(promenjene.first['id'], 'p-4');
      expect(promenjene.skip(1).map((p) => (p['status']! as Map<String, Object?>)['kind']), everyElement('withdrawn'));
      expect(promenjene.skip(1).map((p) => p['id']).toSet(), {'p-2', 'p-8', 'p-9'});
      expect(await jednaVrednost("SELECT zauzeta_mesta FROM ponude WHERE id = 'po-1'"), 2);
    });

    test('povlačenje prihvaćene prijave oslobađa mesto', () async {
      final odgovor = await post(await tokenZa('student1'), ApiPutanje.odbijanjeMesta('p-4'));

      expect(odgovor.statusCode, 200);
      expect(await jednaVrednost("SELECT zauzeta_mesta FROM ponude WHERE id = 'po-1'"), 1);
    });
  });

  group('student: profil i sačuvane ponude', () {
    test('student menja svoj profil; prosek van opsega daje istu grešku kao ekran', () async {
      final student1 = await tokenZa('student1');
      final profil = objekat(await get(student1, ApiPutanje.student('s-1')));

      final dobar = await post(student1, ApiPutanje.profil('s-1'), {...profil, 'average': 905});
      final van = await post(student1, ApiPutanje.profil('s-1'), {...profil, 'average': 1050});
      final tudji = await post(await tokenZa('student2'), ApiPutanje.profil('s-1'), profil);

      expect(dobar.statusCode, 200);
      expect(await jednaVrednost("SELECT prosek::text FROM studenti WHERE id = 's-1'"), '9.05');
      expect((van.statusCode, kodIz(van)), (422, KodoviGresaka.prosekVanOpsega));
      expect(tudji.statusCode, 404);
    });

    test('sačuvane ponude: lista i promena, samo za sebe', () async {
      final student1 = await tokenZa('student1');

      final pre = await get(student1, ApiPutanje.sacuvanePonude('s-1'));
      final posle = await post(student1, ApiPutanje.promenaSacuvane('s-1', 'po-1'));
      final tudje = await get(await tokenZa('student2'), ApiPutanje.sacuvanePonude('s-1'));

      expect((jsonDecode(pre.body) as List<Object?>).toSet(), {'po-2', 'po-7', 'po-8'});
      expect((jsonDecode(posle.body) as List<Object?>).toSet(), {'po-1', 'po-2', 'po-7', 'po-8'});
      expect(tudje.statusCode, 404);
    });

    test('brisanje: samo povučena ili odbijena, i samo svoja', () async {
      final student1 = await tokenZa('student1');

      final povucena = await http.delete(putanja(ApiPutanje.prijava('p-6')), headers: kao(student1));
      final poslata = await http.delete(putanja(ApiPutanje.prijava('p-2')), headers: kao(student1));

      expect(povucena.statusCode, 204);
      expect((poslata.statusCode, kodIz(poslata)), (409, KodoviGresaka.brisanjeNijeMoguce));
      expect(await jednaVrednost('SELECT count(*) FROM prijave'), 26);
    });
  });
}