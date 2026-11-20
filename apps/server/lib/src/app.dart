import 'package:api_contract/api_contract.dart';
import 'package:relic/relic.dart';

import 'cors.dart';
import 'http.dart';
import 'rukovaoci_erasmusa.dart';
import 'sesije.dart';

Handler napraviHandler(
  RukovaociSesija sesije, {
  required RukovaociErasmusa erasmus,
  required List<String> dozvoljenaPorekla,
}) {
  final prijavljen = sesije.prijavljen;
  final router = RelicRouter()
    ..get(ApiPutanje.zdravlje, (zahtev) => Response.ok(body: Body.fromString('ok')))
    ..post(ApiPutanje.sesije, sesije.prijava)
    ..get(ApiPutanje.trenutnaSesija, prijavljen(sesije.trenutna))
    ..delete(ApiPutanje.trenutnaSesija, prijavljen(sesije.odjava))
    ..get(ApiPutanje.univerziteti, erasmus.univerziteti)
    ..get(ApiPutanje.ponude, erasmus.ponude)
    ..post(ApiPutanje.prijave, prijavljen(erasmus.nova))
    ..get(ApiPutanje.prijava(':id'), prijavljen(erasmus.prijava))
    ..delete(ApiPutanje.prijava(':id'), prijavljen(erasmus.brisanje))
    ..post(ApiPutanje.izmena(':id'), prijavljen(erasmus.izmena))
    ..post(ApiPutanje.povlacenje(':id'), prijavljen(erasmus.povlacenje))
    ..post(ApiPutanje.potvrdaMesta(':id'), prijavljen(erasmus.potvrdaMesta))
    ..post(ApiPutanje.odbijanjeMesta(':id'), prijavljen(erasmus.odbijanjeMesta))
    ..post(ApiPutanje.prihvatanje(':id'), prijavljen(erasmus.prihvatanje))
    ..post(ApiPutanje.listaCekanja(':id'), prijavljen(erasmus.listaCekanja))
    ..post(ApiPutanje.odbijanje(':id'), prijavljen(erasmus.odbijanje))
    ..get(ApiPutanje.prijaveStudenta(':id'), prijavljen(erasmus.prijaveStudenta))
    ..get(ApiPutanje.prijaveUniverziteta(':id'), prijavljen(erasmus.prijaveUniverziteta))
    ..get(ApiPutanje.student(':id'), prijavljen(erasmus.student))
    ..post(ApiPutanje.profil(':id'), prijavljen(erasmus.profil))
    ..get(ApiPutanje.sacuvanePonude(':id'), prijavljen(erasmus.sacuvanePonude))
    ..post(ApiPutanje.promenaSacuvane(':id', ':idPonude'), prijavljen(erasmus.promenaSacuvane))
    ..fallback = respondWith((zahtev) => odgovorSaProblemom(nepoznataRuta));
  return const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(allowOrigins(dozvoljenaPorekla))
      .addMiddleware(obradaGresaka())
      .addHandler(router.asHandler);
}