import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'test_baza.dart';


const koordinatorMilano = Korisnik(
  id: IdKorisnika('k-1'),
  korisnickoIme: 'koordinator.milano',
  uloga: Uloga.koordinator,
  idUniverziteta: IdUniverziteta('u-polimi'),
);

const koordinatorBec = Korisnik(
  id: IdKorisnika('k-2'),
  korisnickoIme: 'koordinator.bec',
  uloga: Uloga.koordinator,
  idUniverziteta: IdUniverziteta('u-tuwien'),
);

const student = Student(
  id: IdKorisnika('s-1'),
  ime: 'Andrej',
  prezime: 'Aleksić',
  brojIndeksa: 'RN 76/24',
  email: 'andrej@raf.rs',
  fakultet: 'Računarski fakultet',
  smer: 'Računarske nauke',
  godinaStudija: 4,
  prosek: 8.74,
  znanjeJezika: {Jezik.engleski: NivoJezika.b2},
);

final sat = FiksniSat(DateTime(2026, 11, 1, 12));

final pismo = MotivacionoPismo.proveri('Želim da studiram u Milanu.').vrednostIliNull!;

Ponuda ponuda({String id = 'po-1'}) => Ponuda(
  id: IdPonude(id),
  idUniverziteta: const IdUniverziteta('u-polimi'),
  oblast: 'Računarstvo',
  semestar: const Semestar(vrsta: VrstaSemestra.zimski, akademskaGodina: '2027/28'),
  brojMesta: 2,
  rok: DateTime(2026, 12, 15, 23, 59),
  minimalniProsek: 8.0,
  zahtevJezika: const ZahtevJezika(jezik: Jezik.engleski, nivo: NivoJezika.b2),
  opis: 'Opis ponude.',
  objavio: const IdKorisnika('k-1'),
  objavljena: DateTime(2026, 10, 1),
);

Prijava prijava(String id, {String idPonude = 'po-1', String idStudenta = 's-1', StanjePrijave? stanje}) => Prijava(
  id: IdPrijave(id),
  idStudenta: IdKorisnika(idStudenta),
  idPonude: IdPonude(idPonude),
  motivacionoPismo: pismo,
  napravljena: DateTime(2026, 10, 20),
  stanje: stanje ?? Poslata(kada: DateTime(2026, 10, 21)),
);

final prihvacena = Prihvacena(odlucio: koordinatorMilano.id, kada: DateTime(2026, 10, 22));

void main() {
  group('UcitajPregledKoordinatora', () {
    test('vraca prijave na ponude svog univerziteta, bez prijava u pripremi', () async {
      final baza = TestBaza(
        student: student,
        ponude: [ponuda(), ponuda(id: 'po-2')],
        prijave: [prijava('p-1'), prijava('p-2', idPonude: 'po-2'), prijava('p-3', stanje: const UPripremi())],
      );
      final ucitaj = UcitajPregledKoordinatora(ponude: baza, prijave: baza, studenti: baza, sat: sat);

      final pregled = await ucitaj(koordinatorMilano);

      expect(pregled.univerzitet.id, const IdUniverziteta('u-polimi'));
      expect(pregled.ponude, hasLength(2));
      expect(pregled.prijave.map((p) => p.id), [const IdPrijave('p-1'), const IdPrijave('p-2')]);
      expect(pregled.student(student.id), student);
      expect(pregled.slobodnaMesta(pregled.ponude.first), 2);
    });

    test('greska porta prolazi do onoga ko je pozvao', () async {
      final baza = TestBaza(student: student, ponude: [ponuda()])..greskaSledecegZahteva = true;
      final ucitaj = UcitajPregledKoordinatora(ponude: baza, prijave: baza, studenti: baza, sat: sat);
      await expectLater(ucitaj(koordinatorMilano), throwsA(isA<GreskaRepozitorijuma>()));
    });
  });

  group('Akcije koordinatora', () {
    test('prihvatanje cuva prihvacenu prijavu', () async {
      final baza = TestBaza(student: student, ponude: [ponuda()], prijave: [prijava('p-1')]);
      final rezultat = await PrihvatiPrijavu(ponude: baza, prijave: baza, sat: sat)(
        ko: koordinatorMilano,
        id: const IdPrijave('p-1'),
      );
      expect(rezultat.vrednostIliNull?.stanje, isA<Prihvacena>());
      expect(baza.prijave.single.stanje, isA<Prihvacena>());
    });

    test('kad su mesta popunjena, prihvatanje vraca gresku iz domena i nista ne cuva', () async {
      final baza = TestBaza(
        student: student,
        ponude: [ponuda()],
        prijave: [
          prijava('p-8', idStudenta: 's-8', stanje: prihvacena),
          prijava('p-9', idStudenta: 's-9', stanje: prihvacena),
          prijava('p-1'),
        ],
      );
      final rezultat = await PrihvatiPrijavu(ponude: baza, prijave: baza, sat: sat)(
        ko: koordinatorMilano,
        id: const IdPrijave('p-1'),
      );
      expect(rezultat.greskaIliNull, isA<NemaSlobodnihMesta>());
      expect(baza.prijave.last.stanje, isA<Poslata>());
    });

    test('koordinator drugog univerziteta nema pravo da odlucuje', () async {
      final baza = TestBaza(student: student, ponude: [ponuda()], prijave: [prijava('p-1')]);
      final rezultat = await StaviNaListuCekanja(ponude: baza, prijave: baza, sat: sat)(
        ko: koordinatorBec,
        id: const IdPrijave('p-1'),
      );
      expect(rezultat.greskaIliNull, isA<NemaPravo>());
      expect(baza.prijave.single.stanje, isA<Poslata>());
    });

    test('odbijanje cuva razlog', () async {
      final baza = TestBaza(student: student, ponude: [ponuda()], prijave: [prijava('p-1')]);
      await OdbijPrijavu(ponude: baza, prijave: baza, sat: sat)(
        ko: koordinatorMilano,
        id: const IdPrijave('p-1'),
        razlog: 'Mesta su popunjena.',
      );
      expect(baza.prijave.single.stanje, isA<Odbijena>().having((s) => s.razlog, 'razlog', 'Mesta su popunjena.'));
    });
  });
}
