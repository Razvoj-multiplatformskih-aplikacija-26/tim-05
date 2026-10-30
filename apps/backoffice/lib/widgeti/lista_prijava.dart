import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';


class ListaPrijava extends StatefulWidget {
  const ListaPrijava({
    super.key,
    required this.podaci,
    required this.prijave,
    required this.kursor,
    required this.izabrana,
    required this.focusNode,
    required this.onKursorPomeren,
    required this.onKursorPostavljen,
    required this.onAktiviran,
    required this.onIzaberi,
    required this.onKontekstMeni,
  });

  final PregledKoordinatora podaci;

  final List<Prijava> prijave;
  final int kursor;
  final IdPrijave? izabrana;

  final FocusNode focusNode;
  final ValueChanged<int> onKursorPomeren;
  final ValueChanged<int> onKursorPostavljen;

  final VoidCallback onAktiviran;

  final ValueChanged<Prijava> onIzaberi;

  final void Function(Prijava prijava, Offset pozicija) onKontekstMeni;

  @override
  State<ListaPrijava> createState() => _ListaPrijavaState();
}

class _ListaPrijavaState extends State<ListaPrijava> {
  
  final _karticaKursora = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _otkrijKursor(poravnanje: 0.3));
  }

  @override
  void didUpdateWidget(ListaPrijava stara) {
    super.didUpdateWidget(stara);
    if (widget.kursor == stara.kursor) return;
    final politika = widget.kursor > stara.kursor
        ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
        : ScrollPositionAlignmentPolicy.keepVisibleAtStart;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _otkrijKursor(politika: politika, trajanje: const Duration(milliseconds: 150)),
    );
  }

  void _otkrijKursor({
    double poravnanje = 0,
    ScrollPositionAlignmentPolicy politika = ScrollPositionAlignmentPolicy.explicit,
    Duration trajanje = Duration.zero,
  }) {
    final kartica = _karticaKursora.currentContext;
    if (kartica != null && kartica.mounted) {
      Scrollable.ensureVisible(kartica, alignment: poravnanje, alignmentPolicy: politika, duration: trajanje);
    }
  }

  KeyEventResult _naTaster(FocusNode cvor, KeyEvent dogadjaj) {
    if (dogadjaj is KeyUpEvent) return KeyEventResult.ignored;
    switch (dogadjaj.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        widget.onKursorPomeren(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        widget.onKursorPomeren(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter || LogicalKeyboardKey.numpadEnter:
        widget.onAktiviran();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  void _klik(int indeks, Prijava prijava) {
    widget.onKursorPostavljen(indeks);
    widget.focusNode.requestFocus();
    widget.onIzaberi(prijava);
  }

  void _meni(int indeks, Prijava prijava, Offset pozicija) {
    widget.onKursorPostavljen(indeks);
    widget.focusNode.requestFocus();
    widget.onKontekstMeni(prijava, pozicija);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final podaci = widget.podaci;
    final prijave = widget.prijave;
    return Focus(
      focusNode: widget.focusNode,
      autofocus: true,
      onKeyEvent: _naTaster,
      child: ListenableBuilder(
        listenable: widget.focusNode,
        builder: (context, _) {
          if (prijave.isEmpty) {
            return Center(
              child: Text(
                'Nijedna prijava ne odgovara izabranim filterima.',
                style: tema.textTheme.bodyLarge?.copyWith(color: Boje.sporedniTekst),
              ),
            );
          }
          final kursor = widget.focusNode.hasFocus ? widget.kursor : null;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final ponuda in podaci.ponude)
                  if (prijave.any((p) => p.idPonude == ponuda.id)) ...[
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
                    for (final (indeks, prijava) in prijave.indexed)
                      if (prijava.idPonude == ponuda.id) ...[
                        _KarticaPrijave(
                          key: indeks == widget.kursor ? _karticaKursora : null,
                          prijava: prijava,
                          student: podaci.student(prijava.idStudenta),
                          izabrana: prijava.id == widget.izabrana,
                          podKursorom: indeks == kursor,
                          onTap: () => _klik(indeks, prijava),
                          onKontekstMeni: (pozicija) => _meni(indeks, prijava, pozicija),
                        ),
                        const SizedBox(height: 8),
                      ],
                  ],
              ],
            ),
          );
        },
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
    required this.podKursorom,
    required this.onTap,
    required this.onKontekstMeni,
  });

  final Prijava prijava;
  final Student? student;
  final bool izabrana;
  final bool podKursorom;
  final VoidCallback onTap;
  final ValueChanged<Offset> onKontekstMeni;

  @override
  Widget build(BuildContext context) {
    final ime = student?.punoIme ?? 'Nepoznat student';
    final prosek = student == null ? '' : 'prosek ${formatProsek(student!.prosek)}';
    final ivica = izabrana
        ? const BorderSide(color: Boje.bordo, width: 2)
        : podKursorom
        ? const BorderSide(color: Boje.tekst, width: 2)
        : const BorderSide(color: Boje.ivica);
    return Semantics(
      button: true,
      selected: izabrana,
      label: '$ime, $prosek, ${nazivStanja(prijava.stanje)}',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onLongPressStart: (detalji) => onKontekstMeni(detalji.globalPosition),
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: ivica),
          child: InkWell(
            onTap: onTap,
            onSecondaryTapUp: (detalji) => onKontekstMeni(detalji.globalPosition),
            canRequestFocus: false,
            child: ListTile(
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
      ),
    );
  }
}