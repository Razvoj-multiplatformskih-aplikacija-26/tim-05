import 'package:domain/domain.dart';

import 'lazno_skladiste.dart';

const pocetniKorisnik = Korisnik(id: _andrej, korisnickoIme: 'andrej', uloga: Uloga.student);

const pocetniStudent = Student(
  id: _andrej,
  ime: 'Andrej',
  prezime: 'Aleksić',
  brojIndeksa: 'RN 76/24',
  email: 'andrej@raf.rs',
  fakultet: 'Računarski fakultet, Beograd',
  smer: 'Računarske nauke',
  godinaStudija: 4,
  prosek: 8.74,
  znanjeJezika: {Jezik.engleski: NivoJezika.b2},
);

const pocetneSacuvane = {IdPonude('po-2'), IdPonude('po-7'), IdPonude('po-8')};

final skladiste = LaznoSkladiste(
  korisnik: pocetniKorisnik,
  student: pocetniStudent,
  univerziteti: pocetniUniverziteti,
  ponude: List.of(pocetnePonude),
  svePrijave: List.of(pocetnePrijave),
  sacuvane: Set.of(pocetneSacuvane),
);

final DateTime _danas = () {
  final sada = DateTime.now();
  return DateTime(sada.year, sada.month, sada.day);
}();

DateTime _dan(int broj) => _danas.add(Duration(days: broj));

DateTime _rok(int brojDana) => _dan(brojDana).add(const Duration(hours: 23, minutes: 59));

MotivacionoPismo _pismo(String tekst) => MotivacionoPismo.proveri(tekst).vrednostIliNull!;

const _andrej = IdKorisnika('s-1');
const _marko = IdKorisnika('s-2');
const _ana = IdKorisnika('s-3');
const _luka = IdKorisnika('s-4');
const _mina = IdKorisnika('s-5');

const _polimi = IdUniverziteta('u-polimi');
const _unibo = IdUniverziteta('u-unibo');
const _polito = IdUniverziteta('u-polito');
const _tuwien = IdUniverziteta('u-tuwien');
const _ugr = IdUniverziteta('u-ugr');
const _ulisboa = IdUniverziteta('u-ulisboa');
const _tum = IdUniverziteta('u-tum');
const _uu = IdUniverziteta('u-uu');

const _semestarZimski = Semestar(vrsta: VrstaSemestra.zimski, akademskaGodina: '2027/28');
const _semestarLetnji = Semestar(vrsta: VrstaSemestra.letnji, akademskaGodina: '2026/27');
const _semestarProsli = Semestar(vrsta: VrstaSemestra.letnji, akademskaGodina: '2025/26');

const _engleskiB2 = ZahtevJezika(jezik: Jezik.engleski, nivo: NivoJezika.b2);

