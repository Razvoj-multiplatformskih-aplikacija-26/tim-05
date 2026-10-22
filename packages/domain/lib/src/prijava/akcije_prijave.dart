import '../greske.dart';
import '../korisnik.dart';
import '../ponuda/ponuda.dart';
import '../pravila/mesta.dart';
import '../pravila/uslovi_ponude.dart';
import '../rezultat.dart';
import '../student.dart';
import 'motivaciono_pismo.dart';
import 'prava_pristupa.dart';
import 'prijava.dart';
import 'stanje_prijave.dart';



Rezultat<Prijava> _prelaz(Prijava prijava, StanjePrijave novo) {

  if (!dozvoljenPrelaz(prijava.stanje, novo)) {
    return Neuspeh(NedozvoljenPrelaz(iz: prijava.stanje, u: novo));
  }

  return Uspeh(prijava.copyWith(stanje: novo));
}


Rezultat<Prijava> posaljiPrijavu(
  Prijava prijava, {
  required Korisnik ko,
  required Student student,
  required Ponuda ponuda,
  required List<Prijava> svePrijave,
  required DateTime sada,
}) {

  if (!PravaPristupa.jeVlasnik(ko, prijava)) return const Neuspeh(NemaPravo());

  final novo = Poslata(kada: sada);

  if (!dozvoljenPrelaz(prijava.stanje, novo)) {
    return Neuspeh(NedozvoljenPrelaz(iz: prijava.stanje, u: novo));
  }

  final uslovi = proveriUslove(student: student, ponuda: ponuda, svePrijave: svePrijave, sada: sada);

  if (uslovi case Neuspeh(:final greska)) return Neuspeh(greska);

  return Uspeh(prijava.copyWith(stanje: novo));
}

Rezultat<Prijava> izmeniPrijavu(
  Prijava prijava, {
  required Korisnik ko,
  required MotivacionoPismo motivacionoPismo,
  String? napomena,
}) {

  if (!PravaPristupa.jeVlasnik(ko, prijava)) return const Neuspeh(NemaPravo());

  final smeDaMenja = switch (prijava.stanje) {
    UPripremi() || Poslata() => true,
    NaListiCekanja() || Prihvacena() || Odbijena() || Potvrdjena() || Povucena() => false,
  };

  if (!smeDaMenja) return const Neuspeh(IzmenaNijeMoguca());

  return Uspeh(prijava.copyWith(motivacionoPismo: motivacionoPismo, napomena: napomena));
}


Rezultat<Prijava> povuciPrijavu(Prijava prijava, {required Korisnik ko, required DateTime sada}) {

  if (!PravaPristupa.jeVlasnik(ko, prijava)) return const Neuspeh(NemaPravo());

  return _prelaz(prijava, Povucena(kada: sada));
}


Rezultat<Prijava> odbijMesto(Prijava prijava, {required Korisnik ko, required DateTime sada}) {

  if (!PravaPristupa.jeVlasnik(ko, prijava)) return const Neuspeh(NemaPravo());

  if (prijava.stanje is! Prihvacena) {
    return Neuspeh(NedozvoljenPrelaz(iz: prijava.stanje, u: Povucena(kada: sada)));
  }

  return _prelaz(prijava, Povucena(kada: sada));
}



Rezultat<List<Prijava>> potvrdiMesto(
  Prijava prijava, {
  required Korisnik ko,
  required List<Prijava> svePrijave,
  required DateTime sada,
}) {

  if (!PravaPristupa.jeVlasnik(ko, prijava)) return const Neuspeh(NemaPravo());

  final potvrdjena = _prelaz(prijava, Potvrdjena(kada: sada));

  if (potvrdjena case Neuspeh(:final greska)) return Neuspeh(greska);

  final povuceno = Povucena(kada: sada);

  final ostale = [
    for (final druga in svePrijave)
      if (druga.idStudenta == prijava.idStudenta && druga.id != prijava.id && dozvoljenPrelaz(druga.stanje, povuceno))
        druga.copyWith(stanje: povuceno),
  ];

  return Uspeh([potvrdjena.vrednostIliNull!, ...ostale]);
}



Rezultat<Prijava> prihvatiPrijavu(
  Prijava prijava, {
  required Korisnik ko,
  required Ponuda ponuda,
  required List<Prijava> svePrijave,
  required DateTime sada,
}) {

  if (!PravaPristupa.mozeDaOdlucuje(ko, ponuda) || prijava.idPonude != ponuda.id) {
    return const Neuspeh(NemaPravo());
  }
  
  final novo = Prihvacena(odlucio: ko.id, kada: sada);

  if (!dozvoljenPrelaz(prijava.stanje, novo)) {
    return Neuspeh(NedozvoljenPrelaz(iz: prijava.stanje, u: novo));
  }

  if (preostalaMesta(ponuda, svePrijave) == 0) return const Neuspeh(NemaSlobodnihMesta());

  return Uspeh(prijava.copyWith(stanje: novo));
}


Rezultat<Prijava> staviNaListuCekanja(
  Prijava prijava, {
  required Korisnik ko,
  required Ponuda ponuda,
  required DateTime sada,
}) {

  if (!PravaPristupa.mozeDaOdlucuje(ko, ponuda) || prijava.idPonude != ponuda.id) {
    return const Neuspeh(NemaPravo());
  }

  return _prelaz(prijava, NaListiCekanja(odlucio: ko.id, kada: sada));
}


Rezultat<Prijava> odbijPrijavu(
  Prijava prijava, {
  required Korisnik ko,
  required Ponuda ponuda,
  required String razlog,
  required DateTime sada,
}) {
  
  if (!PravaPristupa.mozeDaOdlucuje(ko, ponuda) || prijava.idPonude != ponuda.id) {
    return const Neuspeh(NemaPravo());
  }
  
  return _prelaz(prijava, Odbijena(odlucio: ko.id, kada: sada, razlog: razlog));
}
