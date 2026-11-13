import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

import 'preslikavanje_ponuda.dart';

extension StudentUDto on Student {
  StudentDto toDto() => StudentDto(
    id: id.vrednost,
    ime: ime,
    prezime: prezime,
    brojIndeksa: brojIndeksa,
    email: email,
    fakultet: fakultet,
    smer: smer,
    godinaStudija: godinaStudija,
    prosekStotih: prosekUStote(prosek),
    znanjeJezika: {for (final MapEntry(:key, :value) in znanjeJezika.entries) key.toDto(): value.toDto()},
  );
}

extension StudentDtoUDomen on StudentDto {
  Rezultat<Student> toDomain() {
    final prosek = Prosek.proveriBroj(prosekIzStotih(prosekStotih));
    if (prosek case Neuspeh(:final greska)) return Neuspeh(greska);
    return Uspeh(
      Student(
        id: IdKorisnika(id),
        ime: ime,
        prezime: prezime,
        brojIndeksa: brojIndeksa,
        email: email,
        fakultet: fakultet,
        smer: smer,
        godinaStudija: godinaStudija,
        prosek: prosek.vrednostIliNull!,
        znanjeJezika: {for (final MapEntry(:key, :value) in znanjeJezika.entries) jezikIzDto(key): nivoIzDto(value)},
      ),
    );
  }
}
