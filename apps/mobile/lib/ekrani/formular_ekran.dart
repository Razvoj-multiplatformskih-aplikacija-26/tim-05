import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

/// PRIVREMENO
class FormularEkran extends StatelessWidget {
  const FormularEkran({super.key, required this.idPonude, this.idPrijave});

  final IdPonude idPonude;
  final IdPrijave? idPrijave;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(idPrijave == null ? 'Nova prijava' : 'Izmena prijave')),
      body: Center(child: Text('Formular za ponudu ${idPonude.vrednost}')),
    );
  }
}
