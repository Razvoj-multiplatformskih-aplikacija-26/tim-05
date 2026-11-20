import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'pomocno.dart';
import 'test_baza.dart';

PonudeBloc ponudeBloc(TestBaza baza, {Korisnik? korisnik}) => PonudeBloc(
  ucitajPregled: ucitajPregled(baza),
  promeniSacuvanu: PromeniSacuvanu(studenti: baza),
  korisnik: korisnik,
);

ProfilBloc profilBloc(TestBaza baza, {Korisnik? korisnik}) => ProfilBloc(
  ucitajPregled: ucitajPregled(baza),
  povuciPrijavu: PovuciPrijavu(ponude: baza, prijave: baza, sat: sat),
  potvrdiMesto: PotvrdiMesto(ponude: baza, prijave: baza, sat: sat),
  odbijMesto: OdbijMesto(ponude: baza, prijave: baza, sat: sat),
  obrisiPrijavu: ObrisiPrijavu(ponude: baza, prijave: baza),
  sacuvajProfil: SacuvajProfil(studenti: baza),
  korisnik: korisnik,
);

void main() {
  group('ponude bez prijave', () {
    blocTest<PonudeBloc, PonudeStanje>(
      'gost vidi ponude i slobodna mesta, bez studenta i bez prijava',
      build: () => ponudeBloc(TestBaza(student: student, ponude: [ponuda()], prijave: [prijava()])),
      act: (bloc) => bloc.add(const PonudeZatrazene()),
      expect: () => [
        const PonudeUcitavanje(),
        isA<PonudeUcitane>()
            .having((s) => s.podaci.student, 'student', isNull)
            .having((s) => s.podaci.mojePrijave, 'moje prijave', isEmpty)
            .having((s) => s.podaci.uslovi(s.podaci.ponude.single), 'uslovi', isNull)
            .having((s) => s.podaci.slobodnaMesta(s.podaci.ponude.single), 'slobodna mesta', 2),
      ],
    );

    blocTest<PonudeBloc, PonudeStanje>(
      'posle prijave ponude se ucitavaju ponovo, sa studentom i njegovim prijavama; filteri ostaju',
      build: () => ponudeBloc(TestBaza(student: student, ponude: [ponuda()], prijave: [prijava()])),
      act: (bloc) async {
        bloc.add(const PonudeZatrazene());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const FilteriPromenjeni(PonudeFilteri(upit: 'Milano')));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const PonudeKorisnikPromenjen(andrej));
      },
      skip: 4,
      expect: () => [
        isA<PonudeUcitane>()
            .having((s) => s.podaci.student, 'student', student)
            .having((s) => s.podaci.mojePrijave, 'moje prijave', hasLength(1))
            .having((s) => s.filteri.upit, 'upit', 'Milano'),
      ],
    );

    blocTest<PonudeBloc, PonudeStanje>(
      'gost ne moze da sacuva ponudu: bloc ništa ne salje',
      build: () => ponudeBloc(TestBaza(student: student, ponude: [ponuda()])),
      act: (bloc) async {
        bloc.add(const PonudeZatrazene());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SacuvanaPromenjena(IdPonude('po-1')));
      },
      expect: () => [const PonudeUcitavanje(), isA<PonudeUcitane>()],
    );

    test('osvezavanje javlja kada je gotovo, i kada podaci nisu promenjeni', () async {
      final bloc = ponudeBloc(
        TestBaza(student: student, ponude: [ponuda()]),
        korisnik: andrej,
      )..add(const PonudeZatrazene());
      await bloc.stream.firstWhere((s) => s is PonudeUcitane);
      final gotovo = Completer<void>();
      bloc.add(PonudeOsvezene(gotovo: gotovo));
      await gotovo.future.timeout(const Duration(seconds: 1));
      await bloc.close();
    });
  });

  group('profil prati sesiju', () {
    blocTest<ProfilBloc, ProfilStanje>(
      'bez prijave: stanje „bez prijave", bez poziva servera',
      build: () => profilBloc(TestBaza(student: student)..greskaSledecegZahteva = true),
      act: (bloc) => bloc.add(const ProfilZatrazen()),
      expect: () => [const ProfilBezPrijave()],
    );

    blocTest<ProfilBloc, ProfilStanje>(
      'prijava pa odjava: podaci, pa bez prijave',
      build: () => profilBloc(TestBaza(student: student, ponude: [ponuda()], prijave: [prijava()])),
      act: (bloc) async {
        bloc.add(const ProfilKorisnikPromenjen(andrej));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ProfilKorisnikPromenjen(null));
      },
      expect: () => [const ProfilUcitavanje(), isA<ProfilUcitan>(), const ProfilBezPrijave()],
    );
  });

  group('zakasneli klijent: razlog i ponovo ucitani podaci', () {
    final baza = TestBaza(
      student: student,
      ponude: [ponuda()],
      prijave: [prijava(stanje: Poslata(kada: sat.sada()))],
    );
    final odbijena = Odbijena(odlucio: const IdKorisnika('k-1'), kada: sat.sada(), razlog: 'Popunjeno.');

    blocTest<ProfilBloc, ProfilStanje>(
      'koordinator je odbio prijavu dok je student povlacio: poruka sa razlogom i novo stanje prijave',
      build: () => profilBloc(baza, korisnik: andrej),
      act: (bloc) async {
        bloc.add(const ProfilZatrazen());
        await Future<void>.delayed(Duration.zero);
        baza.preSledecegUpisa = (b) => b.postavi(prijava(stanje: odbijena));
        bloc.add(const PovlacenjeZatrazeno(IdPrijave('p-1')));
      },
      skip: 3,
      expect: () => [
        isA<ProfilUcitan>()
            .having((s) => s.uToku, 'u toku', isNull)
            .having((s) => s.obavestenje, 'obaveštenje', isA<AkcijaOdbijena>())
            .having((s) => s.podaci.mojePrijave.single.stanje, 'stanje posle ponovnog učitavanja', odbijena),
      ],
    );
  });
}
