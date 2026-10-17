# Hash & Dash — leerpad (extendible hashing, lesnotas §2.1.1, p. 5–10)

Volgens `design/LEARNING.md`: elk **deel** = één nieuw idee, met vier fasen **Kijk → Samen → Zelf → Check**.
Alle voorbeelden, verteltekst, voorspelvragen en antwoorden komen uit één bron: `scripts/game/hd_lessons.gd`
(`HDLessons.PARTS`). De teksten hieronder zijn letterlijk wat de game toont; ze zijn **nagerekend met de core**
(`ExtHashModel.correct_move()` / `auto_insert()`):
- `tools/lesson_trace.gd` speelt elk voorbeeld met het orakel en print elke stap + antwoord
  (`"$G" --headless --path . --script res://tools/lesson_trace.gd [-- deel]`);
- `tests/suites/t_lessons.gd` (in `run_tests.gd`) controleert dat elke les uitspeelt, dat elke voorspelvraag en elke
  Check-vraag (25 willekeurige voorbeelden per deel) een juist antwoord heeft dat de core onafhankelijk bevestigt.

Notatie (zoals de notas): a = globale diepte (muur met 2^a luiken = pointerarray), a_b = lokale diepte (op het rek),
g = plaatsen per rek (emmer), luik = (h(r))|a = de eerste a bits, L/S = lees-/schrijfoperaties op de schijf.

## Overzicht

| # | Deel (één idee) | Kijk-voorbeeld | Samen-voorbeeld | Zelf | Check in de wereld (Kijk) | Check in het rapport |
|---|---|---|---|---|---|---|
| 1 | **Het juiste luik**: luik = (h(r))\|a | a = 1, g = 3, 4 pakjes | a = 2, g = 3, 5 pakjes | dag 1 | "Door welk luik moet 01110?" | 2× luik op een nieuwe tabel |
| 2 | **Splitsen**: vol rek, a_b < a → zaag, verdeel op bit a_b + 1 | a = 3, rek 0 (4 luiken) en rek 10 (2 luiken) | a = 2, 3 pakjes, 1 split | dag 2 (en 3) | "Hendel of zaag?", "Welke kant?" | eerste stap / welke kant |
| 3 | **Verdubbelen**: vol rek, a_b = a → hendel, dan zagen | **Figuur 2 → 3 → 4** (+11111), dan +00010 | a = 1: eerst hendel, daarna enkel zaag | dag 2 | 2× "Hendel of zaag?" | eerste stap |
| 4 | **Ritten tellen**: plaatsen 1 L + 1 S, met split 1 L + 2 S, verdubbelen 0 | a = 2, 3 pakjes met L/S-uitleg | voorspel vóór elk pakje de kost | dag 3 | "Wat kost 00011?" | kost van een nieuw pakje |
| 5 | **Opzoeken** (klanten): zelfde luik, 1 L | **Figuur 4**, 3 klanten | a = 3, 4 klanten | dag 4 | "Door welk luik zoekt de klant 11100?" | luik + aantal L |
| 6 | **Opnieuw**: na splitsen kan één kant leeg blijven → nog eens | **Figuur 4 + 11110 → Figuur 5 → a = 4** | a = 1 + 00001: 2× verdubbelen | dag 5 | "Rek 111 nog vol: wat nu?" | hoe vaak verdubbelen |
| 7 | **Wanneer het faalt**: > g identieke waarden | a = 3, derde 10110 tot a = n = 5 | met overloopbak: de derde 11010 | dag 7 | "Helpt nog eens verdubbelen?" | lukt het ooit? |

**Dagvolgorde.** De dagen blijven in dezelfde volgorde; vóór elke dag worden de delen die die dag (of een eerdere dag)
nodig heeft automatisch en **verplicht** getoond (Kijk, dan Samen), zodat een dag nooit iets vraagt dat nog niet
getoond is: dag 1 ← deel 1; dag 2 ← delen 2 en 3 (dag 2 vraagt verdubbelen én splitsen, dus beide); dag 3 ← deel 4
(dag 3 vraagt "0 dubbels en ritten optimaal"); dag 4 ← deel 5; dag 5 ← deel 6; dag 6 (Oefening 5) = examen over
alles, geen nieuw deel; dag 7 ← deel 7. Wie een latere dag opent (bv. met `--unlock`), krijgt eerst alle ontbrekende
delen in volgorde (`HDLessons.pending_for_day`). Daarna zijn ze overslaanbaar en herbekijkbaar via de gids.
Deel 2 (splitsen met a_b < a) staat vóór deel 3 (verdubbelen): splitsen is de kern; verdubbelen is "zorg eerst
dat er twee luiken naar het rek wijzen, en splits dan" (notas p. 7).

