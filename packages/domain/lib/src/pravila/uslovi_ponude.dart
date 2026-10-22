import '../greske.dart';
import '../ponuda/ponuda.dart';
import '../prijava/prijava.dart';
import '../rezultat.dart';
import '../student.dart';
import 'mesta.dart';



const najviseAktivnihPrijava = 3;



bool rokNijeIstekao(Ponuda ponuda, DateTime sada) => !sada.isAfter(ponuda.rok);

bool imaProsek(Student student, Ponuda ponuda) => student.prosek >= ponuda.minimalniProsek;


bool imaJezik(Student student, Ponuda ponuda) {

  final nivo = student.nivoZa(ponuda.zahtevJezika.jezik);
  return nivo != null && nivo.jeNajmanje(ponuda.zahtevJezika.nivo);
}


bool imaMestaZaNovuPrijavu(Student student, List<Prijava> svePrijave) =>
    aktivnePrijave(student.id, svePrijave).length < najviseAktivnihPrijava;



Rezultat<Ponuda> proveriUslove({
  required Student student,
  required Ponuda ponuda,
  required List<Prijava> svePrijave,
  required DateTime sada,
}) {

  
  if (!rokNijeIstekao(ponuda, sada)) {
    return Neuspeh(RokIstekao(ponuda.rok));
  }

  if (!imaProsek(student, ponuda)) {
    return Neuspeh(NedovoljanProsek(trazeni: ponuda.minimalniProsek, studentov: student.prosek));
  }

  if (!imaJezik(student, ponuda)) {
    return Neuspeh(NedovoljanJezik(trazeni: ponuda.zahtevJezika, studentov: student.nivoZa(ponuda.zahtevJezika.jezik)));
  }

  if (!imaMestaZaNovuPrijavu(student, svePrijave)) {
    return const Neuspeh(PrevisePrijava(najviseAktivnihPrijava));
  }

  return Uspeh(ponuda);
}
