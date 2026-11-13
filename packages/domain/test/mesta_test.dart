import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'pomocno.dart';

void main() {
  group('preostalaMesta', () {
    test('mesto zauzimaju samo prihvacene i potvrdjene prijave', () {
      final sve = [
        prijava(
          id: '1',
          idStudenta: 's-1',
          stanje: Prihvacena(odlucio: koordinatorMilano.id, kada: sada),
        ),
        prijava(
          id: '2',
          idStudenta: 's-2',
          stanje: Potvrdjena(kada: sada),
        ),
        prijava(
          id: '3',
          idStudenta: 's-3',
          stanje: Poslata(kada: sada),
        ),
        prijava(
          id: '4',
          idStudenta: 's-4',
          stanje: NaListiCekanja(odlucio: koordinatorMilano.id, kada: sada),
        ),
        prijava(
          id: '5',
          idStudenta: 's-5',
          stanje: Odbijena(odlucio: koordinatorMilano.id, kada: sada, razlog: 'x'),
        ),
        prijava(
          id: '6',
          idStudenta: 's-6',
          stanje: Povucena(kada: sada),
        ),
        prijava(id: '7', idStudenta: 's-7'),
      ];
      expect(preostalaMesta(ponuda(brojMesta: 5), sve), 3);
    });

    test('prijave na druge ponude ne trose mesta', () {
      final tudje = [
        prijava(
          id: '1',
          idPonude: 'po-2',
          stanje: Potvrdjena(kada: sada),
        ),
        prijava(
          id: '2',
          idStudenta: 's-2',
          idPonude: 'po-3',
          stanje: Potvrdjena(kada: sada),
        ),
      ];
      expect(preostalaMesta(ponuda(brojMesta: 2), tudje), 2);
    });

    test('broj ne ide ispod nule ni kad je ponuda prepunjena', () {
      final sve = [
        prijava(
          id: '1',
          idStudenta: 's-1',
          stanje: Potvrdjena(kada: sada),
        ),
        prijava(
          id: '2',
          idStudenta: 's-2',
          stanje: Potvrdjena(kada: sada),
        ),
      ];
      expect(preostalaMesta(ponuda(brojMesta: 1), sve), 0);
    });

    test('ponuda bez prijava ima sva mesta', () {
      expect(preostalaMesta(ponuda(brojMesta: 4), const []), 4);
    });
  });
  group('zauzetaMesta', () {
    test('broji samo prihvacene i potvrdjene prijave na tu ponudu', () {
      final sve = [
        prijava(
          id: '1',
          idStudenta: 's-1',
          stanje: Prihvacena(odlucio: koordinatorMilano.id, kada: sada),
        ),
        prijava(
          id: '2',
          idStudenta: 's-2',
          stanje: Potvrdjena(kada: sada),
        ),
        prijava(
          id: '3',
          idStudenta: 's-3',
          stanje: Poslata(kada: sada),
        ),
        prijava(
          id: '4',
          idStudenta: 's-4',
          idPonude: 'po-2',
          stanje: Potvrdjena(kada: sada),
        ),
      ];
      expect(zauzetaMesta(ponuda(brojMesta: 5), sve), 2);
    });

    test('kad je ponuda prepunjena, pokazuje stvaran broj, a slobodnih je 0', () {
      final sve = [
        prijava(
          id: '1',
          idStudenta: 's-1',
          stanje: Potvrdjena(kada: sada),
        ),
        prijava(
          id: '2',
          idStudenta: 's-2',
          stanje: Potvrdjena(kada: sada),
        ),
      ];
      expect(zauzetaMesta(ponuda(brojMesta: 1), sve), 2);
      expect(preostalaMesta(ponuda(brojMesta: 1), sve), 0);
    });
  });

  group('aktivnePrijave (najvise tri aktivne)', () {
    test('vraca samo aktivne prijave tog studenta', () {
      final sve = [
        prijava(
          id: '1',
          stanje: Poslata(kada: sada),
        ),
        prijava(
          id: '2',
          stanje: Povucena(kada: sada),
        ),
        prijava(id: '3'),
        prijava(
          id: '4',
          idStudenta: 's-2',
          stanje: Poslata(kada: sada),
        ),
      ];
      expect(aktivnePrijave(andrej.id, sve).map((p) => p.id.vrednost), ['1']);
    });
  });

  group('slobodnaMestaZa', () {
    test('slobodna mesta iz broja zauzetih, bez lista prijava', () {
      expect(slobodnaMestaZa(ponuda(brojMesta: 4), zauzeto: 1), 3);
      expect(slobodnaMestaZa(ponuda(brojMesta: 2), zauzeto: 2), 0);
    });

    test('ne ide ispod nule', () {
      expect(slobodnaMestaZa(ponuda(brojMesta: 2), zauzeto: 5), 0);
    });
  });
}
