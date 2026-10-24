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

  group('Potvrda mesta (samo jedno mesto, ostale se povlace)', () {
    test('potvrda povlaci ostale aktivne prijave studenta, a ne dira zavrsene', () {
      final prihvacena = prijava(
        id: 'p-1',
        idPonude: 'po-1',
        stanje: Prihvacena(odlucio: koordinatorMilano.id, kada: sada),
      );
      final poslata = prijava(
        id: 'p-2',
        idPonude: 'po-2',
        stanje: Poslata(kada: sada),
      );
      final odbijena = prijava(
        id: 'p-3',
        idPonude: 'po-3',
        stanje: Odbijena(odlucio: koordinatorMilano.id, kada: sada, razlog: ''),
      );
      final markova = prijava(
        id: 'p-4',
        idStudenta: 's-2',
        idPonude: 'po-2',
        stanje: Poslata(kada: sada),
      );

      final rezultat = potvrdiMesto(
        prihvacena,
        ko: andrej,
        svePrijave: [prihvacena, poslata, odbijena, markova],
        sada: sada,
      );
      final izmenjene = rezultat.vrednostIliNull!;

      expect(izmenjene, hasLength(2));
      expect(izmenjene[0].id, prihvacena.id);
      expect(izmenjene[0].stanje, isA<Potvrdjena>());
      expect(izmenjene[1].id, poslata.id);
      expect(izmenjene[1].stanje, isA<Povucena>());
    });

    test('prijava koja nije prihvacena ne moze da se potvrdi', () {
      final rezultat = potvrdiMesto(
        prijava(stanje: Poslata(kada: sada)),
        ko: andrej,
        svePrijave: const [],
        sada: sada,
      );
      expect(rezultat.greskaIliNull, isA<NedozvoljenPrelaz>());
    });
  });
}
