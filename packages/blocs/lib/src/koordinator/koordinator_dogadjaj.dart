part of 'koordinator_bloc.dart';

sealed class KoordinatorDogadjaj {
  const KoordinatorDogadjaj();
}

final class PrijaveZatrazene extends KoordinatorDogadjaj {
  const PrijaveZatrazene();
}

final class PrijaveOsvezene extends KoordinatorDogadjaj {
  const PrijaveOsvezene();
}

final class FilteriPrijavaPromenjeni extends KoordinatorDogadjaj {
  const FilteriPrijavaPromenjeni(this.filteri);

  final FilteriPrijava filteri;
}

final class PrijavaIzabrana extends KoordinatorDogadjaj {
  const PrijavaIzabrana(this.id);

  final IdPrijave? id;
}

final class KursorPomeren extends KoordinatorDogadjaj {
  const KursorPomeren(this.pomak);

  final int pomak;
}

final class KursorPostavljen extends KoordinatorDogadjaj {
  const KursorPostavljen(this.indeks);

  final int indeks;
}

final class KursorAktiviran extends KoordinatorDogadjaj {
  const KursorAktiviran();
}

final class PrihvatanjeZatrazeno extends KoordinatorDogadjaj {
  const PrihvatanjeZatrazeno(this.id);

  final IdPrijave id;
}

final class ListaCekanjaZatrazena extends KoordinatorDogadjaj {
  const ListaCekanjaZatrazena(this.id);

  final IdPrijave id;
}

final class OdbijanjeZatrazeno extends KoordinatorDogadjaj {
  const OdbijanjeZatrazeno(this.id, {required this.razlog});

  final IdPrijave id;
  final String razlog;
}

final class ObavestenjeKoordinatoraProcitano extends KoordinatorDogadjaj {
  const ObavestenjeKoordinatoraProcitano();
}