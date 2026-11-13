import 'package:api_contract/api_contract.dart';
import 'package:test/test.dart';

Map<String, Object?> ponudaSaServera() => {
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
};

Map<String, Object?> prijavaSaServera() => {
  'id': 'p-11',
  'studentId': 's-2',
  'offerId': 'po-1',
  'letter': 'Želim da studiram u Milanu.',
  'createdAt': '2026-11-05T23:00:00.000Z',
  'status': {'kind': 'submitted', 'at': '2026-11-07T23:00:00.000Z'},
};

void main() {
  group('ponuda', () {
    test('ponuda prolazi kroz JSON nepromenjena, sa brojem zauzetih mesta i prosekom u stotim delovima', () {
      final ponuda = PonudaDto.fromJson(ponudaSaServera());

      expect(PonudaDto.fromJson(ponuda.toJson()).toJson(), ponuda.toJson());
      expect(ponuda.zauzetaMesta, 2);
      expect(ponuda.minimalniProsekStotih, 800);
      expect(ponuda.rok, DateTime.utc(2027, 1, 4, 22, 59));
      expect(ponuda.toJson().containsKey('note'), isFalse);
    });

    test('stariji klijent cita ponudu koja nosi polje koje jos ne zna', () {
      final ponuda = PonudaDto.fromJson({...ponudaSaServera(), 'scholarship': 450});

      expect(ponuda.id, 'po-1');
    });


    test('prosek kao decimalni broj ili rok bez zone se odbijaju (strogo prema tipu)', () {
      expect(() => PonudaDto.fromJson({...ponudaSaServera(), 'minAverage': 8.5}), throwsFormatException);
      expect(
        () => PonudaDto.fromJson({...ponudaSaServera(), 'deadline': '2027-01-04T23:59:00'}),
        throwsFormatException,
      );
    });
  });

  group('prijava i stanje', () {
    test('prijava prolazi kroz JSON nepromenjena; stanje nosi svoje podatke', () {
      final prijava = PrijavaDto.fromJson(prijavaSaServera());

      expect(PrijavaDto.fromJson(prijava.toJson()).toJson(), prijava.toJson());
      expect(prijava.stanje.vrsta, StanjePrijaveDto.poslata);
      expect(prijava.stanje.kada, DateTime.utc(2026, 11, 7, 23));
    });

    test('odbijena prijava nosi ko je odlucio, kada i razlog', () {
      const stanje = StanjePrijaveDto(vrsta: StanjePrijaveDto.odbijena, odlucio: 'k-polimi', razlog: 'Popunjeno.');

      expect(stanje.toJson(), {'kind': 'rejected', 'by': 'k-polimi', 'reason': 'Popunjeno.'});
    });

    test('stariji klijent cita prijavu sa novim poljem', () {
      final prijava = PrijavaDto.fromJson({...prijavaSaServera(), 'priority': 1});

      expect(prijava.id, 'p-11');
    });

    test('nova prijava ne nosi studenta: server ga uzima iz tokena', () {
      const nova = NovaPrijavaDto(idPonude: 'po-1', motivacionoPismo: 'Pismo', posalji: true);

      expect(nova.toJson(), {'offerId': 'po-1', 'letter': 'Pismo', 'submit': true});
      expect(nova.toJson().containsKey('studentId'), isFalse);
      expect(NovaPrijavaDto.fromJson({'offerId': 'po-1', 'letter': 'Pismo'}).posalji, isFalse);
    });

    test('izmena i odbijanje prolaze kroz JSON', () {
      final izmena = IzmenaPrijaveDto.fromJson(
        const IzmenaPrijaveDto(motivacionoPismo: 'Novo', napomena: 'N', posalji: true).toJson(),
      );
      final odbijanje = OdbijanjeDto.fromJson(const OdbijanjeDto(razlog: 'Popunjeno.').toJson());

      expect((izmena.motivacionoPismo, izmena.napomena, izmena.posalji), ('Novo', 'N', true));
      expect(odbijanje.razlog, 'Popunjeno.');
    });
  });

  group('student', () {
    test('profil prolazi kroz JSON: prosek u stotim delovima, jezici kao mapa', () {
      const student = StudentDto(
        id: 's-1',
        ime: 'Andrej',
        prezime: 'Aleksić',
        brojIndeksa: 'RN 76/24',
        email: 'andrej@raf.rs',
        fakultet: 'RAF',
        smer: 'RN',
        godinaStudija: 4,
        prosekStotih: 874,
        znanjeJezika: {'english': 'B2'},
      );

      final procitan = StudentDto.fromJson(student.toJson());

      expect(procitan.toJson(), student.toJson());
      expect(student.toJson()['average'], 874);
      expect(student.toJson()['languages'], {'english': 'B2'});
    });

    test('nivo jezika koji nije tekst se odbija', () {
      final json = {
        'id': 's-1',
        'firstName': 'A',
        'lastName': 'B',
        'indexNumber': 'RN 1/24',
        'email': 'a@raf.rs',
        'faculty': 'RAF',
        'program': 'RN',
        'year': 1,
        'average': 874,
        'languages': {'english': 2},
      };

      expect(() => StudentDto.fromJson(json), throwsFormatException);
    });
  });

  group('greška sa podacima pravila', () {
    test('Problem Details nosi kod i podatke pravila, a prazna polja se ne salju', () {
      const problem = ProblemDto(
        status: 422,
        code: KodoviGresaka.previsePrijava,
        title: 'Too many active applications',
        max: 3,
      );

      expect(problem.toJson(), {
        'type': 'tag:raf.rs,2026:erasmusgo/problem/too-many-applications',
        'title': 'Too many active applications',
        'status': 422,
        'code': 'too-many-applications',
        'max': 3,
      });
    });

    test('podaci pravila prolaze kroz JSON nepromenjeni', () {
      final problem = ProblemDto(
        status: 409,
        code: KodoviGresaka.nedozvoljenPrelaz,
        title: 'Invalid transition',
        rok: DateTime.utc(2027, 1, 4),
        jezik: 'english',
        nivo: 'B2',
        nivoKorisnika: 'B1',
        iz: const StanjePrijaveDto(vrsta: StanjePrijaveDto.povucena),
        u: const StanjePrijaveDto(vrsta: StanjePrijaveDto.prihvacena),
        value: 1,
        min: 0,
        max: 2,
      );

      expect(ProblemDto.fromJson(problem.toJson()).toJson(), problem.toJson());
    });
  });

  test('putanje: verzija API-ja je u putanji, a id je deo putanje', () {
    expect(ApiPutanje.prihvatanje('p-11'), '/api/v1/applications/p-11/acceptance');
    expect(ApiPutanje.prijaveStudenta('s-1'), '/api/v1/students/s-1/applications');
    expect(ApiPutanje.prijaveUniverziteta('u-polimi'), '/api/v1/universities/u-polimi/applications');
    expect(ApiPutanje.promenaSacuvane('s-1', 'po-2'), '/api/v1/students/s-1/saved-offers/po-2/toggle');
  });
}
