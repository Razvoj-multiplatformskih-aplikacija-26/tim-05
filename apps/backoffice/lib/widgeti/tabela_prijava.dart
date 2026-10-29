import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';


class TabelaPrijava extends StatefulWidget {
  const TabelaPrijava({
    super.key,
    required this.podaci,
    required this.kursor,
    required this.izabrana,
    required this.focusNode,
    required this.onKursorPomeren,
    required this.onKursorPostavljen,
    required this.onAktiviran,
    required this.onIzaberi,
    required this.onKontekstMeni,
  });

  static const visinaReda = 60.0;

  final PregledKoordinatora podaci;
  final int kursor;
  final IdPrijave? izabrana;

  final FocusNode focusNode;

  final ValueChanged<int> onKursorPomeren;

  final ValueChanged<int> onKursorPostavljen;

  final VoidCallback onAktiviran;
  final ValueChanged<Prijava> onIzaberi;

  final void Function(Prijava prijava, Offset pozicija) onKontekstMeni;

  @override
  State<TabelaPrijava> createState() => _TabelaPrijavaState();
}

class _TabelaPrijavaState extends State<TabelaPrijava> {
  final _skrol = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _otkrijKursor(animirano: false));
  }

  @override
  void didUpdateWidget(TabelaPrijava stara) {
    super.didUpdateWidget(stara);
    if (widget.kursor != stara.kursor) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _otkrijKursor());
    }
  }

  @override
  void dispose() {
    _skrol.dispose();
    super.dispose();
  }

  void _otkrijKursor({bool animirano = true}) {
    if (!_skrol.hasClients) return;
    final pozicija = _skrol.position;
    final pocetak = widget.kursor * TabelaPrijava.visinaReda;
    final kraj = pocetak + TabelaPrijava.visinaReda;
    final double cilj;
    if (pocetak < pozicija.pixels) {
      cilj = pocetak;
    } else if (kraj > pozicija.pixels + pozicija.viewportDimension) {
      cilj = kraj - pozicija.viewportDimension;
    } else {
      return;
    }
    final ograniceno = cilj.clamp(pozicija.minScrollExtent, pozicija.maxScrollExtent);
    if (animirano) {
      _skrol.animateTo(ograniceno, duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
    } else {
      _skrol.jumpTo(ograniceno);
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
    final podaci = widget.podaci;
    final prijave = podaci.prijave;
    return Focus(
      focusNode: widget.focusNode,
      autofocus: true,
      onKeyEvent: _naTaster,
      child: Semantics(
        container: true,
        label: 'Tabela prijava, ukupno ${prijave.length}',
        child: Column(
          children: [
            const _Zaglavlje(),
            const Divider(height: 1),
            Expanded(
              // Samo ovaj deo se ponovo crta kad tabela dobije ili izgubi fokus.
              child: ListenableBuilder(
                listenable: widget.focusNode,
                builder: (context, _) {
                  final kursor = widget.focusNode.hasFocus ? widget.kursor : null;
                  return ListView.builder(
                    controller: _skrol,
                    itemExtent: TabelaPrijava.visinaReda,
                    itemCount: prijave.length,
                    itemBuilder: (context, indeks) {
                      final prijava = prijave[indeks];
                      return _RedPrijave(
                        prijava: prijava,
                        student: podaci.student(prijava.idStudenta),
                        ponuda: podaci.ponuda(prijava.idPonude),
                        imaProsek: podaci.imaProsek(prijava),
                        imaJezik: podaci.imaJezik(prijava),
                        izabrana: prijava.id == widget.izabrana,
                        podKursorom: indeks == kursor,
                        onTap: () => _klik(indeks, prijava),
                        onKontekstMeni: (pozicija) => _meni(indeks, prijava, pozicija),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Kolone extends StatelessWidget {
  const _Kolone({
    required this.student,
    required this.ponuda,
    required this.prosek,
    required this.jezik,
    required this.datum,
    required this.stanje,
  });

  final Widget student;
  final Widget ponuda;
  final Widget prosek;
  final Widget jezik;
  final Widget datum;
  final Widget stanje;

  static Widget _stalna(double sirina, Widget dete) => SizedBox(
    width: sirina,
    child: Align(
      alignment: Alignment.centerLeft,
      child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: dete),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: student),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: ponuda),
          const SizedBox(width: 12),
          _stalna(76, prosek),
          _stalna(68, jezik),
          _stalna(76, datum),
          _stalna(120, stanje),
        ],
      ),
    );
  }
}

class _Zaglavlje extends StatelessWidget {
  const _Zaglavlje();

  @override
  Widget build(BuildContext context) {
    final stil = Theme.of(context).textTheme.labelMedium?.copyWith(color: Boje.sporedniTekst);
    Widget naslov(String tekst) => Semantics(
      header: true,
      child: Text(tekst, style: stil, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
    return SizedBox(
      height: 40,
      child: Padding(
        // Isto uvlačenje kao red (8 spolja + 12 u kolonama), da se kolone poklope.
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: _Kolone(
          student: naslov('Student'),
          ponuda: naslov('Ponuda'),
          prosek: naslov('Prosek'),
          jezik: naslov('Jezik'),
          datum: naslov('Napravljena'),
          stanje: naslov('Stanje'),
        ),
      ),
    );
  }
}


class _RedPrijave extends StatelessWidget {
  const _RedPrijave({
    required this.prijava,
    required this.student,
    required this.ponuda,
    required this.imaProsek,
    required this.imaJezik,
    required this.izabrana,
    required this.podKursorom,
    required this.onTap,
    required this.onKontekstMeni,
  });

  final Prijava prijava;
  final Student? student;
  final Ponuda ponuda;
  final bool imaProsek;
  final bool imaJezik;
  final bool izabrana;
  final bool podKursorom;
  final VoidCallback onTap;
  final ValueChanged<Offset> onKontekstMeni;

  @override
  Widget build(BuildContext context) {
    final tekst = Theme.of(context).textTheme;
    final student = this.student;
    final ime = student?.punoIme ?? 'Nepoznat student';
    final jezik = ponuda.zahtevJezika.jezik;
    final nivo = student?.nivoZa(jezik)?.oznaka ?? '—';
    return Semantics(
      button: true,
      selected: izabrana,
      label:
          '$ime, ${ponuda.oblast}, '
          'prosek ${student == null ? 'nepoznat' : formatProsek(student.prosek)}, '
          '${nazivStanja(prijava.stanje)}',
      excludeSemantics: true,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: GestureDetector(
          onLongPressStart: (detalji) => onKontekstMeni(detalji.globalPosition),
          child: Material(
            color: izabrana ? Boje.bordoSvetla : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: podKursorom ? const BorderSide(color: Boje.tekst, width: 2) : BorderSide.none,
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              onSecondaryTapUp: (detalji) => onKontekstMeni(detalji.globalPosition),
              // Fokus drži tabela, ne pojedinačni red; inače bi Tab prolazio kroz svaki red.
              canRequestFocus: false,
              hoverColor: Boje.bordo.withValues(alpha: 0.05),
              child: _Kolone(
                student: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ime, style: tekst.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      student?.brojIndeksa ?? '',
                      style: tekst.bodySmall?.copyWith(color: Boje.sporedniTekst),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                ponuda: Text(ponuda.oblast, style: tekst.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                prosek: _Uslov(
                  tekst: student == null ? '—' : formatProsek(student.prosek),
                  ispunjen: imaProsek,
                ),
                jezik: _Uslov(tekst: nivo, ispunjen: imaJezik),
                datum: Text(formatKratakDatum(prijava.napravljena), style: tekst.bodyMedium),
                stanje: OznakaStanja(stanje: prijava.stanje),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _Uslov extends StatelessWidget {
  const _Uslov({required this.tekst, required this.ispunjen});

  final String tekst;
  final bool ispunjen;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(tekst, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(width: 4),
        Icon(
          ispunjen ? Icons.check_circle : Icons.cancel,
          size: 16,
          color: ispunjen ? Boje.uspeh : Boje.greska,
          semanticLabel: ispunjen ? 'ispunjava uslov' : 'ne ispunjava uslov',
        ),
      ],
    );
  }
}