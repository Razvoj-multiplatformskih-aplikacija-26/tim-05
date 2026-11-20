part of 'sesija_bloc.dart';

sealed class SesijaDogadjaj {
  const SesijaDogadjaj();
}

final class ObnovaSesijeZatrazena extends SesijaDogadjaj {
  const ObnovaSesijeZatrazena();
}

final class SesijaZapoceta extends SesijaDogadjaj {
  const SesijaZapoceta(this.korisnik);

  final Korisnik korisnik;
}

final class OdjavaZatrazena extends SesijaDogadjaj {
  const OdjavaZatrazena();
}

final class SesijaIstekla extends SesijaDogadjaj {
  const SesijaIstekla();
}
