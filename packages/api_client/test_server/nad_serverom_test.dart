library;

import 'dart:io';

import 'package:api_client/api_client.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

final adresa = Uri.parse(Platform.environment['SERVER_URL'] ?? 'http://localhost:8080');
const lozinka = 'erasmus-demo';
const sat = SistemskiSat();

final class Klijent {
  Klijent() : api = ApiKlijent(adresa: adresa, sesijaUKolacicu: false);

  final ApiKlijent api;
  late final ponude = HttpPonudaRepository(api);
  late final prijave = HttpPrijavaRepository(api);
  late final studenti = HttpStudentRepository(api);
  late final sesije = HttpSesijaRepository(api);

  Future<Korisnik> prijaviSe(String korisnickoIme) async =>
      (await PrijaviSe(sesije: sesije)(korisnickoIme: korisnickoIme, lozinka: lozinka))!;
}

void main() {
  test('ponude se čitaju bez prijave', () async {
    final ponude = await Klijent().ponude.ponude();

    expect(ponude, hasLength(11));
  });

  test('bez prijave: isti UcitajPregled daje samo javni deo (mobilna aplikacija pre prijave)', () async {
    final telefon = Klijent();

    final pregled = await UcitajPregled(
      ponude: telefon.ponude,
      prijave: telefon.prijave,
      studenti: telefon.studenti,
      sat: sat,
    )(null);

    expect(pregled.student, isNull);
    expect(pregled.ponude, hasLength(11));
    expect(pregled.mojePrijave, isEmpty);
    final milano = pregled.ponude.firstWhere((p) => p.id == const IdPonude('po-1'));
    expect(pregled.slobodnaMesta(milano), 2);
  });

  test('student: isti UcitajPregled kao na KT1, sada sa servera; samo svoje prijave', () async {
    final telefon = Klijent();
    final andrej = await telefon.prijaviSe('student1');

    final pregled = await UcitajPregled(
      ponude: telefon.ponude,
      prijave: telefon.prijave,
      studenti: telefon.studenti,
      sat: sat,
    )(andrej);

    expect(pregled.student?.ime, 'Andrej');
    expect(pregled.prijaveStudenta, hasLength(10));
    expect(pregled.prijaveStudenta.map((p) => p.idStudenta), everyElement(andrej.id));
    final milano = pregled.ponude.firstWhere((p) => p.id == const IdPonude('po-1'));
    expect(pregled.slobodnaMesta(milano), 2);
  });

  test('isto pravilo i ista greška kao na klijentu: četvrta aktivna prijava', () async {
    final telefon = Klijent();
    final andrej = await telefon.prijaviSe('student1');

    final rezultat =
        await SacuvajPrijavu(ponude: telefon.ponude, prijave: telefon.prijave, studenti: telefon.studenti, sat: sat)(
          ko: andrej,
          idPonude: const IdPonude('po-8'),
          pismo: MotivacionoPismo.proveri('Uppsala me zanima.').vrednostIliNull!,
          posalji: true,
        );

    expect(rezultat.greskaIliNull, const PrevisePrijava(3));
  });

  test('izmena već poslate prijave: novo pismo, prijava ostaje poslata', () async {
    final telefon = Klijent();
    final marko = await telefon.prijaviSe('student2');

    final rezultat =
        await SacuvajPrijavu(ponude: telefon.ponude, prijave: telefon.prijave, studenti: telefon.studenti, sat: sat)(
          ko: marko,
          idPrijave: const IdPrijave('p-25'),
          pismo: MotivacionoPismo.proveri('Dopunjeno pismo: TU München zbog mašinskog učenja.').vrednostIliNull!,
        );

    expect(rezultat.greskaIliNull, isNull);
    expect(rezultat.vrednostIliNull?.stanje, isA<Poslata>());
    expect(rezultat.vrednostIliNull?.motivacionoPismo.tekst, startsWith('Dopunjeno pismo'));
  });
  test('tuđ zapis: drugi student ne može da povuče Andrejevu prijavu', () async {
    final telefon = Klijent();
    final marko = await telefon.prijaviSe('student2');

    final rezultat = await PovuciPrijavu(ponude: telefon.ponude, prijave: telefon.prijave, sat: sat)(
      ko: marko,
      id: const IdPrijave('p-2'),
    );

    expect(rezultat.greskaIliNull, isA<NijePronadjeno>());
  });

  test('promena iz jednog klijenta vidi se u drugom posle ponovnog učitavanja', () async {
    final backoffice = Klijent();
    final telefon = Klijent();
    final koordinator = await backoffice.prijaviSe('koordinator1');
    final marko = await telefon.prijaviSe('student2');
    final ucitajMarka = UcitajPregled(
      ponude: telefon.ponude,
      prijave: telefon.prijave,
      studenti: telefon.studenti,
      sat: sat,
    );

    final pre = await ucitajMarka(marko);
    final prihvatanje = await PrihvatiPrijavu(ponude: backoffice.ponude, prijave: backoffice.prijave, sat: sat)(
      ko: koordinator,
      id: const IdPrijave('p-11'),
    );
    final posle = await ucitajMarka(marko);

    expect(pre.prijava(const IdPrijave('p-11'))?.stanje, isA<Poslata>());
    expect(prihvatanje.vrednostIliNull?.stanje, isA<Prihvacena>());
    expect(posle.prijava(const IdPrijave('p-11'))?.stanje, isA<Prihvacena>());
  });

  test('koordinator: isti UcitajPregledKoordinatora kao na KT1, sada sa servera', () async {
    final backoffice = Klijent();
    final koordinator = await backoffice.prijaviSe('koordinator1');

    final pregled = await UcitajPregledKoordinatora(
      ponude: backoffice.ponude,
      prijave: backoffice.prijave,
      studenti: backoffice.studenti,
      sat: sat,
    )(koordinator);

    expect(pregled.univerzitet.naziv, 'Politecnico di Milano');
    expect(pregled.ponude.map((p) => p.id.vrednost).toSet(), {'po-1', 'po-10', 'po-11'});
    expect(pregled.prijave.map((p) => p.stanje), isNot(contains(isA<UPripremi>())));
    expect(pregled.studenti, isNotEmpty);
  });

  test('odjava: posle nje niko nije prijavljen', () async {
    final telefon = Klijent();
    await telefon.prijaviSe('student1');

    expect(await ObnoviSesiju(sesije: telefon.sesije)(), isNotNull);
    await OdjaviSe(sesije: telefon.sesije)();
    expect(await ObnoviSesiju(sesije: telefon.sesije)(), isNull);
  });
}
