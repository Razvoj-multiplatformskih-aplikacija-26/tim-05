import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'pomocno.dart';
import 'test_baza.dart';

ProfilBloc napravi(TestBaza baza) => ProfilBloc(
  ucitajPregled: ucitajPregled(baza),
  povuciPrijavu: PovuciPrijavu(prijave: baza, sat: sat),
  potvrdiMesto: PotvrdiMesto(ponude: baza, prijave: baza, sat: sat),
  odbijMesto: OdbijMesto(prijave: baza, sat: sat),
  obrisiPrijavu: ObrisiPrijavu(prijave: baza),
  sacuvajProfil: SacuvajProfil(studenti: baza),
  korisnik: andrej,
);

Future<void> Function(ProfilBloc) ucitajPa(ProfilDogadjaj dogadjaj) => (bloc) async {
  bloc.add(const ProfilZatrazen());
  await Future<void>.delayed(Duration.zero);
  bloc.add(dogadjaj);
};

const izmenjen = Student(
  id: IdKorisnika('s-1'),
  ime: 'Andrej',
  prezime: 'Aleksić',
  brojIndeksa: 'RN 76/24',
  email: 'andrej@raf.rs',
  fakultet: 'Računarski fakultet',
  smer: 'Računarske nauke',
  godinaStudija: 4,
  prosek: 9.1,
  znanjeJezika: {Jezik.engleski: NivoJezika.b2},
);

