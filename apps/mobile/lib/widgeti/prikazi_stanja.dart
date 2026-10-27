import 'package:flutter/material.dart';

import '../tema/tema.dart';

class EkranStanja extends StatelessWidget {
  const EkranStanja({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Navigator.canPop(context) ? AppBar() : null,
      body: SafeArea(child: child),
    );
  }
}

class PrikazUcitavanja extends StatelessWidget {
  const PrikazUcitavanja({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        liveRegion: true,
        label: 'Učitavanje',
        child: const CircularProgressIndicator(color: Boje.bordo),
      ),
    );
  }
}

class PrikazGreske extends StatelessWidget {
  const PrikazGreske({super.key, required this.onPonovo});

  static const naslov = 'Podaci trenutno nisu dostupni.';

  final VoidCallback onPonovo;

  @override
  Widget build(BuildContext context) {
    final tekst = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: Boje.greska),
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Text(naslov, textAlign: TextAlign.center, style: tekst.titleMedium),
            ),
            const SizedBox(height: 6),
            Text(
              'Proverite vezu i pokušajte ponovo.',
              textAlign: TextAlign.center,
              style: tekst.bodyMedium?.copyWith(color: Boje.sporedniTekst),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onPonovo, child: const Text('Pokušaj ponovo')),
          ],
        ),
      ),
    );
  }
}

class PrikazPraznog extends StatelessWidget {
  const PrikazPraznog({
    super.key,
    required this.poruka,
    this.dugme,
    this.onPritisak,
    this.ikona = Icons.inbox_outlined,
  });

  final String poruka;
  final String? dugme;
  final VoidCallback? onPritisak;
  final IconData ikona;

  @override
  Widget build(BuildContext context) {
    final dugme = this.dugme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ikona, size: 48, color: Boje.sporedniTekst),
            const SizedBox(height: 16),
            Text(
              poruka,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Boje.sporedniTekst),
            ),
            if (dugme != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(onPressed: onPritisak, child: Text(dugme)),
            ],
          ],
        ),
      ),
    );
  }
}
