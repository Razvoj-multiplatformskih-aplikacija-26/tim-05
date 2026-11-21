# Prijave za Erasmus razmenu

Sistem za prijave na Erasmus razmenu. Studenti preko mobilne aplikacije pregledaju ponude partnerskih univerziteta i prijavljuju se na njih, a koordinatori iz backoffice aplikacije objavljuju ponude i obrađuju prijave. Ponude sa uslovima i rokovima javno su dostupne na vebu.

Sistem pokriva samo prijavu na razmenu, a ne ceo Erasmus proces.

## Tim

| Ime i prezime | Broj indeksa | Grupa | GitHub nalog |
| --- | --- | --- | --- |
| Ivona Stevanović | SI 84/24 | 413 | [IvonaStevanovic](https://github.com/IvonaStevanovic) |
| Vojislav Mitrović | SI 87/24 | 413 | [vojafull](https://github.com/vojafull) |

## Zahtevi za temu

1. **Uloge.** Sistem koriste studenti i koordinatori partnerskih univerziteta. Student upravlja samo svojim prijavama, a koordinator objavljuje ponude svog univerziteta i odlučuje samo o prijavama na njih.
2. **Stanja.** Prijava je prvo u pripremi, dok student popunjava formular, a zatim je poslata. Koordinator je prihvata, odbija ili stavlja na listu čekanja, a student prihvaćeno mesto potvrđuje ili prijavu povlači. Student može da obriše povučenu ili odbijenu prijavu.
3. **Pravila.** Prijava se šalje pre roka, uz traženi prosek i nivo jezika, a student može imati najviše tri aktivne prijave i samo jednu nezavršenu prijavu na istu ponudu. Motivaciono pismo je obavezno i ima najviše 1500 znakova. Prosek je između 6,00 i 10,00. Broj prihvaćenih studenata ne sme preći broj mesta u ponudi, a student može potvrditi samo jedno mesto po semestru, pa se tada povlače njegove ostale prijave za isti semestar i za taj semestar više ne može da šalje nove prijave. To zavisi od prijava drugih studenata, pa konačno odlučuje server.
4. **Rad bez mreže.** Student i bez signala vidi svoje poslate prijave i njihova stanja, može da popunjava formular za prijavu i da povuče poslatu prijavu; izmene se šalju kada se veza vrati.
5. **Posao za osoblje.** Koordinator pregleda i upoređuje sve prijave na ponude svog univerziteta i prati popunjenost mesta, što je posao za veći ekran.
6. **Javni sadržaj.** Ponude partnerskih univerziteta, sa uslovima, brojem mesta i rokovima, može da pogleda svako zainteresovan, bez prijave i bez preuzimanja mobilne aplikacije. Ove stranice traže i studenti koji tek razmišljaju o razmeni, pa ima smisla da budu vidljive i u pretraživačima.

## Delovi sistema

| Deo | Korisnici | Tehnologija | Platforme |
| --- | --- | --- | --- |
| Mobilna aplikacija | studenti | Flutter | Android, iOS |
| Backoffice | koordinatori | Flutter | macOS, Windows, veb |
| Javni veb | svi posetioci | Jaspr | pregledač |
| Server | ostali delovi sistema | Relic, PostgreSQL | Linux, Windows |
| Domenski paket | svi delovi sistema | Dart | sve |

Svi delovi koriste isti domenski paket, u kome su model i pravila. Server čuva podatke i ponovo proverava svako pravilo.

## Pokretanje

Potrebni su Docker (Docker Desktop na macOS-u i Windows-u), Git i Flutter 3.47 (`flutter --version`). Za aplikacije još:

- mobilna: Android Studio sa emulatorom, ili Xcode sa iOS simulatorom (macOS);
- backoffice na Windows-u: Visual Studio sa „Desktop development with C++" i komponentom **„C++ ATL for latest v143 build tools"** (traži je `flutter_secure_storage`);
- backoffice na macOS-u: Xcode.

### Baza i server

Iz korena repozitorijuma, posle kloniranja:

```sh
cp .env.example .env      # Windows (PowerShell): copy .env.example .env
docker compose up -d
```

`.env` se ne menja: razvojne vrednosti iz `.env.example` su dovoljne. Jedna komanda podiže tri servisa:

| Servis | Šta radi | Adresa |
| --- | --- | --- |
| `db` | PostgreSQL 17 | `localhost:5435` |
| `migrate` | dbmate primeni šemu iz `apps/server/migrations`, pa izlazi | — |
| `server` | server u Dartu na Relic-u 1.2.0, slika iz `apps/server/Dockerfile` | http://localhost:8080 |

Kada je baza prazna, server pri pokretanju upisuje početne podatke (univerzitete, ponude, studente, prijave u svim stanjima i naloge). Lozinke su u bazi samo kao Argon2id heš.

Provera: `docker compose ps -a` (servis `migrate` je `Exited (0)`) i `curl localhost:8080/health` (odgovor `ok`; u PowerShell-u `curl.exe`).

| Komanda | Šta radi |
| --- | --- |
| `docker compose logs server` | ispis servera; `logs migrate` za migracije |
| `docker compose up -d --build server` | nova slika servera posle izmene u `apps/server` ili u paketima koje server koristi |
| `docker compose stop server` / `start server` | zaustavlja i ponovo pokreće server (provera „server ne radi") |
| `docker compose down` | gasi sistem, podaci ostaju |
| `docker compose down -v` | gasi sistem i briše bazu; sledeći `up -d` kreće od početnih podataka |

Lozinka baze, `DEMO_PASSWORD`, `JWT_SECRET`, trajanje prijave (`SESSION_TTL_MINUTES`) i portovi su u `.env`, koji nije u git-u.

### Aplikacije

Prvo iz korena `flutter pub get`, pa svaka aplikacija u svom terminalu.

Mobilna aplikacija (studenti):

```sh
cd apps/mobile
flutter run               # izabrati Android emulator ili iOS simulator
```

Server se nalazi bez izmene koda: Android emulator ga vidi na `10.0.2.2:8080`, iOS simulator na `localhost:8080`. Za fizički telefon: `flutter run --dart-define=SERVER_URL=http://<IP računara>:8080`.

Backoffice (koordinatori):

```sh
cd apps/backoffice
flutter run -d macos      # ili -d windows, ili -d chrome --web-port 8081
```

U pregledaču je port **8081** obavezan: server prihvata pozive iz pregledača samo sa adresa iz `CORS_ORIGINS` u `.env`.

### Demo nalozi

Lozinka za sve naloge je `DEMO_PASSWORD` iz `.env` (iz `.env.example`: `erasmus-demo`).

| Nalog | Uloga | Aplikacija | Napomena |
| --- | --- | --- | --- |
| `student1` | student | mobilna | Andrej Aleksić; prijave u svim stanjima |
| `student2` | student | mobilna | Marko Petrović |
| `koordinator1` | koordinator | backoffice | Politecnico di Milano |
| `koordinator2` | koordinator | backoffice | Università di Bologna |

Ponude su javne: mobilna aplikacija ih prikazuje i bez prijave. Koordinator u mobilnoj aplikaciji i student u backoffice-u dobijaju poruku da je to pogrešna aplikacija.

### Pozivi mimo aplikacije

Skripta šalje serveru pozive koje aplikacija ne bi poslala (prekršeno pravilo, akcija koordinatora sa studentskim tokenom, tuđ zapis, bez prijave, dva istovremena prihvatanja poslednjeg mesta) i proverava status i kôd greške:

```sh
docker compose down -v && docker compose up -d
bash tool/pozivi_mimo_aplikacije.sh       # Windows: u Git Bash-u
```

Skripta menja podatke; posle nje ponovo `docker compose down -v && docker compose up -d`.

### Testovi

| Folder | Komanda |
| --- | --- |
| `packages/domain`, `packages/use_cases`, `packages/blocs`, `packages/api_contract`, `packages/api_mapping`, `packages/api_client` | `dart test` |
| `packages/ui`, `apps/mobile`, `apps/backoffice` | `flutter test` |
| `apps/server` | `dart test` (baza mora da radi: `docker compose up -d db`; testovi koriste posebne baze) |
| `packages/api_client` | `dart test test_server -p vm`: isti use case-ovi nad pokrenutim serverom (posle `down -v` i `up -d`) |