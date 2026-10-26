part of 'formular_prijave_bloc.dart';

sealed class FormularPrijaveDogadjaj {
  const FormularPrijaveDogadjaj();
}

final class CuvanjeZatrazeno extends FormularPrijaveDogadjaj {
  const CuvanjeZatrazeno({required this.pismo, this.napomena});

  final MotivacionoPismo pismo;
  final String? napomena;
}

final class SlanjeZatrazeno extends FormularPrijaveDogadjaj {
  const SlanjeZatrazeno({required this.pismo, this.napomena});

  final MotivacionoPismo pismo;
  final String? napomena;
}
