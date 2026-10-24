import 'package:meta/meta.dart';

import '../identifikatori.dart';

sealed class StanjePrijave {
  const StanjePrijave();

  bool get jeAktivna => switch (this) {
    Poslata() || NaListiCekanja() || Prihvacena() => true,
    UPripremi() || Odbijena() || Potvrdjena() || Povucena() => false,
  };

  bool get mozeSeMenjati => switch (this) {
    UPripremi() || Poslata() => true,
    NaListiCekanja() || Prihvacena() || Odbijena() || Potvrdjena() || Povucena() => false,
  };

  bool get jeKonacno => switch (this) {
    Odbijena() || Potvrdjena() || Povucena() => true,
    UPripremi() || Poslata() || NaListiCekanja() || Prihvacena() => false,
  };
}

final class UPripremi extends StanjePrijave {
  const UPripremi();

  @override
  String toString() => 'UPripremi';
}

@immutable
final class Poslata extends StanjePrijave {
  const Poslata({required this.kada});

  final DateTime kada;

  @override
  bool operator ==(Object other) => other is Poslata && other.kada == kada;

  @override
  int get hashCode => Object.hash(Poslata, kada);

  @override
  String toString() => 'Poslata($kada)';
}

@immutable
final class NaListiCekanja extends StanjePrijave {
  const NaListiCekanja({required this.odlucio, required this.kada});

  final IdKorisnika odlucio;
  final DateTime kada;

  @override
  bool operator ==(Object other) => other is NaListiCekanja && other.odlucio == odlucio && other.kada == kada;

  @override
  int get hashCode => Object.hash(NaListiCekanja, odlucio, kada);

  @override
  String toString() => 'NaListiCekanja($odlucio, $kada)';
}

@immutable
final class Prihvacena extends StanjePrijave {
  const Prihvacena({required this.odlucio, required this.kada});

  final IdKorisnika odlucio;
  final DateTime kada;

  @override
  bool operator ==(Object other) => other is Prihvacena && other.odlucio == odlucio && other.kada == kada;

  @override
  int get hashCode => Object.hash(Prihvacena, odlucio, kada);

  @override
  String toString() => 'Prihvacena($odlucio, $kada)';
}

@immutable
final class Odbijena extends StanjePrijave {
  const Odbijena({required this.odlucio, required this.kada, required this.razlog});

  final IdKorisnika odlucio;
  final DateTime kada;
  final String razlog;

  @override
  bool operator ==(Object other) =>
      other is Odbijena && other.odlucio == odlucio && other.kada == kada && other.razlog == razlog;

  @override
  int get hashCode => Object.hash(Odbijena, odlucio, kada, razlog);

  @override
  String toString() => 'Odbijena($odlucio, $kada, "$razlog")';
}

@immutable
final class Potvrdjena extends StanjePrijave {
  const Potvrdjena({required this.kada});

  final DateTime kada;

  @override
  bool operator ==(Object other) => other is Potvrdjena && other.kada == kada;

  @override
  int get hashCode => Object.hash(Potvrdjena, kada);

  @override
  String toString() => 'Potvrdjena($kada)';
}

@immutable
final class Povucena extends StanjePrijave {
  const Povucena({required this.kada});

  final DateTime kada;

  @override
  bool operator ==(Object other) => other is Povucena && other.kada == kada;

  @override
  int get hashCode => Object.hash(Povucena, kada);

  @override
  String toString() => 'Povucena($kada)';
}

bool dozvoljenPrelaz(StanjePrijave iz, StanjePrijave u) => switch ((iz, u)) {
  (UPripremi(), Poslata()) => true,
  (UPripremi(), Povucena()) => true,
  (Poslata(), NaListiCekanja()) => true,
  (Poslata(), Prihvacena()) => true,
  (Poslata(), Odbijena()) => true,
  (Poslata(), Povucena()) => true,
  (NaListiCekanja(), Prihvacena()) => true,
  (NaListiCekanja(), Odbijena()) => true,
  (NaListiCekanja(), Povucena()) => true,
  (Prihvacena(), Potvrdjena()) => true,
  (Prihvacena(), Povucena()) => true,
  _ => false,
};
