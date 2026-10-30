import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../precice.dart';

Future<void> prikaziPregledPrecica(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      final tema = Theme.of(context);
      return AlertDialog(
        title: const Text('Prečice'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final precica in opisiPrecica)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: MergeSemantics(
                      child: Row(
                        children: [
                          Container(
                            width: 90,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Boje.siviBlok, borderRadius: BorderRadius.circular(6)),
                            child: Text(precica.tasteri, style: tema.textTheme.labelLarge, textAlign: TextAlign.center),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Text(precica.opis, style: tema.textTheme.bodyMedium)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Zatvori'))],
      );
    },
  );
}
