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
  });
}
