import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';


class TrakaPopunjenosti extends StatelessWidget {
  const TrakaPopunjenosti({
    super.key,
    required this.podaci,
    required this.izabranaPonuda,
    required this.onIzaberiPonudu,
  });

  final PregledKoordinatora podaci;

  final IdPonude? izabranaPonuda;
  final ValueChanged<IdPonude?> onIzaberiPonudu;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final ponuda in podaci.ponude)
            _KarticaPonude(
              ponuda: ponuda,
              podaci: podaci,
              izabrana: ponuda.id == izabranaPonuda,
              onTap: () => onIzaberiPonudu(ponuda.id == izabranaPonuda ? null : ponuda.id),
            ),
        ],
      ),
    );
  }
}

class _KarticaPonude extends StatelessWidget {
  const _KarticaPonude({required this.ponuda, required this.podaci, required this.izabrana, required this.onTap});

  final Ponuda ponuda;
  final PregledKoordinatora podaci;
  final bool izabrana;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tekst = Theme.of(context).textTheme;
    final slobodno = podaci.slobodnaMesta(ponuda);
    final zauzeto = ponuda.brojMesta - slobodno;
    final popunjeno = slobodno == 0;
    final oblik = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: izabrana ? Boje.bordo : Boje.ivica, width: izabrana ? 2 : 1),
    );
    return Semantics(
      button: true,
      selected: izabrana,
      label: '${ponuda.oblast}, zauzeta mesta $zauzeto od ${ponuda.brojMesta}',
      excludeSemantics: true,
      onTap: onTap,
      child: SizedBox(
        width: 260,
        child: Material(
          color: izabrana ? Boje.bordoSvetla : Boje.kartica,
          shape: oblik,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
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
          ),
        ),
      ),
    );
  }
}