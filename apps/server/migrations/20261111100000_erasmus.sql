-- migrate:up

CREATE TABLE univerziteti (
  id text PRIMARY KEY,
  naziv text NOT NULL,
  grad text NOT NULL,
  drzava text NOT NULL,
  oznaka_drzave text NOT NULL CHECK (oznaka_drzave ~ '^[A-Z]{2}$')
);

CREATE TABLE korisnici (
  id text PRIMARY KEY,
  korisnicko_ime text NOT NULL UNIQUE,
  uloga text NOT NULL CHECK (uloga IN ('student', 'koordinator')),
  id_univerziteta text REFERENCES univerziteti (id),
  lozinka_hes text,
  CONSTRAINT korisnici_koordinator_ima_univerzitet CHECK ((uloga = 'koordinator') = (id_univerziteta IS NOT NULL))
);

CREATE TABLE studenti (
  id text PRIMARY KEY REFERENCES korisnici (id),
  ime text NOT NULL,
  prezime text NOT NULL,
  broj_indeksa text NOT NULL UNIQUE,
  email text NOT NULL,
  fakultet text NOT NULL,
  smer text NOT NULL,
  godina_studija int NOT NULL CHECK (godina_studija > 0),
  prosek numeric(4, 2) NOT NULL CHECK (prosek BETWEEN 6 AND 10)
);

CREATE TABLE znanje_jezika (
  id_studenta text NOT NULL REFERENCES studenti (id),
  jezik text NOT NULL CHECK (jezik IN ('engleski', 'nemacki', 'francuski', 'italijanski', 'spanski', 'portugalski', 'svedski')),
  nivo text NOT NULL CHECK (nivo IN ('a1', 'a2', 'b1', 'b2', 'c1', 'c2')),
  PRIMARY KEY (id_studenta, jezik)
);

CREATE TABLE ponude (
  id text PRIMARY KEY,
  id_univerziteta text NOT NULL REFERENCES univerziteti (id),
  oblast text NOT NULL,
  vrsta_semestra text NOT NULL CHECK (vrsta_semestra IN ('zimski', 'letnji')),
  akademska_godina text NOT NULL CHECK (akademska_godina ~ '^[0-9]{4}/[0-9]{2}$'),
  broj_mesta int NOT NULL CHECK (broj_mesta > 0),
  zauzeta_mesta int NOT NULL DEFAULT 0,
  rok timestamptz NOT NULL,
  minimalni_prosek numeric(4, 2) NOT NULL CHECK (minimalni_prosek BETWEEN 6 AND 10),
  jezik text NOT NULL CHECK (jezik IN ('engleski', 'nemacki', 'francuski', 'italijanski', 'spanski', 'portugalski', 'svedski')),
  nivo_jezika text NOT NULL CHECK (nivo_jezika IN ('a1', 'a2', 'b1', 'b2', 'c1', 'c2')),
  opis text NOT NULL,
  napomena text,
  objavio text NOT NULL REFERENCES korisnici (id),
  objavljena timestamptz NOT NULL,
  CONSTRAINT ponude_zauzeta_mesta CHECK (zauzeta_mesta BETWEEN 0 AND broj_mesta),
  CONSTRAINT ponude_semestar UNIQUE (id, vrsta_semestra, akademska_godina)
);

CREATE TABLE prijave (
  id text PRIMARY KEY DEFAULT gen_random_uuid()::text,
  id_studenta text NOT NULL REFERENCES studenti (id),
  id_ponude text NOT NULL,
  vrsta_semestra text NOT NULL,
  akademska_godina text NOT NULL,
  motivaciono_pismo text NOT NULL CHECK (btrim(motivaciono_pismo) <> ''),
  napomena text,
  napravljena timestamptz NOT NULL,
  stanje text NOT NULL CHECK (
    stanje IN ('u_pripremi', 'poslata', 'na_listi_cekanja', 'prihvacena', 'odbijena', 'potvrdjena', 'povucena')
  ),
  stanje_kada timestamptz,
  odlucio text REFERENCES korisnici (id),
  razlog text,
  CONSTRAINT prijave_semestar_ponude FOREIGN KEY (id_ponude, vrsta_semestra, akademska_godina)
    REFERENCES ponude (id, vrsta_semestra, akademska_godina),
  CONSTRAINT prijave_podaci_stanja CHECK (
    CASE stanje
      WHEN 'u_pripremi' THEN stanje_kada IS NULL AND odlucio IS NULL AND razlog IS NULL
      WHEN 'poslata' THEN stanje_kada IS NOT NULL AND odlucio IS NULL AND razlog IS NULL
      WHEN 'potvrdjena' THEN stanje_kada IS NOT NULL AND odlucio IS NULL AND razlog IS NULL
      WHEN 'povucena' THEN stanje_kada IS NOT NULL AND odlucio IS NULL AND razlog IS NULL
      WHEN 'na_listi_cekanja' THEN stanje_kada IS NOT NULL AND odlucio IS NOT NULL AND razlog IS NULL
      WHEN 'prihvacena' THEN stanje_kada IS NOT NULL AND odlucio IS NOT NULL AND razlog IS NULL
      WHEN 'odbijena' THEN stanje_kada IS NOT NULL AND odlucio IS NOT NULL AND razlog IS NOT NULL
    END
  )
);

CREATE UNIQUE INDEX prijave_jedno_potvrdjeno_po_semestru
  ON prijave (id_studenta, vrsta_semestra, akademska_godina)
  WHERE stanje = 'potvrdjena';

CREATE INDEX prijave_po_studentu ON prijave (id_studenta);
CREATE INDEX prijave_po_ponudi ON prijave (id_ponude);

CREATE TABLE sacuvane_ponude (
  id_studenta text NOT NULL REFERENCES studenti (id),
  id_ponude text NOT NULL REFERENCES ponude (id),
  PRIMARY KEY (id_studenta, id_ponude)
);

-- migrate:down
DROP TABLE sacuvane_ponude;
DROP TABLE prijave;
DROP TABLE ponude;
DROP TABLE znanje_jezika;
DROP TABLE studenti;
DROP TABLE korisnici;
DROP TABLE univerziteti;