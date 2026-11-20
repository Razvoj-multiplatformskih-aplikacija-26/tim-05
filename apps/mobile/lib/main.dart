import 'package:blocs/blocs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'adresa_servera.dart';
import 'app.dart';
import 'podaci/bezbedno_skladiste_tokena.dart';
import 'zavisnosti.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  if (kDebugMode) Bloc.observer = KonzolniBlocObserver(debugPrint);
  runApp(
    ErasmusAplikacija(
      zavisnosti: ZavisnostiAplikacije.server(adresa: adresaServera(), tokeni: const BezbednoSkladisteTokena()),
    ),
  );
}
