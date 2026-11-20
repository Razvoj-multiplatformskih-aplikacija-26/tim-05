import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'koordinator_bloc_test.dart' show dvePrijave, koordinator, napravi, sacekaj;
import 'pomocno.dart';

void main() {
  final baza = dvePrijave();
  final odbijena = Odbijena(odlucio: koordinator.id, kada: sat.sada(), razlog: 'Odlučeno u drugom prozoru.');

  blocTest<KoordinatorBloc, KoordinatorStanje>(
    'zakasneli klijent: prijava je u medjuvremenu odbijena u drugom prozoru, '
    'pa prihvatanje dobija razlog, a tabela ponovo ucitano stanje',
    build: () => napravi(baza),
    act: (bloc) async {
      bloc.add(const PrijaveZatrazene());
      await sacekaj();
      bloc.add(const PrijavaIzabrana(IdPrijave('p-1')));
      await sacekaj();
      baza.preSledecegUpisa = (b) => b.postavi(prijava(stanje: odbijena));
      bloc.add(const PrihvatanjeZatrazeno(IdPrijave('p-1')));
    },
    skip: 4,
    expect: () => [
      isA<KoordinatorUcitano>()
          .having((s) => s.uToku, 'u toku', isNull)
          .having((s) => s.obavestenje, 'obaveštenje', isA<OdlukaOdbijena>())
          .having((s) => s.izabranaPrijava?.stanje, 'stanje posle ponovnog učitavanja', odbijena)
          .having((s) => s.akcijeZa(s.izabranaPrijava!), 'akcije', isEmpty),
    ],
  );
}
