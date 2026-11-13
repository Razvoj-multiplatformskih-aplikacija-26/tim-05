import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

final kada = DateTime(2026, 11, 5, 10, 30);
const koordinator = IdKorisnika('k-polimi');

final ponuda = Ponuda(
  id: const IdPonude('po-1'),
  idUniverziteta: const IdUniverziteta('u-polimi'),
  oblast: 'Računarstvo',
  semestar: const Semestar(vrsta: VrstaSemestra.zimski, akademskaGodina: '2027/28'),
  brojMesta: 4,
  rok: DateTime(2027, 1, 4, 23, 59),
  minimalniProsek: 8.0,
  zahtevJezika: const ZahtevJezika(jezik: Jezik.engleski, nivo: NivoJezika.b2),
  opis: 'Opis.',
  napomena: 'Smeštaj nije obezbeđen.',
  objavio: koordinator,
  objavljena: DateTime(2026, 11, 9),
);

const student = Student(
  id: IdKorisnika('s-1'),
  ime: 'Andrej',
  prezime: 'Aleksić',
  brojIndeksa: 'RN 76/24',
  email: 'andrej@raf.rs',
  fakultet: 'Računarski fakultet, Beograd',
  smer: 'Računarske nauke',
  godinaStudija: 4,
  prosek: 8.74,
  znanjeJezika: {Jezik.engleski: NivoJezika.b2, Jezik.italijanski: NivoJezika.a2},
);

Prijava prijava(StanjePrijave stanje) => Prijava(
  id: const IdPrijave('p-1'),
  idStudenta: student.id,
  idPonude: ponuda.id,
  motivacionoPismo: MotivacionoPismo.proveri('Želim da studiram u Milanu.').vrednostIliNull!,
  napomena: 'Napomena',
  napravljena: DateTime(2026, 11, 1, 9),
  stanje: stanje,
);

final svaStanja = <StanjePrijave>[
  const UPripremi(),
  Poslata(kada: kada),
  NaListiCekanja(odlucio: koordinator, kada: kada),
  Prihvacena(odlucio: koordinator, kada: kada),
  Odbijena(odlucio: koordinator, kada: kada, razlog: 'Mesta su popunjena.'),
  Potvrdjena(kada: kada),
  Povucena(kada: kada),
];

final sveGreske = <GreskaDomena>[
  const PismoPrazno(),
  const PismoPredugacko(1501),
  RokIstekao(DateTime(2026, 11, 1, 23, 59)),
  const NedovoljanProsek(trazeni: 8.0, studentov: 7.85),
  const NedovoljanJezik(
    trazeni: ZahtevJezika(jezik: Jezik.engleski, nivo: NivoJezika.c1),
    studentov: NivoJezika.b2,
  ),
  const NedovoljanJezik(
    trazeni: ZahtevJezika(jezik: Jezik.italijanski, nivo: NivoJezika.b1),
  ),
  const PrevisePrijava(3),
  const NemaSlobodnihMesta(),
  const NemaPravo(),
  const NijePronadjeno(),
  NedozvoljenPrelaz(
    iz: Povucena(kada: kada),
    u: Prihvacena(odlucio: koordinator, kada: kada),
  ),
  const IzmenaNijeMoguca(),
  const VecPotvrdjenoMesto(),
  const BrisanjeNijeMoguce(),
  const ProsekNijeBroj(),
  const ProsekVanOpsega(),
  const VecPostojiPrijava(),
];

