import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';


class DobrodosliEkran extends StatelessWidget {
  const DobrodosliEkran({super.key});

  @override
  Widget build(BuildContext context) {
    final tekst = Theme.of(context).textTheme;
    final dugme = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

    return Scaffold(
      backgroundColor: Boje.bordo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Logo(velicina: 104),
                    const SizedBox(height: 22),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'Erasmus'),
                          TextSpan(
                            text: 'Go',
                            style: TextStyle(color: Boje.bela.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      style: tekst.displaySmall?.copyWith(color: Boje.bela, fontSize: 36, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 26),
                    Semantics(
                      header: true,
                      child: Text(
                        'Dobrodošli!',
                        style: tekst.headlineSmall?.copyWith(
                          color: Boje.bela,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pronađite razmenu na partnerskim univerzitetima i prijavite se iz jedne aplikacije.',
                      textAlign: TextAlign.center,
                      style: tekst.bodyLarge?.copyWith(color: Boje.bela.withValues(alpha: 0.85), fontSize: 15),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => context.go('/'),
                style: FilledButton.styleFrom(
                  backgroundColor: Boje.zuta,
                  foregroundColor: Boje.naZutoj,
                  minimumSize: const Size.fromHeight(56),
                  shape: dugme,
                ),
                child: const Text('Uloguj se'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Boje.bela,
                  side: BorderSide(color: Boje.bela.withValues(alpha: 0.85), width: 2),
                  minimumSize: const Size.fromHeight(56),
                  shape: dugme,
                ),
                child: const Text('Napravi nalog'),
              ),
              const SizedBox(height: 18),
              Text(
                'Za studente i koordinatore partnerskih univerziteta',
                textAlign: TextAlign.center,
                style: tekst.bodySmall?.copyWith(color: Boje.belaProvidna, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
