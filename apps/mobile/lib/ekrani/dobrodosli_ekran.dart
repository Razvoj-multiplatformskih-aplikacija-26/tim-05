import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// PRIVREMENO
class DobrodosliEkran extends StatelessWidget {
  const DobrodosliEkran({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(onPressed: () => context.go('/'), child: const Text('Uloguj se')),
      ),
    );
  }
}