## Werking van de fasen in de game

- **Kijk** (`LessonCoach`, modus kijk): de chef speelt het orakel af. Vóór elke stap staat de wereld stil, het
  juiste element licht op (luik, hendel, zaag, kant van de sorteertafel, overloopbak) en het chefpaneel onderaan
  toont *wat* (vet) en *waarom* (de regel). Knoppen: **Volgende stap** (of Spatie/Enter), **Afspelen** (gaat zelf
  door, ±3–4 s per stap), **Overslaan** (pas na de eerste keer). De speler kan in Kijk niets in de wereld doen.
- **Voorspelvragen (Check in de wereld)**: op de aangeduide stap vraagt de chef eerst "Voorspel: …" met 2–4
  antwoordknoppen (of 1–4 op het toetsenbord); meteen feedback (groen "Juist" / rood + uitleg), daarna toont de
  chef de stap echt. Afspelen pauzeert bij een vraag.
- **Samen** (modus samen): de speler doet alles zelf met de gewone bediening. **Hint** (knop of H) licht het juiste
  element op en zegt de regel. **Fading:** de eerste 2 keer dat een soort stap (luik kiezen, hendel/zaag,
  verdelen, klant helpen, bak) voorkomt, verschijnt de tip vanzelf; daarna enkel "Jouw beurt" + hint op vraag.
  **Fout** = de zet wordt niet uitgevoerd: de chef legt uit waarom (met de bits/a_b van dít geval) en de speler
  probeert opnieuw; na 2 fouten op dezelfde stap licht het juiste element vanzelf op. Geen munten/hartjes.
- **Zelf**: het bestaande dag-level, met de echte gevolgen. Hint (spookhand/chef) zoals vroeger.
- **Check in het rapport**: na de dag (1–2 vragen over de delen van die dag, dag 6: verdubbelen + kost) op een
  **nieuw willekeurig voorbeeld** (getekend zoals de figuren in de notas, `NotasView`). Fout → uitleg + een nieuw
  voorbeeld van hetzelfde deel (max. 2 herkansingen). Juist → deel "begrepen".
- **Badge per deel** op de dagenkaart (onder de sterren, één bolletje per deel van die dag):
  grijs = nog niet, amber = demo bekeken, blauw = samen geoefend, groen met vinkje = **begrepen**
  (samen gedaan én Check juist). Opslag: `SaveData` setting `learning` = `{deel: {kijk, samen, check}}`.
- **Gids (F1 / ?)**, tab *Doel*: per deel een pagina "Leerpad · deel k" met de regel, de status en de knoppen
  **Bekijk de demo opnieuw** en **Oefen dit opnieuw** (start die les; daarna terug naar waar je was).
- **Bot-modus** (`--bot`): geen lessen, geen vragen.

## Per deel

Tekst per stap = `HDLessons.narrate()` ("wat" | "waarom"). Rekken worden aangeduid met hun bordje (de eerste a_b bits).

### Deel 1 · Het juiste luik (notas p. 6–7) — Zelf: dag 1
**Regel:** luik = (h(r))|a: de eerste a bits van de hashwaarde.
**Kijk** — start a = 1, g = 3, `0{} 1{}`, pakjes `10110 00101 01110 11001`:
1. Pakje 10110: het eerste bit (a = 1) is 1, dus luik 1. | Luik 1 wijst naar rek 1; daar is nog plaats (0/3).
2. Pakje 00101: het eerste bit (a = 1) is 0, dus luik 0. | Luik 0 wijst naar rek 0; daar is nog plaats (0/3).
3. **Voorspel:** door welk luik moet het pakje 01110? (luik 0 / luik 1) → **luik 0**. Dan: Pakje 01110 … luik 0 (1/3).
4. Pakje 11001: het eerste bit is 1, dus luik 1 (1/3). Eind: `0{00101,01110} 1{10110,11001}`, L 4 S 4.
**Samen** — a = 2, g = 3, `00{} 01{} 10{} 11{}`, pakjes `11010 01001 10011 00110 11100` → luiken 11, 01, 10, 00, 11.
Typische fout: luik op het laatste bit / verkeerd aantal bits → "Niet luik 10: bij 11010 zijn de eerste a = 2 bits 11, dus luik 11."
**Check (rapport):** "Door welk luik gaat een nieuw pakje x?" op een willekeurige tabel met a = 2–3 (enkel luiken
naar verschillende rekken als opties). Vb. (seed 7): tabel `00{00111,00010} 01{01001} 10{10101,10111} 11{11100,11101}`, x = 00101 → **luik 00**.

