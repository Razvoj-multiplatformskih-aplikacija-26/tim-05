import 'package:flutter/material.dart';

class NijePronadjenoEkran extends StatelessWidget {
  const NijePronadjenoEkran({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Traženi podatak nije pronađen.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}
