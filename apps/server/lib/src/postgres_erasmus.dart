import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart';
import 'package:use_cases/use_cases.dart';

import 'seme.dart';

const _jedinstvenost = '23505';
const _jednoPotvrdjeno = 'prijave_jedno_potvrdjeno_po_semestru';
const _aktivnaStanja = "('u_pripremi', 'poslata', 'na_listi_cekanja', 'prihvacena')";

final class PostgresErasmus implements PonudaRepository, PrijavaRepository, StudentRepository {
  const PostgresErasmus(this._baza);

  final Pool<void> _baza;

  // ponude

  @override
  Future<List<Univerzitet>> univerziteti() async {
    final redovi = await _baza.execute(
      'SELECT id, naziv, grad, drzava, oznaka_drzave FROM univerziteti ORDER BY naziv',
    );
    return [
      for (final [id, naziv, grad, drzava, oznaka] in redovi)
        Univerzitet(
          id: IdUniverziteta(id! as String),
          naziv: naziv! as String,
          grad: grad! as String,
          drzava: drzava! as String,
          oznakaDrzave: oznaka! as String,
        ),
    ];
  }

  @override
  Future<List<Ponuda>> ponude() async {
    final redovi = await _baza.execute('''
      SELECT id, id_univerziteta, oblast, vrsta_semestra, akademska_godina, broj_mesta, rok,
             minimalni_prosek::float8 AS minimalni_prosek, jezik, nivo_jezika, opis, napomena, objavio, objavljena
      FROM ponude
      ORDER BY objavljena DESC, id
    ''');
    return [for (final red in redovi) _ponuda(red.toColumnMap())];
  }

  @override
  Future<Map<IdPonude, int>> zauzetaMesta() async {
    final redovi = await _baza.execute('SELECT id, zauzeta_mesta FROM ponude');
    return {for (final [id, zauzeto] in redovi) IdPonude(id! as String): zauzeto! as int};
  }

  // prijave: čitanje

  @override
  Future<Prijava?> prijava(IdPrijave id) async {
    final nadjene = await _prijave('id = @id', {'id': id.vrednost});
    return nadjene.firstOrNull;
  }

  @override
  Future<List<Prijava>> prijaveStudenta(IdKorisnika idStudenta) =>
      _prijave('id_studenta = @student', {'student': idStudenta.vrednost});

  @override
  Future<List<Prijava>> prijaveNaPonudeUniverziteta(IdUniverziteta idUniverziteta) => _prijave(
    "stanje <> 'u_pripremi' AND id_ponude IN (SELECT id FROM ponude WHERE id_univerziteta = @univerzitet)",
    {'univerzitet': idUniverziteta.vrednost},
  );

  Future<List<Prijava>> _prijave(String uslov, Map<String, Object?> parametri, {Session? sesija}) async {
    final redovi = await (sesija ?? _baza).execute(
      Sql.named('''
        SELECT id, id_studenta, id_ponude, motivaciono_pismo, napomena, napravljena, stanje, stanje_kada, odlucio, razlog
        FROM prijave
        WHERE $uslov
        ORDER BY napravljena DESC, id
      '''),
      parameters: parametri,
    );
    return [for (final red in redovi) _prijava(red.toColumnMap())];
  }

  // prijave: upis


  @override
  Future<Rezultat<Prijava>> napravi(Prijava nova) async {
    final kolone = koloneStanja(nova.stanje);
    final redovi = await _baza.execute(
      Sql.named('''
        INSERT INTO prijave (id_studenta, id_ponude, vrsta_semestra, akademska_godina, motivaciono_pismo, napomena,
                             napravljena, stanje, stanje_kada, odlucio, razlog)
        SELECT @student, p.id, p.vrsta_semestra, p.akademska_godina, @pismo, @napomena,
               @napravljena, @stanje, @kada, @odlucio, @razlog
        FROM ponude p WHERE p.id = @ponuda
        RETURNING id
      '''),
      parameters: {
        'student': nova.idStudenta.vrednost,
        'ponuda': nova.idPonude.vrednost,
        'pismo': nova.motivacionoPismo.tekst,
        'napomena': nova.napomena,
        'napravljena': nova.napravljena.toUtc(),
        'stanje': kolone.vrsta,
        'kada': kolone.kada?.toUtc(),
        'odlucio': kolone.odlucio?.vrednost,
        'razlog': kolone.razlog,
      },
    );
    if (redovi.isEmpty) return const Neuspeh(NijePronadjeno());
    final upisana = await prijava(IdPrijave(redovi.single[0]! as String));
    return Uspeh(upisana!);
  }


