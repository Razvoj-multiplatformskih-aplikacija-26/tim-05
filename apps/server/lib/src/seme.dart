import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart';

import 'passwords.dart';
import 'pocetni_podaci.dart';

Future<void> upisiPocetnePodatke(Pool<void> baza, {required DateTime sada, required String? demoLozinka}) async {
  final redovi = await baza.execute('SELECT count(*) FROM korisnici');
  if (redovi.single[0] != 0) return;
  if (demoLozinka == null || demoLozinka.isEmpty) {
    throw StateError('DEMO_PASSWORD nije postavljen. Kopirajte .env.example u .env.');
  }
  final podaci = pocetniPodaci(sada);
  await baza.runTx((tx) => _upisi(tx, podaci, demoLozinka: demoLozinka));
}

Future<void> _upisi(Session tx, PocetniPodaci podaci, {required String demoLozinka}) async {
  for (final u in podaci.univerziteti) {
    await tx.execute(
      Sql.named(
        'INSERT INTO univerziteti (id, naziv, grad, drzava, oznaka_drzave) '
        'VALUES (@id, @naziv, @grad, @drzava, @oznaka)',
      ),
      parameters: {'id': u.id.vrednost, 'naziv': u.naziv, 'grad': u.grad, 'drzava': u.drzava, 'oznaka': u.oznakaDrzave},
    );
  }

  for (final k in podaci.sviKorisnici) {
    await tx.execute(
      Sql.named(
        'INSERT INTO korisnici (id, korisnicko_ime, uloga, id_univerziteta, lozinka_hes) '
        'VALUES (@id, @ime, @uloga, @univerzitet, @hes)',
      ),
      parameters: {
        'id': k.id.vrednost,
        'ime': k.korisnickoIme,
        'uloga': k.uloga.name,
        'univerzitet': k.idUniverziteta?.vrednost,
        'hes': podaci.nalozi.contains(k.id) ? await hashPassword(demoLozinka) : null,
      },
    );
  }

  for (final s in podaci.studenti) {
    await tx.execute(
      Sql.named(
        'INSERT INTO studenti (id, ime, prezime, broj_indeksa, email, fakultet, smer, godina_studija, prosek) '
        'VALUES (@id, @ime, @prezime, @indeks, @email, @fakultet, @smer, @godina, @prosek::numeric)',
      ),
      parameters: {
        'id': s.id.vrednost,
        'ime': s.ime,
        'prezime': s.prezime,
        'indeks': s.brojIndeksa,
        'email': s.email,
        'fakultet': s.fakultet,
        'smer': s.smer,
        'godina': s.godinaStudija,
        'prosek': s.prosek,
      },
    );
    for (final MapEntry(key: jezik, value: nivo) in s.znanjeJezika.entries) {
      await tx.execute(
        Sql.named('INSERT INTO znanje_jezika (id_studenta, jezik, nivo) VALUES (@id, @jezik, @nivo)'),
        parameters: {'id': s.id.vrednost, 'jezik': jezik.name, 'nivo': nivo.name},
      );
    }
  }

  for (final p in podaci.ponude) {
    await tx.execute(
      Sql.named('''
        INSERT INTO ponude (id, id_univerziteta, oblast, vrsta_semestra, akademska_godina, broj_mesta, rok,
                            minimalni_prosek, jezik, nivo_jezika, opis, napomena, objavio, objavljena)
        VALUES (@id, @univerzitet, @oblast, @vrsta, @godina, @mesta, @rok,
                @prosek::numeric, @jezik, @nivo, @opis, @napomena, @objavio, @objavljena)
      '''),
      parameters: {
        'id': p.id.vrednost,
        'univerzitet': p.idUniverziteta.vrednost,
        'oblast': p.oblast,
        'vrsta': p.semestar.vrsta.name,
        'godina': p.semestar.akademskaGodina,
        'mesta': p.brojMesta,
        'rok': p.rok.toUtc(),
        'prosek': p.minimalniProsek,
        'jezik': p.zahtevJezika.jezik.name,
        'nivo': p.zahtevJezika.nivo.name,
        'opis': p.opis,
        'napomena': p.napomena,
        'objavio': p.objavio.vrednost,
        'objavljena': p.objavljena.toUtc(),
      },
    );
  }

  final semestri = {for (final p in podaci.ponude) p.id: p.semestar};
  for (final p in podaci.prijave) {
    final stanje = koloneStanja(p.stanje);
    final semestar = semestri[p.idPonude]!;
    await tx.execute(
      Sql.named('''
        INSERT INTO prijave (id, id_studenta, id_ponude, vrsta_semestra, akademska_godina, motivaciono_pismo,
                             napomena, napravljena, stanje, stanje_kada, odlucio, razlog)
        VALUES (@id, @student, @ponuda, @vrsta, @godina, @pismo, @napomena, @napravljena,
                @stanje, @kada, @odlucio, @razlog)
      '''),
      parameters: {
        'id': p.id.vrednost,
        'student': p.idStudenta.vrednost,
        'ponuda': p.idPonude.vrednost,
        'vrsta': semestar.vrsta.name,
        'godina': semestar.akademskaGodina,
        'pismo': p.motivacionoPismo.tekst,
        'napomena': p.napomena,
        'napravljena': p.napravljena.toUtc(),
        'stanje': stanje.vrsta,
        'kada': stanje.kada?.toUtc(),
        'odlucio': stanje.odlucio?.vrednost,
        'razlog': stanje.razlog,
      },
    );
  }

  await tx.execute('''
    UPDATE ponude SET zauzeta_mesta = (
      SELECT count(*) FROM prijave
      WHERE prijave.id_ponude = ponude.id AND prijave.stanje IN ('prihvacena', 'potvrdjena')
    )
  ''');

  for (final MapEntry(key: student, value: ponude) in podaci.sacuvane.entries) {
    for (final ponuda in ponude) {
      await tx.execute(
        Sql.named('INSERT INTO sacuvane_ponude (id_studenta, id_ponude) VALUES (@student, @ponuda)'),
        parameters: {'student': student.vrednost, 'ponuda': ponuda.vrednost},
      );
    }
  }
}

({String vrsta, DateTime? kada, IdKorisnika? odlucio, String? razlog}) koloneStanja(StanjePrijave stanje) =>
    switch (stanje) {
      UPripremi() => (vrsta: 'u_pripremi', kada: null, odlucio: null, razlog: null),
      Poslata(:final kada) => (vrsta: 'poslata', kada: kada, odlucio: null, razlog: null),
      NaListiCekanja(:final odlucio, :final kada) => (
        vrsta: 'na_listi_cekanja',
        kada: kada,
        odlucio: odlucio,
        razlog: null,
      ),
      Prihvacena(:final odlucio, :final kada) => (vrsta: 'prihvacena', kada: kada, odlucio: odlucio, razlog: null),
      Odbijena(:final odlucio, :final kada, :final razlog) => (
        vrsta: 'odbijena',
        kada: kada,
        odlucio: odlucio,
        razlog: razlog,
      ),
      Potvrdjena(:final kada) => (vrsta: 'potvrdjena', kada: kada, odlucio: null, razlog: null),
      Povucena(:final kada) => (vrsta: 'povucena', kada: kada, odlucio: null, razlog: null),
    };