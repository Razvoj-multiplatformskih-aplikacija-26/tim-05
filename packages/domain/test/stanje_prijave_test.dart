import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'pomocno.dart';

void main() {
  group('Stanja prijave (zahtev 2)', () {
    test('dozvoljeno je tacno 11 prelaza od 49 mogucih', () {
      final stanja = <StanjePrijave>[
        const UPripremi(),
        Poslata(kada: sada),
        NaListiCekanja(odlucio: koordinatorMilano.id, kada: sada),
        Prihvacena(odlucio: koordinatorMilano.id, kada: sada),
        Odbijena(odlucio: koordinatorMilano.id, kada: sada, razlog: 'test'),
        Potvrdjena(kada: sada),
        Povucena(kada: sada),
      ];

      final dozvoljeni = <(Type, Type)>[
        for (final iz in stanja)
          for (final u in stanja)
            if (dozvoljenPrelaz(iz, u)) (iz.runtimeType, u.runtimeType),
      ];

      expect(dozvoljeni, [
        (UPripremi, Poslata),
        (UPripremi, Povucena),
        (Poslata, NaListiCekanja),
        (Poslata, Prihvacena),
        (Poslata, Odbijena),
        (Poslata, Povucena),
        (NaListiCekanja, Prihvacena),
        (NaListiCekanja, Odbijena),
        (NaListiCekanja, Povucena),
        (Prihvacena, Potvrdjena),
        (Prihvacena, Povucena),
      ]);
    });

    test('aktivne su samo poslata, na listi cekanja i prihvacena', () {
      expect(const UPripremi().jeAktivna, isFalse);
      expect(Poslata(kada: sada).jeAktivna, isTrue);
      expect(NaListiCekanja(odlucio: koordinatorMilano.id, kada: sada).jeAktivna, isTrue);
      expect(Prihvacena(odlucio: koordinatorMilano.id, kada: sada).jeAktivna, isTrue);
      expect(Potvrdjena(kada: sada).jeAktivna, isFalse);
      expect(Povucena(kada: sada).jeAktivna, isFalse);
    });

        test('menjati se može samo prijava u pripremi i poslata', () {
      expect(const UPripremi().mozeSeMenjati, isTrue);
      expect(Poslata(kada: sada).mozeSeMenjati, isTrue);
      expect(NaListiCekanja(odlucio: koordinatorMilano.id, kada: sada).mozeSeMenjati, isFalse);
      expect(Prihvacena(odlucio: koordinatorMilano.id, kada: sada).mozeSeMenjati, isFalse);
      expect(Odbijena(odlucio: koordinatorMilano.id, kada: sada, razlog: 'test').mozeSeMenjati, isFalse);
      expect(Potvrdjena(kada: sada).mozeSeMenjati, isFalse);
      expect(Povucena(kada: sada).mozeSeMenjati, isFalse);
    });

        test('obrisati se može samo odbijena i povučena prijava', () {
      expect(Odbijena(odlucio: koordinatorMilano.id, kada: sada, razlog: 'test').mozeSeObrisati, isTrue);
      expect(Povucena(kada: sada).mozeSeObrisati, isTrue);
      expect(const UPripremi().mozeSeObrisati, isFalse);
      expect(Poslata(kada: sada).mozeSeObrisati, isFalse);
      expect(NaListiCekanja(odlucio: koordinatorMilano.id, kada: sada).mozeSeObrisati, isFalse);
      expect(Prihvacena(odlucio: koordinatorMilano.id, kada: sada).mozeSeObrisati, isFalse);
      expect(Potvrdjena(kada: sada).mozeSeObrisati, isFalse);
    });
  });
}
