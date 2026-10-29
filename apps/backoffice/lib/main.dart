import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:ui/ui.dart';

import 'zavisnosti.dart';

// PRIVREMENO
void main() {
  usePathUrlStrategy();
  final zavisnosti = ZavisnostiBackoffice.lazne();
  runApp(
    MaterialApp(
      theme: AppTema.svetla(),
      home: Scaffold(body: Center(child: Text('Backoffice: ${zavisnosti.korisnik.korisnickoIme}'))),
    ),
  );
}
