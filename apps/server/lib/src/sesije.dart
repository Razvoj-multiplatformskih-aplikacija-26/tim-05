import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:domain/domain.dart';
import 'package:relic/relic.dart';

import 'http.dart';
import 'nalozi.dart';
import 'passwords.dart';

final class Sesija {
  const Sesija({required this.korisnik, required this.istice});

  final Korisnik korisnik;
  final DateTime istice;
}

final trenutnaSesija = ContextProperty<Sesija>('sesija');

const _potrebnaPrijava = ProblemDto(status: 401, code: KodoviGresaka.potrebnaPrijava, title: 'Sign in required');
const _sesijaIstekla = ProblemDto(status: 401, code: KodoviGresaka.sesijaIstekla, title: 'Session expired');
const _pogresniPodaci = ProblemDto(
  status: 401,
  code: KodoviGresaka.pogresniPodaciZaPrijavu,
  title: 'Invalid credentials',
);
const _algoritam = JWTAlgorithm.HS256;

final class RukovaociSesija {
  RukovaociSesija({required this.nalozi, required String tajna, required this.trajanje, this.bezbedanKolacic = false})
    : _kljuc = SecretKey(tajna),
      _hesBezNaloga = hashPassword('nalog ne postoji');

  final SkladisteNaloga nalozi;
  final Duration trajanje;
  final bool bezbedanKolacic;
  final SecretKey _kljuc;

  final Future<String> _hesBezNaloga;

  Handler prijavljen(Handler rukovalac) => (Request zahtev) async {
    final token = _tokenIz(zahtev);
    if (token == null) return _neovlascen(_potrebnaPrijava);
    final sesija = _proveri(token);
    if (sesija == null) return _neovlascen(_sesijaIstekla);
    trenutnaSesija[zahtev] = sesija;
    return rukovalac(zahtev);
  };

  Future<Response> prijava(Request zahtev) async {
    final telo = PrijavljivanjeDto.fromJson(await procitajObjekat(zahtev));
    final nalog = await nalozi.nalog(telo.korisnickoIme);
    final lozinkaJeDobra = await verifyPassword(telo.lozinka, nalog?.lozinkaHes ?? await _hesBezNaloga);
    if (nalog == null || !lozinkaJeDobra) return _neovlascen(_pogresniPodaci);

    final korisnik = nalog.korisnik;
    final token = JWT({
      'name': korisnik.korisnickoIme,
      'role': korisnik.uloga.toDto(),
      'university': ?korisnik.idUniverziteta?.vrednost,
    }, subject: korisnik.id.vrednost).sign(_kljuc, algorithm: _algoritam, expiresIn: trajanje);
    final istice = _proveri(token)!.istice;

    final odgovor = json(
      201,
      SesijaDto(korisnik: korisnik.toDto(), istice: istice, token: telo.kolacic ? null : token).toJson(),
    );
    if (!telo.kolacic) return odgovor;
    return odgovor.copyWith(
      headers: odgovor.headers.transform(
        (zaglavlja) => zaglavlja.setCookie = _kolacic(token, trajanjeSekundi: trajanje.inSeconds),
      ),
    );
  }

  Future<Response> trenutna(Request zahtev) async {
    final sesija = trenutnaSesija.get(zahtev);
    return json(200, SesijaDto(korisnik: sesija.korisnik.toDto(), istice: sesija.istice).toJson());
  }

  Future<Response> odjava(Request zahtev) async =>
      Response.noContent(headers: Headers.build((zaglavlja) => zaglavlja.setCookie = _kolacic('', trajanjeSekundi: 0)));

  SetCookieHeader _kolacic(String vrednost, {required int trajanjeSekundi}) => SetCookieHeader(
    name: ApiKolacici.sesija,
    value: vrednost,
    path: Uri.parse('/'),
    maxAge: trajanjeSekundi,
    httpOnly: true,
    secure: bezbedanKolacic,
    sameSite: SameSite.lax,
  );

  Response _neovlascen(ProblemDto problem) {
    final odgovor = odgovorSaProblemom(problem);
    return odgovor.copyWith(
      headers: odgovor.headers.transform((zaglavlja) => zaglavlja['WWW-Authenticate'] = ['Bearer']),
    );
  }

  Sesija? _proveri(String token) {
    try {
      if (JWT.decode(token).header?['alg'] != _algoritam.name) return null;
      return switch (JWT.verify(token, _kljuc).payload) {
        {'sub': final String id, 'name': final String ime, 'role': final String uloga, 'exp': final int exp} &&
            final Map<String, Object?> podaci =>
          Sesija(
            korisnik: KorisnikDto(
              id: id,
              korisnickoIme: ime,
              uloga: uloga,
              idUniverziteta: podaci['university'] as String?,
            ).toDomain(),
            istice: DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true),
          ),
        _ => null,
      };
    } on JWTException {
      return null;
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    } on TypeError {
      return null;
    }
  }

  String? _tokenIz(Request zahtev) => switch (zahtev.headers.authorization) {
    BearerAuthorizationHeader(:final token) => token,
    _ => zahtev.headers.cookie?.getCookie(ApiKolacici.sesija)?.value,
  };
}