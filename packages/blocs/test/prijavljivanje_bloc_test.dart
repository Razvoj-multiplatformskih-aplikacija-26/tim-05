import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

const student1 = Korisnik(id: IdKorisnika('s-1'), korisnickoIme: 'student1', uloga: Uloga.student);

final class JedanNalog implements SesijaRepository {
  bool serverRadi = true;
  String? poslednjeIme;

  @override
  Future<Korisnik?> prijavi({required String korisnickoIme, required String lozinka}) async {
    if (!serverRadi) throw const GreskaRepozitorijuma('Server nije dostupan', vrsta: VrstaKvara.nemaVeze);
    poslednjeIme = korisnickoIme;
    return korisnickoIme == 'student1' && lozinka == 'erasmus-demo' ? student1 : null;
  }

  @override
  Future<Korisnik?> trenutni() async => null;

  @override
  Future<void> odjavi() async {}

  @override
  Stream<void> get istekle => const Stream.empty();
}

void main() {
  late JedanNalog nalog;

  PrijavljivanjeBloc napravi() => PrijavljivanjeBloc(prijaviSe: PrijaviSe(sesije: nalog));

  blocTest<PrijavljivanjeBloc, PrijavljivanjeStanje>(
    'ispravni podaci: u toku, pa uspelo sa korisnikom; razmaci oko imena se uklanjaju',
    setUp: () => nalog = JedanNalog(),
    build: napravi,
    act: (bloc) => bloc.add(const PrijavljivanjeZatrazeno(korisnickoIme: ' student1 ', lozinka: 'erasmus-demo')),
    expect: () => [const PrijavljivanjeUToku(), const PrijavljivanjeUspelo(student1)],
    verify: (_) => expect(nalog.poslednjeIme, 'student1'),
  );

  blocTest<PrijavljivanjeBloc, PrijavljivanjeStanje>(
    'pogresna lozinka: odbijeno',
    setUp: () => nalog = JedanNalog(),
    build: napravi,
    act: (bloc) => bloc.add(const PrijavljivanjeZatrazeno(korisnickoIme: 'student1', lozinka: 'pogresna')),
    expect: () => [const PrijavljivanjeUToku(), const PrijavljivanjeOdbijeno()],
  );

  blocTest<PrijavljivanjeBloc, PrijavljivanjeStanje>(
    'server ne radi: neuspelo, sa uzrokom za poruku',
    setUp: () => nalog = JedanNalog()..serverRadi = false,
    build: napravi,
    act: (bloc) => bloc.add(const PrijavljivanjeZatrazeno(korisnickoIme: 'student1', lozinka: 'erasmus-demo')),
    expect: () => [
      const PrijavljivanjeUToku(),
      isA<PrijavljivanjeNeuspelo>().having(
        (s) => s.uzrok,
        'uzrok',
        isA<GreskaRepozitorijuma>().having((g) => g.vrsta, 'vrsta', VrstaKvara.nemaVeze),
      ),
    ],
  );
}
