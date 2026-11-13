abstract final class KodoviGresaka {
  // Opste
  static const losZahtev = 'bad-request';
  static const nepodrzanTipSadrzaja = 'unsupported-media-type';
  static const prevelikZahtev = 'payload-too-large';
  static const greskaServera = 'server-error';
  static const nijePronadjeno = 'not-found';
  static const pogresniPodaciZaPrijavu = 'invalid-credentials';
  static const sesijaIstekla = 'session-expired';
  static const potrebnaPrijava = 'sign-in-required';

  // Greske domena
  static const pismoPrazno = 'letter-empty';
  static const pismoPredugacko = 'letter-too-long';
  static const rokIstekao = 'deadline-passed';
  static const nedovoljanProsek = 'average-too-low';
  static const nedovoljanJezik = 'language-level-too-low';
  static const previsePrijava = 'too-many-applications';
  static const nemaSlobodnihMesta = 'no-free-places';
  static const nemaPravo = 'not-allowed';
  static const nedozvoljenPrelaz = 'invalid-transition';
  static const izmenaNijeMoguca = 'change-not-possible';
  static const vecPotvrdjenoMesto = 'place-already-confirmed';
  static const brisanjeNijeMoguce = 'delete-not-possible';
  static const prosekNijeBroj = 'average-not-a-number';
  static const prosekVanOpsega = 'average-out-of-range';
  static const vecPostojiPrijava = 'application-already-exists';
}
