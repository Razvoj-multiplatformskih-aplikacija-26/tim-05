import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

class BordoZaglavlje extends StatelessWidget {
  const BordoZaglavlje({super.key, required this.child, this.preklop, this.dubinaPreklopa = 0, this.razmakDole = 20});

  final Widget child;
  final Widget? preklop;
  final double dubinaPreklopa;

  final double razmakDole;

  static const _oblik = BoxDecoration(
    color: Boje.bordo,
    borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
  );

  @override
  Widget build(BuildContext context) {
    final sadrzaj = SafeArea(
      bottom: false,
      child: Padding(padding: EdgeInsets.fromLTRB(20, 8, 20, razmakDole), child: child),
    );

    final preklop = this.preklop;
    if (preklop == null) return DecoratedBox(decoration: _oblik, child: sadrzaj);

    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          bottom: dubinaPreklopa,
          child: const DecoratedBox(decoration: _oblik),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [sadrzaj, preklop]),
      ],
    );
  }
}

class DugmeZaglavlja extends StatelessWidget {
  const DugmeZaglavlja({
    super.key,
    required this.ikona,
    required this.opis,
    required this.onPressed,
    this.boja = Boje.bela,
  });

  final IconData ikona;

  final String opis;
  final VoidCallback? onPressed;
  final Color boja;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: opis,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Boje.bela.withValues(alpha: 0.14),
        foregroundColor: boja,
        fixedSize: const Size(40, 40),
      ),
      icon: Icon(ikona, size: 20),
    );
  }
}
