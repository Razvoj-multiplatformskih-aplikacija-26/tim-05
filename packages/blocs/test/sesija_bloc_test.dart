import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

const student1 = Korisnik(id: IdKorisnika('s-1'), korisnickoIme: 'student1', uloga: Uloga.student);
const koordinator1 = Korisnik(
  id: IdKorisnika('k-1'),
  korisnickoIme: 'koordinator1',
  uloga: Uloga.koordinator,
  idUniverziteta: IdUniverziteta('u-polimi'),
);

final class ZapamcenaSesija implements SesijaRepository {
  ZapamcenaSesija(this.zapamcen);

  Korisnik? zapamcen;
  bool serverRadi = true;
  bool neocekivanaGreska = false;
  final _istekle = StreamController<void>.broadcast();

  void istekni() => _istekle.add(null);

  @override
  Future<Korisnik?> prijavi({required String korisnickoIme, required String lozinka}) async => null;

  @override
  Future<Korisnik?> trenutni() async {
    if (neocekivanaGreska) throw const FormatException('Oštećen zapis u skladištu');
    if (!serverRadi) throw const GreskaRepozitorijuma('Server nije dostupan', vrsta: VrstaKvara.nemaVeze);
    return zapamcen;
  }

  @override
  Future<void> odjavi() async {
    zapamcen = null;
    if (!serverRadi) throw const GreskaRepozitorijuma('Server nije dostupan', vrsta: VrstaKvara.nemaVeze);
  }

  @override
  Stream<void> get istekle => _istekle.stream;
}

void main() {
  late ZapamcenaSesija sesije;

  SesijaBloc mobilna() => SesijaBloc(
    obnoviSesiju: ObnoviSesiju(sesije: sesije),
    odjaviSe: OdjaviSe(sesije: sesije),
    dozvoljen: PravaPristupa.koristiMobilnuAplikaciju,
    istekle: sesije.istekle,
  );

  blocTest<SesijaBloc, SesijaStanje>(
    'zapamcena prijava prezivi ponovno pokretanje, a kada server kaze da je istekla, zavrsava se sa razlogom',
    setUp: () => sesije = ZapamcenaSesija(student1),
    build: mobilna,
    act: (bloc) async {
      bloc.add(const ObnovaSesijeZatrazena());
      await Future<void>.delayed(Duration.zero);
      sesije.istekni();
    },
    expect: () => [const Prijavljen(student1), const Odjavljen(razlog: RazlogOdjave.istekla)],
  );

  blocTest<SesijaBloc, SesijaStanje>(
    'bez zapamcene prijave: odjavljen, bez razloga (bez poruke)',
    setUp: () => sesije = ZapamcenaSesija(null),
    build: mobilna,
    act: (bloc) => bloc.add(const ObnovaSesijeZatrazena()),
    expect: () => [const Odjavljen()],
  );

  blocTest<SesijaBloc, SesijaStanje>(
    'server ne radi pri pokretanju: odjavljen sa razlogom „nedostupan", ne ceka bez kraja',
    setUp: () => sesije = ZapamcenaSesija(student1)..serverRadi = false,
    build: mobilna,
    act: (bloc) => bloc.add(const ObnovaSesijeZatrazena()),
    expect: () => [const Odjavljen(razlog: RazlogOdjave.nedostupan)],
  );

  blocTest<SesijaBloc, SesijaStanje>(
    'skladiste tokena ne može da se procita: odjavljen, bez cekanja bez kraja',
    setUp: () => sesije = ZapamcenaSesija(student1)..neocekivanaGreska = true,
    build: mobilna,
    act: (bloc) => bloc.add(const ObnovaSesijeZatrazena()),
    expect: () => [const Odjavljen()],
    errors: () => [isA<FormatException>()],
  );

  blocTest<SesijaBloc, SesijaStanje>(
    'koordinator u mobilnoj aplikaciji: odmah se odjavljuje (i na serveru), uz razlog za poruku',
    setUp: () => sesije = ZapamcenaSesija(koordinator1),
    build: mobilna,
    act: (bloc) => bloc.add(const SesijaZapoceta(koordinator1)),
    expect: () => [const Odjavljen(razlog: RazlogOdjave.pogresnaAplikacija)],
    verify: (_) => expect(sesije.zapamcen, isNull),
  );

  blocTest<SesijaBloc, SesijaStanje>(
    'odjava brise prijavu i kada server ne radi',
    setUp: () => sesije = ZapamcenaSesija(student1),
    build: mobilna,
    act: (bloc) async {
      bloc.add(const SesijaZapoceta(student1));
      await Future<void>.delayed(Duration.zero);
      sesije.serverRadi = false;
      bloc.add(const OdjavaZatrazena());
    },
    expect: () => [const Prijavljen(student1), const Odjavljen(razlog: RazlogOdjave.odjava)],
    errors: () => [isA<GreskaRepozitorijuma>()],
    verify: (_) => expect(sesije.zapamcen, isNull),
  );

  blocTest<SesijaBloc, SesijaStanje>(
    'istek dok niko nije prijavljen nista ne menja',
    setUp: () => sesije = ZapamcenaSesija(null),
    build: mobilna,
    act: (bloc) async {
      bloc.add(const ObnovaSesijeZatrazena());
      await Future<void>.delayed(Duration.zero);
      sesije.istekni();
    },
    expect: () => [const Odjavljen()],
  );
}
