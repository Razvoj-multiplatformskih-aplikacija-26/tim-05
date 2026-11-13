abstract final class ApiPutanje {
  static const zdravlje = '/health';
  static const sesije = '/api/v1/sessions';
  static const trenutnaSesija = '/api/v1/sessions/current';

  static const univerziteti = '/api/v1/universities';
  static const ponude = '/api/v1/offers';

  static const prijave = '/api/v1/applications';

  static String prijava(String id) => '$prijave/$id';

  static String izmena(String id) => '${prijava(id)}/revision';

  static String povlacenje(String id) => '${prijava(id)}/withdrawal';

  static String potvrdaMesta(String id) => '${prijava(id)}/confirmation';

  static String odbijanjeMesta(String id) => '${prijava(id)}/place-decline';

  static String prihvatanje(String id) => '${prijava(id)}/acceptance';

  static String listaCekanja(String id) => '${prijava(id)}/waitlist';

  static String odbijanje(String id) => '${prijava(id)}/rejection';

  static String prijaveStudenta(String idStudenta) => '/api/v1/students/$idStudenta/applications';

  static String prijaveUniverziteta(String idUniverziteta) => '$univerziteti/$idUniverziteta/applications';

  static String student(String id) => '/api/v1/students/$id';

  static String profil(String id) => '${student(id)}/profile';

  static String sacuvanePonude(String idStudenta) => '${student(idStudenta)}/saved-offers';

  static String promenaSacuvane(String idStudenta, String idPonude) => '${sacuvanePonude(idStudenta)}/$idPonude/toggle';
}

abstract final class ApiKolacici {
  static const sesija = 'erasmusgo_session';
}
