part of 'ponude_bloc.dart';

sealed class PonudeDogadjaj {
  const PonudeDogadjaj();
}

final class PonudeZatrazene extends PonudeDogadjaj {
  const PonudeZatrazene();
}

final class PonudeOsvezene extends PonudeDogadjaj {
  const PonudeOsvezene();
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
