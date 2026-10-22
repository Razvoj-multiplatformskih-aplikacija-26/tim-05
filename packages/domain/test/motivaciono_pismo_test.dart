import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('Motivaciono pismo (obavezno, najvise 1500 znakova)', () {
    test('prazno pismo nije dozvoljeno', () {
      expect(MotivacionoPismo.proveri(''), const Neuspeh<MotivacionoPismo>(PismoPrazno()));
    });

    test('pismo od samih razmaka je prazno', () {
      expect(MotivacionoPismo.proveri('    '), const Neuspeh<MotivacionoPismo>(PismoPrazno()));
    });

    test('tacno 1500 znakova je dozvoljeno', () {
      expect(MotivacionoPismo.proveri('a' * MotivacionoPismo.najvise).jeUspeh, isTrue);
    });

    test('1501 znak nije dozvoljen', () {
      expect(
        MotivacionoPismo.proveri('a' * (MotivacionoPismo.najvise + 1)),
        const Neuspeh<MotivacionoPismo>(PismoPredugacko(1501)),
      );
    });
  });
}
