import 'dart:async';
import 'dart:convert';

import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:http/http.dart' as http;
import 'package:use_cases/use_cases.dart';

import 'platform_client.dart';
import 'token_store.dart';

sealed class ApiOdgovor {
  const ApiOdgovor();
}

final class ApiPrihvacen extends ApiOdgovor {
  const ApiPrihvacen(this.json);

  final Object? json;
}

final class ApiOdbijen extends ApiOdgovor {
  const ApiOdbijen(this.greska);

  final GreskaDomena greska;
}

final class ApiOdbacen extends ApiOdgovor {
  const ApiOdbacen(this.problem);

  final ProblemDto problem;
}

final class ApiKlijent {
  ApiKlijent({
    required this.adresa,
    TokenStore? tokeni,
    http.Client? httpKlijent,
    this.sesijaUKolacicu = platformKeepsSessionInCookie,
    this.cekanje = const Duration(seconds: 10),
  }) : tokeni = tokeni ?? MemoryTokenStore(),
       _http = httpKlijent ?? platformHttpClient();

  final Uri adresa;
  final TokenStore tokeni;

  final bool sesijaUKolacicu;

  final Duration cekanje;
  final http.Client _http;
  final _istekle = StreamController<void>.broadcast();

  Stream<void> get istekle => _istekle.stream;

  Future<ApiOdgovor> get(String putanja) => _posalji('GET', putanja);

  Future<ApiOdgovor> post(String putanja, {Map<String, Object?>? telo}) => _posalji('POST', putanja, telo: telo);

  Future<ApiOdgovor> delete(String putanja) => _posalji('DELETE', putanja);

  Future<ApiOdgovor> _posalji(String metoda, String putanja, {Map<String, Object?>? telo}) async {
    final zahtev = http.Request(metoda, adresa.replace(path: putanja))..headers['Accept'] = 'application/json';
    if (!sesijaUKolacicu) {
      if (await tokeni.read() case final token?) zahtev.headers['Authorization'] = 'Bearer $token';
    }
    if (telo != null) {
      zahtev
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(telo);
    }
    final http.Response odgovor;
    try {
      odgovor = await _http.send(zahtev).then(http.Response.fromStream).timeout(cekanje);
    } on http.ClientException catch (uzrok) {
      throw GreskaRepozitorijuma('Server nije dostupan', vrsta: VrstaKvara.nemaVeze, uzrok: uzrok);
    } on TimeoutException catch (uzrok) {
      throw GreskaRepozitorijuma('Server nije odgovorio', vrsta: VrstaKvara.nemaVeze, uzrok: uzrok);
    }
    return _odgovorIz(odgovor);
  }

  ApiOdgovor _odgovorIz(http.Response odgovor) {
    final status = odgovor.statusCode;
    final json = procitaj(() => odgovor.body.isEmpty ? null : jsonDecode(utf8.decode(odgovor.bodyBytes)));
    if (status >= 200 && status < 300) return ApiPrihvacen(json);
    if (status >= 400 && status < 500 && json is Map<String, Object?>) {
      final problem = procitaj(() => ProblemDto.fromJson(json));
      if (problem.code case KodoviGresaka.sesijaIstekla || KodoviGresaka.potrebnaPrijava) {
        _istekle.add(null);
        throw const GreskaRepozitorijuma('Prijava je istekla', vrsta: VrstaKvara.sesijaIstekla);
      }
      return switch (problem.toDomainError()) {
        final greska? => ApiOdbijen(greska),
        null => ApiOdbacen(problem),
      };
    }
    throw GreskaRepozitorijuma('Server je odgovorio sa $status', vrsta: VrstaKvara.greskaServera);
  }
}

T procitaj<T>(T Function() citanje) {
  try {
    return citanje();
  } on FormatException catch (uzrok) {
    throw GreskaRepozitorijuma('Nečitljiv odgovor servera', vrsta: VrstaKvara.greskaServera, uzrok: uzrok);
  } on ArgumentError catch (uzrok) {
    throw GreskaRepozitorijuma('Nečitljiv odgovor servera', vrsta: VrstaKvara.greskaServera, uzrok: uzrok);
  }
}

T prihvaceno<T>(ApiOdgovor odgovor, T Function(Object? json) citanje) => switch (odgovor) {
  ApiPrihvacen(:final json) => procitaj(() => citanje(json)),
  ApiOdbijen(:final greska) => throw GreskaRepozitorijuma(
    'Neočekivano odbijanje: $greska',
    vrsta: VrstaKvara.greskaServera,
  ),
  ApiOdbacen(:final problem) => throw GreskaRepozitorijuma(
    'Server nije prihvatio zahtev: ${problem.code}',
    vrsta: VrstaKvara.odbijeno,
  ),
};


Rezultat<T> rezultat<T>(ApiOdgovor odgovor, T Function(Object? json) citanje) => switch (odgovor) {
  ApiPrihvacen(:final json) => Uspeh(procitaj(() => citanje(json))),
  ApiOdbijen(:final greska) => Neuspeh(greska),
  ApiOdbacen(:final problem) => throw GreskaRepozitorijuma(
    'Server nije prihvatio zahtev: ${problem.code}',
    vrsta: VrstaKvara.odbijeno,
  ),
};

Map<String, Object?> objekat(Object? json) => switch (json) {
  final Map<String, Object?> objekat => objekat,
  _ => throw FormatException('Expected a JSON object', json),
};

List<Map<String, Object?>> objekti(Object? json) => switch (json) {
  final List<Object?> lista => [for (final o in lista) objekat(o)],
  _ => throw FormatException('Expected a JSON list', json),
};