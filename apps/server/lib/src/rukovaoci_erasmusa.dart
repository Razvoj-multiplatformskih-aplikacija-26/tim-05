import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:relic/relic.dart';
import 'package:use_cases/use_cases.dart';

import 'http.dart';
import 'postgres_erasmus.dart';
import 'sesije.dart';


final class RukovaociErasmusa {
  RukovaociErasmusa({required this.skladiste, required Sat sat})
    : _sacuvajPrijavu = SacuvajPrijavu(ponude: skladiste, prijave: skladiste, studenti: skladiste, sat: sat),
      _povuciPrijavu = PovuciPrijavu(ponude: skladiste, prijave: skladiste, sat: sat),
      _potvrdiMesto = PotvrdiMesto(ponude: skladiste, prijave: skladiste, sat: sat),
      _odbijMesto = OdbijMesto(ponude: skladiste, prijave: skladiste, sat: sat),
      _obrisiPrijavu = ObrisiPrijavu(ponude: skladiste, prijave: skladiste),
      _prihvatiPrijavu = PrihvatiPrijavu(ponude: skladiste, prijave: skladiste, sat: sat),
      _staviNaListuCekanja = StaviNaListuCekanja(ponude: skladiste, prijave: skladiste, sat: sat),
      _odbijPrijavu = OdbijPrijavu(ponude: skladiste, prijave: skladiste, sat: sat),
      _sacuvajProfil = SacuvajProfil(studenti: skladiste),
      _promeniSacuvanu = PromeniSacuvanu(studenti: skladiste);

  final PostgresErasmus skladiste;
  final SacuvajPrijavu _sacuvajPrijavu;
  final PovuciPrijavu _povuciPrijavu;
  final PotvrdiMesto _potvrdiMesto;
  final OdbijMesto _odbijMesto;
  final ObrisiPrijavu _obrisiPrijavu;
  final PrihvatiPrijavu _prihvatiPrijavu;
  final StaviNaListuCekanja _staviNaListuCekanja;
  final OdbijPrijavu _odbijPrijavu;
  final SacuvajProfil _sacuvajProfil;
  final PromeniSacuvanu _promeniSacuvanu;

  // javno, bez prijave

  Future<Response> univerziteti(Request zahtev) async =>
      json(200, [for (final u in await skladiste.univerziteti()) u.toDto().toJson()]);

  Future<Response> ponude(Request zahtev) async {
    final zauzeto = await skladiste.zauzetaMesta();
    return json(200, [for (final p in await skladiste.ponude()) p.toDto(zauzeto: zauzeto[p.id] ?? 0).toJson()]);
  }

  // prijave: čitanje

