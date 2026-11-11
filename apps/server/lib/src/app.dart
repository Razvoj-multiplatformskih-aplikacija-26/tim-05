import 'package:api_contract/api_contract.dart';
import 'package:relic/relic.dart';

import 'cors.dart';
import 'http.dart';
import 'sesije.dart';

Handler napraviHandler(RukovaociSesija sesije, {required List<String> dozvoljenaPorekla}) {
  final prijavljen = sesije.prijavljen;
  final router = RelicRouter()
    ..get(ApiPutanje.zdravlje, (zahtev) => Response.ok(body: Body.fromString('ok')))
    ..post(ApiPutanje.sesije, sesije.prijava)
    ..get(ApiPutanje.trenutnaSesija, prijavljen(sesije.trenutna))
    ..delete(ApiPutanje.trenutnaSesija, prijavljen(sesije.odjava))
    ..fallback = respondWith((zahtev) => odgovorSaProblemom(nepoznataRuta));
  return const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(allowOrigins(dozvoljenaPorekla))
      .addMiddleware(obradaGresaka())
      .addHandler(router.asHandler);
}