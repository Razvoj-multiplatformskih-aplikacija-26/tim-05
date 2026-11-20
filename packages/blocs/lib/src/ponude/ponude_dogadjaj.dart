part of 'ponude_bloc.dart';

sealed class PonudeDogadjaj {
  const PonudeDogadjaj();
}

final class PonudeZatrazene extends PonudeDogadjaj {
  const PonudeZatrazene();
}

final class PonudeKorisnikPromenjen extends PonudeDogadjaj {
  const PonudeKorisnikPromenjen(this.korisnik);

  final Korisnik? korisnik;
}

final class PonudeOsvezene extends PonudeDogadjaj {
  const PonudeOsvezene({this.gotovo});

  final Completer<void>? gotovo;
}

final class FilteriPromenjeni extends PonudeDogadjaj {
  const FilteriPromenjeni(this.filteri);

  final PonudeFilteri filteri;
}

final class SacuvanaPromenjena extends PonudeDogadjaj {
  const SacuvanaPromenjena(this.idPonude);

  final IdPonude idPonude;
}

final class ObavestenjePonudaProcitano extends PonudeDogadjaj {
  const ObavestenjePonudaProcitano();
}
