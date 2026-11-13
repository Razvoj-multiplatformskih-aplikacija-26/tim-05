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

    test('granice i sa više decimala', () {
      expect(Prosek.proveri('5,999').greskaIliNull, isA<ProsekVanOpsega>());
      expect(Prosek.proveri('6,000').jeUspeh, isTrue);
      expect(Prosek.proveri('10,0001').greskaIliNull, isA<ProsekVanOpsega>());
    });

    test('nula i negativan broj su van opsega', () {
      expect(Prosek.proveri('0').greskaIliNull, isA<ProsekVanOpsega>());
      expect(Prosek.proveri('-8').greskaIliNull, isA<ProsekVanOpsega>());
    });

    test('tekst koji nije broj', () {
      for (final unos in ['', ' ', 'osam', '8,7,4', '8 5', ',', '--8']) {
        expect(Prosek.proveri(unos).greskaIliNull, isA<ProsekNijeBroj>(), reason: 'unos: "$unos"');
      }
    });

    test('NaN nije prosek, a beskonačnost je van opsega', () {
      expect(Prosek.proveri('NaN').greskaIliNull, isA<ProsekNijeBroj>());
      expect(Prosek.proveri('Infinity').greskaIliNull, isA<ProsekVanOpsega>());
      expect(Prosek.proveri('-Infinity').greskaIliNull, isA<ProsekVanOpsega>());
    });
  });


  
  group('Prosek.proveriBroj (prosek koji stize kao broj, npr. sa mrese)', () {
    test('isto pravilo kao za unos: granice 6 i 10 dozvoljene, van njih nije', () {
      expect(Prosek.proveriBroj(8.74).vrednostIliNull, 8.74);
      expect(Prosek.proveriBroj(6).jeUspeh, isTrue);
      expect(Prosek.proveriBroj(10).jeUspeh, isTrue);
      expect(Prosek.proveriBroj(5.99).greskaIliNull, isA<ProsekVanOpsega>());
      expect(Prosek.proveriBroj(10.01).greskaIliNull, isA<ProsekVanOpsega>());
    });

    test('NaN nije broj', () {
      expect(Prosek.proveriBroj(double.nan).greskaIliNull, isA<ProsekNijeBroj>());
    });
  });

}