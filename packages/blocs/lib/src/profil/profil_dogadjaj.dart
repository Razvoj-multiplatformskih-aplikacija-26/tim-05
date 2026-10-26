part of 'profil_bloc.dart';

sealed class ProfilDogadjaj {
  const ProfilDogadjaj();
}

final class ProfilZatrazen extends ProfilDogadjaj {
  const ProfilZatrazen();
}

final class ProfilOsvezen extends ProfilDogadjaj {
  const ProfilOsvezen();
}

final class PovlacenjeZatrazeno extends ProfilDogadjaj {
  const PovlacenjeZatrazeno(this.id);

  final IdPrijave id;
}

final class PotvrdaMestaZatrazena extends ProfilDogadjaj {
  const PotvrdaMestaZatrazena(this.id);

  final IdPrijave id;
}

final class OdbijanjeMestaZatrazeno extends ProfilDogadjaj {
  const OdbijanjeMestaZatrazeno(this.id);

  final IdPrijave id;
}

final class BrisanjeZatrazeno extends ProfilDogadjaj {
  const BrisanjeZatrazeno(this.id);

  final IdPrijave id;
}

final class ProfilIzmenjen extends ProfilDogadjaj {
  const ProfilIzmenjen(this.student);

  final Student student;
}

final class PrikazProfilaPromenjen extends ProfilDogadjaj {
  const PrikazProfilaPromenjen(this.prikaz);

  final PrikazProfila prikaz;
}

final class ObavestenjeProfilaProcitano extends ProfilDogadjaj {
  const ObavestenjeProfilaProcitano();
}
