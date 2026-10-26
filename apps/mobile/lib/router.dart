import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'ekrani/dobrodosli_ekran.dart';
import 'ekrani/formular_ekran.dart';
import 'ekrani/glavni_okvir.dart';
import 'ekrani/moja_prijava_ekran.dart';
import 'ekrani/pocetna_ekran.dart';
import 'ekrani/ponuda_ekran.dart';
import 'ekrani/profil_ekran.dart';
import 'ekrani/uredi_profil_ekran.dart';
import 'podaci/lazni_podaci.dart';
import 'widgeti/nije_pronadjeno.dart';

GoRoute _mojaPrijava(GlobalKey<NavigatorState> korenski, String putanja, String parametar) => GoRoute(
  path: putanja,
  parentNavigatorKey: korenski,
  builder: (context, state) => MojaPrijavaEkran(idPrijave: IdPrijave(state.pathParameters[parametar]!)),
  routes: [
    GoRoute(
      path: 'izmena',
      parentNavigatorKey: korenski,
      builder: (context, state) {
        // PRIVREMENO
        final prijava = skladiste.prijava(IdPrijave(state.pathParameters[parametar]!));
        if (prijava == null) return const NijePronadjenoEkran();
        return FormularEkran(idPonude: prijava.idPonude, idPrijave: prijava.id);
      },
    ),
  ],
);

GoRoute _ponuda(GlobalKey<NavigatorState> korenski, String putanja) => GoRoute(
  path: putanja,
  parentNavigatorKey: korenski,
  builder: (context, state) => PonudaEkran(idPonude: IdPonude(state.pathParameters['id']!)),
  routes: [
    GoRoute(
      path: 'prijava',
      parentNavigatorKey: korenski,
      builder: (context, state) => FormularEkran(idPonude: IdPonude(state.pathParameters['id']!)),
    ),
    _mojaPrijava(korenski, 'moja/:idPrijave', 'idPrijave'),
  ],
);


GoRouter napraviRuter() {
  final korenski = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: korenski,
    initialLocation: '/dobrodosli',
    routes: [
      GoRoute(path: '/dobrodosli', builder: (context, state) => const DobrodosliEkran()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, okvir) => GlavniOkvir(okvir: okvir),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => PocetnaEkran(key: state.pageKey),
                routes: [_ponuda(korenski, 'ponude/:id')],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profil',
                builder: (context, state) => ProfilEkran(key: state.pageKey),
                routes: [
                  GoRoute(
                    path: 'uredi',
                    parentNavigatorKey: korenski,
                    builder: (context, state) => const UrediProfilEkran(),
                  ),
                  _mojaPrijava(korenski, 'prijave/:id', 'id'),
                  _ponuda(korenski, 'sacuvane/:id'),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