void main() {
  group('domen -> ugovor -> JSON -> ugovor -> domen: isti objekat', () {
    test('univerzitet', () {
      const univerzitet = Univerzitet(
        id: IdUniverziteta('u-polimi'),
        naziv: 'Politecnico di Milano',
        grad: 'Milano',
        drzava: 'Italija',
        oznakaDrzave: 'IT',
      );
      final kroz = UniverzitetDto.fromJson(univerzitet.toDto().toJson()).toDomain();

      expect(
        (kroz.id, kroz.naziv, kroz.grad, kroz.drzava, kroz.oznakaDrzave),
        (univerzitet.id, univerzitet.naziv, univerzitet.grad, univerzitet.drzava, univerzitet.oznakaDrzave),
      );
    });

    test('ponuda, sa svim poljima, i broj zauzetih mesta', () {
      final dto = PonudaDto.fromJson(ponuda.toDto(zauzeto: 2).toJson());
      final kroz = dto.toDomain();

      expect(kroz.id, ponuda.id);
      expect(kroz.idUniverziteta, ponuda.idUniverziteta);
      expect(kroz.oblast, ponuda.oblast);
      expect(kroz.semestar, ponuda.semestar);
      expect(kroz.brojMesta, ponuda.brojMesta);
      expect(kroz.rok, ponuda.rok);
      expect(kroz.minimalniProsek, ponuda.minimalniProsek);
      expect(kroz.zahtevJezika, ponuda.zahtevJezika);
      expect(kroz.opis, ponuda.opis);
      expect(kroz.napomena, ponuda.napomena);
      expect(kroz.objavio, ponuda.objavio);
      expect(kroz.objavljena, ponuda.objavljena);
      expect(zauzetaMestaIz([dto]), {ponuda.id: 2});
    });

    test('student, sa prosekom bez gubitka tacnosti', () {
      final kroz = StudentDto.fromJson(student.toDto().toJson()).toDomain();

      expect(kroz.vrednostIliNull, student);
      expect(student.toDto().prosekStotih, 874);
    });

    for (final stanje in svaStanja) {
      test('prijava u stanju ${stanje.runtimeType}', () {
        final original = prijava(stanje);

        final kroz = PrijavaDto.fromJson(original.toDto().toJson()).toDomain();

        expect(kroz, original);
      });
    }
  });

  group('vreme', () {
    test('na mrezi je vreme u UTC-u, a u domenu se vraca kao lokalno', () {
      final dto = ponuda.toDto(zauzeto: 0);

      expect(dto.toJson()['deadline'], ponuda.rok.toUtc().toIso8601String());
      expect(dto.toDomain().rok.isUtc, isFalse);
    });
  });

  group('zahtevi klijenta', () {
    test('nova prijava u pripremi salje submit: false, a poslata submit: true', () {
      expect(prijava(const UPripremi()).toNovaDto().posalji, isFalse);
      expect(prijava(Poslata(kada: kada)).toNovaDto().posalji, isTrue);
      expect(prijava(Poslata(kada: kada)).toIzmenaDto().posalji, isTrue);
      expect(prijava(const UPripremi()).toNovaDto().idPonude, 'po-1');
    });
  });

  group('greške', () {
    for (final greska in sveGreske) {
      test('${greska.runtimeType} ima svoj kod i vraca se kao ista greska', () {
        final problem = ProblemDto.fromJson(greska.toProblem().toJson());

        expect(problem.toDomainError(), greska);
      });
    }

    test('svaka vrsta greske ima svoj kod', () {
      final kodovi = {for (final greska in sveGreske) greska.toProblem().code};

      expect(kodovi, hasLength(sveGreske.map((g) => g.runtimeType).toSet().length));
    });

    test('statusi: pravilo 422, sukob sa stanjem 409, uloga 403, nema zapisa 404', () {
      expect(const PismoPrazno().toProblem().status, 422);
      expect(const PrevisePrijava(3).toProblem().status, 422);
      expect(const NemaSlobodnihMesta().toProblem().status, 409);
      expect(
        NedozvoljenPrelaz(
          iz: Povucena(kada: kada),
          u: Poslata(kada: kada),
        ).toProblem().status,
        409,
      );
      expect(const NemaPravo().toProblem().status, 403);
      expect(const NijePronadjeno().toProblem().status, 404);
    });

    test('greska nosi podatke pravila, a ne poruku', () {
      final problem = const PrevisePrijava(3).toProblem().toJson();

      expect(problem['max'], 3);
      expect(problem.values, isNot(contains(contains('aktivne'))));
    });

    test('nepoznat kod (novo pravilo na serveru) daje null, a ne gresku', () {
      const novo = ProblemDto(status: 422, code: 'too-many-applications-per-country', title: 'New rule', max: 2);

      expect(novo.toDomainError(), isNull);
    });

    test('poznat kod bez podataka pravila daje null', () {
      const bezGranice = ProblemDto(status: 422, code: KodoviGresaka.previsePrijava, title: '');
      const nepoznatJezik = ProblemDto(
        status: 422,
        code: KodoviGresaka.nedovoljanJezik,
        title: '',
        jezik: 'klingon',
        nivo: 'B2',
      );

      expect(bezGranice.toDomainError(), isNull);
      expect(nepoznatJezik.toDomainError(), isNull);
    });
  });

  group('vrednosti koje ne odgovaraju ugovoru ili pravilu', () {
    test('nepoznato stanje ili stanje bez svojih podataka je FormatException', () {
      expect(() => const StanjePrijaveDto(vrsta: 'archived').toDomain(), throwsFormatException);
      expect(
        () => const StanjePrijaveDto(vrsta: StanjePrijaveDto.odbijena, odlucio: 'k').toDomain(),
        throwsFormatException,
      );
    });

    test('nepoznat jezik, nivo ili vrsta semestra je FormatException', () {
      expect(() => const ZahtevJezikaDto(jezik: 'klingon', nivo: 'B2').toDomain(), throwsFormatException);
      expect(() => const ZahtevJezikaDto(jezik: 'english', nivo: 'B3').toDomain(), throwsFormatException);
      expect(() => const SemestarDto(vrsta: 'spring', akademskaGodina: '2027/28').toDomain(), throwsFormatException);
    });

    test('prosek van opsega na mrezi daje istu gresku kao unos na ekranu', () {
      final dto = student.toDto();
      final van = StudentDto(
        id: dto.id,
        ime: dto.ime,
        prezime: dto.prezime,
        brojIndeksa: dto.brojIndeksa,
        email: dto.email,
        fakultet: dto.fakultet,
        smer: dto.smer,
        godinaStudija: dto.godinaStudija,
        prosekStotih: 1050,
        znanjeJezika: dto.znanjeJezika,
      );

      expect(van.toDomain().greskaIliNull, isA<ProsekVanOpsega>());
    });

    test('prijava sa praznim pismom ne moze da stigne kao gotova prijava', () {
      final dto = PrijavaDto.fromJson({...prijava(const UPripremi()).toDto().toJson(), 'letter': '   '});

      expect(dto.toDomain, throwsFormatException);
    });
  });
}
