import 'package:use_cases/use_cases.dart';

const porukaNemaVeze = 'Nema veze sa serverom.';
const porukaSesijaIstekla = 'Prijava je istekla. Prijavite se ponovo.';


String porukaKvara(Object? uzrok) => switch (uzrok) {
  GreskaRepozitorijuma(vrsta: VrstaKvara.nemaVeze) => porukaNemaVeze,
  GreskaRepozitorijuma(vrsta: VrstaKvara.greskaServera) => 'Greška na serveru.',
  GreskaRepozitorijuma(vrsta: VrstaKvara.odbijeno) => 'Server nije prihvatio zahtev.',
  GreskaRepozitorijuma(vrsta: VrstaKvara.sesijaIstekla) => porukaSesijaIstekla,
  _ => 'Podaci trenutno nisu dostupni.',
};