  @override
  Future<Rezultat<Prijava>> sacuvaj(Prijava nova, {required StanjePrijave iz}) => _uTransakciji((tx) async {
    if (!await _promeniPrijavu(tx, nova, izStanja: koloneStanja(iz).vrsta)) {
      final trenutna = (await _prijave('id = @id', {'id': nova.id.vrednost}, sesija: tx)).firstOrNull;
      throw _Odustani(
        trenutna == null ? const NijePronadjeno() : NedozvoljenPrelaz(iz: trenutna.stanje, u: nova.stanje),
      );
    }
    final zauzimaMesto = _zauzimaMesto(nova.stanje);
    if (zauzimaMesto && !_zauzimaMesto(iz)) {
      if (!await _zauzmiMesto(tx, nova.idPonude)) throw const _Odustani(NemaSlobodnihMesta());
    } else if (!zauzimaMesto && _zauzimaMesto(iz)) {
      await _oslobodiMesto(tx, nova.idPonude);
    }
    return nova;
  });


  @override
  Future<Rezultat<List<Prijava>>> potvrdiMesto(Prijava potvrdjena, {required List<Prijava> povucene}) =>
      _uTransakciji((tx) async {
        await tx.execute(
          Sql.named('SELECT id FROM prijave WHERE id = ANY(@id) ORDER BY id FOR UPDATE'),
          parameters: {
            'id': TypedValue(Type.textArray, [
              for (final p in [potvrdjena, ...povucene]) p.id.vrednost,
            ]),
          },
        );
        if (!await _promeniPrijavu(tx, potvrdjena, izStanja: 'prihvacena')) {
          final trenutna = (await _prijave('id = @id', {'id': potvrdjena.id.vrednost}, sesija: tx)).firstOrNull;
          throw _Odustani(
            trenutna == null ? const NijePronadjeno() : NedozvoljenPrelaz(iz: trenutna.stanje, u: potvrdjena.stanje),
          );
        }
        final upisane = <Prijava>[potvrdjena];
        for (final povucena in povucene) {
          final redovi = await tx.execute(
            Sql.named('''
              WITH stara AS (SELECT id, id_ponude, stanje FROM prijave WHERE id = @id AND stanje IN $_aktivnaStanja)
              UPDATE prijave SET stanje = 'povucena', stanje_kada = @kada, odlucio = NULL, razlog = NULL
              FROM stara WHERE prijave.id = stara.id
              RETURNING stara.stanje
            '''),
            parameters: {'id': povucena.id.vrednost, 'kada': koloneStanja(povucena.stanje).kada?.toUtc()},
          );
          if (redovi.isEmpty) continue;
          if (redovi.single[0] == 'prihvacena') await _oslobodiMesto(tx, povucena.idPonude);
          upisane.add(povucena);
        }
        return upisane;
      });

  @override
  Future<void> obrisi(IdPrijave id) async {
    await _baza.execute(
      Sql.named("DELETE FROM prijave WHERE id = @id AND stanje IN ('odbijena', 'povucena')"),
      parameters: {'id': id.vrednost},
    );
  }

  Future<bool> _promeniPrijavu(Session tx, Prijava nova, {required String izStanja}) async {
    final kolone = koloneStanja(nova.stanje);
    final rezultat = await tx.execute(
      Sql.named('''
        UPDATE prijave
        SET motivaciono_pismo = @pismo, napomena = @napomena,
            stanje = @stanje, stanje_kada = @kada, odlucio = @odlucio, razlog = @razlog
        WHERE id = @id AND stanje = @iz
      '''),
      parameters: {
        'id': nova.id.vrednost,
        'iz': izStanja,
        'pismo': nova.motivacionoPismo.tekst,
        'napomena': nova.napomena,
        'stanje': kolone.vrsta,
        'kada': kolone.kada?.toUtc(),
        'odlucio': kolone.odlucio?.vrednost,
        'razlog': kolone.razlog,
      },
    );
    return rezultat.affectedRows == 1;
  }


