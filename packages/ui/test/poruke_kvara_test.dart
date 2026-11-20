import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

void main() {
  test('svaka vrsta kvara ima poruku za korisnika, bez tehničkog teksta', () {
    String poruka(VrstaKvara vrsta) => porukaKvara(GreskaRepozitorijuma('tehnički opis', vrsta: vrsta));

    expect(poruka(VrstaKvara.nemaVeze), 'Nema veze sa serverom.');
    expect(poruka(VrstaKvara.greskaServera), 'Greška na serveru.');
    expect(poruka(VrstaKvara.odbijeno), 'Server nije prihvatio zahtev.');
    expect(poruka(VrstaKvara.sesijaIstekla), 'Prijava je istekla. Prijavite se ponovo.');
    expect(poruka(VrstaKvara.nedostupno), 'Podaci trenutno nisu dostupni.');
    for (final vrsta in VrstaKvara.values) {
      expect(poruka(vrsta), isNot(contains('tehnički')));
    }
  });

  test('nepoznat uzrok dobija opštu poruku', () {
    expect(porukaKvara(Exception('x')), 'Podaci trenutno nisu dostupni.');
    expect(porukaKvara(null), 'Podaci trenutno nisu dostupni.');
  });
}