import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import '../podaci/lazna_baza.dart';
import '../precice.dart';
import '../widgeti/detalj_prijave.dart';
import '../widgeti/dijalog_odbijanja.dart';
import '../widgeti/lista_prijava.dart';
import '../widgeti/pregled_precica.dart';
import '../widgeti/tabela_prijava.dart';
import '../widgeti/traka_filtera.dart';
import '../widgeti/traka_popunjenosti.dart';
import '../zavisnosti.dart';


class PrijaveEkran extends StatefulWidget {
  const PrijaveEkran({super.key, this.izabrana});

  static const sirokoOd = 840.0;

  final IdPrijave? izabrana;

  static String putanja({IdPrijave? izabrana}) =>
      izabrana == null ? '/prijave' : '/prijave?prijava=${Uri.encodeQueryComponent(izabrana.vrednost)}';

  @override
  State<PrijaveEkran> createState() => _PrijaveEkranState();
}

class _PrijaveEkranState extends State<PrijaveEkran> {
  final _fokusPrijava = FocusNode(debugLabel: 'prijave');

  KoordinatorBloc get _bloc => context.read<KoordinatorBloc>();

  bool get _usko => MediaQuery.sizeOf(context).width < PrijaveEkran.sirokoOd;

  KoordinatorUcitano? get _ucitano => switch (_bloc.state) {
    final KoordinatorUcitano stanje => stanje,
    _ => null,
  };

  @override
  void initState() {
    super.initState();
    _sinhronizujSaAdresom();
  }

  @override
  void didUpdateWidget(PrijaveEkran stari) {
    super.didUpdateWidget(stari);
    if (stari.izabrana != widget.izabrana) _sinhronizujSaAdresom();
  }

  @override
  void dispose() {
    _fokusPrijava.dispose();
    super.dispose();
  }

  void _sinhronizujSaAdresom() {
    final stanje = _ucitano;
    if (stanje != null && stanje.izabrana != widget.izabrana) _bloc.add(PrijavaIzabrana(widget.izabrana));
  }

  void _izaberi(Prijava? prijava) => _bloc.add(PrijavaIzabrana(prijava?.id));

  
  void _otvori(Prijava prijava) {
    _izaberi(prijava);
    if (_usko) _prikaziDonjiList(prijava);
  }

  void _otvoriPodKursorom() {
    final prijava = _ucitano?.prijavaPodKursorom;
    if (prijava != null) _otvori(prijava);
  }

  void _filtriraj(FilteriPrijava filteri) => _bloc.add(FilteriPrijavaPromenjeni(filteri));