### Deel 2 · Splitsen (notas p. 7–8) — Zelf: dag 2 (en dag 3)
**Regel:** vol rek met a_b < a: zaag (splitsen) en verdeel op bit a_b + 1.
**Kijk** — a = 3, g = 2, `0{00100,01111} 10{10010,10111} 110{11000} 111{11100}`, pakjes `01010 10100`:
1. Pakje 01010: de eerste a = 3 bits zijn 010, dus luik 010. | Maar rek 0 is vol (g = 2): het pakje blijft in de buis steken.
2. Rek 0 is vol, maar a_b = 1 < a = 3: er wijzen 4 luiken naar. Dus: de zaag (splitsen). | Er komt een nieuw rek bij; de pakjes worden verdeeld op bit a_b + 1 = 2.
3. 00100: bit 2 is 0, dus links (rek 00). | Bit a_b + 1 = 2 beslist: 0 blijft in het oude rek, 1 gaat naar het nieuwe.
4. 01111: bit 2 is 1, dus rechts (rek 01). (01010 schuift daarna door naar rek 01.)
5. Pakje 10100 … luik 101 | Maar rek 10 is vol.
6. **Voorspel:** rek 10 is vol (a_b = 2, a = 3). Wat nu? (Hendel / Zaag) → **Zaag**. Dan: Rek 10 … 2 luiken … zaag; verdelen op bit 3.
7. **Voorspel:** naar welke kant gaat 10010? → **Links (oud rek 100)** (bit 3 = 0). 8. 10111: bit 3 is 1, rechts (rek 101).
Eind: `00{00100} 01{01111,01010} 100{10010} 101{10111,10100} 110{11000} 111{11100}`, L 2 S 4.
**Samen** — a = 2, `0{00011,01100} 10{10001,10110} 11{11010}`, pakjes `11000 01001 00110`:
11000 → luik 11 (plaats); 01001 → luik 01, vast; **zaag rek 0**; 00011 links, 01100 rechts; 00110 → luik 00.
Typische fouten + uitleg: hendel i.p.v. zaag → "Niet nodig: a_b = 1 < a = 2, er wijzen al 2 luiken naar dit rek.
Gebruik de zaag."; verkeerde kant → "Kijk naar bit 2 van 01100: dat is 1, dus rechts (nieuw rek)."
**Check (rapport):** (a) "Je voegt x toe. Wat moet er eerst gebeuren?" (Gewoon plaatsen / Zaag / Hendel) in een
situatie met a_b < a; of (b) "Je voegt x toe en zaagt rek B (a_b = k). Naar welk rek gaat y?".
Vb.: `0{01100,00111} 10{10010,10111} 11{11101,11111}`, x = 00011, y = 00111 → **rek 00** (bit 2 = 0).

### Deel 3 · Verdubbelen (notas p. 7, Figuur 2–4) — Zelf: dag 2
**Regel:** vol rek met a_b = a (één luik): eerst de hendel (verdubbelen), dan zagen.
**Kijk** — **Figuur 2**: a = 1, `0{00100,01111} 1{10010,11100}`, pakjes `11111 00010`:
1. Pakje 11111: het eerste bit (a = 1) is 1, dus luik 1. | Maar rek 1 is vol (g = 2): het pakje blijft in de buis steken.
2. Rek 1 is vol en a_b = a = 1: er wijst maar één luik naar. Dus: de hendel (verdubbelen). | a wordt 2 en elk luik wordt er twee die naar hetzelfde rek wijzen. Dat gebeurt in het geheugen: 0 ritten. (= **Figuur 3**)
3. **Voorspel:** rek 1 is vol (a_b = 1, a = 2). Wat nu? → **Zaag** (er wijzen nu 2 luiken naar). Dan splitsen op bit 2: 10010 links (rek 10), 11100 rechts (rek 11); 11111 schuift door naar rek 11 (= **Figuur 4**).
4. Pakje 00010 → luik 00, rek 0 vol. **Voorspel:** wat nu? → **Zaag** (a_b = 1 < a = 2: niet verdubbelen!). 00100 links, 01111 rechts.
Eind: `00{00100,00010} 01{01111} 10{10010} 11{11100,11111}`, L 2 S 4.
**Samen** — a = 1, `0{00101,01110} 1{10011,11001}`, pakjes `00001 10111`: 00001 → luik 0 vast → **hendel** →
**zaag rek 0** (00101 links, 01110 rechts); 10111 → luik 10 vast → **zaag rek 1** (géén hendel: a_b = 1 < a = 2;
10011 links, 11001 rechts). Typische fout: zaag bij a_b = a → "Dit rek heeft a_b = a = 1: er wijst maar één luik
naar. Eerst de hendel (verdubbelen)."; of een tweede keer verdubbelen → uitleg "Niet nodig …".
**Check (rapport):** "Je voegt x toe. Wat moet er eerst gebeuren?" in een situatie met a_b = a.
Vb.: `0{00001} 10{10010,10101} 11{11010}`, x = 10110 → **Hendel: eerst verdubbelen** (rek 10 vol, a_b = a = 2).

