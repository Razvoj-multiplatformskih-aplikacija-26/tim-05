import 'package:domain/domain.dart';

String formatDatum(DateTime datum) => '${datum.day}. ${datum.month}. ${datum.year}.';

String formatKratakDatum(DateTime datum) => '${datum.day}. ${datum.month}.';

String formatProsek(double prosek) => prosek.toStringAsFixed(2).replaceAll('.', ',');

String velikoPrvo(String tekst) => tekst.isEmpty ? tekst : tekst[0].toUpperCase() + tekst.substring(1);

String nazivJezika(Jezik jezik) => switch (jezik) {
  Jezik.engleski => 'engleski',
  Jezik.nemacki => 'nemački',
  Jezik.francuski => 'francuski',
  Jezik.italijanski => 'italijanski',
  Jezik.spanski => 'španski',
  Jezik.portugalski => 'portugalski',
  Jezik.svedski => 'švedski',
};

String opisZahtevaJezika(ZahtevJezika zahtev) => '${velikoPrvo(nazivJezika(zahtev.jezik))} ${zahtev.nivo.oznaka}';

String nazivSemestra(Semestar semestar) {
  final vrsta = switch (semestar.vrsta) {
    VrstaSemestra.zimski => 'Zimski',
    VrstaSemestra.letnji => 'Letnji',
  };
  return '$vrsta ${semestar.akademskaGodina}';
}

String nazivStanja(StanjePrijave stanje) => switch (stanje) {
  UPripremi() => 'U pripremi',
  Poslata() => 'Poslata',
  NaListiCekanja() => 'Lista čekanja',
  Prihvacena() => 'Prihvaćena',
  Odbijena() => 'Odbijena',
  Potvrdjena() => 'Potvrđena',
  Povucena() => 'Povučena',
};

String brojMesta(int broj) {
  final jednina = broj % 10 == 1 && broj % 100 != 11;
  return '$broj ${jednina ? 'mesto' : 'mesta'}';
}
