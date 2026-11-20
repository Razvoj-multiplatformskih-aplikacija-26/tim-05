import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'api_klijent.dart';

final class HttpPonudaRepository implements PonudaRepository {
  const HttpPonudaRepository(this._api);

  final ApiKlijent _api;

  @override
  Future<List<Ponuda>> ponude() async => prihvaceno(
    await _api.get(ApiPutanje.ponude),
    (json) => [for (final o in objekti(json)) PonudaDto.fromJson(o).toDomain()],
  );

  @override
  Future<List<Univerzitet>> univerziteti() async => prihvaceno(
    await _api.get(ApiPutanje.univerziteti),
    (json) => [for (final o in objekti(json)) UniverzitetDto.fromJson(o).toDomain()],
  );

  @override
  Future<Map<IdPonude, int>> zauzetaMesta() async => prihvaceno(
    await _api.get(ApiPutanje.ponude),
    (json) => zauzetaMestaIz([for (final o in objekti(json)) PonudaDto.fromJson(o)]),
  );
}

final class HttpPrijavaRepository implements PrijavaRepository {
  const HttpPrijavaRepository(this._api);

  final ApiKlijent _api;

  @override
  Future<Prijava?> prijava(IdPrijave id) async {
    final odgovor = await _api.get(ApiPutanje.prijava(id.vrednost));
    if (odgovor case ApiOdbijen(greska: NijePronadjeno())) return null;
    return prihvaceno(odgovor, _prijava);
  }

  @override
  Future<List<Prijava>> prijaveStudenta(IdKorisnika idStudenta) async =>
      prihvaceno(await _api.get(ApiPutanje.prijaveStudenta(idStudenta.vrednost)), _prijave);

  @override
  Future<List<Prijava>> prijaveNaPonudeUniverziteta(IdUniverziteta idUniverziteta) async =>
      prihvaceno(await _api.get(ApiPutanje.prijaveUniverziteta(idUniverziteta.vrednost)), _prijave);

  @override
  Future<Rezultat<Prijava>> napravi(Prijava nova) async =>
      rezultat(await _api.post(ApiPutanje.prijave, telo: nova.toNovaDto().toJson()), _prijava);

  @override
  Future<Rezultat<Prijava>> sacuvaj(Prijava nova, {required StanjePrijave iz}) async {
    final id = nova.id.vrednost;
    final odgovor = await switch (nova.stanje) {
      UPripremi() || Poslata() => _api.post(ApiPutanje.izmena(id), telo: nova.toIzmenaDto().toJson()),
      Povucena() when iz is Prihvacena => _api.post(ApiPutanje.odbijanjeMesta(id)),
      Povucena() => _api.post(ApiPutanje.povlacenje(id)),
      Prihvacena() => _api.post(ApiPutanje.prihvatanje(id)),
      NaListiCekanja() => _api.post(ApiPutanje.listaCekanja(id)),
      Odbijena(:final razlog) => _api.post(ApiPutanje.odbijanje(id), telo: OdbijanjeDto(razlog: razlog).toJson()),
      Potvrdjena() => throw ArgumentError.value(nova, 'nova', 'Potvrda mesta ide kroz potvrdiMesto'),
    };
    return rezultat(odgovor, _prijava);
  }

  @override
  Future<Rezultat<List<Prijava>>> potvrdiMesto(Prijava potvrdjena, {required List<Prijava> povucene}) async =>
      rezultat(await _api.post(ApiPutanje.potvrdaMesta(potvrdjena.id.vrednost)), _prijave);

  @override
  Future<void> obrisi(IdPrijave id) async {
    final odgovor = await _api.delete(ApiPutanje.prijava(id.vrednost));
    if (odgovor case ApiOdbijen(:final greska)) {
      throw GreskaRepozitorijuma('Brisanje odbijeno: $greska', vrsta: VrstaKvara.odbijeno);
    }
    prihvaceno(odgovor, (_) {});
  }

  Prijava _prijava(Object? json) => PrijavaDto.fromJson(objekat(json)).toDomain();

  List<Prijava> _prijave(Object? json) => [for (final o in objekti(json)) PrijavaDto.fromJson(o).toDomain()];
}

final class HttpStudentRepository implements StudentRepository {
  const HttpStudentRepository(this._api);

  final ApiKlijent _api;

  @override
  Future<Student> student(IdKorisnika id) async => prihvaceno(
    await _api.get(ApiPutanje.student(id.vrednost)),
    (json) => switch (StudentDto.fromJson(objekat(json)).toDomain()) {
      Uspeh(:final vrednost) => vrednost,
      Neuspeh(:final greska) => throw FormatException('Profil sa servera krši pravilo domena', greska),
    },
  );

  @override
  Future<void> sacuvajStudenta(Student student) async {
    final odgovor = await _api.post(ApiPutanje.profil(student.id.vrednost), telo: student.toDto().toJson());
    if (odgovor case ApiOdbijen(:final greska)) {
      throw GreskaRepozitorijuma('Profil odbijen: $greska', vrsta: VrstaKvara.odbijeno);
    }
    prihvaceno(odgovor, (_) {});
  }

  @override
  Future<Set<IdPonude>> sacuvanePonude(IdKorisnika idStudenta) async =>
      prihvaceno(await _api.get(ApiPutanje.sacuvanePonude(idStudenta.vrednost)), _idPonuda);

  @override
  Future<void> promeniSacuvanu(IdKorisnika idStudenta, IdPonude idPonude) async =>
      prihvaceno(await _api.post(ApiPutanje.promenaSacuvane(idStudenta.vrednost, idPonude.vrednost)), _idPonuda);

  Set<IdPonude> _idPonuda(Object? json) => switch (json) {
    final List<Object?> lista => {
      for (final id in lista)
        switch (id) {
          final String id => IdPonude(id),
          _ => throw FormatException('Expected an offer id', id),
        },
    },
    _ => throw FormatException('Expected a JSON list', json),
  };
}

final class HttpSesijaRepository implements SesijaRepository {
  const HttpSesijaRepository(this._api);

  final ApiKlijent _api;

  @override
  Future<Korisnik?> prijavi({required String korisnickoIme, required String lozinka}) async {
    final zahtev = PrijavljivanjeDto(korisnickoIme: korisnickoIme, lozinka: lozinka, kolacic: _api.sesijaUKolacicu);
    final odgovor = await _api.post(ApiPutanje.sesije, telo: zahtev.toJson());
    if (odgovor case ApiOdbacen(problem: ProblemDto(code: KodoviGresaka.pogresniPodaciZaPrijavu))) return null;
    final sesija = prihvaceno(odgovor, (json) => SesijaDto.fromJson(objekat(json)));
    if (sesija.token case final token?) await _api.tokeni.write(token);
    return procitaj(() => sesija.korisnik.toDomain());
  }

  @override
  Future<Korisnik?> trenutni() async {
    if (!_api.sesijaUKolacicu && await _api.tokeni.read() == null) return null;
    try {
      final odgovor = await _api.get(ApiPutanje.trenutnaSesija);
      return prihvaceno<Korisnik>(odgovor, (json) => SesijaDto.fromJson(objekat(json)).korisnik.toDomain());
    } on GreskaRepozitorijuma catch (greska) {
      if (greska.vrsta != VrstaKvara.sesijaIstekla) rethrow;
      await _api.tokeni.clear();
      return null;
    }
  }

  @override
  Future<void> odjavi() async {
    try {
      await _api.delete(ApiPutanje.trenutnaSesija);
    } finally {
      await _api.tokeni.clear();
    }
  }

  @override
  Stream<void> get istekle => _api.istekle;
}