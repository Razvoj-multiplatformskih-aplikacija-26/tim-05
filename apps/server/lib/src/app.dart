import 'package:relic/relic.dart';

const putanjaZdravlja = '/health';

Handler napraviHandler() {
  final router = RelicRouter()
    ..get(putanjaZdravlja, (request) => Response.ok(body: Body.fromString('ok')))
    ..fallback = respondWith((request) => Response.notFound(body: Body.fromString('Nema takve rute.')));
  return const Pipeline().addMiddleware(logRequests()).addHandler(router.asHandler);
}