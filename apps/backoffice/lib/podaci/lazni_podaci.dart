import 'package:domain/domain.dart';

const pocetniKoordinator = Korisnik(
  id: IdKorisnika('k-polimi'),
  korisnickoIme: 'koordinator.polimi',
  uloga: Uloga.koordinator,
  idUniverziteta: _polimi,
);

final DateTime _danas = () {
  final sada = DateTime.now();
  return DateTime(sada.year, sada.month, sada.day);
}();

DateTime _dan(int broj) => _danas.add(Duration(days: broj));

DateTime _rok(int brojDana) => _dan(brojDana).add(const Duration(hours: 23, minutes: 59));

MotivacionoPismo _pismo(String tekst) => MotivacionoPismo.proveri(tekst).vrednostIliNull!;

const _polimi = IdUniverziteta('u-polimi');
const _unibo = IdUniverziteta('u-unibo');

const _andrej = IdKorisnika('s-1');
const _marko = IdKorisnika('s-2');
const _ana = IdKorisnika('s-3');
const _luka = IdKorisnika('s-4');
const _mina = IdKorisnika('s-5');
const _jovana = IdKorisnika('s-6');
const _stefan = IdKorisnika('s-7');
const _milica = IdKorisnika('s-8');

const _semestarZimski = Semestar(vrsta: VrstaSemestra.zimski, akademskaGodina: '2027/28');
const _semestarLetnji = Semestar(vrsta: VrstaSemestra.letnji, akademskaGodina: '2026/27');

const _engleskiB2 = ZahtevJezika(jezik: Jezik.engleski, nivo: NivoJezika.b2);

const pocetniUniverziteti = [
  Univerzitet(id: _polimi, naziv: 'Politecnico di Milano', grad: 'Milano', drzava: 'Italija', oznakaDrzave: 'IT'),
  Univerzitet(id: _unibo, naziv: 'Università di Bologna', grad: 'Bologna', drzava: 'Italija', oznakaDrzave: 'IT'),
];

Student _student(
  IdKorisnika id,
  String ime,
  String prezime,
  String indeks,
  double prosek,
  Map<Jezik, NivoJezika> jezici, {
  int godina = 3,
  String smer = 'Računarske nauke',
}) => Student(
  id: id,
  ime: ime,
  prezime: prezime,
  brojIndeksa: indeks,
  email: '${ime.toLowerCase()}.${indeks.replaceAll(RegExp('[^0-9]'), '')}@raf.rs',
  fakultet: 'Računarski fakultet, Beograd',
  smer: smer,
  godinaStudija: godina,
  prosek: prosek,
  znanjeJezika: jezici,
);

final pocetniStudenti = <Student>[
  _student(_andrej, 'Andrej', 'Aleksić', 'RN 76/24', 8.74, {Jezik.engleski: NivoJezika.b2}, godina: 4),
  _student(_marko, 'Marko', 'Petrović', 'RN 12/23', 9.21, {Jezik.engleski: NivoJezika.c1}),
  _student(_ana, 'Ana', 'Jovanović', 'SI 33/23', 9.56, {
    Jezik.engleski: NivoJezika.c1,
    Jezik.italijanski: NivoJezika.b1,
  }, smer: 'Softversko inženjerstvo'),
  _student(_luka, 'Luka', 'Nikolić', 'RN 41/24', 8.10, {Jezik.engleski: NivoJezika.b2}),
  _student(_mina, 'Mina', 'Đorđević', 'RI 7/23', 8.95, {
    Jezik.engleski: NivoJezika.b2,
  }, smer: 'Računarsko inženjerstvo'),
  _student(_jovana, 'Jovana', 'Ilić', 'SI 58/24', 7.85, {
    Jezik.engleski: NivoJezika.b2,
  }, smer: 'Softversko inženjerstvo'),
  _student(_stefan, 'Stefan', 'Marković', 'RN 90/23', 8.42, {Jezik.engleski: NivoJezika.b1}),
  _student(_milica, 'Milica', 'Stojanović', 'RN 5/22', 9.80, {Jezik.engleski: NivoJezika.c2}, godina: 4),
];

