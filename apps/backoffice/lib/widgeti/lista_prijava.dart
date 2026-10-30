import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

class ListaPrijava extends StatefulWidget {
  const ListaPrijava({
    super.key,
    required this.podaci,
    required this.izabrana,
    required this.onIzaberi,
    required this.onKontekstMeni,
  });

  final PregledKoordinatora podaci;
  final IdPrijave? izabrana;
  final ValueChanged<Prijava> onIzaberi;

  final void Function(Prijava prijava, Offset pozicija) onKontekstMeni;

  @override
  State<ListaPrijava> createState() => _ListaPrijavaState();
}

class _ListaPrijavaState extends State<ListaPrijava> {
  final _izabranaKartica = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final kartica = _izabranaKartica.currentContext;
      if (kartica != null && kartica.mounted) Scrollable.ensureVisible(kartica, alignment: 0.3);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final podaci = widget.podaci;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final ponuda in podaci.ponude)
            if (podaci.brojPrijava(ponuda) > 0) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                child: Semantics(
                  header: true,
                  child: Text(
                    '${ponuda.oblast} · zauzeta mesta: '
                    '${ponuda.brojMesta - podaci.slobodnaMesta(ponuda)}/${ponuda.brojMesta}',
                    style: tema.textTheme.titleMedium,
                  ),
                ),
              ),
              for (final prijava in podaci.prijave)
                if (prijava.idPonude == ponuda.id) ...[
                  _KarticaPrijave(
                    key: prijava.id == widget.izabrana ? _izabranaKartica : null,
                    prijava: prijava,
                    student: podaci.student(prijava.idStudenta),
                    izabrana: prijava.id == widget.izabrana,
                    onTap: () => widget.onIzaberi(prijava),
                    onKontekstMeni: (pozicija) => widget.onKontekstMeni(prijava, pozicija),
                  ),
                  const SizedBox(height: 8),
                ],
            ],
        ],
      ),
    );
  }
}

class _KarticaPrijave extends StatelessWidget {
  const _KarticaPrijave({
    super.key,
    required this.prijava,
    required this.student,
    required this.izabrana,
    required this.onTap,
    required this.onKontekstMeni,
  });

  final Prijava prijava;
  final Student? student;
  final bool izabrana;
  final VoidCallback onTap;
  final ValueChanged<Offset> onKontekstMeni;

  @override
  Widget build(BuildContext context) {
    final ime = student?.punoIme ?? 'Nepoznat student';
    final prosek = student == null ? '' : 'prosek ${formatProsek(student!.prosek)}';
    return Semantics(
      button: true,
      selected: izabrana,
      label: '$ime, $prosek, ${nazivStanja(prijava.stanje)}',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onSecondaryTapUp: (detalji) => onKontekstMeni(detalji.globalPosition),
        onLongPressStart: (detalji) => onKontekstMeni(detalji.globalPosition),
        child: Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: izabrana ? Boje.bordo : Boje.ivica, width: izabrana ? 2 : 1),
          ),
          child: ListTile(
            onTap: onTap,
            title: Text(ime, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              [student?.brojIndeksa ?? '', prosek].where((deo) => deo.isNotEmpty).join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: OznakaStanja(stanje: prijava.stanje),
          ),
        ),
      ),
    );
  }
}
