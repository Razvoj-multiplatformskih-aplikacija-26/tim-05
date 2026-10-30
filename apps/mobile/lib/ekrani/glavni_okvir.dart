import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

class GlavniOkvir extends StatelessWidget {
  const GlavniOkvir({super.key, required this.okvir});

  final StatefulNavigationShell okvir;

  void _idi(int indeks) => okvir.goBranch(indeks, initialLocation: indeks == okvir.currentIndex);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: okvir,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Boje.bela,
          border: Border(top: BorderSide(color: Boje.ivica)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: Row(
              children: [
                _Tab(
                  ikona: Icons.home_outlined,
                  izabranaIkona: Icons.home,
                  naziv: 'Početna',
                  izabran: okvir.currentIndex == 0,
                  onTap: () => _idi(0),
                ),
                _Tab(
                  ikona: Icons.person_outline,
                  izabranaIkona: Icons.person,
                  naziv: 'Profil',
                  izabran: okvir.currentIndex == 1,
                  onTap: () => _idi(1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.ikona,
    required this.izabranaIkona,
    required this.naziv,
    required this.izabran,
    required this.onTap,
  });

  final IconData ikona;
  final IconData izabranaIkona;
  final String naziv;
  final bool izabran;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final boja = izabran ? Boje.bordo : Boje.sporedniTekst;
    return Expanded(
      child: Semantics(
        selected: izabran,
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(izabran ? izabranaIkona : ikona, color: boja),
              const SizedBox(height: 3),
              Text(naziv, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: boja)),
              const SizedBox(height: 3),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(color: izabran ? Boje.zuta : Colors.transparent, shape: BoxShape.circle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
