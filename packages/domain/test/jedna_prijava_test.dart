import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'pomocno.dart';

Rezultat<Prijava> nova(List<Prijava> svePrijave, {Korisnik ko = andrej, String idPonude = 'po-1'}) => napraviPrijavu(
  id: const IdPrijave('p-nova'),
  ko: ko,
  idPonude: IdPonude(idPonude),
  motivacionoPismo: pismo,
  svePrijave: svePrijave,
  sada: sada,
);

void main() {
  group('napraviPrijavu', () {
    test('prva prijava na ponudu je u pripremi i pripada studentu', () {
      final prijava = nova(const []).vrednostIliNull!;
      expect(prijava.stanje, isA<UPripremi>());
      expect(prijava.idStudenta, andrej.id);
      expect(prijava.napravljena, sada);
    });

    test('ne može druga dok postoji nezavrsena prijava na istu ponudu', () {
      final nezavrsene = [
        const UPripremi(),
        Poslata(kada: sada),
        NaListiCekanja(odlucio: koordinatorMilano.id, kada: sada),
        Prihvacena(odlucio: koordinatorMilano.id, kada: sada),
      ];
      for (final stanje in nezavrsene) {
        expect(
          nova([prijava(stanje: stanje)]).greskaIliNull,
          isA<VecPostojiPrijava>(),
          reason: 'postojeca prijava: $stanje',
        );
      }
    });

    test('posle odbijene ili povucene prijave moze nova na istu ponudu', () {
      expect(
        nova([prijava(stanje: Odbijena(odlucio: koordinatorMilano.id, kada: sada, razlog: 'x'))]).jeUspeh,
        isTrue,
      );
      expect(nova([prijava(stanje: Povucena(kada: sada))]).jeUspeh, isTrue);
    });

    test('prijava na drugu ponudu i tufja prijava na istu ponudu ne smetaju', () {
      expect(nova([prijava(idPonude: 'po-2', stanje: Poslata(kada: sada))]).jeUspeh, isTrue);
      expect(nova([prijava(idStudenta: 's-2', stanje: Poslata(kada: sada))]).jeUspeh, isTrue);
    });

    test('koordinator ne pravi prijavu', () {
      expect(nova(const [], ko: koordinatorMilano).greskaIliNull, isA<NemaPravo>());
    });
  });
}
