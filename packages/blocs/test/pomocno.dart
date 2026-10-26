import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'test_baza.dart';

const andrej = Korisnik(id: IdKorisnika('s-1'), korisnickoIme: 'andrej', uloga: Uloga.student);

const student = Student(
  id: IdKorisnika('s-1'),
  ime: 'Andrej',
  prezime: 'Aleksić',
  brojIndeksa: 'RN 76/24',
  email: 'andrej@raf.rs',
  fakultet: 'Računarski fakultet',
  smer: 'Računarske nauke',
  godinaStudija: 4,
  prosek: 8.74,
  znanjeJezika: {Jezik.engleski: NivoJezika.b2},
);

final sat = FiksniSat(DateTime(2026, 11, 1, 12));

Ponuda ponuda({String id = 'po-1', double minimalniProsek = 8.0}) => Ponuda(
  id: IdPonude(id),
  idUniverziteta: const IdUniverziteta('u-polimi'),
  oblast: 'Računarstvo',
  semestar: const Semestar(vrsta: VrstaSemestra.zimski, akademskaGodina: '2027/28'),
  brojMesta: 2,
  rok: DateTime(2026, 12, 15, 23, 59),
  minimalniProsek: minimalniProsek,
  zahtevJezika: const ZahtevJezika(jezik: Jezik.engleski, nivo: NivoJezika.b2),
  opis: 'Opis ponude.',
  objavio: const IdKorisnika('k-1'),
  objavljena: DateTime(2026, 10, 1),
);

final pismo = MotivacionoPismo.proveri('Želim da studiram u Milanu.').vrednostIliNull!;

Prijava prijava({String id = 'p-1', String idPonude = 'po-1', StanjePrijave stanje = const UPripremi()}) => Prijava(
  id: IdPrijave(id),
  idStudenta: andrej.id,
  idPonude: IdPonude(idPonude),
  motivacionoPismo: pismo,
  napravljena: DateTime(2026, 10, 20),
  stanje: stanje,
);

UcitajPregled ucitajPregled(TestBaza baza) => UcitajPregled(ponude: baza, prijave: baza, studenti: baza, sat: sat);
