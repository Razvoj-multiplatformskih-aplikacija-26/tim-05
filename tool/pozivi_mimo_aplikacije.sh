#!/usr/bin/env bash
# Pozivi mimo aplikacije (spec. KT2, stavke 1 i 4): server odbija istim pravilom i istim kodom greške kao aplikacija.
# Pokretanje iz korena repozitorijuma, nad svežim početnim podacima:
#   docker compose down -v && docker compose up -d
#   bash tool/pozivi_mimo_aplikacije.sh
# Na Windows-u u Git Bash-u. Skripta menja podatke (prihvata prijave), pa se posle nje ponovo radi `down -v` i `up -d`.
set -u

SERVER="${SERVER_URL:-http://localhost:8080}"
LOZINKA="${DEMO_PASSWORD:-erasmus-demo}"
API="$SERVER/api/v1"
uspelo=0
palo=0

token() {
  curl -s -X POST "$API/sessions" -H 'Content-Type: application/json' \
    -d "{\"username\":\"$1\",\"password\":\"$LOZINKA\"}" | sed -E 's/.*"token":"([^"]+)".*/\1/'
}

# proveri <opis> <očekivani status> <očekivani kôd ili -> <curl argumenti...>
proveri() {
  local opis="$1" status="$2" kod="$3"
  shift 3
  local odgovor
  odgovor=$(curl -s -w '\n%{http_code}' "$@")
  local dobijen="${odgovor##*$'\n'}"
  local telo="${odgovor%$'\n'*}"
  if [[ "$dobijen" == "$status" && ( "$kod" == "-" || "$telo" == *"\"code\":\"$kod\""* ) ]]; then
    echo "OK    $status ${kod/#-/}  $opis"
    uspelo=$((uspelo + 1))
  else
    echo "PALO  očekivano $status $kod, dobijeno $dobijen  $opis"
    echo "      $telo"
    palo=$((palo + 1))
  fi
}

curl -sf "$SERVER/health" > /dev/null || { echo "Server ne radi na $SERVER (docker compose up -d)"; exit 1; }

S1=$(token student1)
S2=$(token student2)
K1=$(token koordinator1)
K2=$(token koordinator2)

echo "== Bez prijave: ponude su javne, ostalo traži prijavu"
proveri "ponude bez prijave" 200 - "$API/offers"
proveri "prijave studenta bez prijave" 401 sign-in-required "$API/students/s-1/applications"
proveri "lažan token" 401 session-expired "$API/students/s-1/applications" -H "Authorization: Bearer lazan.token.x"

echo "== Pravilo prekršeno mimo aplikacije: isti kôd kao kada pravilo proveri aplikacija (stavka 1)"
PISMO=$(printf 'a%.0s' $(seq 1 1501))
proveri "pismo od 1501 znaka" 422 letter-too-long -X POST "$API/applications" -H "Authorization: Bearer $S1" \
  -H 'Content-Type: application/json' -d "{\"offerId\":\"po-8\",\"letter\":\"$PISMO\",\"submit\":true}"
proveri "četvrta aktivna prijava" 422 too-many-applications -X POST "$API/applications" -H "Authorization: Bearer $S1" \
  -H 'Content-Type: application/json' -d '{"offerId":"po-8","letter":"Uppsala me zanima.","submit":true}'

echo "== Akcija koju sme samo koordinator, poslata studentskim tokenom (stavka 4)"
proveri "student prihvata svoju prijavu" 403 not-allowed -X POST "$API/applications/p-11/acceptance" -H "Authorization: Bearer $S2"
proveri "student stavlja svoju prijavu na listu čekanja" 403 not-allowed -X POST "$API/applications/p-11/waitlist" -H "Authorization: Bearer $S2"
proveri "student odbija svoju prijavu kao koordinator" 403 not-allowed -X POST "$API/applications/p-11/rejection" \
  -H "Authorization: Bearer $S2" -H 'Content-Type: application/json' -d '{"reason":"x"}'

echo "== Tuđ zapis (stavka 4): server ne otkriva ni da postoji"
proveri "student2 povlači prijavu student1" 404 not-found -X POST "$API/applications/p-2/withdrawal" -H "Authorization: Bearer $S2"
proveri "student2 čita prijave student1" 404 not-found "$API/students/s-1/applications" -H "Authorization: Bearer $S2"
proveri "koordinator drugog univerziteta prihvata prijavu na Milano" 404 not-found -X POST "$API/applications/p-11/acceptance" -H "Authorization: Bearer $K2"

echo "== Poslednje mesto, dva istovremena prihvatanja (stavka 1): prolazi samo jedno"
proveri "prihvatanje p-20 (Dizajn interakcije, 1/3)" 200 - -X POST "$API/applications/p-20/acceptance" -H "Authorization: Bearer $K1"
proveri "prihvatanje p-21 (Dizajn interakcije, 2/3)" 200 - -X POST "$API/applications/p-21/acceptance" -H "Authorization: Bearer $K1"
A=$(mktemp)
B=$(mktemp)
curl -s -o /dev/null -w '%{http_code}' -X POST "$API/applications/p-24/acceptance" -H "Authorization: Bearer $K1" > "$A" &
curl -s -o /dev/null -w '%{http_code}' -X POST "$API/applications/p-22/acceptance" -H "Authorization: Bearer $K1" > "$B" &
wait
ISHOD=$(printf '%s\n%s\n' "$(cat "$A")" "$(cat "$B")" | sort | tr '\n' ' ')
GUBITNIK=$([[ "$(cat "$A")" == 409 ]] && echo p-24 || echo p-22)
rm -f "$A" "$B"
if [[ "$ISHOD" == "200 409 " ]]; then
  echo "OK    200 i 409  istovremeno p-24 i p-22: jedno prolazi, drugo no-free-places"
  uspelo=$((uspelo + 1))
else
  echo "PALO  očekivano 200 i 409, dobijeno $ISHOD"
  palo=$((palo + 1))
fi
proveri "ponovljeno prihvatanje odbijenog ($GUBITNIK): mesta nema" 409 no-free-places \
  -X POST "$API/applications/$GUBITNIK/acceptance" -H "Authorization: Bearer $K1"

echo
echo "Uspelo: $uspelo, palo: $palo"
echo "Podaci su promenjeni. Početni podaci: docker compose down -v && docker compose up -d"
[[ $palo -eq 0 ]]