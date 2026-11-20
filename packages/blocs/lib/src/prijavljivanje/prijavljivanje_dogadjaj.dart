part of 'prijavljivanje_bloc.dart';

sealed class PrijavljivanjeDogadjaj {
  const PrijavljivanjeDogadjaj();
}

final class PrijavljivanjeZatrazeno extends PrijavljivanjeDogadjaj {
  const PrijavljivanjeZatrazeno({required this.korisnickoIme, required this.lozinka});

  final String korisnickoIme;
  final String lozinka;
}
