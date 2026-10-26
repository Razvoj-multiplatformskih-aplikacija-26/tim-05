import 'package:domain/domain.dart';

final sada = DateTime(2026, 11, 1, 12);

const andrej = Korisnik(id: IdKorisnika('s-1'), korisnickoIme: 'andrej', uloga: Uloga.student);
const luka = Korisnik(id: IdKorisnika('s-2'), korisnickoIme: 'luka', uloga: Uloga.student);

const koordinatorMilano = Korisnik(
  id: IdKorisnika('k-1'),
  korisnickoIme: 'koordinator.milano',
  uloga: Uloga.koordinator,
  idUniverziteta: IdUniverziteta('u-polimi'),
);

const koordinatorBec = Korisnik(
  id: IdKorisnika('k-2'),
  korisnickoIme: 'koordinator.bec',
  uloga: Uloga.koordinator,
  idUniverziteta: IdUniverziteta('u-tuwien'),
);

const studentAndrej = Student(
  id: IdKorisnika('s-1'),
  ime: 'Andrej',
  prezime: 'Aleksić',
  brojIndeksa: 'RN 76/24',
  email: 'andrej@raf.rs',
  fakultet: 'Racunarski fakultet',
  smer: 'Racunarske nauke',
  godinaStudija: 4,
  prosek: 8.74,
  znanjeJezika: {Jezik.engleski: NivoJezika.b2},
);

Ponuda ponuda({
  String id = 'po-1',
  int brojMesta = 2,
  double minimalniProsek = 8.0,
  Jezik jezik = Jezik.engleski,
  NivoJezika nivo = NivoJezika.b2,
  DateTime? rok,
  Semestar semestar = const Semestar(vrsta: VrstaSemestra.zimski, akademskaGodina: '2027/28'),
}) {
  return Ponuda(
    id: IdPonude(id),
    idUniverziteta: const IdUniverziteta('u-polimi'),
    oblast: 'Racunarstvo',
    semestar: semestar,
    brojMesta: brojMesta,
    rok: rok ?? DateTime(2026, 12, 15, 23, 59),
    minimalniProsek: minimalniProsek,
    zahtevJezika: ZahtevJezika(jezik: jezik, nivo: nivo),
    opis: 'Opis ponude.',
    objavio: const IdKorisnika('k-1'),
    objavljena: DateTime(2026, 10, 1),
  );
}

final pismo = MotivacionoPismo.proveri('zelim da studiram u Milanu.').vrednostIliNull!;

Prijava prijava({
  String id = 'p-1',
  String idStudenta = 's-1',
  String idPonude = 'po-1',
  StanjePrijave stanje = const UPripremi(),
}) {
  return Prijava(
    id: IdPrijave(id),
    idStudenta: IdKorisnika(idStudenta),
    idPonude: IdPonude(idPonude),
    motivacionoPismo: pismo,
    napravljena: DateTime(2026, 10, 20),
    stanje: stanje,
  );
}