final pocetnePonude = <Ponuda>[
  Ponuda(
    id: const IdPonude('po-1'),
    idUniverziteta: _polimi,
    oblast: 'Računarstvo i softversko inženjerstvo',
    semestar: _semestarZimski,
    brojMesta: 4,
    rok: _rok(55),
    minimalniProsek: 8.0,
    zahtevJezika: _engleskiB2,
    opis: 'Najveći tehnički univerzitet u Italiji. Nastava iz računarstva održava se na engleskom jeziku.',
    objavio: pocetniKoordinator.id,
    objavljena: _dan(-2),
  ),
  // Sva mesta su popunjena - ekran ne nudi Prihvati.
  Ponuda(
    id: const IdPonude('po-10'),
    idUniverziteta: _polimi,
    oblast: 'Nauka o podacima',
    semestar: _semestarLetnji,
    brojMesta: 2,
    rok: _rok(-5),
    minimalniProsek: 8.0,
    zahtevJezika: _engleskiB2,
    opis: 'Program iz nauke o podacima na engleskom jeziku.',
    objavio: pocetniKoordinator.id,
    objavljena: _dan(-40),
  ),
  Ponuda(
    id: const IdPonude('po-11'),
    idUniverziteta: _polimi,
    oblast: 'Dizajn interakcije',
    semestar: _semestarZimski,
    brojMesta: 3,
    rok: _rok(70),
    minimalniProsek: 7.5,
    zahtevJezika: const ZahtevJezika(jezik: Jezik.engleski, nivo: NivoJezika.b1),
    opis: 'Predmeti iz dizajna korisničkih interfejsa i istraživanja korisnika, na engleskom jeziku.',
    objavio: pocetniKoordinator.id,
    objavljena: _dan(-10),
  ),
  // Drugi univerzitet - ne bi trebala da se vidi
  Ponuda(
    id: const IdPonude('po-2'),
    idUniverziteta: _unibo,
    oblast: 'Softversko inženjerstvo',
    semestar: _semestarLetnji,
    brojMesta: 2,
    rok: _rok(30),
    minimalniProsek: 8.0,
    zahtevJezika: _engleskiB2,
    opis: 'Master program iz softverskog inženjerstva na engleskom jeziku.',
    objavio: const IdKorisnika('k-unibo'),
    objavljena: _dan(-20),
  ),
];

Prijava _prijava(
  String id,
  IdKorisnika student,
  String ponuda,
  StanjePrijave stanje, {
  required int napravljenaPre,
  String pismo = 'Želim da proširim znanje iz računarstva i upoznam drugačiji način studiranja.',
  String? napomena,
}) {
  return Prijava(
    id: IdPrijave(id),
    idStudenta: student,
    idPonude: IdPonude(ponuda),
    motivacionoPismo: _pismo(pismo),
    napomena: napomena,
    stanje: stanje,
    napravljena: _dan(-napravljenaPre),
  );
}

final pocetnePrijave = <Prijava>[
  // 4 mesta jedno zauzeto.
  _prijava(
    'p-1',
    _andrej,
    'po-1',
    Poslata(kada: _dan(-3)),
    napravljenaPre: 5,
    pismo: 'Politecnico di Milano me zanima zbog predmeta iz računarstva visokih performansi.',
    napomena: 'Zanima me i mogućnost produženja boravka.',
  ),
  _prijava('p-2', _marko, 'po-1', Poslata(kada: _dan(-4)), napravljenaPre: 6),
  _prijava(
    'p-3',
    _ana,
    'po-1',
    Prihvacena(odlucio: pocetniKoordinator.id, kada: _dan(-1)),
    napravljenaPre: 12,
    pismo: 'Želim da u Milanu slušam predmete iz distribuiranih sistema i da radim na timskom projektu.',
  ),
  _prijava('p-4', _luka, 'po-1', NaListiCekanja(odlucio: pocetniKoordinator.id, kada: _dan(-2)), napravljenaPre: 9),
  _prijava(
    'p-5',
    _mina,
    'po-1',
    Odbijena(odlucio: pocetniKoordinator.id, kada: _dan(-2), razlog: 'Prednost su imali studenti sa višim prosekom.'),
    napravljenaPre: 15,
  ),
  _prijava('p-6', _jovana, 'po-1', Poslata(kada: _dan(-2)), napravljenaPre: 4),
  // U pripremi - koordinator ne bi trebalo da vidi
  _prijava('p-7', _stefan, 'po-1', const UPripremi(), napravljenaPre: 1),

  // 2 mesta zauzeta.
  _prijava('p-8', _milica, 'po-10', Potvrdjena(kada: _dan(-7)), napravljenaPre: 30),
  _prijava('p-9', _marko, 'po-10', Prihvacena(odlucio: pocetniKoordinator.id, kada: _dan(-8)), napravljenaPre: 28),
  _prijava('p-10', _ana, 'po-10', Poslata(kada: _dan(-20)), napravljenaPre: 22),
  _prijava('p-11', _jovana, 'po-10', Povucena(kada: _dan(-12)), napravljenaPre: 25),

  // 3 mesta slobodna
  _prijava('p-12', _luka, 'po-11', Poslata(kada: _dan(-1)), napravljenaPre: 3),
  _prijava('p-13', _mina, 'po-11', Poslata(kada: _dan(-2)), napravljenaPre: 3),
  _prijava('p-14', _stefan, 'po-11', NaListiCekanja(odlucio: pocetniKoordinator.id, kada: _dan(-1)), napravljenaPre: 6),
  _prijava(
    'p-15',
    _milica,
    'po-11',
    Odbijena(odlucio: pocetniKoordinator.id, kada: _dan(-3), razlog: 'Ponuda nije u skladu sa studijskim programom.'),
    napravljenaPre: 8,
  ),

  // Drugi univerzitet - ne bi trebala da se vidi
  _prijava('p-16', _andrej, 'po-2', Poslata(kada: _dan(-6)), napravljenaPre: 7),
];
