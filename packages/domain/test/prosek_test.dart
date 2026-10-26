import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('Prosek (README: između 6,00 i 10,00)', () {
    test('prihvata decimalni zarez i tačku', () {
      expect(Prosek.proveri('8,74').vrednostIliNull, 8.74);
      expect(Prosek.proveri(' 8.74 ').vrednostIliNull, 8.74);
    });

    test('granice 6,00 i 10,00 su dozvoljene', () {
      expect(Prosek.proveri('6').jeUspeh, isTrue);
      expect(Prosek.proveri('10,00').jeUspeh, isTrue);
    });

    test('ispod 6 i iznad 10 nije dozvoljeno', () {
      expect(Prosek.proveri('5,99').greskaIliNull, isA<ProsekVanOpsega>());
      expect(Prosek.proveri('10,01').greskaIliNull, isA<ProsekVanOpsega>());
    });

    test('tekst koji nije broj', () {
      expect(Prosek.proveri('').greskaIliNull, isA<ProsekNijeBroj>());
      expect(Prosek.proveri('osam').greskaIliNull, isA<ProsekNijeBroj>());
    });
  });
}
