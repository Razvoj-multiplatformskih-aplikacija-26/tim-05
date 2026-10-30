import 'package:domain/domain.dart';
import 'package:go_router/go_router.dart';

import 'ekrani/prijave_ekran.dart';

GoRouter napraviRuter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', redirect: (context, state) => PrijaveEkran.putanja()),
      GoRoute(
        path: '/prijave',
        builder: (context, state) {
          final izabrana = state.uri.queryParameters['prijava'];
          return PrijaveEkran(izabrana: izabrana == null ? null : IdPrijave(izabrana));
        },
      ),
    ],
  );
}
