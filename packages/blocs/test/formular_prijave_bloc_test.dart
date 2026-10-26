import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'pomocno.dart';
import 'test_baza.dart';

FormularPrijaveBloc napravi(TestBaza baza, {IdPonude? idPonude, IdPrijave? idPrijave}) => FormularPrijaveBloc(
  sacuvajPrijavu: SacuvajPrijavu(ponude: baza, prijave: baza, studenti: baza, sat: sat),
  korisnik: andrej,
  idPonude: idPonude,
  idPrijave: idPrijave,
);

void main() {
  blocTest<FormularPrijaveBloc, FormularPrijaveStanje>(
    'čuvanje nove prijave: u toku, pa sačuvana u pripremi',
    build: () => napravi(
      TestBaza(student: student, ponude: [ponuda()]),
      idPonude: const IdPonude('po-1'),
    ),
    act: (bloc) => bloc.add(CuvanjeZatrazeno(pismo: pismo)),
    expect: () => [
      const FormularUToku(posalji: false),
      isA<FormularSacuvan>()
          .having((s) => s.poslata, 'poslata', isFalse)
          .having((s) => s.prijava.stanje, 'stanje', isA<UPripremi>()),
    ],
  );

  blocTest<FormularPrijaveBloc, FormularPrijaveStanje>(
    'slanje uz premali prosek vraća grešku iz domena (P2)',
    build: () => napravi(
      TestBaza(student: student, ponude: [ponuda(minimalniProsek: 9.0)]),
      idPonude: const IdPonude('po-1'),
    ),
    act: (bloc) => bloc.add(SlanjeZatrazeno(pismo: pismo)),
    expect: () => [
      const FormularUToku(posalji: true),
      isA<FormularOdbijen>().having((s) => s.greska, 'greška', isA<NedovoljanProsek>()),
    ],
  );

  blocTest<FormularPrijaveBloc, FormularPrijaveStanje>(
    'slanje postojeće prijave je menja u poslatu',
    build: () => napravi(
      TestBaza(student: student, ponude: [ponuda()], prijave: [prijava()]),
      idPrijave: const IdPrijave('p-1'),
    ),
    act: (bloc) => bloc.add(SlanjeZatrazeno(pismo: pismo)),
    expect: () => [
      const FormularUToku(posalji: true),
      isA<FormularSacuvan>()
          .having((s) => s.poslata, 'poslata', isTrue)
          .having((s) => s.prijava.stanje, 'stanje', isA<Poslata>()),
    ],
  );

  blocTest<FormularPrijaveBloc, FormularPrijaveStanje>(
    'greška porta daje stanje neuspeha',
    build: () => napravi(
      TestBaza(student: student, ponude: [ponuda()])..greskaSledecegZahteva = true,
      idPonude: const IdPonude('po-1'),
    ),
    act: (bloc) => bloc.add(CuvanjeZatrazeno(pismo: pismo)),
    expect: () => [const FormularUToku(posalji: false), isA<FormularNeuspeo>()],
  );
}
