import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart';

final class Nalog {
  const Nalog({required this.korisnik, required this.lozinkaHes});

  final Korisnik korisnik;
  final String lozinkaHes;
}

final class SkladisteNaloga {
  const SkladisteNaloga(this._baza);

  final Session _baza;

  Future<Nalog?> nalog(String korisnickoIme) async {
    final redovi = await _baza.execute(
      Sql.named(
        'SELECT id, korisnicko_ime, uloga, id_univerziteta, lozinka_hes FROM korisnici '
        'WHERE korisnicko_ime = @ime AND lozinka_hes IS NOT NULL',
      ),
      parameters: {'ime': korisnickoIme},
    );
    if (redovi.isEmpty) return null;
    final [id, ime, uloga, univerzitet, hes] = redovi.single;
    return Nalog(
      korisnik: Korisnik(
        id: IdKorisnika(id! as String),
        korisnickoIme: ime! as String,
        uloga: Uloga.values.byName(uloga! as String),
        idUniverziteta: switch (univerzitet) {
          final String id => IdUniverziteta(id),
          _ => null,
        },
      ),
      lozinkaHes: hes! as String,
    );
  }
}