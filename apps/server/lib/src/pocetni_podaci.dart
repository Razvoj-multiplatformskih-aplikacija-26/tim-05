import 'package:domain/domain.dart';

final class PocetniPodaci {
  const PocetniPodaci({
    required this.univerziteti,
    required this.koordinatori,
    required this.studenti,
    required this.korisniciStudenata,
    required this.ponude,
    required this.prijave,
    required this.sacuvane,
    required this.nalozi,
  });

  final List<Univerzitet> univerziteti;
  final List<Korisnik> koordinatori;
  final List<Student> studenti;
  final List<Korisnik> korisniciStudenata;
  final List<Ponuda> ponude;
  final List<Prijava> prijave;
  final Map<IdKorisnika, Set<IdPonude>> sacuvane;

  final Set<IdKorisnika> nalozi;

  List<Korisnik> get sviKorisnici => [...koordinatori, ...korisniciStudenata];
}

const _andrej = IdKorisnika('s-1');
const _marko = IdKorisnika('s-2');
const _ana = IdKorisnika('s-3');
const _luka = IdKorisnika('s-4');
const _mina = IdKorisnika('s-5');
const _jovana = IdKorisnika('s-6');
const _stefan = IdKorisnika('s-7');
const _milica = IdKorisnika('s-8');

const _polimi = IdUniverziteta('u-polimi');
const _unibo = IdUniverziteta('u-unibo');
const _polito = IdUniverziteta('u-polito');
const _tuwien = IdUniverziteta('u-tuwien');
const _ugr = IdUniverziteta('u-ugr');
const _ulisboa = IdUniverziteta('u-ulisboa');
const _tum = IdUniverziteta('u-tum');
const _uu = IdUniverziteta('u-uu');

const _kPolimi = IdKorisnika('k-polimi');
const _kUnibo = IdKorisnika('k-unibo');
const _kPolito = IdKorisnika('k-polito');
const _kTuwien = IdKorisnika('k-tuwien');
const _kUgr = IdKorisnika('k-ugr');
const _kUlisboa = IdKorisnika('k-ulisboa');
const _kTum = IdKorisnika('k-tum');
const _kUu = IdKorisnika('k-uu');

const _semestarZimski = Semestar(vrsta: VrstaSemestra.zimski, akademskaGodina: '2027/28');
const _semestarLetnji = Semestar(vrsta: VrstaSemestra.letnji, akademskaGodina: '2026/27');
const _semestarProsli = Semestar(vrsta: VrstaSemestra.letnji, akademskaGodina: '2025/26');

const _engleskiB2 = ZahtevJezika(jezik: Jezik.engleski, nivo: NivoJezika.b2);

