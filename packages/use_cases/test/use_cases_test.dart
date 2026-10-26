import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'test_baza.dart';

const andrej = Korisnik(id: IdKorisnika('s-1'), korisnickoIme: 'andrej', uloga: Uloga.student);

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

Ponuda ponuda({String id = 'po-1', double minimalniProsek = 8.0}) => Ponuda(
  id: IdPonude(id),
  idUniverziteta: const IdUniverziteta('u-polimi'),
  oblast: 'Računarstvo',
  semestar: const Semestar(vrsta: VrstaSemestra.zimski, akademskaGodina: '2027/28'),
  brojMesta: 2,
  rok: DateTime(2026, 12, 15, 23, 59),
  minimalniProsek: minimalniProsek,
  zahtevJezika: const ZahtevJezika(jezik: Jezik.engleski, nivo: NivoJezika.b2),
  opis: 'Opis ponude.',
  objavio: const IdKorisnika('k-1'),
  objavljena: DateTime(2026, 10, 1),
);

final pismo = MotivacionoPismo.proveri('Želim da studiram u Milanu.').vrednostIliNull!;

Prijava prijava({String id = 'p-1', String idPonude = 'po-1', StanjePrijave stanje = const UPripremi()}) => Prijava(
  id: IdPrijave(id),
  idStudenta: andrej.id,
  idPonude: IdPonude(idPonude),
  motivacionoPismo: pismo,
  napravljena: DateTime(2026, 10, 20),
  stanje: stanje,
);

SacuvajPrijavu sacuvajPrijavu(TestBaza baza) => SacuvajPrijavu(ponude: baza, prijave: baza, studenti: baza, sat: sat);

void main() {
  group('UcitajPregled', () {
    test('vraća studenta, ponude i prijave iz portova', () async {
      final baza = TestBaza(student: student, ponude: [ponuda()], prijave: [prijava()]);
      final pregled = await UcitajPregled(ponude: baza, prijave: baza, studenti: baza, sat: sat)(andrej);
      expect(pregled.student, student);
      expect(pregled.ponude, hasLength(1));
      expect(pregled.mojePrijave, hasLength(1));
    });

    test('uslove i slobodna mesta za ekran računa domen', () async {
      final baza = TestBaza(
        student: student,
        ponude: [ponuda(minimalniProsek: 9.0)],
        prijave: [
          prijava(
            stanje: Prihvacena(odlucio: const IdKorisnika('k-1'), kada: sat.sada()),
          ),
        ],
      );
      final pregled = await UcitajPregled(ponude: baza, prijave: baza, studenti: baza, sat: sat)(andrej);
      final svaPonuda = pregled.ponude.single;
      expect(pregled.slobodnaMesta(svaPonuda), 1);
      expect(pregled.brojAktivnih, 1);
      expect(pregled.uslovi(svaPonuda).prosek, isFalse);
      expect(pregled.uslovi(svaPonuda).ishod.greskaIliNull, isA<NedovoljanProsek>());
    });

    test('greška porta prolazi do onoga ko je pozvao', () async {
      final baza = TestBaza(student: student)..greskaSledecegZahteva = true;
      final ucitaj = UcitajPregled(ponude: baza, prijave: baza, studenti: baza, sat: sat);
      await expectLater(ucitaj(andrej), throwsA(isA<GreskaRepozitorijuma>()));
    });
  });

  group('SacuvajPrijavu', () {
    test('nova prijava se čuva u pripremi', () async {
      final baza = TestBaza(student: student, ponude: [ponuda()]);
      final rezultat = await sacuvajPrijavu(baza)(ko: andrej, idPonude: const IdPonude('po-1'), pismo: pismo);
      expect(rezultat.vrednostIliNull?.stanje, isA<UPripremi>());
      expect(baza.prijave, hasLength(1));
    });

    test('slanje uz premali prosek vraća grešku iz domena i ništa ne čuva (P2)', () async {
      final baza = TestBaza(student: student, ponude: [ponuda(minimalniProsek: 9.0)]);
      final rezultat = await sacuvajPrijavu(baza)(
        ko: andrej,
        idPonude: const IdPonude('po-1'),
        pismo: pismo,
        posalji: true,
      );
      expect(rezultat.greskaIliNull, isA<NedovoljanProsek>());
      expect(baza.prijave, isEmpty);
    });

    test('slanje postojeće prijave je menja u poslatu', () async {
      final baza = TestBaza(student: student, ponude: [ponuda()], prijave: [prijava()]);
      final rezultat = await sacuvajPrijavu(baza)(
        ko: andrej,
        idPrijave: const IdPrijave('p-1'),
        pismo: pismo,
        posalji: true,
      );
      expect(rezultat.vrednostIliNull?.stanje, isA<Poslata>());
      expect(baza.prijave.single.stanje, isA<Poslata>());
    });
  });

  group('Akcije nad prijavom', () {
    test('povlačenje čuva povučenu prijavu', () async {
      final baza = TestBaza(
        student: student,
        prijave: [prijava(stanje: Poslata(kada: sat.sada()))],
      );
      final rezultat = await PovuciPrijavu(prijave: baza, sat: sat)(ko: andrej, id: const IdPrijave('p-1'));
      expect(rezultat.jeUspeh, isTrue);
      expect(baza.prijave.single.stanje, isA<Povucena>());
    });

    test('potvrda mesta povlači ostale prijave za isti semestar (P6)', () async {
      final baza = TestBaza(
        student: student,
        ponude: [
          ponuda(),
          ponuda(id: 'po-2'),
        ],
        prijave: [
          prijava(
            stanje: Prihvacena(odlucio: const IdKorisnika('k-1'), kada: sat.sada()),
          ),
          prijava(
            id: 'p-2',
            idPonude: 'po-2',
            stanje: Poslata(kada: sat.sada()),
          ),
        ],
      );
      final rezultat = await PotvrdiMesto(ponude: baza, prijave: baza, sat: sat)(
        ko: andrej,
        id: const IdPrijave('p-1'),
      );
      expect(rezultat.vrednostIliNull, hasLength(2));
      expect(baza.prijave.last.stanje, isA<Povucena>());
    });

    test('brisanje prijave u pripremi nije dozvoljeno', () async {
      final baza = TestBaza(student: student, prijave: [prijava()]);
      final rezultat = await ObrisiPrijavu(prijave: baza)(ko: andrej, id: const IdPrijave('p-1'));
      expect(rezultat.greskaIliNull, isA<BrisanjeNijeMoguce>());
      expect(baza.prijave, hasLength(1));
    });
  });
}
