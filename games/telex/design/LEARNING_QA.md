# TELEX — leerpad-QA (nieuwe speler + fixer)

Tester met frisse blik: enkel `design/LEARNING.md` en de CLI-sectie van `LEARNING_PATH.md` gelezen, geen GDD/notas
vooraf. Per deel: Kijk + Samen gespeeld (`lesson=<id> autoplay lesson_demo auto_answer`), Check-vragen bekeken
(`map check=<level>` en `TxLessons.check_question`), daarna een eigen examenvraag op een nieuw voorbeeld, gecontroleerd
met `TxReference` (core) en de lesnotas (p. 50–80).

**Hulpmiddel (nieuw):** `lesson_log` schrijft nu ook `LESSON_SAY #n <tekst>` en `LESSON_STATE <toestand>` (wat de speler
leest), en `lesson_shots=<map>` bewaart een schermafbeelding bij elke coachtekst. Dat is ±40× sneller dan
`--write-movie` (600 frames ≈ 9 min onder xvfb) en toont precies de momenten die tellen.

**WIP-commit ababcb0 (Kijk: uitleg ná de stap)** — gecontroleerd en behouden. Vroeger stond de uitleg van stap k al in
beeld terwijl machine en toestand nog stap k−1 toonden; na "Volgende" sprong de tekst meteen door naar stap k+1. Nu:
Volgende → de Chef voert de stap uit → pas dan verschijnen *wat/waarom* en de toestand van díe stap. Op de frames van
brute/RK/KMP klopt tekst = lint = toestandsregel. Voorspelvragen blijven vóór de stap (spookhand + vraag, dan "Toon het").

## Groep 1 — brute kracht en Rabin-Karp

### Deel 1 · brute (Algoritme 2)
- **Geleerd:** elke start i = 0 … n − m; vergelijk z[0], z[1], … met t[i], … tot het eerste verschil; 1 vergelijking =
  1 tik; een treffer kost m tikken; slechtste geval (n − m + 1)·m.
- **Examenvraag:** z = aab, t = aaab: hoeveel tikken (alle voorkomens)? Mijn antwoord: start 0: a=a, a=a, a≠b → 3;
  start 1: treffer → 3; totaal 6, treffer op 1. **Controle:** `TxReference.brute` → cmp 6, hits [1]. Juist.
- **Probleem + fix:** de Samen-tip zei altijd "Klik Naald / Volgende: het sjabloon schuift 1 op", ook bij de eerste
  klik (Naald) die niets verschuift. Nu twee tips: *Naald* = "de naald vergelijkt z[0], z[1], … met t[i], … tot het
  eerste verschil", *Volgende* = "het sjabloon schuift 1 op en de naald begint opnieuw bij z[0]".
- **UI:** kopbalk: "alle voorkomens" liep onder de knop *Speelhal* ("alle voorkome…"), en bij RK viel het tellerlabel
  WIELSLAGEN half onder de knop ("ELSLAGEN"). Fix: het huisje schuift mee met de breedte van het tellerlabel en
  "alle voorkomens" wordt enkel getekend als het vóór de knop past. Opdrachtkaart: met 4 velden raakte "modus:" de
  notasverwijzing onderaan → regels iets dichter bij elkaar.

### Deel 2 · rk_hash (h(s) = g(s) mod q, Horner)
- **Geleerd:** per bit ×2, +1 als het bit 1 is, mod q mag tussendoor; gelijke h → strings_gelijk.
- **Examenvraag:** h(0110) met q = 7. Horner: 0 → 1 → 3 → 6, dus h = 6. **Controle:** `TxReference.h` = 6,
  `horner_prefixes` = [0, 1, 3, 6]. Juist.
- **Probleem + fix:** foutuitleg in Samen "De stand klopt nog niet: het wiel zou 1 moeten tonen" was dubbelzinnig (nu?
  na de stap?). Nu met de formule: "Deze stap is nog niet af: het wiel moet eerst (2·0 + 1) mod 5 = 1 tonen." (bij rollen:
  "(2·h − uit·w + in) mod q = …"). Het machinepaneel telde bits vanaf 1 ("bit 1 van 3") terwijl Chef en toestand
  vanaf 0 tellen (s_0, notas) → nu "bit 0 (van 0 … 2)".

### Deel 3 · rk_rollen (rollend bijwerken)
- **Geleerd:** h(t_{p+1}…t_{p+m}) = (2·h(t_p…t_{p+m−1}) − t_p·2^m + t_{p+m}) mod q (= notas p. 53); w = 2^m mod q één
  keer vooraf (begin op 1, m keer ×2).
- **Examenvraag:** z = 0110, q = 7, t = 1011011. w = 16 mod 7 = 2. Vensters: 1011 → 4; rol: 2·4 − 2 + 0 = 6 (alarm);
  2·6 − 0 + 1 = 13 → 6 (alarm); 2·6 − 2 + 1 = 11 → 4. **Controle:** `TxReference.rk` → w 2, hs [4, 6, 6, 4]. Juist.
- Geen inhoudelijke problemen; formule en notatie volgen de notas.

### Deel 4 · rk_vals (alarm en valse treffer)
- **Geleerd:** alarm = gelijke hash; strings_gelijk beslist; een valse treffer kost tikken tot het eerste verschil;
  slechtste geval blijft O((n − m + 1)·m) (Opmerking 10).
- **Examenvraag:** zelfde voorbeeld: alarm op 1 (0110 = 0110, echte treffer, 4 tikken) en op 2 (1101 ≠ 0110: valse
  treffer, 1 tik). **Controle:** `TxReference.rk` → hits [1], false_hits [2], calls cmp 4 en 1. Juist.
- Check-scherm (`map check=2-2`) bekeken: examenblad links, vraag + 4 knoppen rechts, leesbaar.
