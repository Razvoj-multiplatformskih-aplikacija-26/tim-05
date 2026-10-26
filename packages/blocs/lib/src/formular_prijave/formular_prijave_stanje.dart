part of 'formular_prijave_bloc.dart';

sealed class FormularPrijaveStanje extends Equatable {
  const FormularPrijaveStanje();

  @override
  List<Object?> get props => const [];

  @override
  String toString() => '$runtimeType';
}

final class FormularSpreman extends FormularPrijaveStanje {
  const FormularSpreman();
}

final class FormularUToku extends FormularPrijaveStanje {
  const FormularUToku({required this.posalji});

  final bool posalji;

  @override
  List<Object?> get props => [posalji];
}

final class FormularSacuvan extends FormularPrijaveStanje {
  const FormularSacuvan(this.prijava, {required this.poslata});

  final Prijava prijava;
  final bool poslata;

  @override
  List<Object?> get props => [prijava, poslata];
}

final class FormularOdbijen extends FormularPrijaveStanje {
  const FormularOdbijen(this.greska);

  final GreskaDomena greska;

  @override
  List<Object?> get props => [greska];

  @override
  String toString() => 'FormularOdbijen($greska)';
}

final class FormularNeuspeo extends FormularPrijaveStanje {
  const FormularNeuspeo(this.uzrok);

  final Object uzrok;

  @override
  List<Object?> get props => [uzrok];

  @override
  String toString() => 'FormularNeuspeo($uzrok)';
}