const pocetniUniverziteti = [
  Univerzitet(id: _polimi, naziv: 'Politecnico di Milano', grad: 'Milano', drzava: 'Italija', oznakaDrzave: 'IT'),
  Univerzitet(id: _unibo, naziv: 'Università di Bologna', grad: 'Bologna', drzava: 'Italija', oznakaDrzave: 'IT'),
  Univerzitet(id: _polito, naziv: 'Politecnico di Torino', grad: 'Torino', drzava: 'Italija', oznakaDrzave: 'IT'),
  Univerzitet(id: _tuwien, naziv: 'TU Wien', grad: 'Beč', drzava: 'Austrija', oznakaDrzave: 'AT'),
  Univerzitet(id: _ugr, naziv: 'Universidad de Granada', grad: 'Granada', drzava: 'Španija', oznakaDrzave: 'ES'),
  Univerzitet(
    id: _ulisboa,
    naziv: 'Universidade de Lisboa',
    grad: 'Lisabon',
    drzava: 'Portugalija',
    oznakaDrzave: 'PT',
  ),
  Univerzitet(id: _tum, naziv: 'TU München', grad: 'Minhen', drzava: 'Nemačka', oznakaDrzave: 'DE'),
  Univerzitet(id: _uu, naziv: 'Uppsala universitet', grad: 'Upsala', drzava: 'Švedska', oznakaDrzave: 'SE'),
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
    opis:
        'Najveći tehnički univerzitet u Italiji. Nastava iz računarstva održava se na engleskom jeziku, '
        'sa izbornim predmetima iz računarstva visokih performansi i distribuiranih sistema.',
    napomena: 'Predmeti se biraju u dogovoru sa koordinatorom posle prihvatanja prijave. Smeštaj nije obezbeđen.',
    objavio: const IdKorisnika('k-polimi'),
    objavljena: _dan(-2),
  ),
  Ponuda(
    id: const IdPonude('po-2'),
    idUniverziteta: _unibo,
    oblast: 'Softversko inženjerstvo',
    semestar: _semestarLetnji,
    brojMesta: 2,
    rok: _rok(30),
    minimalniProsek: 8.0,
    zahtevJezika: _engleskiB2,
    opis: 'Najstariji univerzitet u Evropi, sa master programom iz softverskog inženjerstva na engleskom.',
    objavio: const IdKorisnika('k-unibo'),
    objavljena: _dan(-20),
  ),
  Ponuda(
    id: const IdPonude('po-3'),
    idUniverziteta: _polito,
    oblast: 'Računarstvo',
    semestar: _semestarZimski,
    brojMesta: 3,
    rok: _rok(80),
    minimalniProsek: 7.5,
    zahtevJezika: const ZahtevJezika(jezik: Jezik.italijanski, nivo: NivoJezika.b1),
    opis: 'Tehnički univerzitet u Torinu. Deo predmeta se izvodi na italijanskom jeziku.',
    objavio: const IdKorisnika('k-polito'),
    objavljena: _dan(-5),
  ),
  Ponuda(
    id: const IdPonude('po-4'),
    idUniverziteta: _tuwien,
    oblast: 'Informatika',
    semestar: _semestarZimski,
    brojMesta: 3,
    rok: _rok(40),
    minimalniProsek: 8.0,
    zahtevJezika: _engleskiB2,
    opis: 'Tehnički univerzitet u Beču, poznat po grupama za distribuirane i paralelne sisteme.',
    objavio: const IdKorisnika('k-tuwien'),
    objavljena: _dan(-12),
  ),
  Ponuda(
    id: const IdPonude('po-5'),
    idUniverziteta: _ugr,
    oblast: 'Računarstvo',
    semestar: _semestarLetnji,
    brojMesta: 2,
    rok: _rok(20),
    minimalniProsek: 7.0,
    zahtevJezika: const ZahtevJezika(jezik: Jezik.engleski, nivo: NivoJezika.b1),
    opis: 'Univerzitet u Granadi, jedan od najpopularnijih među studentima na razmeni.',
    objavio: const IdKorisnika('k-ugr'),
    objavljena: _dan(-15),
  ),
  Ponuda(
    id: const IdPonude('po-6'),
    idUniverziteta: _ulisboa,
    oblast: 'Informatika',
    semestar: _semestarLetnji,
    brojMesta: 2,
    rok: _rok(60),
    minimalniProsek: 7.5,
    zahtevJezika: _engleskiB2,
    opis: 'Najveći univerzitet u Portugaliji, sa programom informatike na engleskom jeziku.',
    objavio: const IdKorisnika('k-ulisboa'),
    objavljena: _dan(-4),
  ),
  Ponuda(
    id: const IdPonude('po-7'),
    idUniverziteta: _tum,
    oblast: 'Informatika',
    semestar: _semestarZimski,
    brojMesta: 5,
    rok: _rok(45),
    minimalniProsek: 9.0,
    zahtevJezika: const ZahtevJezika(jezik: Jezik.engleski, nivo: NivoJezika.c1),
    opis: 'Tehnički univerzitet u Minhenu, sa visokim uslovima za upis predmeta na razmeni.',
    objavio: const IdKorisnika('k-tum'),
    objavljena: _dan(-1),
  ),
  Ponuda(
    id: const IdPonude('po-8'),
    idUniverziteta: _uu,
    oblast: 'Računarstvo',
    semestar: _semestarZimski,
    brojMesta: 2,
    rok: _rok(90),
    minimalniProsek: 8.0,
    zahtevJezika: _engleskiB2,
    opis: 'Najstariji univerzitet u Skandinaviji. Nastava na engleskom, u malim grupama.',
    objavio: const IdKorisnika('k-uu'),
    objavljena: _dan(-30),
  ),
  Ponuda(
    id: const IdPonude('po-9'),
    idUniverziteta: _tum,
    oblast: 'Informatika',
    semestar: _semestarProsli,
    brojMesta: 3,
    rok: _rok(-200),
    minimalniProsek: 8.0,
    zahtevJezika: _engleskiB2,
    opis: 'Prošlogodišnja ponuda TU München.',
    objavio: const IdKorisnika('k-tum'),
    objavljena: _dan(-260),
  ),
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
    objavio: const IdKorisnika('k-polimi'),
    objavljena: _dan(-40),
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
  _prijava(
    'p-1',
    _andrej,
    'po-6',
    const UPripremi(),
    napravljenaPre: 1,
    pismo: 'Lisabon me zanima zbog programa informatike i iskustva života u drugoj zemlji.',
  ),
  _prijava(
    'p-2',
    _andrej,
    'po-4',
    Poslata(kada: _dan(-6)),
    napravljenaPre: 8,
    pismo: 'TU Wien me zanima zbog jake grupe za distribuirane sisteme.',
  ),
  _prijava(
    'p-3',
    _andrej,
    'po-5',
    NaListiCekanja(odlucio: const IdKorisnika('k-ugr'), kada: _dan(-3)),
    napravljenaPre: 10,
  ),
  _prijava(
    'p-4',
    _andrej,
    'po-1',
    Prihvacena(odlucio: const IdKorisnika('k-polimi'), kada: _dan(-1)),
    napravljenaPre: 14,
    pismo: 'Politecnico di Milano me zanima zbog predmeta iz računarstva visokih performansi.',
    napomena: 'Zanima me i mogućnost produženja boravka.',
  ),
  _prijava(
    'p-5',
    _andrej,
    'po-2',
    Odbijena(
      odlucio: const IdKorisnika('k-unibo'),
      kada: _dan(-9),
      razlog: 'Mesta su popunjena studentima sa višim prosekom.',
    ),
    napravljenaPre: 18,
  ),
  _prijava('p-6', _andrej, 'po-8', Povucena(kada: _dan(-15)), napravljenaPre: 25),
  _prijava('p-7', _andrej, 'po-9', Potvrdjena(kada: _dan(-220)), napravljenaPre: 240),

  _prijava(
    'p-13',
    _andrej,
    'po-3',
    const UPripremi(),
    napravljenaPre: 2,
    pismo: 'Torino me zanima zbog laboratorije za ugrađene sisteme.',
  ),
  _prijava(
    'p-14',
    _andrej,
    'po-7',
    const UPripremi(),
    napravljenaPre: 3,
    pismo: 'TU München me zanima zbog predmeta iz mašinskog učenja.',
  ),
  _prijava(
    'p-15',
    _andrej,
    'po-10',
    Odbijena(
      odlucio: const IdKorisnika('k-polimi'),
      kada: _dan(-3),
      razlog: 'Prednost su imali studenti sa iskustvom u obradi podataka.',
    ),
    napravljenaPre: 30,
  ),

  _prijava(
    'p-8',
    _marko,
    'po-1',
    Prihvacena(odlucio: const IdKorisnika('k-polimi'), kada: _dan(-2)),
    napravljenaPre: 12,
  ),
  _prijava('p-9', _ana, 'po-1', Poslata(kada: _dan(-4)), napravljenaPre: 5),
  _prijava('p-10', _luka, 'po-2', Potvrdjena(kada: _dan(-7)), napravljenaPre: 21),
  _prijava(
    'p-11',
    _mina,
    'po-2',
    Prihvacena(odlucio: const IdKorisnika('k-unibo'), kada: _dan(-8)),
    napravljenaPre: 20,
  ),
  _prijava('p-12', _marko, 'po-7', Poslata(kada: _dan(-1)), napravljenaPre: 2),
];
