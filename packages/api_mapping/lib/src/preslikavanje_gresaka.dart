import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

import 'preslikavanje_ponuda.dart';
import 'preslikavanje_prijava.dart';


extension GreskaDomenaUProblem on GreskaDomena {
  ProblemDto toProblem() => switch (this) {
    PismoPrazno() => const ProblemDto(status: 422, code: KodoviGresaka.pismoPrazno, title: 'Letter is empty'),
    PismoPredugacko(:final duzina) => ProblemDto(
      status: 422,
      code: KodoviGresaka.pismoPredugacko,
      title: 'Letter too long',
      value: duzina,
      max: MotivacionoPismo.najvise,
    ),
    RokIstekao(:final rok) => ProblemDto(
      status: 422,
      code: KodoviGresaka.rokIstekao,
      title: 'Deadline passed',
      rok: rok,
    ),
    NedovoljanProsek(:final trazeni, :final studentov) => ProblemDto(
      status: 422,
      code: KodoviGresaka.nedovoljanProsek,
      title: 'Average too low',
      min: prosekUStote(trazeni),
      value: prosekUStote(studentov),
    ),
    NedovoljanJezik(:final trazeni, :final studentov) => ProblemDto(
      status: 422,
      code: KodoviGresaka.nedovoljanJezik,
      title: 'Language level too low',
      jezik: trazeni.jezik.toDto(),
      nivo: trazeni.nivo.toDto(),
      nivoKorisnika: studentov?.toDto(),
    ),
    PrevisePrijava(:final najvise) => ProblemDto(
      status: 422,
      code: KodoviGresaka.previsePrijava,
      title: 'Too many active applications',
      max: najvise,
    ),
    NemaSlobodnihMesta() => const ProblemDto(
      status: 409,
      code: KodoviGresaka.nemaSlobodnihMesta,
      title: 'No free places',
    ),
    NemaPravo() => const ProblemDto(status: 403, code: KodoviGresaka.nemaPravo, title: 'Not allowed'),
    NijePronadjeno() => const ProblemDto(status: 404, code: KodoviGresaka.nijePronadjeno, title: 'Not found'),
    NedozvoljenPrelaz(:final iz, :final u) => ProblemDto(
      status: 409,
      code: KodoviGresaka.nedozvoljenPrelaz,
      title: 'Invalid transition',
      iz: iz.toDto(),
      u: u.toDto(),
    ),
    IzmenaNijeMoguca() => const ProblemDto(
      status: 409,
      code: KodoviGresaka.izmenaNijeMoguca,
      title: 'Application can no longer be changed',
    ),
    VecPotvrdjenoMesto() => const ProblemDto(
      status: 409,
      code: KodoviGresaka.vecPotvrdjenoMesto,
      title: 'A place is already confirmed for this semester',
    ),
    BrisanjeNijeMoguce() => const ProblemDto(
      status: 409,
      code: KodoviGresaka.brisanjeNijeMoguce,
      title: 'Application cannot be deleted',
    ),
    ProsekNijeBroj() => const ProblemDto(
      status: 422,
      code: KodoviGresaka.prosekNijeBroj,
      title: 'Average is not a number',
    ),
    ProsekVanOpsega() => ProblemDto(
      status: 422,
      code: KodoviGresaka.prosekVanOpsega,
      title: 'Average out of range',
      min: prosekUStote(Prosek.najmanje),
      max: prosekUStote(Prosek.najvise),
    ),
    VecPostojiPrijava() => const ProblemDto(
      status: 409,
      code: KodoviGresaka.vecPostojiPrijava,
      title: 'Application already exists',
    ),
  };
}

extension ProblemUGreskuDomena on ProblemDto {

  GreskaDomena? toDomainError() {
    try {
      return switch (this) {
        ProblemDto(code: KodoviGresaka.pismoPrazno) => const PismoPrazno(),
        ProblemDto(code: KodoviGresaka.pismoPredugacko, :final value?) => PismoPredugacko(value),
        ProblemDto(code: KodoviGresaka.rokIstekao, :final rok?) => RokIstekao(rok.toLocal()),
        ProblemDto(code: KodoviGresaka.nedovoljanProsek, :final min?, :final value?) => NedovoljanProsek(
          trazeni: prosekIzStotih(min),
          studentov: prosekIzStotih(value),
        ),
        ProblemDto(code: KodoviGresaka.nedovoljanJezik, :final jezik?, :final nivo?, :final nivoKorisnika) =>
          NedovoljanJezik(
            trazeni: ZahtevJezika(jezik: jezikIzDto(jezik), nivo: nivoIzDto(nivo)),
            studentov: nivoKorisnika == null ? null : nivoIzDto(nivoKorisnika),
          ),
        ProblemDto(code: KodoviGresaka.previsePrijava, :final max?) => PrevisePrijava(max),
        ProblemDto(code: KodoviGresaka.nemaSlobodnihMesta) => const NemaSlobodnihMesta(),
        ProblemDto(code: KodoviGresaka.nemaPravo) => const NemaPravo(),
        ProblemDto(code: KodoviGresaka.nijePronadjeno) => const NijePronadjeno(),
        ProblemDto(code: KodoviGresaka.nedozvoljenPrelaz, :final iz?, :final u?) => NedozvoljenPrelaz(
          iz: iz.toDomain(),
          u: u.toDomain(),
        ),
        ProblemDto(code: KodoviGresaka.izmenaNijeMoguca) => const IzmenaNijeMoguca(),
        ProblemDto(code: KodoviGresaka.vecPotvrdjenoMesto) => const VecPotvrdjenoMesto(),
        ProblemDto(code: KodoviGresaka.brisanjeNijeMoguce) => const BrisanjeNijeMoguce(),
        ProblemDto(code: KodoviGresaka.prosekNijeBroj) => const ProsekNijeBroj(),
        ProblemDto(code: KodoviGresaka.prosekVanOpsega) => const ProsekVanOpsega(),
        ProblemDto(code: KodoviGresaka.vecPostojiPrijava) => const VecPostojiPrijava(),
        _ => null,
      };
    } on FormatException {
      return null;
    }
  }
}
