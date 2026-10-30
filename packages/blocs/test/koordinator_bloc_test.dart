import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'pomocno.dart';
import 'test_baza.dart';

const koordinator = Korisnik(
  id: IdKorisnika('k-1'),
  korisnickoIme: 'koordinator.milano',
  uloga: Uloga.koordinator,
  idUniverziteta: IdUniverziteta('u-polimi'),
);

final poslata = Poslata(kada: DateTime(2026, 10, 21));
final prihvacena = Prihvacena(odlucio: koordinator.id, kada: DateTime(2026, 10, 22));

KoordinatorBloc napravi(TestBaza baza) => KoordinatorBloc(
  ucitajPregled: UcitajPregledKoordinatora(ponude: baza, prijave: baza, studenti: baza, sat: sat),
  prihvatiPrijavu: PrihvatiPrijavu(ponude: baza, prijave: baza, sat: sat),
  staviNaListuCekanja: StaviNaListuCekanja(ponude: baza, prijave: baza, sat: sat),
  odbijPrijavu: OdbijPrijavu(ponude: baza, prijave: baza, sat: sat),
  korisnik: koordinator,
);

TestBaza dvePrijave() => TestBaza(
  student: student,
  ponude: [
    ponuda(),
    ponuda(id: 'po-2'),
  ],
  prijave: [
    prijava(stanje: poslata),
    prijava(id: 'p-2', idPonude: 'po-2', stanje: poslata),
  ],
);

Future<void> sacekaj() => Future<void>.delayed(Duration.zero);