### Deel 4 · Ritten tellen (notas p. 9) — Zelf: dag 3
**Regel:** pakje plaatsen: 1 L + 1 S. Met splitsen: 1 L + 2 S. Verdubbelen: 0 (geheugen).
**Kijk** — a = 2, `0{00100} 10{10010,10111} 11{11100}`, pakjes `01000 10001 00011` (elke tekst eindigt met de kost):
1. Pakje 01000 → luik 01 → rek 0 (a_b = 1, dus 2 luiken delen die buis); er is plaats. Kost: 1 L (rek lezen) + 1 S (rek schrijven). Totaal L+1 S+1.
2. Pakje 10001 → luik 10, rek 10 vol. Kost: 1 L (het volle rek lezen). → hendel (0 ritten) → zaag ("Straks: S + 2 (oud en nieuw rek wegschrijven), geen extra L") → 10010 links, 10111 rechts. Totaal **L+1 S+2**.
3. **Voorspel:** hoeveel ritten kost 00011? (1 L + 1 S / 1 L + 2 S / 1 L + 3 S / 2 L + 2 S) → **1 L + 2 S** (rek 0 vol, a_b = 1 < a = 3 → zaag).
Eind: `00{00100,00011} 01{01000} 100{10010,10001} 101{10111} 11{11100}`, L 3 S 5.
**Samen** — a = 1, `0{00110} 1{10101,11011}`, pakjes `01100 11110 00011`; vóór elk pakje voorspelt de speler de
kost: 01100 → **1 L + 1 S**; 11110 → **1 L + 2 S** (hendel + zaag); 00011 → **1 L + 2 S** (zaag). De teller L/S
rechtsboven bevestigt het.
**Check (rapport):** "Hoeveel L en S kost het toevoegen van x?" (meestal met één splitsing).
Vb.: `0{01101} 1{10001,10010}`, x = 11011 → **1 L + 2 S** (verdubbelen kost niets).

### Deel 5 · Opzoeken (notas p. 7) — Zelf: dag 4
**Regel:** opzoeken = zelfde regel: luik (h(r))|a, dan dat ene rek lezen (1 L).
**Kijk** — **Figuur 4** (a = 2, `0{00100,01111} 10{10010} 11{11100,11111}`), klanten `10010 01111 11100`:
1. Klant zoekt 10010: de eerste a = 2 bits zijn 10, dus luik 10. | Opzoeken gaat met dezelfde regel als toevoegen. Luik 10 wijst naar rek 10: dat ene rek lezen = 1 L.
2. Klant zoekt 01111 → luik 01 | Luik 01 wijst naar rek 0 (2 luiken delen die buis): 1 L.
3. **Voorspel:** door welk luik moet de klant 11100? (luik 00 / 10 / 11) → **luik 11**. Eind: L 3, S 0.
**Samen** — a = 3, `00{00011,00110} 01{01101} 100{10001} 101{10100,10110} 11{11010,11100}`, klanten
`01101 10110 11100 00110` → luiken 011, 101, 111, 001 (een luik dat dezelfde buis deelt, telt ook als juist).
**Check (rapport):** "Een klant zoekt y. Door welk luik, en hoeveel leesoperaties?" → luik (h(y))|a, **1 L**.

### Deel 6 · Nog eens verdubbelen (notas p. 8, Figuur 5) — Zelf: dag 5
**Regel:** blijft één kant leeg en het rek vol? Dan opnieuw: hendel of zaag, tot het past.
**Kijk** — **Figuur 4** + `11110` (het voorbeeld van de notas):
1. Pakje 11110 → luik 11, rek 11 vol. 2. a_b = a = 2 → hendel (a = 3). 3. a_b = 2 < 3 → zaag, verdelen op bit 3:
11100 rechts, 11111 rechts → rek 110 blijft **leeg** = **Figuur 5**.
4. **Voorspel:** rek 111 is vol (a_b = 3, a = 3). Wat nu? → **Hendel**. Tekst: "Pech: rek 111 is nog altijd vol
(alle pakjes gingen naar dezelfde kant) en a_b = a = 3. Dus opnieuw de hendel."
5. zaag op bit 4: 11100 links (1110), 11111 rechts (1111); 11110 → rek 1111.
Eind: `0{00100,01111} 10{10010} 110{} 1110{11100} 1111{11111,11110}`, L 1 S 3.
**Samen** — a = 1, `0{00100,00011} 1{10101}`, pakjes `00001 11011`: 00001 → hendel, zaag (beide links, rek 01
leeg) → hendel, zaag op bit 3 (00100 rechts, 00011 links) → geplaatst in rek 000; 11011 → luik 110 (rek 1).
**Check (rapport):** "Hoe vaak moet de muur verdubbelen om x toe te voegen?" (voorbeelden met ≥ 2 splitsingen).
Vb.: `0{01001,01111} 10{10111,10110} 11{11111}`, x = 10101 → **2 keer**.

