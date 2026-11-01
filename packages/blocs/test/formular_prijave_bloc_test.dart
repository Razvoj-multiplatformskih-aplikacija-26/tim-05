import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'pomocno.dart';
import 'test_baza.dart';

const po1 = IdPonude('po-1');

FormularPrijaveBloc napravi(TestBaza baza, {IdPonude? idPonude, IdPrijave? idPrijave}) => FormularPrijaveBloc(
  sacuvajPrijavu: SacuvajPrijavu(ponude: baza, prijave: baza, studenti: baza, sat: sat),
  korisnik: andrej,
  idPonude: idPonude,
  idPrijave: idPrijave,
);

void main() {
  test('formular bez ID-a ponude i bez ID-a prijave nije dozvoljen', () {
    expect(() => napravi(TestBaza(student: student)), throwsA(isA<AssertionError>()));
  });

  blocTest<FormularPrijaveBloc, FormularPrijaveStanje>(
    'potečnmo stanje je spreman',
    build: () => napravi(TestBaza(student: student, ponude: [ponuda()]), idPonude: po1),
    verify: (bloc) => expect(bloc.state, const FormularSpreman()),
  );

  blocTest<FormularPrijaveBloc, FormularPrijaveStanje>(
    'cuvanje: u toku, pa sacuvano u pripremi',
    build: () => napravi(TestBaza(student: student, ponude: [ponuda()]), idPonude: po1),
    act: (bloc) => bloc.add(CuvanjeZatrazeno(pismo: pismo)),
    expect: () => [
      const FormularUToku(posalji: false),
      isA<FormularSacuvan>()
          .having((s) => s.poslata, 'poslata', isFalse)
          .having((s) => s.prijava.stanje, 'stanje', isA<UPripremi>()),
    ],
  );

  blocTest<FormularPrijaveBloc, FormularPrijaveStanje>(
    'slanje: u toku, pa polsata',
    build: () => napravi(TestBaza(student: student, ponude: [ponuda()]), idPonude: po1),
    act: (bloc) => bloc.add(SlanjeZatrazeno(pismo: pismo)),
    expect: () => [
      const FormularUToku(posalji: true),
      isA<FormularSacuvan>()
          .having((s) => s.poslata, 'poslata', isTrue)
          .having((s) => s.prijava.stanje, 'stanje', isA<Poslata>()),
    ],
  );

  blocTest<FormularPrijaveBloc, FormularPrijaveStanje>(
    'slanje uz premali prosek: domen odbija, nista se ne cuva',
    build: () => napravi(TestBaza(student: student, ponude: [ponuda(minimalniProsek: 9.0)]), idPonude: po1),
    act: (bloc) => bloc.add(SlanjeZatrazeno(pismo: pismo)),
    expect: () => [
      const FormularUToku(posalji: true),
      const FormularOdbijen(NedovoljanProsek(trazeni: 9.0, studentov: 8.74)),
    ],
  );

  test('slanje uz premali prosek ne ostavlja prijavu u bazi', () async {
    final baza = TestBaza(student: student, ponude: [ponuda(minimalniProsek: 9.0)]);
    final bloc = napravi(baza, idPonude: po1)..add(SlanjeZatrazeno(pismo: pismo));
    await bloc.stream.firstWhere((s) => s is FormularOdbijen);
    expect(baza.prijave, isEmpty);
    await bloc.close();
  });

  blocTest<FormularPrijaveBloc, FormularPrijaveStanje>(
    'greska porta daje FormularNeuspeo, a ne FormularOdbijen',
    build: () => napravi(TestBaza(student: student, ponude: [ponuda()])..greskaSledecegZahteva = true, idPonude: po1),
    act: (bloc) => bloc.add(CuvanjeZatrazeno(pismo: pismo)),
    expect: () => [const FormularUToku(posalji: false), isA<FormularNeuspeo>()],
  );

  blocTest<FormularPrijaveBloc, FormularPrijaveStanje>(
    'posle neuspeha isto slanje moze ponovo i uspeva',
    build: () => napravi(TestBaza(student: student, ponude: [ponuda()])..greskaSledecegZahteva = true, idPonude: po1),
    act: (bloc) async {
      bloc.add(SlanjeZatrazeno(pismo: pismo));
      await Future<void>.delayed(Duration.zero);
      bloc.add(SlanjeZatrazeno(pismo: pismo));
    },
    expect: () => [
      const FormularUToku(posalji: true),
      isA<FormularNeuspeo>(),
      const FormularUToku(posalji: true),
      isA<FormularSacuvan>(),
    ],
  );

  test('dva uzastopna zahteva dok je jedan u toku: ceo tok se izvrsi samo jednom', () async {
    final baza = TestBaza(student: student, ponude: [ponuda()]);
    final bloc = napravi(baza, idPonude: po1)
      ..add(CuvanjeZatrazeno(pismo: pismo))
      ..add(CuvanjeZatrazeno(pismo: pismo));
    await bloc.stream.firstWhere((s) => s is FormularSacuvan);
    await Future<void>.delayed(Duration.zero);
    expect(baza.prijave, hasLength(1));
    await bloc.close();
  });

  blocTest<FormularPrijaveBloc, FormularPrijaveStanje>(
    'izmena postojece poslate prijave ne menja njeno stanje',
    build: () => napravi(
      TestBaza(student: student, ponude: [ponuda()], prijave: [prijava(stanje: Poslata(kada: sat.sada()))]),
      idPrijave: const IdPrijave('p-1'),
    ),
    act: (bloc) => bloc.add(CuvanjeZatrazeno(pismo: pismo, napomena: 'Nova napomena')),
    expect: () => [
      const FormularUToku(posalji: false),
      isA<FormularSacuvan>()
          .having((s) => s.prijava.stanje, 'stanje', isA<Poslata>())
          .having((s) => s.prijava.napomena, 'napomena', 'Nova napomena'),
    ],
  );

  blocTest<FormularPrijaveBloc, FormularPrijaveStanje>(
    'izmena prihvacene prijave daje IzmenaNijeMoguca',
    build: () => napravi(
      TestBaza(
        student: student, ponude: [ponuda()],
        prijave: [prijava(stanje: Prihvacena(odlucio: const IdKorisnika('k-1'), kada: sat.sada()))],
      ),
      idPrijave: const IdPrijave('p-1'),
    ),
    act: (bloc) => bloc.add(CuvanjeZatrazeno(pismo: pismo)),
    expect: () => [
      const FormularUToku(posalji: false),
      isA<FormularOdbijen>().having((s) => s.greska, 'greška', isA<IzmenaNijeMoguca>()),
    ],
  );

  blocTest<FormularPrijaveBloc, FormularPrijaveStanje>(
    'izmena nepostojece prijave daje NijePronadjeno',
    build: () => napravi(TestBaza(student: student), idPrijave: const IdPrijave('nema')),
    act: (bloc) => bloc.add(CuvanjeZatrazeno(pismo: pismo)),
    expect: () => [
      const FormularUToku(posalji: false),
      isA<FormularOdbijen>().having((s) => s.greska, 'greška', isA<NijePronadjeno>()),
    ],
  );
}
