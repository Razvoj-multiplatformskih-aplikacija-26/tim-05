import 'dart:async';

import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'lazni_podaci.dart';

const lazniKoordinator = Korisnik(
  id: IdKorisnika('k-1'),
  korisnickoIme: 'koordinator1',
  uloga: Uloga.koordinator,
  idUniverziteta: IdUniverziteta('u-polimi'),
);

final class LazneSesije implements SesijaRepository {
  LazneSesije({this._prijavljen});

  static const nalozi = {'student1': pocetniKorisnik, 'koordinator1': lazniKoordinator};

  Korisnik? _prijavljen;
  final _istekle = StreamController<void>.broadcast();

  void istekni() {
    _prijavljen = null;
    _istekle.add(null);
  }

  @override
  Future<Korisnik?> prijavi({required String korisnickoIme, required String lozinka}) async {
    if (lozinka.isEmpty) return null;
    return _prijavljen = nalozi[korisnickoIme];
  }

  @override
  Future<Korisnik?> trenutni() async => _prijavljen;

  @override
  Future<void> odjavi() async => _prijavljen = null;

  @override
  Stream<void> get istekle => _istekle.stream;
}
