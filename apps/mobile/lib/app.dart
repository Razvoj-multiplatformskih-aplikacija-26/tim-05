import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'router.dart';
import 'tema/tema.dart';

class ErasmusAplikacija extends StatelessWidget {
  const ErasmusAplikacija({super.key});

  static const jezik = Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ErasmusGo',
      debugShowCheckedModeBanner: false,
      theme: AppTema.svetla(),
      locale: jezik,
      supportedLocales: const [jezik],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ruter,
    );
  }
}
