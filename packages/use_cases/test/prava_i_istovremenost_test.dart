import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'test_baza.dart';

const andrej = Korisnik(id: IdKorisnika('s-1'), korisnickoIme: 'student1', uloga: Uloga.student);
const marko = Korisnik(id: IdKorisnika('s-2'), korisnickoIme: 'student2', uloga: Uloga.student);
const koordinatorMilano = Korisnik(
  id: IdKorisnika('k-polimi'),
  korisnickoIme: 'koordinator1',
  uloga: Uloga.koordinator,
  idUniverziteta: IdUniverziteta('u-polimi'),
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

final ponuda = Ponuda(
  id: const IdPonude('po-1'),
  idUniverziteta: const IdUniverziteta('u-polimi'),
  oblast: 'Računarstvo',
  semestar: const Semestar(vrsta: VrstaSemestra.zimski, akademskaGodina: '2027/28'),
  brojMesta: 3,
  rok: DateTime(2026, 12, 15, 23, 59),
  minimalniProsek: 8.0,
  zahtevJezika: const ZahtevJezika(jezik: Jezik.engleski, nivo: NivoJezika.b2),
  opis: 'Opis ponude.',
  objavio: const IdKorisnika('k-polimi'),
  objavljena: DateTime(2026, 10, 1),
);

Prijava prijava(String id, {String idStudenta = 's-1', StanjePrijave? stanje}) => Prijava(
  id: IdPrijave(id),
  idStudenta: IdKorisnika(idStudenta),
  idPonude: const IdPonude('po-1'),
  motivacionoPismo: pismo,
  napravljena: DateTime(2026, 10, 20),
  stanje: stanje ?? Poslata(kada: DateTime(2026, 10, 21)),
);

final prihvacena = Prihvacena(odlucio: koordinatorMilano.id, kada: DateTime(2026, 10, 22));

TestBaza baza(List<Prijava> prijave) => TestBaza(student: student, ponude: [ponuda], prijave: prijave);

void main() {
  group('tudj zapis: ko ne sme da vidi prijavu, za njega ona ne postoji', () {
    test('drugi student ne moze da povuce tudju prijavu: NijePronadjeno i nista se ne menja', () async {
      final b = baza([prijava('p-1')]);

      final rezultat = await PovuciPrijavu(ponude: b, prijave: b, sat: sat)(ko: marko, id: const IdPrijave('p-1'));

      expect(rezultat.greskaIliNull, isA<NijePronadjeno>());
      expect(b.prijave.single.stanje, isA<Poslata>());
    });

    test('drugi student ne moze da izmeni ni da obrise tudju prijavu', () async {
      final b = baza([prijava('p-1', stanje: const UPripremi()), prijava('p-2', stanje: Povucena(kada: sat.sada()))]);

      final izmena = await SacuvajPrijavu(ponude: b, prijave: b, studenti: b, sat: sat)(
        ko: marko,
        idPrijave: const IdPrijave('p-1'),
        pismo: pismo,
      );
      final brisanje = await ObrisiPrijavu(ponude: b, prijave: b)(ko: marko, id: const IdPrijave('p-2'));

      expect(izmena.greskaIliNull, isA<NijePronadjeno>());
      expect(brisanje.greskaIliNull, isA<NijePronadjeno>());
      expect(b.prijave, hasLength(2));
    });

    test('koordinator ne vidi prijavu koja je jos u pripremi', () async {
      final b = baza([prijava('p-1', stanje: const UPripremi())]);

      final rezultat = await PrihvatiPrijavu(ponude: b, prijave: b, sat: sat)(
        ko: koordinatorMilano,
        id: const IdPrijave('p-1'),
      );

      expect(rezultat.greskaIliNull, isA<NijePronadjeno>());
    });
  });

  group('uloga koja ne sme akciju: NemaPravo (403), i nista se ne menja', () {
    test('student ne moze sam da prihvati svoju prijavu', () async {
      final b = baza([prijava('p-1')]);

      final rezultat = await PrihvatiPrijavu(ponude: b, prijave: b, sat: sat)(ko: andrej, id: const IdPrijave('p-1'));

      expect(rezultat.greskaIliNull, isA<NemaPravo>());
      expect(b.prijave.single.stanje, isA<Poslata>());
    });

    test('koordinator ne moze da povuce prijavu umesto studenta', () async {
      final b = baza([prijava('p-1')]);

      final rezultat = await PovuciPrijavu(ponude: b, prijave: b, sat: sat)(
        ko: koordinatorMilano,
        id: const IdPrijave('p-1'),
      );

      expect(rezultat.greskaIliNull, isA<NemaPravo>());
      expect(b.prijave.single.stanje, isA<Poslata>());
    });
  });

  group('zakasneli klijent: upis samo ako se stanje nije promenilo', () {
    test('student je povukao prijavu dok je koordinator odlucivao: koordinator dobija razlog za novo stanje', () async {
      final b = baza([prijava('p-1')]);
      b.preSledecegUpisa = (baza) => baza.postavi(prijava('p-1', stanje: Povucena(kada: sat.sada())));

      final rezultat = await PrihvatiPrijavu(ponude: b, prijave: b, sat: sat)(
        ko: koordinatorMilano,
        id: const IdPrijave('p-1'),
      );

      expect(rezultat.greskaIliNull, isA<NedozvoljenPrelaz>().having((g) => g.iz, 'iz', isA<Povucena>()));
      expect(b.prijave.single.stanje, isA<Povucena>());
    });

    test('ako novo stanje i dalje dozvoljava akciju, ponovljen pokusaj uspeva nad svezom prijavom', () async {
      final b = baza([prijava('p-1')]);
      b.preSledecegUpisa = (baza) => baza.postavi(
        prijava(
          'p-1',
          stanje: NaListiCekanja(odlucio: koordinatorMilano.id, kada: sat.sada()),
        ),
      );

      final rezultat = await PrihvatiPrijavu(ponude: b, prijave: b, sat: sat)(
        ko: koordinatorMilano,
        id: const IdPrijave('p-1'),
      );

      expect(rezultat.vrednostIliNull?.stanje, isA<Prihvacena>());
      expect(b.prijave.single.stanje, isA<Prihvacena>());
    });

    test('potvrda mesta koje je u medjuvremenu povuceno se odbija i nista ne menja', () async {
      final b = baza([prijava('p-1', stanje: prihvacena)]);
      b.preSledecegUpisa = (baza) => baza.postavi(prijava('p-1', stanje: Povucena(kada: sat.sada())));

      final rezultat = await PotvrdiMesto(ponude: b, prijave: b, sat: sat)(ko: andrej, id: const IdPrijave('p-1'));

      expect(rezultat.greskaIliNull, isA<NedozvoljenPrelaz>());
      expect(b.prijave.single.stanje, isA<Povucena>());
    });
  });

  group('sta student dobija', () {
    test('pregled studenta sadrzi samo njegove prijave, a slobodna mesta dolaze iz broja zauzetih', () async {
      final b = baza([
        prijava('p-1'),
        prijava('p-2', idStudenta: 's-2', stanje: prihvacena),
        prijava(
          'p-3',
          idStudenta: 's-3',
          stanje: Potvrdjena(kada: sat.sada()),
        ),
      ]);

      final pregled = await UcitajPregled(ponude: b, prijave: b, studenti: b, sat: sat)(andrej);

      expect(pregled.prijaveStudenta.map((p) => p.id), [const IdPrijave('p-1')]);
      expect(pregled.zauzetaMesta[ponuda.id], 2);
      expect(pregled.slobodnaMesta(ponuda), 1);
    });
  });
}
