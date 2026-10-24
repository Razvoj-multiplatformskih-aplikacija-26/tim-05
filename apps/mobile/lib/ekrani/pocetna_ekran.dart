import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../podaci/lazni_podaci.dart';

/// PRIVREMENO
class PocetnaEkran extends StatelessWidget {
  const PocetnaEkran({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ponude')),
      body: ListView(
        children: [
          for (final ponuda in skladiste.ponude)
            ListTile(
              title: Text(skladiste.univerzitet(ponuda.idUniverziteta).naziv),
              subtitle: Text(ponuda.oblast),
              onTap: () => context.push('/ponude/${ponuda.id.vrednost}'),
            ),
        ],
      ),
    );
  }
}