const _univerziteti = [
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

Korisnik _koordinator(IdKorisnika id, String korisnickoIme, IdUniverziteta univerzitet) =>
    Korisnik(id: id, korisnickoIme: korisnickoIme, uloga: Uloga.koordinator, idUniverziteta: univerzitet);

final _koordinatori = [
  _koordinator(_kPolimi, 'koordinator1', _polimi),
  _koordinator(_kUnibo, 'koordinator2', _unibo),
  _koordinator(_kPolito, 'koordinator.polito', _polito),
  _koordinator(_kTuwien, 'koordinator.tuwien', _tuwien),
  _koordinator(_kUgr, 'koordinator.ugr', _ugr),
  _koordinator(_kUlisboa, 'koordinator.ulisboa', _ulisboa),
  _koordinator(_kTum, 'koordinator.tum', _tum),
  _koordinator(_kUu, 'koordinator.uu', _uu),
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

final _studenti = <Student>[
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

const _korisnickaImenaStudenata = {
  _andrej: 'student1',
  _marko: 'student2',
  _ana: 'ana.jovanovic',
  _luka: 'luka.nikolic',
  _mina: 'mina.djordjevic',
  _jovana: 'jovana.ilic',
  _stefan: 'stefan.markovic',
  _milica: 'milica.stojanovic',
};

PocetniPodaci pocetniPodaci(DateTime sada) {
  final danas = DateTime(sada.year, sada.month, sada.day);
  DateTime dan(int broj) => danas.add(Duration(days: broj));
  DateTime rok(int brojDana) => dan(brojDana).add(const Duration(hours: 23, minutes: 59));

  final ponude = <Ponuda>[
    Ponuda(
      id: const IdPonude('po-1'),
      idUniverziteta: _polimi,
      oblast: 'Računarstvo i softversko inženjerstvo',
      semestar: _semestarZimski,
      brojMesta: 4,
      rok: rok(55),
      minimalniProsek: 8.0,
      zahtevJezika: _engleskiB2,
      opis:
          'Najveći tehnički univerzitet u Italiji. Nastava iz računarstva održava se na engleskom jeziku, '
          'sa izbornim predmetima iz računarstva visokih performansi i distribuiranih sistema.',
      napomena: 'Predmeti se biraju u dogovoru sa koordinatorom posle prihvatanja prijave. Smeštaj nije obezbeđen.',
      objavio: _kPolimi,
      objavljena: dan(-2),
    ),
    Ponuda(
      id: const IdPonude('po-2'),
      idUniverziteta: _unibo,
      oblast: 'Softversko inženjerstvo',
      semestar: _semestarLetnji,
      brojMesta: 2,
      rok: rok(30),
      minimalniProsek: 8.0,
      zahtevJezika: _engleskiB2,
      opis: 'Najstariji univerzitet u Evropi, sa master programom iz softverskog inženjerstva na engleskom.',
      objavio: _kUnibo,
      objavljena: dan(-20),
    ),
    Ponuda(
      id: const IdPonude('po-3'),
      idUniverziteta: _polito,
      oblast: 'Računarstvo',
      semestar: _semestarZimski,
      brojMesta: 3,
      rok: rok(80),
      minimalniProsek: 7.5,
      zahtevJezika: const ZahtevJezika(jezik: Jezik.italijanski, nivo: NivoJezika.b1),
      opis: 'Tehnički univerzitet u Torinu. Deo predmeta se izvodi na italijanskom jeziku.',
      objavio: _kPolito,
      objavljena: dan(-5),
    ),
    Ponuda(
      id: const IdPonude('po-4'),
      idUniverziteta: _tuwien,
      oblast: 'Informatika',
      semestar: _semestarZimski,
      brojMesta: 3,
      rok: rok(40),
      minimalniProsek: 8.0,
      zahtevJezika: _engleskiB2,
      opis: 'Tehnički univerzitet u Beču, poznat po grupama za distribuirane i paralelne sisteme.',
      objavio: _kTuwien,
      objavljena: dan(-12),
    ),
    Ponuda(
      id: const IdPonude('po-5'),
      idUniverziteta: _ugr,
      oblast: 'Računarstvo',
      semestar: _semestarLetnji,
      brojMesta: 2,
      rok: rok(20),
      minimalniProsek: 7.0,
      zahtevJezika: const ZahtevJezika(jezik: Jezik.engleski, nivo: NivoJezika.b1),
      opis: 'Univerzitet u Granadi, jedan od najpopularnijih među studentima na razmeni.',
      objavio: _kUgr,
      objavljena: dan(-15),
    ),
    Ponuda(
      id: const IdPonude('po-6'),
      idUniverziteta: _ulisboa,
      oblast: 'Informatika',
      semestar: _semestarLetnji,
      brojMesta: 2,
      rok: rok(60),
      minimalniProsek: 7.5,
      zahtevJezika: _engleskiB2,
      opis: 'Najveći univerzitet u Portugaliji, sa programom informatike na engleskom jeziku.',
      objavio: _kUlisboa,
      objavljena: dan(-4),
    ),
    Ponuda(
      id: const IdPonude('po-7'),
      idUniverziteta: _tum,
      oblast: 'Informatika',
      semestar: _semestarZimski,
      brojMesta: 5,
      rok: rok(45),
      minimalniProsek: 9.0,
      zahtevJezika: const ZahtevJezika(jezik: Jezik.engleski, nivo: NivoJezika.c1),
      opis: 'Tehnički univerzitet u Minhenu, sa visokim uslovima za upis predmeta na razmeni.',
      objavio: _kTum,
      objavljena: dan(-1),
    ),
    Ponuda(
      id: const IdPonude('po-8'),
      idUniverziteta: _uu,
      oblast: 'Računarstvo',
      semestar: _semestarZimski,
      brojMesta: 2,
      rok: rok(90),
      minimalniProsek: 8.0,
      zahtevJezika: _engleskiB2,
      opis: 'Najstariji univerzitet u Skandinaviji. Nastava na engleskom, u malim grupama.',
      objavio: _kUu,
      objavljena: dan(-30),
    ),
    Ponuda(
      id: const IdPonude('po-9'),
      idUniverziteta: _tum,
      oblast: 'Informatika',
      semestar: _semestarProsli,
      brojMesta: 3,
      rok: rok(-200),
      minimalniProsek: 8.0,
      zahtevJezika: _engleskiB2,
      opis: 'Prošlogodišnja ponuda TU München.',
      objavio: _kTum,
      objavljena: dan(-260),
    ),
    Ponuda(
      id: const IdPonude('po-10'),
      idUniverziteta: _polimi,
      oblast: 'Nauka o podacima',
      semestar: _semestarLetnji,
      brojMesta: 2,
      rok: rok(-5),
      minimalniProsek: 8.0,
      zahtevJezika: _engleskiB2,
      opis: 'Program iz nauke o podacima na engleskom jeziku.',
      objavio: _kPolimi,
      objavljena: dan(-40),
    ),
    Ponuda(
      id: const IdPonude('po-11'),
      idUniverziteta: _polimi,
      oblast: 'Dizajn interakcije',
      semestar: _semestarZimski,
      brojMesta: 3,
      rok: rok(70),
      minimalniProsek: 7.5,
      zahtevJezika: const ZahtevJezika(jezik: Jezik.engleski, nivo: NivoJezika.b1),
      opis: 'Predmeti iz dizajna korisničkih interfejsa i istraživanja korisnika, na engleskom jeziku.',
      objavio: _kPolimi,
      objavljena: dan(-10),
    ),
  ];

  Prijava prijava(
    String id,
    IdKorisnika student,
    String ponuda,
    StanjePrijave stanje, {
    required int napravljenaPre,
    String pismo = 'Želim da proširim znanje iz računarstva i upoznam drugačiji način studiranja.',
    String? napomena,
  }) => Prijava(
    id: IdPrijave(id),
    idStudenta: student,
    idPonude: IdPonude(ponuda),
    motivacionoPismo: MotivacionoPismo.proveri(pismo).vrednostIliNull!,
    napomena: napomena,
    stanje: stanje,
    napravljena: dan(-napravljenaPre),
  );

  final prijave = <Prijava>[
    // student1 (Andrej): isto kao u mobilnoj aplikaciji na KT1, sve vrste stanja.
    prijava(
      'p-1',
      _andrej,
      'po-6',
      const UPripremi(),
      napravljenaPre: 1,
      pismo: 'Lisabon me zanima zbog programa informatike i iskustva života u drugoj zemlji.',
    ),
    prijava(
      'p-2',
      _andrej,
      'po-4',
      Poslata(kada: dan(-6)),
      napravljenaPre: 8,
      pismo: 'TU Wien me zanima zbog jake grupe za distribuirane sisteme.',
    ),
    prijava('p-3', _andrej, 'po-5', NaListiCekanja(odlucio: _kUgr, kada: dan(-3)), napravljenaPre: 10),
    prijava(
      'p-4',
      _andrej,
      'po-1',
      Prihvacena(odlucio: _kPolimi, kada: dan(-1)),
      napravljenaPre: 14,
      pismo: 'Politecnico di Milano me zanima zbog predmeta iz računarstva visokih performansi.',
      napomena: 'Zanima me i mogućnost produženja boravka.',
    ),
    prijava(
      'p-5',
      _andrej,
      'po-2',
      Odbijena(odlucio: _kUnibo, kada: dan(-9), razlog: 'Mesta su popunjena studentima sa višim prosekom.'),
      napravljenaPre: 18,
    ),
    prijava('p-6', _andrej, 'po-8', Povucena(kada: dan(-15)), napravljenaPre: 25),
    prijava('p-7', _andrej, 'po-9', Potvrdjena(kada: dan(-220)), napravljenaPre: 240),
    prijava(
      'p-8',
      _andrej,
      'po-3',
      const UPripremi(),
      napravljenaPre: 2,
      pismo: 'Torino me zanima zbog laboratorije za ugrađene sisteme.',
    ),
    prijava(
      'p-9',
      _andrej,
      'po-7',
      const UPripremi(),
      napravljenaPre: 3,
      pismo: 'TU München me zanima zbog predmeta iz mašinskog učenja.',
    ),
    prijava(
      'p-10',
      _andrej,
      'po-10',
      Odbijena(odlucio: _kPolimi, kada: dan(-3), razlog: 'Prednost su imali studenti sa iskustvom u obradi podataka.'),
      napravljenaPre: 30,
    ),

    // Prijave na ponude Politecnico di Milano, kao u backoffice-u na KT1 (koordinator1).
    prijava('p-11', _marko, 'po-1', Poslata(kada: dan(-4)), napravljenaPre: 6),
    prijava(
      'p-12',
      _ana,
      'po-1',
      Prihvacena(odlucio: _kPolimi, kada: dan(-1)),
      napravljenaPre: 12,
      pismo: 'Želim da u Milanu slušam predmete iz distribuiranih sistema i da radim na timskom projektu.',
    ),
    prijava('p-13', _luka, 'po-1', NaListiCekanja(odlucio: _kPolimi, kada: dan(-2)), napravljenaPre: 9),
    prijava(
      'p-14',
      _mina,
      'po-1',
      Odbijena(odlucio: _kPolimi, kada: dan(-2), razlog: 'Prednost su imali studenti sa višim prosekom.'),
      napravljenaPre: 15,
    ),
    prijava('p-15', _stefan, 'po-1', const UPripremi(), napravljenaPre: 1),
    prijava('p-16', _milica, 'po-10', Potvrdjena(kada: dan(-7)), napravljenaPre: 30),
    prijava('p-17', _marko, 'po-10', Prihvacena(odlucio: _kPolimi, kada: dan(-8)), napravljenaPre: 28),
    prijava('p-18', _ana, 'po-10', Poslata(kada: dan(-20)), napravljenaPre: 22),
    prijava('p-19', _jovana, 'po-10', Povucena(kada: dan(-12)), napravljenaPre: 25),
    prijava('p-20', _luka, 'po-11', Poslata(kada: dan(-1)), napravljenaPre: 3),
    prijava('p-21', _mina, 'po-11', Poslata(kada: dan(-2)), napravljenaPre: 3),
    prijava('p-22', _stefan, 'po-11', NaListiCekanja(odlucio: _kPolimi, kada: dan(-1)), napravljenaPre: 6),
    prijava(
      'p-23',
      _milica,
      'po-11',
      Odbijena(odlucio: _kPolimi, kada: dan(-3), razlog: 'Ponuda nije u skladu sa studijskim programom.'),
      napravljenaPre: 8,
    ),
    prijava('p-24', _jovana, 'po-11', Poslata(kada: dan(-2)), napravljenaPre: 4),

    // Prijave na ponude drugih univerziteta (koordinator2 i ostali).
    prijava('p-25', _marko, 'po-7', Poslata(kada: dan(-1)), napravljenaPre: 2),
    prijava('p-26', _luka, 'po-2', Potvrdjena(kada: dan(-7)), napravljenaPre: 21),
    prijava('p-27', _mina, 'po-2', Prihvacena(odlucio: _kUnibo, kada: dan(-8)), napravljenaPre: 20),
  ];

  return PocetniPodaci(
    univerziteti: _univerziteti,
    koordinatori: _koordinatori,
    studenti: _studenti,
    korisniciStudenata: [
      for (final student in _studenti)
        Korisnik(id: student.id, korisnickoIme: _korisnickaImenaStudenata[student.id]!, uloga: Uloga.student),
    ],
    ponude: ponude,
    prijave: prijave,
    sacuvane: const {
      _andrej: {IdPonude('po-2'), IdPonude('po-7'), IdPonude('po-8')},
    },
    nalozi: const {_andrej, _marko, _kPolimi, _kUnibo},
  );
}