  Future<Response> prijava(Request zahtev) async {
    final ko = _ko(zahtev);
    final prijava = await skladiste.prijava(IdPrijave(_parametar(zahtev, #id)));
    if (prijava == null || !await smeDaVidi(ko, prijava, skladiste)) return problem(const NijePronadjeno());
    return json(200, prijava.toDto().toJson());
  }

  Future<Response> prijaveStudenta(Request zahtev) async {
    final ko = _ko(zahtev);
    final id = IdKorisnika(_parametar(zahtev, #id));
    if (!PravaPristupa.koristiMobilnuAplikaciju(ko) || ko.id != id) return problem(const NijePronadjeno());
    return json(200, [for (final p in await skladiste.prijaveStudenta(id)) p.toDto().toJson()]);
  }

  Future<Response> prijaveUniverziteta(Request zahtev) async {
    final ko = _ko(zahtev);
    final id = IdUniverziteta(_parametar(zahtev, #id));
    if (!PravaPristupa.koristiBackoffice(ko)) return problem(const NemaPravo());
    if (ko.idUniverziteta != id) return problem(const NijePronadjeno());
    return json(200, [for (final p in await skladiste.prijaveNaPonudeUniverziteta(id)) p.toDto().toJson()]);
  }

  // prijave: akcije studenta

  Future<Response> nova(Request zahtev) async {
    final telo = NovaPrijavaDto.fromJson(await procitajObjekat(zahtev));
    final pismo = MotivacionoPismo.proveri(telo.motivacionoPismo);
    if (pismo case Neuspeh(:final greska)) return problem(greska);
    final rezultat = await _sacuvajPrijavu(
      ko: _ko(zahtev),
      idPonude: IdPonude(telo.idPonude),
      pismo: pismo.vrednostIliNull!,
      napomena: telo.napomena,
      posalji: telo.posalji,
    );
    return odgovor(rezultat, status: 201);
  }

  Future<Response> izmena(Request zahtev) async {
    final telo = IzmenaPrijaveDto.fromJson(await procitajObjekat(zahtev));
    final pismo = MotivacionoPismo.proveri(telo.motivacionoPismo);
    if (pismo case Neuspeh(:final greska)) return problem(greska);
    return odgovor(
      await _sacuvajPrijavu(
        ko: _ko(zahtev),
        idPrijave: IdPrijave(_parametar(zahtev, #id)),
        pismo: pismo.vrednostIliNull!,
        napomena: telo.napomena,
        posalji: telo.posalji,
      ),
    );
  }

  Future<Response> povlacenje(Request zahtev) async =>
      odgovor(await _povuciPrijavu(ko: _ko(zahtev), id: IdPrijave(_parametar(zahtev, #id))));

  Future<Response> odbijanjeMesta(Request zahtev) async =>
      odgovor(await _odbijMesto(ko: _ko(zahtev), id: IdPrijave(_parametar(zahtev, #id))));

  Future<Response> potvrdaMesta(Request zahtev) async =>
      switch (await _potvrdiMesto(ko: _ko(zahtev), id: IdPrijave(_parametar(zahtev, #id)))) {
        Uspeh(:final vrednost) => json(200, [for (final p in vrednost) p.toDto().toJson()]),
        Neuspeh(:final greska) => problem(greska),
      };

  Future<Response> brisanje(Request zahtev) async =>
      switch (await _obrisiPrijavu(ko: _ko(zahtev), id: IdPrijave(_parametar(zahtev, #id)))) {
        Uspeh() => Response.noContent(),
        Neuspeh(:final greska) => problem(greska),
      };

  // prijave: akcije koordinatora

  Future<Response> prihvatanje(Request zahtev) async =>
      odgovor(await _prihvatiPrijavu(ko: _ko(zahtev), id: IdPrijave(_parametar(zahtev, #id))));

  Future<Response> listaCekanja(Request zahtev) async =>
      odgovor(await _staviNaListuCekanja(ko: _ko(zahtev), id: IdPrijave(_parametar(zahtev, #id))));

  Future<Response> odbijanje(Request zahtev) async {
    final telo = OdbijanjeDto.fromJson(await procitajObjekat(zahtev));
    return odgovor(await _odbijPrijavu(ko: _ko(zahtev), id: IdPrijave(_parametar(zahtev, #id)), razlog: telo.razlog));
  }

  // studenti

  Future<Response> student(Request zahtev) async {
    final ko = _ko(zahtev);
    final id = IdKorisnika(_parametar(zahtev, #id));
    if (!await _smeDaVidiStudenta(ko, id)) return problem(const NijePronadjeno());
    final student = await skladiste.studentAkoPostoji(id);
    if (student == null) return problem(const NijePronadjeno());
    return json(200, student.toDto().toJson());
  }

  Future<Response> profil(Request zahtev) async {
    final ko = _ko(zahtev);
    final id = IdKorisnika(_parametar(zahtev, #id));
    if (PravaPristupa.koristiMobilnuAplikaciju(ko) && ko.id != id) return problem(const NijePronadjeno());
    final telo = StudentDto.fromJson(await procitajObjekat(zahtev));
    if (telo.id != id.vrednost) return losZahtev('Student id in the body does not match the path');
    final student = telo.toDomain();
    if (student case Neuspeh(:final greska)) return problem(greska);
    return switch (await _sacuvajProfil(ko: ko, student: student.vrednostIliNull!)) {
      Uspeh(:final vrednost) => json(200, vrednost.toDto().toJson()),
      Neuspeh(:final greska) => problem(greska),
    };
  }

  Future<Response> sacuvanePonude(Request zahtev) async {
    final ko = _ko(zahtev);
    final id = IdKorisnika(_parametar(zahtev, #id));
    if (!PravaPristupa.koristiMobilnuAplikaciju(ko) || ko.id != id) return problem(const NijePronadjeno());
    return json(200, [for (final p in await skladiste.sacuvanePonude(id)) p.vrednost]);
  }

  Future<Response> promenaSacuvane(Request zahtev) async {
    final ko = _ko(zahtev);
    final id = IdKorisnika(_parametar(zahtev, #id));
    if (!PravaPristupa.koristiMobilnuAplikaciju(ko) || ko.id != id) return problem(const NijePronadjeno());
    await _promeniSacuvanu(ko: ko, idPonude: IdPonude(_parametar(zahtev, #idPonude)));
    return json(200, [for (final p in await skladiste.sacuvanePonude(id)) p.vrednost]);
  }

  Future<bool> _smeDaVidiStudenta(Korisnik ko, IdKorisnika id) async => switch (ko.uloga) {
    Uloga.student => ko.id == id,
    Uloga.koordinator => (await skladiste.prijaveNaPonudeUniverziteta(
      ko.idUniverziteta!,
    )).any((p) => p.idStudenta == id),
  };

  // pomoćno

  Korisnik _ko(Request zahtev) => trenutnaSesija.get(zahtev).korisnik;

  String _parametar(Request zahtev, Symbol ime) => zahtev.rawPathParameters[ime]!;
}

Response odgovor(Rezultat<Prijava> rezultat, {int status = 200}) => switch (rezultat) {
  Uspeh(:final vrednost) => json(status, vrednost.toDto().toJson()),
  Neuspeh(:final greska) => problem(greska),
};