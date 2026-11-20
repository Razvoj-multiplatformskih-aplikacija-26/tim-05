import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

class PotrebnaPrijava extends StatelessWidget {
  const PotrebnaPrijava({super.key});

  static const poruka = 'Ulogujte se da vidite svoje prijave i sačuvane ponude.';

  @override
  Widget build(BuildContext context) {
    return EkranStanja(
      child: PrikazPraznog(
        ikona: Icons.lock_outline,
        poruka: poruka,
        dugme: 'Uloguj se',
        onPritisak: () => context.push('/login'),
      ),
    );
  }
}
