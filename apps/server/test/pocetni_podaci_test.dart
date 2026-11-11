import 'package:domain/domain.dart';
import 'package:server/server.dart';
import 'package:test/test.dart';

void main() {
  final podaci = pocetniPodaci(DateTime(2026, 11, 11, 10));
  final ponude = {for (final p in podaci.ponude) p.id: p};
  final studenti = {for (final s in podaci.studenti) s.id: s};
  final korisnici = {for (final k in podaci.sviKorisnici) k.id: k};

  group('ono što specifikacija traži od početnih podataka', () {
    test('bar deset prijava (glavni pojam)', () {
      expect(podaci.prijave.length, greaterThanOrEqualTo(10));
    });

    test('bar jedna prijava u svakom od sedam stanja', () {
      final vrste = {for (final p in podaci.prijave) p.stanje.runtimeType};
      expect(vrste, {UPripremi, Poslata, NaListiCekanja, Prihvacena, Odbijena, Potvrdjena, Povucena});
    });

    test('nalog za svaku ulogu i bar dva naloga mobilne uloge (student)', () {
      final nalozi = [for (final id in podaci.nalozi) korisnici[id]!];
      expect(nalozi.where((k) => k.uloga == Uloga.koordinator), isNotEmpty);
      expect(nalozi.where((k) => k.uloga == Uloga.student).length, greaterThanOrEqualTo(2));
    });

    test('demo nalozi su student1, student2, koordinator1 i koordinator2', () {
      final imena = {for (final id in podaci.nalozi) korisnici[id]!.korisnickoIme};
      expect(imena, {'student1', 'student2', 'koordinator1', 'koordinator2'});
    });
  });

  group('podaci poštuju pravila domena iz KT1', () {
    test('svaka prijava pokazuje na postojećeg studenta i postojeću ponudu', () {
      for (final p in podaci.prijave) {
        expect(studenti, contains(p.idStudenta), reason: '${p.id}');
        expect(ponude, contains(p.idPonude), reason: '${p.id}');
      }
    });

    test('nijedan student nema više od $najviseAktivnihPrijava aktivne prijave', () {
      for (final s in podaci.studenti) {
        expect(aktivnePrijave(s.id, podaci.prijave).length, lessThanOrEqualTo(najviseAktivnihPrijava), reason: s.ime);
      }
    });

    test('broj prihvaćenih i potvrđenih ne prelazi broj mesta', () {
      for (final ponuda in podaci.ponude) {
        expect(zauzetaMesta(ponuda, podaci.prijave), lessThanOrEqualTo(ponuda.brojMesta), reason: '${ponuda.id}');
      }
    });

    test('najviše jedna nezavršena prijava istog studenta na istu ponudu', () {
      final parovi = [
        for (final p in podaci.prijave)
          if (!p.stanje.jeKonacno) (p.idStudenta, p.idPonude),
      ];
      expect(parovi.toSet().length, parovi.length);
    });

    test('najviše jedno potvrđeno mesto po studentu i semestru, bez drugih aktivnih prijava za taj semestar', () {
      for (final potvrdjena in podaci.prijave.where((p) => p.stanje is Potvrdjena)) {
        final semestar = ponude[potvrdjena.idPonude]!.semestar;
        final istiSemestar = podaci.prijave.where(
          (p) =>
              p.idStudenta == potvrdjena.idStudenta &&
              p.id != potvrdjena.id &&
              ponude[p.idPonude]!.semestar == semestar,
        );
        expect(istiSemestar.where((p) => p.stanje is Potvrdjena || p.jeAktivna), isEmpty, reason: '${potvrdjena.id}');
      }
    });

    test('poslate prijave ispunjavaju prosek i jezik ponude', () {
      for (final p in podaci.prijave) {
        if (p.stanje is UPripremi || p.stanje is Povucena) continue;
        final student = studenti[p.idStudenta]!;
        final ponuda = ponude[p.idPonude]!;
        expect(imaProsek(student, ponuda), isTrue, reason: '${p.id}');
        expect(imaJezik(student, ponuda), isTrue, reason: '${p.id}');
      }
    });

    test('o prijavi je odlučio koordinator univerziteta te ponude', () {
      for (final p in podaci.prijave) {
        final odlucio = switch (p.stanje) {
          NaListiCekanja(:final odlucio) || Prihvacena(:final odlucio) || Odbijena(:final odlucio) => odlucio,
          _ => null,
        };
        if (odlucio == null) continue;
        expect(PravaPristupa.mozeDaOdlucuje(korisnici[odlucio]!, ponude[p.idPonude]!), isTrue, reason: '${p.id}');
      }
    });

    test('ponudu je objavio koordinator njenog univerziteta', () {
      for (final ponuda in podaci.ponude) {
        expect(PravaPristupa.mozeDaOdlucuje(korisnici[ponuda.objavio]!, ponuda), isTrue, reason: '${ponuda.id}');
      }
    });
  });
}