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
  });
}