void main() {
  group('četiri stanja ekrana', () {
    blocTest<ProfilBloc, ProfilStanje>(
      'podaci',
      build: () => napravi(TestBaza(student: student, ponude: [ponuda()], prijave: [prijava()])),
      act: (bloc) => bloc.add(const ProfilZatrazen()),
      expect: () => [
        const ProfilUcitavanje(),
        isA<ProfilUcitan>().having((s) => s.podaci.mojePrijave, 'moje prijave', hasLength(1)),
      ],
    );

    blocTest<ProfilBloc, ProfilStanje>(
      'prazno',
      build: () => napravi(TestBaza(student: student, ponude: [ponuda()])),
      act: (bloc) => bloc.add(const ProfilZatrazen()),
      expect: () => [const ProfilUcitavanje(), isA<ProfilPrazan>()],
    );

    blocTest<ProfilBloc, ProfilStanje>(
      'greška, pa „Pokušaj ponovo": učitavanje i podaci',
      build: () => napravi(TestBaza(student: student, prijave: [prijava()])..greskaSledecegZahteva = true),
      act: (bloc) async {
        bloc.add(const ProfilZatrazen());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ProfilZatrazen());
      },
      expect: () => [const ProfilUcitavanje(), isA<ProfilGreska>(), const ProfilUcitavanje(), isA<ProfilUcitan>()],
    );
  });

  group('akcije', () {
    blocTest<ProfilBloc, ProfilStanje>(
      'povlačenje: prijava je u toku, pa povučena, uz poruku',
      build: () => napravi(
        TestBaza(
          student: student,
          prijave: [prijava(stanje: Poslata(kada: sat.sada()))],
        ),
      ),
      act: ucitajPa(const PovlacenjeZatrazeno(IdPrijave('p-1'))),
      skip: 2,
      expect: () => [
        isA<ProfilUcitan>().having((s) => s.uToku, 'u toku', const IdPrijave('p-1')),
        isA<ProfilUcitan>()
            .having((s) => s.uToku, 'u toku', isNull)
            .having((s) => s.podaci.mojePrijave.single.stanje, 'stanje', isA<Povucena>())
            .having((s) => s.obavestenje, 'obaveštenje', const PrijavaPovucena()),
      ],
    );

    blocTest<ProfilBloc, ProfilStanje>(
      'potvrda mesta povlači ostale prijave za isti semestar (P6)',
      build: () => napravi(
        TestBaza(
          student: student,
          ponude: [
            ponuda(),
            ponuda(id: 'po-2'),
          ],
          prijave: [
            prijava(
              stanje: Prihvacena(odlucio: const IdKorisnika('k-1'), kada: sat.sada()),
            ),
            prijava(
              id: 'p-2',
              idPonude: 'po-2',
              stanje: Poslata(kada: sat.sada()),
            ),
          ],
        ),
      ),
      act: ucitajPa(const PotvrdaMestaZatrazena(IdPrijave('p-1'))),
      skip: 3,
      expect: () => [
        isA<ProfilUcitan>().having((s) => s.obavestenje, 'obaveštenje', const MestoPotvrdjeno(brojPovucenih: 1)),
      ],
    );

    blocTest<ProfilBloc, ProfilStanje>(
      'brisanje prijave u pripremi: domen odbija, prijava ostaje',
      build: () => napravi(TestBaza(student: student, prijave: [prijava()])),
      act: ucitajPa(const BrisanjeZatrazeno(IdPrijave('p-1'))),
      skip: 3,
      expect: () => [
        isA<ProfilUcitan>()
            .having((s) => s.podaci.mojePrijave, 'moje prijave', hasLength(1))
            .having(
              (s) => s.obavestenje,
              'obaveštenje',
              isA<AkcijaOdbijena>().having((o) => o.greska, 'greška', isA<BrisanjeNijeMoguce>()),
            ),
      ],
    );

    blocTest<ProfilBloc, ProfilStanje>(
      'brisanje poslednje prijave vodi u prazno stanje',
      build: () => napravi(
        TestBaza(
          student: student,
          prijave: [prijava(stanje: Povucena(kada: sat.sada()))],
        ),
      ),
      act: ucitajPa(const BrisanjeZatrazeno(IdPrijave('p-1'))),
      skip: 3,
      expect: () => [isA<ProfilPrazan>().having((s) => s.obavestenje, 'obaveštenje', const PrijavaObrisana())],
    );

    final baza = TestBaza(
      student: student,
      prijave: [prijava(stanje: Poslata(kada: sat.sada()))],
    );
    blocTest<ProfilBloc, ProfilStanje>(
      'greška porta tokom akcije: podaci ostaju, uz poruku o neuspehu',
      build: () => napravi(baza),
      act: (bloc) async {
        bloc.add(const ProfilZatrazen());
        await Future<void>.delayed(Duration.zero);
        baza.greskaSledecegZahteva = true;
        bloc.add(const PovlacenjeZatrazeno(IdPrijave('p-1')));
      },
      skip: 3,
      expect: () => [
        isA<ProfilUcitan>()
            .having((s) => s.uToku, 'u toku', isNull)
            .having((s) => s.obavestenje, 'obaveštenje', isA<AkcijaNeuspela>()),
      ],
    );

    blocTest<ProfilBloc, ProfilStanje>(
      'izmena profila čuva studenta, a pročitana poruka se briše',
      build: () => napravi(TestBaza(student: student, prijave: [prijava()])),
      act: (bloc) async {
        bloc.add(const ProfilZatrazen());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ProfilIzmenjen(izmenjen));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ObavestenjeProfilaProcitano());
      },
      skip: 2,
      expect: () => [
        isA<ProfilUcitan>().having((s) => s.cuvaSeProfil, 'čuva se profil', isTrue),
        isA<ProfilUcitan>()
            .having((s) => s.cuvaSeProfil, 'čuva se profil', isFalse)
            .having((s) => s.podaci.student.prosek, 'prosek', 9.1)
            .having((s) => s.obavestenje, 'obaveštenje', const ProfilSacuvan()),
        isA<ProfilUcitan>().having((s) => s.obavestenje, 'obaveštenje', isNull),
      ],
    );
  });

  blocTest<ProfilBloc, ProfilStanje>(
    'izbor „Sačuvano" ostaje i posle osvežavanja',
    build: () => napravi(TestBaza(student: student, prijave: [prijava()])),
    act: (bloc) async {
      bloc.add(const ProfilZatrazen());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const PrikazProfilaPromenjen(PrikazProfila.sacuvano));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ProfilOsvezen());
    },
    skip: 2,
    expect: () => [isA<ProfilUcitan>().having((s) => s.prikaz, 'prikaz', PrikazProfila.sacuvano)],
  );
}