### Deel 7 · Wanneer het faalt (notas p. 8–9, Oefening 4) — Zelf: dag 7
**Regel:** meer dan g identieke hashwaarden: geen bits meer, de methode faalt.
**Kijk** — a = 3, `0{00100,01001} 100{} 101{10110,10110} 11{11000}`, pakje `10110` (de derde):
luik 101 vast → hendel (a = 4) → zaag op bit 4: beide 10110 rechts →
**Voorspel:** helpt nog een keer verdubbelen en zagen? → **Nee: ze hebben dezelfde bits** ("Kijk wat het algoritme
toch doet") → hendel (a = 5) → zaag op bit 5: beide links → "Rek 10110 is vol en a = n = 5: er zijn geen bits meer
om te verdubbelen. | Meer dan g identieke hashwaarden: de methode faalt (notas p. 8)." → hendel op de eindaanslag,
de buis barst.
**Samen** — a = 1, met overloopbak, pakjes `11010 00111 11010 10001 11010`: gewoon sorteren; 10001 → hendel + zaag
(beide 11010 rechts, 10001 → rek 10); de derde 11010 → **overloopbak** (sleep of K). Typische fout: hendel/zaag →
"Verdubbelen helpt hier niet: identieke pakjes blijven altijd samen. Sleep het naar de bak."
**Check (rapport):** "g = 2. Je voegt nog een y toe. Lukt dat ooit?" — twee varianten: 2× y in het rek → **Nee,
nooit**; y en y' die enkel in het laatste bit verschillen → **Ja** (pas bij a = 5).

## CLI-opties voor de tester (na `--`)

| optie | effect |
|---|---|
| `--lesson=<deel>` | start meteen de les van dat deel (`luik`, `splitsen`, `verdubbelen`, `kost`, `opzoeken`, `opnieuw`, `faalt`); scène `res://scenes/depot.tscn` |
| `--phase=kijk` / `--phase=samen` | enkel die fase (zonder: Kijk en dan Samen) |
| `--autoplay` | Kijk speelt vanzelf af (zoals de knop Afspelen) |
| `--auto-answer` | voorspelvragen worden na 2,5 s automatisch beantwoord (eerste fout, daarna juist) — voor opnames |
| `--lesson-demo` | Samen: een "speler" vraagt een hint, maakt bij de eerste stap van elke soort een fout en doet het dan juist |
| `--check=<dag>` | opent meteen de Check-vragen van die dag (scène `res://scenes/day_map.tscn`) |
| `--no-lessons` | dag starten zonder de verplichte lessen |
| `--reset-learning` | wist de leervoortgang (alles weer "eerste keer") |
| `--bot` | bot speelt; lessen en vragen worden overgeslagen |

Voorbeelden (frame-opnames, 30 fps):
```
G=/opt/godot/Godot_v4.7.2-stable_linux.x86_64
xvfb-run -a -s "-screen 0 1920x1080x24" $G --path . --rendering-driver opengl3 --write-movie /tmp/f/kijk.png --fixed-fps 30 --quit-after 900 res://scenes/depot.tscn -- --lesson=verdubbelen --phase=kijk --autoplay --auto-answer
xvfb-run -a -s "-screen 0 1920x1080x24" $G --path . --rendering-driver opengl3 --write-movie /tmp/f/samen.png --fixed-fps 30 --quit-after 900 res://scenes/depot.tscn -- --lesson=splitsen --phase=samen --lesson-demo
xvfb-run -a -s "-screen 0 1920x1080x24" $G --path . --rendering-driver opengl3 --write-movie /tmp/f/check.png --fixed-fps 30 --quit-after 300 res://scenes/day_map.tscn -- --check=2 --auto-answer
```
Normaal spelen: titel → kaart → dag N: de ontbrekende lessen starten vanzelf (eerste keer verplicht).