  Future<bool> _zauzmiMesto(Session tx, IdPonude ponuda) async {
    final rezultat = await tx.execute(
      Sql.named('UPDATE ponude SET zauzeta_mesta = zauzeta_mesta + 1 WHERE id = @id AND zauzeta_mesta < broj_mesta'),
      parameters: {'id': ponuda.vrednost},
    );
    return rezultat.affectedRows == 1;
  }

  Future<void> _oslobodiMesto(Session tx, IdPonude ponuda) => tx.execute(
    Sql.named('UPDATE ponude SET zauzeta_mesta = zauzeta_mesta - 1 WHERE id = @id'),
    parameters: {'id': ponuda.vrednost},
  );

  static bool _zauzimaMesto(StanjePrijave stanje) => stanje is Prihvacena || stanje is Potvrdjena;

  Future<Rezultat<T>> _uTransakciji<T>(Future<T> Function(TxSession tx) posao) async {
    try {
      return Uspeh(await _baza.runTx(posao));
    } on _Odustani catch (odustajanje) {
      return Neuspeh(odustajanje.greska);
    } on ServerException catch (greska) {
      if (greska.code == _jedinstvenost && greska.constraintName == _jednoPotvrdjeno) {
        return const Neuspeh(VecPotvrdjenoMesto());
      }
      rethrow;
    }
  }

  // studenti

  Future<Student?> studentAkoPostoji(IdKorisnika id) async {
    final redovi = await _baza.execute(
      Sql.named('''
        SELECT id, ime, prezime, broj_indeksa, email, fakultet, smer, godina_studija, prosek::float8 AS prosek
        FROM studenti WHERE id = @id
      '''),
      parameters: {'id': id.vrednost},
    );
    if (redovi.isEmpty) return null;
    final jezici = await _baza.execute(
      Sql.named('SELECT jezik, nivo FROM znanje_jezika WHERE id_studenta = @id'),
      parameters: {'id': id.vrednost},
    );
    final red = redovi.single.toColumnMap();
    return Student(
      id: IdKorisnika(red['id'] as String),
      ime: red['ime'] as String,
      prezime: red['prezime'] as String,
      brojIndeksa: red['broj_indeksa'] as String,
      email: red['email'] as String,
      fakultet: red['fakultet'] as String,
      smer: red['smer'] as String,
      godinaStudija: red['godina_studija'] as int,
      prosek: red['prosek'] as double,
      znanjeJezika: {
        for (final [jezik, nivo] in jezici)
          Jezik.values.byName(jezik! as String): NivoJezika.values.byName(nivo! as String),
      },
    );
  }

  @override
  Future<Student> student(IdKorisnika id) async =>
      await studentAkoPostoji(id) ?? (throw const GreskaRepozitorijuma('Student nije pronađen'));

  @override
  Future<void> sacuvajStudenta(Student student) => _baza.runTx((tx) async {
    await tx.execute(
      Sql.named('''
        UPDATE studenti
        SET ime = @ime, prezime = @prezime, broj_indeksa = @indeks, email = @email, fakultet = @fakultet,
            smer = @smer, godina_studija = @godina, prosek = @prosek::numeric
        WHERE id = @id
      '''),
      parameters: {
        'id': student.id.vrednost,
        'ime': student.ime,
        'prezime': student.prezime,
        'indeks': student.brojIndeksa,
        'email': student.email,
        'fakultet': student.fakultet,
        'smer': student.smer,
        'godina': student.godinaStudija,
        'prosek': student.prosek,
      },
    );
    await tx.execute(
      Sql.named('DELETE FROM znanje_jezika WHERE id_studenta = @id'),
      parameters: {'id': student.id.vrednost},
    );
    for (final MapEntry(key: jezik, value: nivo) in student.znanjeJezika.entries) {
      await tx.execute(
        Sql.named('INSERT INTO znanje_jezika (id_studenta, jezik, nivo) VALUES (@id, @jezik, @nivo)'),
        parameters: {'id': student.id.vrednost, 'jezik': jezik.name, 'nivo': nivo.name},
      );
    }
  });

