import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// PRIVREMENO
class PonudaEkran extends StatelessWidget {
  const PonudaEkran({super.key, required this.idPonude});

  final IdPonude idPonude;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ponuda ${idPonude.vrednost}')),
      body: Center(
        child: FilledButton(
          onPressed: () => context.push('/ponude/${idPonude.vrednost}/prijava'),
          child: const Text('Prijavi se'),
        ),
      ),
    );
  }
}