  Future<void> _prikaziDonjiList(Prijava prijava) {
    final stanje = _ucitano;
    if (stanje == null) return Future.value();
    final akcije = stanje.akcijeZa(prijava);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (kontekstLista) {
        void zatvoriPa(void Function() akcija) {
          Navigator.pop(kontekstLista);
          akcija();
        }

        return SizedBox(
          height: MediaQuery.sizeOf(kontekstLista).height * 0.75,
          child: FocusScope(
            autofocus: true,
            child: DetaljPrijave(
              prijava: prijava,
              podaci: stanje.podaci,
              onZatvori: () => Navigator.pop(kontekstLista),
              onPrihvati: akcije.contains(AkcijaKoordinatora.prihvati)
                  ? () => zatvoriPa(() => _prihvati(prijava))
                  : null,
              onListaCekanja: akcije.contains(AkcijaKoordinatora.listaCekanja)
                  ? () => zatvoriPa(() => _staviNaListuCekanja(prijava))
                  : null,
              onOdbij: akcije.contains(AkcijaKoordinatora.odbij) ? () => zatvoriPa(() => _odbij(prijava)) : null,
            ),
          ),
        );
      },
    );
  }

  bool _dozvoljeno(AkcijaKoordinatora akcija) => _ucitano?.dozvoljeno(akcija) ?? false;

  void _prihvati([Prijava? prijava]) {
    final cilj = prijava ?? _ucitano?.izabranaPrijava;
    if (cilj != null) _bloc.add(PrihvatanjeZatrazeno(cilj.id));
  }

  void _staviNaListuCekanja([Prijava? prijava]) {
    final cilj = prijava ?? _ucitano?.izabranaPrijava;
    if (cilj != null) _bloc.add(ListaCekanjaZatrazena(cilj.id));
  }

  Future<void> _odbij([Prijava? prijava]) async {
    final cilj = prijava ?? _ucitano?.izabranaPrijava;
    if (cilj == null) return;
    final student = _ucitano?.podaci.student(cilj.idStudenta);
    final razlog = await prikaziDijalogOdbijanja(context, imeStudenta: student?.punoIme ?? 'nepoznatog studenta');
    if (!mounted || razlog == null) return;
    _bloc.add(OdbijanjeZatrazeno(cilj.id, razlog: razlog));
  }

  
  Future<void> _prikaziMeni(Prijava prijava, Offset pozicija) async {
    final stanje = _ucitano;
    if (stanje == null) return;
    final akcije = stanje.zauzet ? const <AkcijaKoordinatora>{} : stanje.akcijeZa(prijava);
    final prekrivac = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final izbor = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(pozicija & const Size(1, 1), Offset.zero & prekrivac.size),
      items: [
        if (akcije.contains(AkcijaKoordinatora.prihvati))
          const PopupMenuItem(value: 'prihvati', child: Text('Prihvati (P)')),
        if (akcije.contains(AkcijaKoordinatora.listaCekanja))
          const PopupMenuItem(value: 'lista', child: Text('Lista čekanja (L)')),
        if (akcije.contains(AkcijaKoordinatora.odbij)) const PopupMenuItem(value: 'odbij', child: Text('Odbij (O)')),
        const PopupMenuItem(value: 'detalji', child: Text('Detalji')),
      ],
    );
    if (!mounted || izbor == null) return;
    switch (izbor) {
      case 'prihvati':
        _prihvati(prijava);
      case 'lista':
        _staviNaListuCekanja(prijava);
      case 'odbij':
        await _odbij(prijava);
      case 'detalji':
        _otvori(prijava);
    }
  }

  void _simulirajGresku(LaznaBaza baza) {
    baza.neuspesniZahtevi = 1;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sledeći zahtev neće uspeti.')));
  }

  void _prikaziObavestenje(BuildContext context, KoordinatorObavestenje obavestenje) {
    final poruka = switch (obavestenje) {
      OdlukaSacuvana(:final prijava) => switch (prijava.stanje) {
        Prihvacena() => 'Prijava je prihvaćena.',
        NaListiCekanja() => 'Prijava je stavljena na listu čekanja.',
        Odbijena() => 'Prijava je odbijena.',
        UPripremi() || Poslata() || Potvrdjena() || Povucena() => 'Prijava je sačuvana.',
      },
      OdlukaOdbijena(:final greska) => greska.poruka,
      OdlukaNeuspela() => 'Odluka nije sačuvana. Pokušajte ponovo.',
      PodaciOsvezeni() => 'Podaci su osveženi.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(poruka)));
    _bloc.add(const ObavestenjeKoordinatoraProcitano());
  }

  @override
  Widget build(BuildContext context) {
    final bloc = _bloc;
    final baza = context.read<ZavisnostiBackoffice>().laznaBaza;
    final usko = MediaQuery.sizeOf(context).width < PrijaveEkran.sirokoOd;
    return Shortcuts(
      shortcuts: precicePrijava(),
      child: Actions(
        actions: {
          PrihvatiIntent: ZasticenaAkcija<PrihvatiIntent>(
            dozvoljena: () => _dozvoljeno(AkcijaKoordinatora.prihvati),
            onInvoke: (_) => _prihvati(),
          ),
          ListaCekanjaIntent: ZasticenaAkcija<ListaCekanjaIntent>(
            dozvoljena: () => _dozvoljeno(AkcijaKoordinatora.listaCekanja),
            onInvoke: (_) => _staviNaListuCekanja(),
          ),
          OdbijIntent: ZasticenaAkcija<OdbijIntent>(
            dozvoljena: () => _dozvoljeno(AkcijaKoordinatora.odbij),
            onInvoke: (_) => _odbij(),
          ),
          
          ZatvoriDetaljIntent: ZasticenaAkcija<ZatvoriDetaljIntent>(
            dozvoljena: () => !_usko && _ucitano?.izabrana != null,
            onInvoke: (_) {
              _izaberi(null);
              _fokusPrijava.requestFocus();
              return null;
            },
          ),
          PregledPrecicaIntent: CallbackAction<PregledPrecicaIntent>(
            onInvoke: (_) => prikaziPregledPrecica(context),
          ),
        },
        child: FocusScope(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Logo(velicina: 34),
                  const SizedBox(width: 12),
                  const Text('ErasmusGo'),
                  if (!usko) ...[
                    const SizedBox(width: 10),
                    Text(
                      'Backoffice',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Boje.belaProvidna),
                    ),
                  ],
                ],
              ),
              actions: [
                if (!usko) ...[
                  IconButton(
                    tooltip: 'Osveži',
                    onPressed: () => bloc.add(const PrijaveOsvezene()),
                    icon: const Icon(Icons.refresh),
                  ),
                  IconButton(
                    tooltip: 'Prečice (?)',
                    onPressed: () => prikaziPregledPrecica(context),
                    icon: const Icon(Icons.keyboard_outlined),
                  ),
                  if (kDebugMode && baza != null)
                    IconButton(
                      tooltip: 'Simuliraj grešku',
                      onPressed: () => _simulirajGresku(baza),
                      icon: const Icon(Icons.cloud_off_outlined),
                    ),
                ] else
                  PopupMenuButton<String>(
                    tooltip: 'Više',
                    onSelected: (izbor) {
                      switch (izbor) {
                        case 'osvezi':
                          bloc.add(const PrijaveOsvezene());
                        case 'precice':
                          prikaziPregledPrecica(context);
                        case 'greska':
                          if (baza != null) _simulirajGresku(baza);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'osvezi', child: Text('Osveži')),
                      const PopupMenuItem(value: 'precice', child: Text('Prečice')),
                      if (kDebugMode && baza != null)
                        const PopupMenuItem(value: 'greska', child: Text('Simuliraj grešku')),
                    ],
                  ),
                const SizedBox(width: 8),
              ],
            ),
            body: MultiBlocListener(
              listeners: [
                BlocListener<KoordinatorBloc, KoordinatorStanje>(
                  listenWhen: (pre, sada) => pre is! KoordinatorUcitano && sada is KoordinatorUcitano,
                  listener: (context, stanje) => _sinhronizujSaAdresom(),
                ),
                BlocListener<KoordinatorBloc, KoordinatorStanje>(
                  listenWhen: (pre, sada) =>
                      pre is KoordinatorUcitano && sada is KoordinatorUcitano && pre.izabrana != sada.izabrana,
                  listener: (context, stanje) {
                    final izabrana = (stanje as KoordinatorUcitano).izabrana;
                    if (izabrana != widget.izabrana) context.go(PrijaveEkran.putanja(izabrana: izabrana));
                  },
                ),
                BlocListener<KoordinatorBloc, KoordinatorStanje>(
                  listenWhen: (pre, sada) =>
                      sada is KoordinatorUcitano &&
                      sada.obavestenje != null &&
                      (pre is! KoordinatorUcitano || pre.obavestenje != sada.obavestenje),
                  listener: (context, stanje) =>
                      _prikaziObavestenje(context, (stanje as KoordinatorUcitano).obavestenje!),
                ),
              ],
              child: BlocBuilder<KoordinatorBloc, KoordinatorStanje>(
                builder: (context, stanje) => switch (stanje) {
                  KoordinatorUcitavanje() => const PrikazUcitavanja(),
                  KoordinatorGreska() => PrikazGreske(onPonovo: () => bloc.add(const PrijaveZatrazene())),
                  KoordinatorPrazno() => const PrikazPraznog(
                    poruka: 'Na ponude vašeg univerziteta još nije stigla nijedna prijava.',
                  ),
                  KoordinatorUcitano() => _Sadrzaj(
                    stanje: stanje,
                    fokusPrijava: _fokusPrijava,
                    onIzaberi: _izaberi,
                    onOtvori: _otvori,
                    onOtvoriPodKursorom: _otvoriPodKursorom,
                    onFilteri: _filtriraj,
                    onPrihvati: _prihvati,
                    onListaCekanja: _staviNaListuCekanja,
                    onOdbij: _odbij,
                    onKontekstMeni: _prikaziMeni,
                  ),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _Sadrzaj extends StatelessWidget {
  const _Sadrzaj({
    required this.stanje,
    required this.fokusPrijava,
    required this.onIzaberi,
    required this.onOtvori,
    required this.onOtvoriPodKursorom,
    required this.onFilteri,
    required this.onPrihvati,
    required this.onListaCekanja,
    required this.onOdbij,
    required this.onKontekstMeni,
  });

  final KoordinatorUcitano stanje;
  final FocusNode fokusPrijava;
  final ValueChanged<Prijava?> onIzaberi;
  final ValueChanged<Prijava> onOtvori;
  final VoidCallback onOtvoriPodKursorom;
  final ValueChanged<FilteriPrijava> onFilteri;
  final void Function([Prijava? prijava]) onPrihvati;
  final void Function([Prijava? prijava]) onListaCekanja;
  final Future<void> Function([Prijava? prijava]) onOdbij;
  final void Function(Prijava prijava, Offset pozicija) onKontekstMeni;

  @override
  Widget build(BuildContext context) {
    final izabrana = stanje.izabranaPrijava;
    final akcije = izabrana == null ? const <AkcijaKoordinatora>{} : stanje.akcijeZa(izabrana);
    final prijave = stanje.prijave;
    final bloc = context.read<KoordinatorBloc>();
    return Column(
      children: [
       
        if (stanje.zauzet) const LinearProgressIndicator(minHeight: 3) else const SizedBox(height: 3),
        Expanded(
          child: LayoutBuilder(
            builder: (context, granice) {
              if (granice.maxWidth < PrijaveEkran.sirokoOd) {
                return Column(
                  children: [
                    TrakaFiltera(stanje: stanje, onPromena: onFilteri, saPonudama: true),
                    Expanded(
                      child: ListaPrijava(
                        podaci: stanje.podaci,
                        prijave: prijave,
                        kursor: stanje.kursor,
                        izabrana: stanje.izabrana,
                        focusNode: fokusPrijava,
                        onKursorPomeren: (pomak) => bloc.add(KursorPomeren(pomak)),
                        onKursorPostavljen: (indeks) => bloc.add(KursorPostavljen(indeks)),
                        onAktiviran: onOtvoriPodKursorom,
                        onIzaberi: onOtvori,
                        onKontekstMeni: onKontekstMeni,
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  TrakaPopunjenosti(
                    podaci: stanje.podaci,
                    izabranaPonuda: stanje.filteri.ponuda,
                    onIzaberiPonudu: (ponuda) => onFilteri(stanje.filteri.copyWith(ponuda: () => ponuda)),
                  ),
                  TrakaFiltera(stanje: stanje, onPromena: onFilteri),
                  const Divider(height: 1),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: TabelaPrijava(
                            podaci: stanje.podaci,
                            prijave: prijave,
                            kursor: stanje.kursor,
                            izabrana: stanje.izabrana,
                            focusNode: fokusPrijava,
                            onKursorPomeren: (pomak) => bloc.add(KursorPomeren(pomak)),
                            onKursorPostavljen: (indeks) => bloc.add(KursorPostavljen(indeks)),
                            onAktiviran: () => bloc.add(const KursorAktiviran()),
                            onIzaberi: onIzaberi,
                            onKontekstMeni: onKontekstMeni,
                          ),
                        ),
                        if (izabrana != null) ...[
                          const VerticalDivider(width: 1),
                          SizedBox(
                            width: 340,
                            child: DetaljPrijave(
                              prijava: izabrana,
                              podaci: stanje.podaci,
                              akcijaTraje: stanje.zauzet,
                              onZatvori: () => onIzaberi(null),
                              onPrihvati: akcije.contains(AkcijaKoordinatora.prihvati)
                                  ? () => onPrihvati(izabrana)
                                  : null,
                              onListaCekanja: akcije.contains(AkcijaKoordinatora.listaCekanja)
                                  ? () => onListaCekanja(izabrana)
                                  : null,
                              onOdbij: akcije.contains(AkcijaKoordinatora.odbij) ? () => onOdbij(izabrana) : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}