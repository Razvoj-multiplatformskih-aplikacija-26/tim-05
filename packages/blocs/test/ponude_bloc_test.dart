import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'pomocno.dart';
import 'test_baza.dart';

PonudeBloc napravi(TestBaza baza) => PonudeBloc(
  ucitajPregled: ucitajPregled(baza),
  promeniSacuvanu: PromeniSacuvanu(studenti: baza),
  korisnik: andrej,
);

void main() {
  blocTest<PonudeBloc, PonudeStanje>(
    'učitava ponude',
    build: () => napravi(TestBaza(student: student, ponude: [ponuda()])),
    act: (bloc) => bloc.add(const PonudeZatrazene()),
    expect: () => [
      const PonudeUcitavanje(),
      isA<PonudeUcitane>().having((s) => s.filtrirane, 'filtrirane', hasLength(1)).having(
        (s) => s.drzave,
        'države za filter',
        ['Italija'],
      ),
    ],
  );

  blocTest<PonudeBloc, PonudeStanje>(
    'greška porta daje stanje greške',
    build: () => napravi(TestBaza(student: student, ponude: [ponuda()])..greskaSledecegZahteva = true),
    act: (bloc) => bloc.add(const PonudeZatrazene()),
    expect: () => [const PonudeUcitavanje(), isA<PonudeGreska>()],
  );

  blocTest<PonudeBloc, PonudeStanje>(
    'bez ponuda daje prazno stanje',
    build: () => napravi(TestBaza(student: student)),
    act: (bloc) => bloc.add(const PonudeZatrazene()),
    expect: () => [const PonudeUcitavanje(), const PonudePrazne()],
  );

  blocTest<PonudeBloc, PonudeStanje>(
    'pretraga sužava listu, a podaci ostaju isti',
    build: () => napravi(TestBaza(student: student, ponude: [ponuda()])),
    act: (bloc) async {
      bloc.add(const PonudeZatrazene());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const FilteriPromenjeni(PonudeFilteri(upit: 'Beč')));
    },
    expect: () => [
      const PonudeUcitavanje(),
      isA<PonudeUcitane>().having((s) => s.filtrirane, 'filtrirane', hasLength(1)),
      isA<PonudeUcitane>().having((s) => s.filtrirane, 'filtrirane', isEmpty),
    ],
  );

  blocTest<PonudeBloc, PonudeStanje>(
    'čuvanje ponude ponovo učitava podatke',
    build: () => napravi(TestBaza(student: student, ponude: [ponuda()])),
    act: (bloc) async {
      bloc.add(const PonudeZatrazene());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const SacuvanaPromenjena(IdPonude('po-1')));
    },
    expect: () => [
      const PonudeUcitavanje(),
      isA<PonudeUcitane>().having((s) => s.podaci.jeSacuvana(const IdPonude('po-1')), 'sačuvana', isFalse),
      isA<PonudeUcitane>().having((s) => s.cuvaSe, 'čuva se', const IdPonude('po-1')),
      isA<PonudeUcitane>()
          .having((s) => s.podaci.jeSacuvana(const IdPonude('po-1')), 'sačuvana', isTrue)
          .having((s) => s.cuvaSe, 'čuva se', isNull)
          .having((s) => s.obavestenje, 'obaveštenje', const PonudaSacuvana()),
    ],
  );

  final baza = TestBaza(student: student, ponude: [ponuda()]);
  blocTest<PonudeBloc, PonudeStanje>(
    'neuspelo čuvanje ponude ostavlja podatke i daje poruku',
    build: () => napravi(baza),
    act: (bloc) async {
      bloc.add(const PonudeZatrazene());
      await Future<void>.delayed(Duration.zero);
      baza.greskaSledecegZahteva = true;
      bloc.add(const SacuvanaPromenjena(IdPonude('po-1')));
    },
    expect: () => [
      const PonudeUcitavanje(),
      isA<PonudeUcitane>().having((s) => s.obavestenje, 'obaveštenje', isNull),
      isA<PonudeUcitane>().having((s) => s.cuvaSe, 'čuva se', const IdPonude('po-1')),
      isA<PonudeUcitane>()
          .having((s) => s.cuvaSe, 'čuva se', isNull)
          .having((s) => s.obavestenje, 'obaveštenje', isA<CuvanjePonudeNeuspelo>()),
    ],
  );
}
