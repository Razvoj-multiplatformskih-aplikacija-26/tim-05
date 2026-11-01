import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'pomocno.dart';

void main() {
  group('Uslovi ponude (rok, prosek, jezik, najvise 3 aktivne)', () {
    test('student koji ispunjava sve uslove prolazi', () {
      final rezultat = proveriUslove(student: studentAndrej, ponuda: ponuda(), svePrijave: const [], sada: sada);
      expect(rezultat.jeUspeh, isTrue);
    });

    test('P1: posle roka prijava nije moguca', () {
      final rok = DateTime(2026, 10, 31);
      final rezultat = proveriUslove(
        student: studentAndrej,
        ponuda: ponuda(rok: rok),
        svePrijave: const [],
        sada: sada,
      );
      expect(rezultat.greskaIliNull, RokIstekao(rok));
    });

    test('P2: prosek nizi od trazenog', () {
      final rezultat = proveriUslove(
        student: studentAndrej,
        ponuda: ponuda(minimalniProsek: 9.0),
        svePrijave: const [],
        sada: sada,
      );
      expect(rezultat.greskaIliNull, const NedovoljanProsek(trazeni: 9.0, studentov: 8.74));
    });

    test('P3: student nema jezik ponude u profilu', () {
      final rezultat = proveriUslove(
        student: studentAndrej,
        ponuda: ponuda(jezik: Jezik.italijanski, nivo: NivoJezika.b1),
        svePrijave: const [],
        sada: sada,
      );
      expect(
        rezultat.greskaIliNull,
        const NedovoljanJezik(
          trazeni: ZahtevJezika(jezik: Jezik.italijanski, nivo: NivoJezika.b1),
        ),
      );
    });

    test('P3: nivo jezika nizi od trazenog', () {
      final rezultat = proveriUslove(
        student: studentAndrej,
        ponuda: ponuda(nivo: NivoJezika.c1),
        svePrijave: const [],
        sada: sada,
      );
      expect(
        rezultat.greskaIliNull,
        const NedovoljanJezik(
          trazeni: ZahtevJezika(jezik: Jezik.engleski, nivo: NivoJezika.c1),
          studentov: NivoJezika.b2,
        ),
      );
    });

    test('P4: sa 3 aktivne prijave ne moze cetvrta', () {
      final tri = [
        prijava(
          id: 'p-1',
          idPonude: 'po-1',
          stanje: Poslata(kada: sada),
        ),
        prijava(
          id: 'p-2',
          idPonude: 'po-2',
          stanje: Poslata(kada: sada),
        ),
        prijava(
          id: 'p-3',
          idPonude: 'po-3',
          stanje: NaListiCekanja(odlucio: koordinatorMilano.id, kada: sada),
        ),
      ];
      final rezultat = proveriUslove(
        student: studentAndrej,
        ponuda: ponuda(id: 'po-4'),
        svePrijave: tri,
        sada: sada,
      );
      expect(rezultat.greskaIliNull, const PrevisePrijava(najviseAktivnihPrijava));
    });

    test('P4: odbijene i povucene prijave se ne broje', () {
      final neaktivne = [
        prijava(
          id: 'p-1',
          stanje: Odbijena(odlucio: koordinatorMilano.id, kada: sada, razlog: ''),
        ),
        prijava(
          id: 'p-2',
          stanje: Povucena(kada: sada),
        ),
        prijava(
          id: 'p-3',
          stanje: Povucena(kada: sada),
        ),
      ];
      final rezultat = proveriUslove(student: studentAndrej, ponuda: ponuda(), svePrijave: neaktivne, sada: sada);
      expect(rezultat.jeUspeh, isTrue);
    });
    test('posle potvrđenog mesta nema nove prijave za isti semestar', () {
      final potvrdjena = prijava(
        idPonude: 'po-2',
        stanje: Potvrdjena(kada: sada),
      );
      final rezultat = proveriUslove(
        student: studentAndrej,
        ponuda: ponuda(),
        svePrijave: [potvrdjena],
        sada: sada,
        ponude: [
          ponuda(),
          ponuda(id: 'po-2'),
        ],
      );
      expect(rezultat.greskaIliNull, isA<VecPotvrdjenoMesto>());
    });

    test('potvrđeno mesto u drugom semestru ne smeta', () {
      final potvrdjena = prijava(
        idPonude: 'po-2',
        stanje: Potvrdjena(kada: sada),
      );
      const letnji = Semestar(vrsta: VrstaSemestra.letnji, akademskaGodina: '2027/28');
      final rezultat = proveriUslove(
        student: studentAndrej,
        ponuda: ponuda(),
        svePrijave: [potvrdjena],
        sada: sada,
        ponude: [
          ponuda(),
          ponuda(id: 'po-2', semestar: letnji),
        ],
      );
      expect(rezultat.jeUspeh, isTrue);
    });
  });

  group('Uslovi ponude: granice', () {
    Student saProsekom(double prosek) => Student(
      id: studentAndrej.id,
      ime: studentAndrej.ime,
      prezime: studentAndrej.prezime,
      brojIndeksa: studentAndrej.brojIndeksa,
      email: studentAndrej.email,
      fakultet: studentAndrej.fakultet,
      smer: studentAndrej.smer,
      godinaStudija: studentAndrej.godinaStudija,
      prosek: prosek,
      znanjeJezika: studentAndrej.znanjeJezika,
    );

    List<Prijava> aktivne(int broj, {String idStudenta = 's-1'}) => [
      for (var i = 0; i < broj; i++)
        prijava(id: 'a-$i', idStudenta: idStudenta, idPonude: 'po-${i + 10}', stanje: Poslata(kada: sada)),
    ];

    test('rok u istom trenutku kao „sada" još važi', () {
      final rezultat = proveriUslove(student: studentAndrej, ponuda: ponuda(rok: sada), svePrijave: const [], sada: sada);
      expect(rezultat.jeUspeh, isTrue);
    });

    test('rok istekao pre jedne sekunde', () {
      final rok = sada.subtract(const Duration(seconds: 1));
      final rezultat = proveriUslove(student: studentAndrej, ponuda: ponuda(rok: rok), svePrijave: const [], sada: sada);
      expect(rezultat.greskaIliNull, RokIstekao(rok));
    });

    test('prosek tačno jednak traženom prolazi, a 0,01 niži ne', () {
      expect(
        proveriUslove(student: saProsekom(8.0), ponuda: ponuda(), svePrijave: const [], sada: sada).jeUspeh,
        isTrue,
      );
      expect(
        proveriUslove(student: saProsekom(7.99), ponuda: ponuda(), svePrijave: const [], sada: sada).greskaIliNull,
        const NedovoljanProsek(trazeni: 8.0, studentov: 7.99),
      );
    });

    test('sa 2 aktivne prijave može treća', () {
      final rezultat = proveriUslove(student: studentAndrej, ponuda: ponuda(), svePrijave: aktivne(2), sada: sada);
      expect(rezultat.jeUspeh, isTrue);
    });

    test('prihvaćena prijava se broji kao aktivna', () {
      final tri = [
        ...aktivne(2),
        prijava(id: 'a-9', idPonude: 'po-19', stanje: Prihvacena(odlucio: koordinatorMilano.id, kada: sada)),
      ];
      final rezultat = proveriUslove(student: studentAndrej, ponuda: ponuda(), svePrijave: tri, sada: sada);
      expect(rezultat.greskaIliNull, const PrevisePrijava(najviseAktivnihPrijava));
    });

    test('prijave u pripremi i tuđe aktivne prijave se ne broje', () {
      final prijave = [
        ...aktivne(2),
        for (var i = 0; i < 3; i++) prijava(id: 'n-$i', idPonude: 'po-2$i'),
        ...aktivne(5, idStudenta: 's-2'),
      ];
      final rezultat = proveriUslove(student: studentAndrej, ponuda: ponuda(), svePrijave: prijave, sada: sada);
      expect(rezultat.jeUspeh, isTrue);
    });
  });
}