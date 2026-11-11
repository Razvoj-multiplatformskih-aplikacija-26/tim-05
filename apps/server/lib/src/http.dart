import 'dart:convert';
import 'dart:io';

import 'package:api_contract/api_contract.dart';
import 'package:relic/relic.dart';

final _mimeProblema = MimeType.parse(ProblemDto.mediaType);

Response json(int status, Object? telo) =>
    Response(status, body: Body.fromString(jsonEncode(telo), mimeType: MimeType.json));

Response odgovorSaProblemom(ProblemDto problem) =>
    Response(problem.status, body: Body.fromString(jsonEncode(problem.toJson()), mimeType: _mimeProblema));

Response losZahtev(String naslov) =>
    odgovorSaProblemom(ProblemDto(status: 400, code: KodoviGresaka.losZahtev, title: naslov));

const najviseBajtovaTela = 16 * 1024;

final class NepodrzanTipSadrzaja implements Exception {
  const NepodrzanTipSadrzaja();
}

Future<Map<String, Object?>> procitajObjekat(Request zahtev) async {
  if (zahtev.mimeType != MimeType.json) throw const NepodrzanTipSadrzaja();
  return switch (jsonDecode(await zahtev.readAsString(maxLength: najviseBajtovaTela))) {
    final Map<String, Object?> objekat => objekat,
    _ => throw const FormatException('Expected a JSON object'),
  };
}

Middleware obradaGresaka() =>
    (Handler sledeci) => (Request zahtev) async {
      try {
        return await sledeci(zahtev);
      } on FormatException catch (greska) {
        return losZahtev(greska.message);
      } on NepodrzanTipSadrzaja {
        return odgovorSaProblemom(nepodrzanTipSadrzaja);
      } on MaxBodySizeExceeded {
        return odgovorSaProblemom(prevelikZahtev);
      } catch (greska, trag) {
        stderr.writeln('${zahtev.method} ${zahtev.url.path}: $greska\n$trag');
        return odgovorSaProblemom(greskaServera);
      }
    };

const nepodrzanTipSadrzaja = ProblemDto(
  status: 415,
  code: KodoviGresaka.nepodrzanTipSadrzaja,
  title: 'Expected application/json',
);

const prevelikZahtev = ProblemDto(status: 413, code: KodoviGresaka.prevelikZahtev, title: 'Request body too large');

const greskaServera = ProblemDto(status: 500, code: KodoviGresaka.greskaServera, title: 'Server error');

const nepoznataRuta = ProblemDto(status: 404, code: KodoviGresaka.nijePronadjeno, title: 'No such route');