import 'dart:async';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:relic/relic.dart' show IOAdapter, RelicServer;
import 'package:server/server.dart';

Future<void> main() async {
  final konfiguracija = KonfiguracijaServera.izOkruzenja(serverEnvironment());
  final baza = Pool<void>.withUrl(konfiguracija.adresaBaze);
  await upisiPocetnePodatke(baza, sada: DateTime.now(), demoLozinka: konfiguracija.demoLozinka);
  final sesije = RukovaociSesija(
    nalozi: SkladisteNaloga(baza),
    tajna: konfiguracija.tajnaZaTokene,
    trajanje: konfiguracija.trajanjeSesije,
    bezbedanKolacic: konfiguracija.bezbedanKolacic,
  );
  final server = RelicServer(() => IOAdapter.bind(InternetAddress(konfiguracija.host), port: konfiguracija.port));
  await server.mountAndStart(napraviHandler(sesije, dozvoljenaPorekla: konfiguracija.dozvoljenaPorekla));
  stdout.writeln('ErasmusGo server na http://${konfiguracija.host}:${konfiguracija.port}');
  await _signalZaKraj();
  await server.close();
  await baza.close();
}

Future<void> _signalZaKraj() async {
  final kraj = Completer<void>();
  final pretplate = [
    for (final signal in [ProcessSignal.sigint, if (!Platform.isWindows) ProcessSignal.sigterm])
      signal.watch().listen((_) => kraj.isCompleted ? null : kraj.complete()),
  ];
  await kraj.future;
  for (final pretplata in pretplate) {
    await pretplata.cancel();
  }
}