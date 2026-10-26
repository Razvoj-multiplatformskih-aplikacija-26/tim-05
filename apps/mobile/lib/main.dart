import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:blocs/blocs.dart';
import 'package:flutter/foundation.dart';
import 'app.dart';
import 'zavisnosti.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  if (kDebugMode) Bloc.observer = KonzolniBlocObserver(debugPrint);
  runApp(ErasmusAplikacija(zavisnosti: ZavisnostiAplikacije.lazne()));
}
