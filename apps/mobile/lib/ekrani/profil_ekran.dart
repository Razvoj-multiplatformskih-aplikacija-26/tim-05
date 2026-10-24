import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../podaci/lazni_podaci.dart';

/// PRIVREMENO
class ProfilEkran extends StatelessWidget {
  const ProfilEkran({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [IconButton(onPressed: () => context.push('/profil/uredi'), icon: const Icon(Icons.edit))],
      ),
      body: ListView(
        children: [
          for (final prijava in skladiste.mojePrijave)
            ListTile(
              title: Text(prijava.id.vrednost),
              subtitle: Text(prijava.stanje.toString()),
              onTap: () => context.push('/profil/prijave/${prijava.id.vrednost}'),
            ),
        ],
      ),
    );
  }
}
