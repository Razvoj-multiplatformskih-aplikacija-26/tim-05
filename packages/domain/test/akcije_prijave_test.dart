import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'pomocno.dart';

void main() {
  group('Slanje prijave', () {
    test('student salje svoju prijavu iz pripreme', () {
      final rezultat = posaljiPrijavu(
        prijava(),
        ko: andrej,
        student: studentAndrej,
        ponuda: ponuda(),
        svePrijave: const [],
        sada: sada,
      );
      expect(rezultat.vrednostIliNull?.stanje, isA<Poslata>());
    });

    test('student ne moze da posalje tudju prijavu', () {
      final rezultat = posaljiPrijavu(
        prijava(idStudenta: 's-2'),
        ko: andrej,
        student: studentAndrej,
        ponuda: ponuda(),
        svePrijave: const [],
        sada: sada,
      );
      expect(rezultat.greskaIliNull, isA<NemaPravo>());
    });
  });

  group('Povlacenje i izmena', () {
    test('odbijena prijava ne moze da se povuce', () {
      final odbijena = prijava(
        stanje: Odbijena(odlucio: koordinatorMilano.id, kada: sada, razlog: ''),
      );
      expect(povuciPrijavu(odbijena, ko: andrej, sada: sada).greskaIliNull, isA<NedozvoljenPrelaz>());
    });

    test('prihvacena prijava ne moze da se menja', () {
      final prihvacena = prijava(
        stanje: Prihvacena(odlucio: koordinatorMilano.id, kada: sada),
      );
      final rezultat = izmeniPrijavu(prihvacena, ko: andrej, motivacionoPismo: pismo);
      expect(rezultat.greskaIliNull, isA<IzmenaNijeMoguca>());
    });
  });

  group('Prihvatanje (prihvacenih ne vise od broja mesta)', () {
    test('koordinator prihvata dok ima mesta', () {
      final rezultat = prihvatiPrijavu(
        prijava(stanje: Poslata(kada: sada)),
        ko: koordinatorMilano,
        ponuda: ponuda(brojMesta: 2),
        svePrijave: const [],
        sada: sada,
      );
      expect(rezultat.vrednostIliNull?.stanje, isA<Prihvacena>());
    });

    test('kad su mesta popunjena, prihvatanje nije moguce', () {
      final popunjeno = [
        prijava(
          id: 'p-8',
          idStudenta: 's-8',
          stanje: Prihvacena(odlucio: koordinatorMilano.id, kada: sada),
        ),
        prijava(
          id: 'p-9',
          idStudenta: 's-9',
          stanje: Potvrdjena(kada: sada),
        ),
      ];
      final rezultat = prihvatiPrijavu(
        prijava(stanje: Poslata(kada: sada)),
        ko: koordinatorMilano,
        ponuda: ponuda(brojMesta: 2),
        svePrijave: popunjeno,
        sada: sada,
      );
      expect(rezultat.greskaIliNull, isA<NemaSlobodnihMesta>());
    });

    test('koordinator drugog univerziteta nema pravo da odlucuje', () {
      final rezultat = prihvatiPrijavu(
        prijava(stanje: Poslata(kada: sada)),
        ko: koordinatorBec,
        ponuda: ponuda(),
        svePrijave: const [],
        sada: sada,
      );
      expect(rezultat.greskaIliNull, isA<NemaPravo>());
    });
  });

group('Potvrda mesta (samo jedno mesto po semestru, ostale za taj semestar se povlace)', () {
    const zimski = Semestar(vrsta: VrstaSemestra.zimski, akademskaGodina: '2027/28');
    const letnji = Semestar(vrsta: VrstaSemestra.letnji, akademskaGodina: '2026/27');
    final ponude = [
      ponuda(id: 'po-1', semestar: zimski),
      ponuda(id: 'po-2', semestar: zimski),
      ponuda(id: 'po-3', semestar: zimski),
      ponuda(id: 'po-5', semestar: letnji),
    ];
    final milano = ponude.first;
    final prihvacena = prijava(id: 'p-1', idPonude: 'po-1', stanje: Prihvacena(odlucio: koordinatorMilano.id, kada: sada));

    test('povlaci ostale prijave za isti semestar, a ne dira zavrsene i tudje', () {
      final poslata = prijava(id: 'p-2', idPonude: 'po-2', stanje: Poslata(kada: sada));
      final odbijena = prijava(id: 'p-3', idPonude: 'po-3', stanje: Odbijena(odlucio: koordinatorMilano.id, kada: sada, razlog: ''));
      final markova = prijava(id: 'p-4', idStudenta: 's-2', idPonude: 'po-2', stanje: Poslata(kada: sada));

      final izmenjene = potvrdiMesto(
        prihvacena,
        ko: andrej,
        ponuda: milano,
        ponude: ponude,
        svePrijave: [prihvacena, poslata, odbijena, markova],
        sada: sada,
      ).vrednostIliNull!;

      expect(izmenjene, hasLength(2));
      expect(izmenjene[0].stanje, isA<Potvrdjena>());
      expect(izmenjene[1].id, poslata.id);
      expect(izmenjene[1].stanje, isA<Povucena>());
    });

    test('prijava za drugi semestar ostaje', () {
      final letnja = prijava(id: 'p-5', idPonude: 'po-5', stanje: Poslata(kada: sada));
      final izmenjene = potvrdiMesto(
        prihvacena,
        ko: andrej,
        ponuda: milano,
        ponude: ponude,
        svePrijave: [prihvacena, letnja],
        sada: sada,
      ).vrednostIliNull!;
      expect(izmenjene, hasLength(1));
    });

    test('drugo mesto u istom semestru ne moze da se potvrdi', () {
      final vecPotvrdjena = prijava(id: 'p-2', idPonude: 'po-2', stanje: Potvrdjena(kada: sada));
      final rezultat = potvrdiMesto(
        prihvacena,
        ko: andrej,
        ponuda: milano,
        ponude: ponude,
        svePrijave: [vecPotvrdjena, prihvacena],
        sada: sada,
      );
      expect(rezultat.greskaIliNull, isA<VecPotvrdjenoMesto>());
    });

    test('mesto u drugom semestru moze da se potvrdi', () {
      final letnjaPotvrdjena = prijava(id: 'p-5', idPonude: 'po-5', stanje: Potvrdjena(kada: sada));
      final rezultat = potvrdiMesto(
        prihvacena,
        ko: andrej,
        ponuda: milano,
        ponude: ponude,
        svePrijave: [letnjaPotvrdjena, prihvacena],
        sada: sada,
      );
      expect(rezultat.jeUspeh, isTrue);
    });

    test('prijava koja nije prihvacena ne moze da se potvrdi', () {
      final rezultat = potvrdiMesto(
        prijava(stanje: Poslata(kada: sada)),
        ko: andrej,
        ponuda: milano,
        ponude: ponude,
        svePrijave: const [],
        sada: sada,
      );
      expect(rezultat.greskaIliNull, isA<NedozvoljenPrelaz>());
    });
  });

    group('Brisanje (README: samo odbijena ili povučena)', () {
    test('student briše svoju povučenu prijavu', () {
      expect(obrisiPrijavu(prijava(stanje: Povucena(kada: sada)), ko: andrej).jeUspeh, isTrue);
    });

    test('prijava u pripremi ne može da se obriše', () {
      final rezultat = obrisiPrijavu(prijava(), ko: andrej);
      expect(rezultat.greskaIliNull, isA<BrisanjeNijeMoguce>());
    });

    test('student ne može da obriše tuđu prijavu', () {
      final rezultat = obrisiPrijavu(prijava(idStudenta: 's-2', stanje: Povucena(kada: sada)), ko: andrej);
      expect(rezultat.greskaIliNull, isA<NemaPravo>());
    });
  });

}
