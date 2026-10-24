import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// PRIVREMENO
class MojaPrijavaEkran extends StatelessWidget {
  const MojaPrijavaEkran({super.key, required this.idPrijave});

  final IdPrijave idPrijave;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Prijava ${idPrijave.vrednost}')),
      body: Center(
        child: FilledButton(
          onPressed: () => context.push('/profil/prijave/${idPrijave.vrednost}/izmena'),
          child: const Text('Izmeni'),
        ),
      ),
    );
  }
}
