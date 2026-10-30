import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:blocs/blocs.dart';
import 'package:flutter/foundation.dart';

import 'app.dart';
import 'zavisnosti.dart';

void main() {
  usePathUrlStrategy();
  if (kDebugMode) Bloc.observer = KonzolniBlocObserver(debugPrint);
  runApp(BackofficeAplikacija(zavisnosti: ZavisnostiBackoffice.lazne()));
}