  @override
  Future<Set<IdPonude>> sacuvanePonude(IdKorisnika idStudenta) async {
    final redovi = await _baza.execute(
      Sql.named('SELECT id_ponude FROM sacuvane_ponude WHERE id_studenta = @id'),
      parameters: {'id': idStudenta.vrednost},
    );
    return {for (final [id] in redovi) IdPonude(id! as String)};
  }

  @override
  Future<void> promeniSacuvanu(IdKorisnika idStudenta, IdPonude idPonude) => _baza.runTx((tx) async {
    final parametri = {'student': idStudenta.vrednost, 'ponuda': idPonude.vrednost};
    final obrisano = await tx.execute(
      Sql.named('DELETE FROM sacuvane_ponude WHERE id_studenta = @student AND id_ponude = @ponuda'),
      parameters: parametri,
    );
    if (obrisano.affectedRows == 0) {
      await tx.execute(
        Sql.named(
          'INSERT INTO sacuvane_ponude (id_studenta, id_ponude) VALUES (@student, @ponuda) ON CONFLICT DO NOTHING',
        ),
        parameters: parametri,
      );
    }
  });
}

final class _Odustani implements Exception {
  const _Odustani(this.greska);

  final GreskaDomena greska;
}

Ponuda _ponuda(Map<String, dynamic> red) => Ponuda(
  id: IdPonude(red['id'] as String),
  idUniverziteta: IdUniverziteta(red['id_univerziteta'] as String),
  oblast: red['oblast'] as String,
  semestar: Semestar(
    vrsta: VrstaSemestra.values.byName(red['vrsta_semestra'] as String),
    akademskaGodina: red['akademska_godina'] as String,
  ),
  brojMesta: red['broj_mesta'] as int,
  rok: red['rok'] as DateTime,
  minimalniProsek: red['minimalni_prosek'] as double,
  zahtevJezika: ZahtevJezika(
    jezik: Jezik.values.byName(red['jezik'] as String),
    nivo: NivoJezika.values.byName(red['nivo_jezika'] as String),
  ),
  opis: red['opis'] as String,
  napomena: red['napomena'] as String?,
  objavio: IdKorisnika(red['objavio'] as String),
  objavljena: red['objavljena'] as DateTime,
);

Prijava _prijava(Map<String, dynamic> red) => Prijava(
  id: IdPrijave(red['id'] as String),
  idStudenta: IdKorisnika(red['id_studenta'] as String),
  idPonude: IdPonude(red['id_ponude'] as String),
  motivacionoPismo: MotivacionoPismo.proveri(red['motivaciono_pismo'] as String).vrednostIliNull!,
  napomena: red['napomena'] as String?,
  napravljena: red['napravljena'] as DateTime,
  stanje: stanjeIzKolona(
    vrsta: red['stanje'] as String,
    kada: red['stanje_kada'] as DateTime?,
    odlucio: red['odlucio'] as String?,
    razlog: red['razlog'] as String?,
  ),
);


StanjePrijave stanjeIzKolona({required String vrsta, DateTime? kada, String? odlucio, String? razlog}) =>
    switch (vrsta) {
      'u_pripremi' => const UPripremi(),
      'poslata' => Poslata(kada: kada!),
      'na_listi_cekanja' => NaListiCekanja(odlucio: IdKorisnika(odlucio!), kada: kada!),
      'prihvacena' => Prihvacena(odlucio: IdKorisnika(odlucio!), kada: kada!),
      'odbijena' => Odbijena(odlucio: IdKorisnika(odlucio!), kada: kada!, razlog: razlog!),
      'potvrdjena' => Potvrdjena(kada: kada!),
      'povucena' => Povucena(kada: kada!),
      _ => throw StateError('Nepoznato stanje u bazi: $vrsta'),
    };