void main() {
  blocTest<KoordinatorBloc, KoordinatorStanje>(
    'učitava prijave i za svaku računa dozvoljene akcije iz domena',
    build: () => napravi(dvePrijave()),
    act: (bloc) => bloc.add(const PrijaveZatrazene()),
    expect: () => [
      const KoordinatorUcitavanje(),
      isA<KoordinatorUcitano>()
          .having((s) => s.prijave, 'prijave', hasLength(2))
          .having((s) => s.kursor, 'kursor', 0)
          .having((s) => s.izabrana, 'izabrana', isNull)
          .having((s) => s.akcijeZa(s.prijave.first), 'akcije', {
            AkcijaKoordinatora.prihvati,
            AkcijaKoordinatora.listaCekanja,
            AkcijaKoordinatora.odbij,
          }),
    ],
  );

  blocTest<KoordinatorBloc, KoordinatorStanje>(
    'prijava u pripremi se ne vidi, pa je ekran prazan',
    build: () => napravi(TestBaza(student: student, ponude: [ponuda()], prijave: [prijava()])),
    act: (bloc) => bloc.add(const PrijaveZatrazene()),
    expect: () => [const KoordinatorUcitavanje(), isA<KoordinatorPrazno>()],
  );

  blocTest<KoordinatorBloc, KoordinatorStanje>(
    'greška porta daje stanje greške',
    build: () => napravi(dvePrijave()..greskaSledecegZahteva = true),
    act: (bloc) => bloc.add(const PrijaveZatrazene()),
    expect: () => [const KoordinatorUcitavanje(), isA<KoordinatorGreska>()],
  );

  blocTest<KoordinatorBloc, KoordinatorStanje>(
    'kursor ostaje u granicama liste, a Enter otvara prijavu pod kursorom',
    build: () => napravi(dvePrijave()),
    act: (bloc) async {
      bloc.add(const PrijaveZatrazene());
      await sacekaj();
      bloc
        ..add(const KursorPomeren(5))
        ..add(const KursorAktiviran());
    },
    skip: 2,
    expect: () => [
      isA<KoordinatorUcitano>().having((s) => s.kursor, 'kursor', 1),
      isA<KoordinatorUcitano>().having((s) => s.izabrana, 'izabrana', const IdPrijave('p-2')),
    ],
  );

  blocTest<KoordinatorBloc, KoordinatorStanje>(
    'izbor iz adrese pomera kursor, a nepoznat ID se zanemaruje',
    build: () => napravi(dvePrijave()),
    act: (bloc) async {
      bloc.add(const PrijaveZatrazene());
      await sacekaj();
      bloc
        ..add(const PrijavaIzabrana(IdPrijave('p-2')))
        ..add(const PrijavaIzabrana(IdPrijave('nema')))
        ..add(const PrijavaIzabrana(null));
    },
    skip: 2,
    expect: () => [
      isA<KoordinatorUcitano>()
          .having((s) => s.izabrana, 'izabrana', const IdPrijave('p-2'))
          .having((s) => s.kursor, 'kursor', 1),
      isA<KoordinatorUcitano>().having((s) => s.izabrana, 'izabrana', isNull).having((s) => s.kursor, 'kursor', 1),
    ],
  );

  blocTest<KoordinatorBloc, KoordinatorStanje>(
    'prihvatanje: akcija traje, pa novi podaci uz poruku, a izbor ostaje',
    build: () => napravi(dvePrijave()),
    act: (bloc) async {
      bloc.add(const PrijaveZatrazene());
      await sacekaj();
      bloc.add(const PrijavaIzabrana(IdPrijave('p-1')));
      await sacekaj();
      bloc.add(const PrihvatanjeZatrazeno(IdPrijave('p-1')));
    },
    skip: 3,
    expect: () => [
      isA<KoordinatorUcitano>()
          .having((s) => s.uToku, 'u toku', const IdPrijave('p-1'))
          .having((s) => s.dozvoljeno(AkcijaKoordinatora.prihvati), 'dozvoljeno dok traje', isFalse),
      isA<KoordinatorUcitano>()
          .having((s) => s.uToku, 'u toku', isNull)
          .having((s) => s.izabrana, 'izabrana', const IdPrijave('p-1'))
          .having((s) => s.izabranaPrijava?.stanje, 'stanje', isA<Prihvacena>())
          .having((s) => s.obavestenje, 'obaveštenje', isA<OdlukaSacuvana>())
          // Iz prihvaćene prijave domen ne dozvoljava nijednu od tri odluke.
          .having((s) => s.akcijeZa(s.izabranaPrijava!), 'akcije', isEmpty),
    ],
  );

  blocTest<KoordinatorBloc, KoordinatorStanje>(
    'kad su mesta popunjena, dugme se ne nudi, a zahtev vraća grešku domena',
    build: () => napravi(
      TestBaza(
        student: student,
        ponude: [ponuda()],
        prijave: [
          prijava(id: 'p-8', stanje: prihvacena),
          prijava(id: 'p-9', stanje: prihvacena),
          prijava(stanje: poslata),
        ],
      ),
    ),
    act: (bloc) async {
      bloc.add(const PrijaveZatrazene());
      await sacekaj();
      bloc.add(const PrihvatanjeZatrazeno(IdPrijave('p-1')));
    },
    skip: 1,
    expect: () => [
      isA<KoordinatorUcitano>().having((s) => s.akcijeZa(s.podaci.prijava(const IdPrijave('p-1'))!), 'akcije', {
        AkcijaKoordinatora.listaCekanja,
        AkcijaKoordinatora.odbij,
      }),
      isA<KoordinatorUcitano>().having((s) => s.uToku, 'u toku', const IdPrijave('p-1')),
      isA<KoordinatorUcitano>()
          .having((s) => s.uToku, 'u toku', isNull)
          .having((s) => s.obavestenje, 'obaveštenje', const OdlukaOdbijena(NemaSlobodnihMesta())),
    ],
  );

  final baza = dvePrijave();
  blocTest<KoordinatorBloc, KoordinatorStanje>(
    'greška porta tokom odbijanja ostavlja podatke i daje poruku, koja se zatim briše',
    build: () => napravi(baza),
    act: (bloc) async {
      bloc.add(const PrijaveZatrazene());
      await sacekaj();
      baza.greskaSledecegZahteva = true;
      bloc.add(const OdbijanjeZatrazeno(IdPrijave('p-1'), razlog: 'Mesta su popunjena.'));
      await sacekaj();
      bloc.add(const ObavestenjeKoordinatoraProcitano());
    },
    skip: 2,
    expect: () => [
      isA<KoordinatorUcitano>().having((s) => s.uToku, 'u toku', const IdPrijave('p-1')),
      isA<KoordinatorUcitano>()
          .having((s) => s.uToku, 'u toku', isNull)
          .having((s) => s.prijave.first.stanje, 'stanje', isA<Poslata>())
          .having((s) => s.obavestenje, 'obaveštenje', isA<OdlukaNeuspela>()),
      isA<KoordinatorUcitano>().having((s) => s.obavestenje, 'obaveštenje', isNull),
    ],
  );
}
