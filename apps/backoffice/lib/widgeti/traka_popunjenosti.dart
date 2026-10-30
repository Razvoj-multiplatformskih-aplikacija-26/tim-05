import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

class TrakaPopunjenosti extends StatelessWidget {
  const TrakaPopunjenosti({super.key, required this.podaci});

  final PregledKoordinatora podaci;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [for (final ponuda in podaci.ponude) _KarticaPonude(ponuda: ponuda, podaci: podaci)],
      ),
    );
  }
}

class _KarticaPonude extends StatelessWidget {
  const _KarticaPonude({required this.ponuda, required this.podaci});

  final Ponuda ponuda;
  final PregledKoordinatora podaci;

  @override
  Widget build(BuildContext context) {
    final tekst = Theme.of(context).textTheme;
    final slobodno = podaci.slobodnaMesta(ponuda);
    final zauzeto = ponuda.brojMesta - slobodno;
    final popunjeno = slobodno == 0;
    return MergeSemantics(
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Boje.kartica,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Boje.ivica),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ponuda.oblast, style: tekst.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              nazivSemestra(ponuda.semestar),
              style: tekst.bodySmall?.copyWith(color: Boje.sporedniTekst),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: ponuda.brojMesta == 0 ? 1.0 : zauzeto / ponuda.brojMesta,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
              color: popunjeno ? Boje.greska : Boje.uspeh,
              backgroundColor: Boje.siviBlok,
              semanticsLabel: 'Popunjenost',
            ),
            const SizedBox(height: 6),
            Text(
              'Zauzeta mesta: $zauzeto/${ponuda.brojMesta} · prijava: ${podaci.brojPrijava(ponuda)}',
              style: tekst.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
