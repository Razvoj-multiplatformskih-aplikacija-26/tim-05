import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';


import 'isprekidana_linija.dart';
import 'oznaka_drzave.dart';

class KarticaPonude extends StatelessWidget {
  const KarticaPonude({
    super.key,
    required this.ponuda,
    required this.univerzitet,
    required this.preostaloMesta,
    required this.jeNova,
    required this.onTap,
  });

  final Ponuda ponuda;
  final Univerzitet univerzitet;

  final int preostaloMesta;
  final bool jeNova;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tekst = Theme.of(context).textTheme;
    final sporedni = tekst.bodySmall?.copyWith(color: Boje.sporedniTekst);

    return Semantics(
      button: true,
      label:
          '${univerzitet.grad}, ${univerzitet.naziv}, ${brojMesta(preostaloMesta)} slobodno, rok ${formatDatum(ponuda.rok)}',
      excludeSemantics: true,
      onTap: onTap,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OznakaDrzave(oznaka: univerzitet.oznakaDrzave),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(univerzitet.grad, style: tekst.titleLarge),
                          const SizedBox(height: 2),
                          Text(univerzitet.naziv, style: sporedni),
                        ],
                      ),
                    ),
                    if (jeNova) const _Novo(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: ponuda.oblast, style: tekst.titleSmall?.copyWith(fontSize: 12.5)),
                      TextSpan(
                        text: ' · ${nazivSemestra(ponuda.semestar)} · ${opisZahtevaJezika(ponuda.zahtevJezika)}',
                      ),
                    ],
                  ),
                  style: sporedni,
                ),
              ),
              const _Zasek(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _Podatak(naslov: 'MESTA', vrednost: '$preostaloMesta / ${ponuda.brojMesta}'),
                    ),
                    Expanded(
                      child: _Podatak(naslov: 'ROK', vrednost: formatKratakDatum(ponuda.rok)),
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(color: Boje.bordo, shape: BoxShape.circle),
                      child: const Icon(Icons.chevron_right, color: Boje.bela, size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Zasek extends StatelessWidget {
  const _Zasek();

  @override
  Widget build(BuildContext context) {
    const krug = DecoratedBox(
      decoration: BoxDecoration(
        color: Boje.pozadina,
        shape: BoxShape.circle,
        border: Border.fromBorderSide(BorderSide(color: Boje.ivica)),
      ),
      child: SizedBox(width: 18, height: 18),
    );
    return const SizedBox(
      height: 18,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 14, right: 14, top: 8, child: IsprekidanaLinija()),
          Positioned(left: -9, top: 0, child: krug),
          Positioned(right: -9, top: 0, child: krug),
        ],
      ),
    );
  }
}

class _Podatak extends StatelessWidget {
  const _Podatak({required this.naslov, required this.vrednost});

  final String naslov;
  final String vrednost;

  @override
  Widget build(BuildContext context) {
    final tekst = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          naslov,
          style: tekst.labelSmall?.copyWith(color: Boje.sporedniTekst, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 1),
        Text(vrednost, style: tekst.titleLarge?.copyWith(fontSize: 17)),
      ],
    );
  }
}

class _Novo extends StatelessWidget {
  const _Novo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: Boje.zuta, borderRadius: BorderRadius.circular(10)),
      child: Text('NOVO', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Boje.naZutoj)),
    );
  }
}
