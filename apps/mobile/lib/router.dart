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

final _korenskiNavigator = GlobalKey<NavigatorState>();

GoRoute _mojaPrijava(String putanja, String parametar) => GoRoute(
  path: putanja,
  parentNavigatorKey: _korenskiNavigator,
  builder: (context, state) => MojaPrijavaEkran(idPrijave: IdPrijave(state.pathParameters[parametar]!)),
  routes: [
    GoRoute(
      path: 'izmena',
      parentNavigatorKey: _korenskiNavigator,
      builder: (context, state) {
        final prijava = skladiste.prijava(IdPrijave(state.pathParameters[parametar]!));
        if (prijava == null) return const NijePronadjenoEkran();
        return FormularEkran(idPonude: prijava.idPonude, idPrijave: prijava.id);
      },
    ),
  ],
);

GoRoute _ponuda(String putanja) => GoRoute(
  path: putanja,
  parentNavigatorKey: _korenskiNavigator,
  builder: (context, state) => PonudaEkran(idPonude: IdPonude(state.pathParameters['id']!)),
  routes: [
    GoRoute(
      path: 'prijava',
      parentNavigatorKey: _korenskiNavigator,
      builder: (context, state) => FormularEkran(idPonude: IdPonude(state.pathParameters['id']!)),
    ),
    _mojaPrijava('moja/:idPrijave', 'idPrijave'),
  ],
);

final ruter = GoRouter(
  navigatorKey: _korenskiNavigator,
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
              routes: [_ponuda('ponude/:id')],
            ),
          ],
        ),
        // Tab 2: Profil i sve što se otvara iz njega
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profil',
              builder: (context, state) => ProfilEkran(key: state.pageKey),
              routes: [
                GoRoute(
                  path: 'uredi',
                  parentNavigatorKey: _korenskiNavigator,
                  builder: (context, state) => const UrediProfilEkran(),
                ),
                _mojaPrijava('prijave/:id', 'id'),
                _ponuda('sacuvane/:id'),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
