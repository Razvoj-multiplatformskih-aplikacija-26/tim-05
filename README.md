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
2. **Stanja.** Prijava je prvo u pripremi, dok student popunjava formular, a zatim je poslata. Koordinator je prihvata, odbija ili stavlja na listu čekanja, a student prihvaćeno mesto potvrđuje ili prijavu povlači.
3. **Pravila.** Prijava se šalje pre roka, uz traženi prosek i nivo jezika, a student može imati najviše tri aktivne prijave. Broj prihvaćenih studenata ne sme preći broj mesta u ponudi, a student može potvrditi samo jedno mesto, pa se njegove ostale prijave tada povlače. To zavisi od prijava drugih studenata, pa konačno odlučuje server.
4. **Rad bez mreže.** Student i bez signala vidi svoje poslate prijave i njihova stanja, može da popunjava formular za prijavu i da povuče poslatu prijavu; izmene se šalju kada se veza vrati.
5. **Posao za osoblje.** Koordinator pregleda i upoređuje sve prijave na ponude svog univerziteta i prati popunjenost mesta, što je posao za veći ekran.
6. **Javni sadržaj.** Ponude partnerskih univerziteta, sa uslovima, brojem mesta i rokovima, može da pogleda svako zainteresovan, bez prijave i bez preuzimanja mobilne aplikacije. Ove stranice traže i studenti koji tek razmišljaju o razmeni, pa ima smisla da budu vidljive i u pretraživačima.

## Delovi sistema

| Deo | Korisnici | Tehnologija | Platforme |
| --- | --- | --- | --- |
| Mobilna aplikacija | studenti | Flutter | Android, iOS |
| Backoffice | koordinatori | Flutter | Windows, veb |
| Javni veb | svi posetioci | Jaspr | pregledač |
| Server | ostali delovi sistema | Relic, PostgreSQL | Linux, Windows |
| Domenski paket | svi delovi sistema | Dart | sve |

Svi delovi koriste isti domenski paket, u kome su model i pravila. Server čuva podatke i ponovo proverava svako pravilo.
