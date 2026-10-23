import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

abstract final class Boje {
  static const bordo = Color(0xFF7E0D0E);

  static const bordoSvetla = Color(0xFFF5E1DF);
  static const naBordoSvetloj = Color(0xFF5A0A0B);

  static const zuta = Color(0xFFF4CE14);
  static const naZutoj = Color(0xFF3D3200);

  static const pozadina = Color(0xFFFAF7F3);
  static const kartica = Color(0xFFFFFFFF);
  static const ivica = Color(0xFFE8E0D7);
  static const tekst = Color(0xFF211A17);
  static const sporedniTekst = Color(0xFF6E645D);

  static const uspeh = Color(0xFF235E32);
  static const uspehPozadina = Color(0xFFDCEFDF);

  static const greska = Color(0xFFB3261E);
  static const greskaPozadina = Color(0xFFF9DEDC);

  static const bela = Color(0xFFFFFFFF);
  static const belaProvidna = Color(0xB3FFFFFF);

  static const senka = Color(0x42000000);

  static const napomenaPozadina = Color(0xFFFFF8DA);
  static const napomenaIvica = Color(0xFFF1E2A0);

  static const siviBlok = Color(0xFFF3EEE8);
  static const siviBlokLinija = Color(0xFFE6DED5);
  static const prekidac = Color(0xFFEFE8E1);

  static const uspehNaslov = Color(0xFF1C4A27);
  static const uspehTekst = Color(0xFF2E5A38);
  static const uspehIvica = Color(0xFFBFE0C6);

  static const opasnost = Color(0xFF9B1B1C);
  static const opasnostIvica = Color(0xFFE6C9C9);
}

typedef BojeOznake = ({Color pozadina, Color tekst});

BojeOznake bojeStanja(StanjePrijave stanje) => switch (stanje) {
  UPripremi() => const (pozadina: Color(0xFFEFEAE4), tekst: Color(0xFF5A514B)),
  Poslata() => const (pozadina: Color(0xFFE4E9F2), tekst: Color(0xFF33445E)),
  NaListiCekanja() => const (pozadina: Color(0xFFFCF1C4), tekst: Color(0xFF5C4A00)),
  Prihvacena() => const (pozadina: Boje.uspehPozadina, tekst: Boje.uspeh),
  Odbijena() => const (pozadina: Color(0xFFF6DADA), tekst: Boje.bordo),
  Potvrdjena() => const (pozadina: Boje.uspeh, tekst: Boje.bela),
  Povucena() => const (pozadina: Color(0xFFEDEDED), tekst: Color(0xFF6B6B6B)),
};
