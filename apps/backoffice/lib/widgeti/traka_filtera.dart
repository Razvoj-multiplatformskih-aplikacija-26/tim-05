import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';


class TrakaFiltera extends StatelessWidget {
  const TrakaFiltera({super.key, required this.stanje, required this.onPromena, this.saPonudama = false});

  final KoordinatorUcitano stanje;
  final ValueChanged<FilteriPrijava> onPromena;

  final bool saPonudama;

  static String naziv(FilterStanja filter) => switch (filter) {
    FilterStanja.poslate => 'Poslate',
    FilterStanja.listaCekanja => 'Lista čekanja',
    FilterStanja.prihvacene => 'Prihvaćene',
    FilterStanja.potvrdjene => 'Potvrđene',
    FilterStanja.odbijene => 'Odbijene',
    FilterStanja.povucene => 'Povučene',
  };

  @override
  Widget build(BuildContext context) {
    final filteri = stanje.filteri;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          if (saPonudama) ...[
            _Cip(
              tekst: 'Sve ponude',
              izabran: filteri.ponuda == null,
              onIzbor: () => onPromena(filteri.copyWith(ponuda: () => null)),
            ),
            for (final ponuda in stanje.podaci.ponude)
              _Cip(
                tekst: ponuda.oblast,
                izabran: filteri.ponuda == ponuda.id,
                onIzbor: () => onPromena(filteri.copyWith(ponuda: () => ponuda.id)),
              ),
            const SizedBox(height: 24, child: VerticalDivider(width: 17)),
          ],
          _Cip(
            tekst: 'Sva stanja',
            izabran: filteri.stanje == null,
            onIzbor: () => onPromena(filteri.copyWith(stanje: () => null)),
          ),
          for (final filter in FilterStanja.values)
            _Cip(
              tekst: '${naziv(filter)} (${stanje.broj(filter)})',
              izabran: filteri.stanje == filter,
              // Drugi klik na izabran čip vraća sva stanja.
              onIzbor: () => onPromena(filteri.copyWith(stanje: () => filteri.stanje == filter ? null : filter)),
            ),
        ],
      ),
    );
  }
}

class _Cip extends StatelessWidget {
  const _Cip({required this.tekst, required this.izabran, required this.onIzbor});

  final String tekst;
  final bool izabran;
  final VoidCallback onIzbor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(tekst),
        selected: izabran,
        showCheckmark: false,
        selectedColor: Boje.bordoSvetla,
        onSelected: (_) => onIzbor(),
      ),
    );
  }
}