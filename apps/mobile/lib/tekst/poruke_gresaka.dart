import 'package:domain/domain.dart';

import 'format.dart';

extension PorukaGreske on GreskaDomena {
  String get poruka => switch (this) {
    PismoPrazno() => 'Motivaciono pismo je obavezno.',
    PismoPredugacko(:final duzina) =>
      'Motivaciono pismo može imati najviše ${MotivacionoPismo.najvise} znakova (sada ima $duzina).',
    RokIstekao(:final rok) => 'Rok za prijavu je istekao ${formatDatum(rok)}',
    NedovoljanProsek(:final trazeni, :final studentov) =>
      'Za ovu ponudu potreban je prosek najmanje ${formatProsek(trazeni)}, a vaš je ${formatProsek(studentov)}.',
    NedovoljanJezik(:final trazeni, :final studentov) =>
      studentov == null
          ? 'Ponuda traži ${opisZahtevaJezika(trazeni)}, a taj jezik nemate u profilu.'
          : 'Ponuda traži ${opisZahtevaJezika(trazeni)} ili više, a vi imate ${studentov.oznaka}.',
    PrevisePrijava(:final najvise) =>
      'Već imate $najvise aktivne prijave, što je najviše dozvoljeno. Povucite neku pre nove prijave.',
    NemaSlobodnihMesta() => 'Sva mesta u ovoj ponudi su popunjena.',
    NemaPravo() => 'Nemate pravo na ovu radnju.',
    NijePronadjeno() => 'Traženi podatak nije pronađen.',
    NedozvoljenPrelaz() => 'Ova promena nije moguća u trenutnom stanju prijave.',
    IzmenaNijeMoguca() => 'Prijava se više ne može menjati jer je koordinator već odlučio.',
    VecPotvrdjenoMesto() => 'Već imate potvrđeno mesto za ovaj semestar.',
  };
}
