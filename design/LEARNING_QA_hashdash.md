# Hash & Dash — QA als nieuwe speler (leerpad extendible hashing)

Tester + fixer, frisse blik. Werkwijze: enkel `design/LEARNING.md` en de CLI-sectie van het leerpad gelezen; elk deel
gespeeld via frame-opnames (`--lesson=<deel> --autoplay --auto-answer --lesson-demo`, `--reset-learning`), daarna
zonder de game een examenvraag op een nieuw voorbeeld opgelost, gecontroleerd met `ExtHashModel` (headless
script: `setup` + `load_layout` + `simulate_insert`/`auto_insert`) en pas dan met de lesnotas (§2.1.1).

Notatie hieronder: `label{inhoud}` per rek in pointerarray-volgorde (zoals `ExtHashModel.describe()`), n = 5.

## Deel 1 · Het juiste luik

**Wat ik begreep.** De pointerarray heeft 2^a luiken; het luik van een pakje = de eerste a bits van zijn hashwaarde
((h(r))|a). Elk luik wijst naar een rek (emmer). De voorspelvraag (01110 met a = 1) en de Samen-ronde (a = 2) maken
het concreet.

**Examen.** a = 2: welk luik voor 10110? → `10`. a = 3: 01101 → `011`. **Klopt** (`index_of`).

**Onduidelijk.** De capaciteit van een rek heet in deel 2 plots `g`, maar die letter werd in deel 1 nooit genoemd
(daar stond enkel "0/3"). Het label `ab` op elk rek wordt ook nog niet uitgelegd (mag, komt in deel 2).

**Verbeterd.** Kijk-intro van deel 1 zegt nu: "De pointerarray heeft 2^a luiken; elk luik wijst naar een rek (emmer)
met plaats voor g pakjes (hier g = 3)." (nieuw veld `idea` per deel in `hd_lessons.gd`, getoond in de Kijk-intro).
Muntenteller: stond in de lessen op −1 (een rit kost meteen −1, de beloning komt pas later). Munten zijn in een les
zinloos → teller, "−1"-zwevers en muntenregen worden in lessen verborgen (`hud.show_coins`).

## Deel 2 · Splitsen

**Wat ik begreep.** Vol rek (g pakjes) en `ab < a` (er wijzen 2^(a−ab) ≥ 2 luiken naar) → zaag: nieuw rek erbij,
pakjes verdeeld op bit ab + 1 (0 blijft in het oude, 1 naar het nieuwe), daarna probeert het vastzittende pakje
opnieuw.

**Examen.** a = 2, g = 2, start `0{00110,01001} 10{10000} 11{11000}`; voeg 01111 toe. Mijn antwoord: luik 01 → rek 0
vol, ab = 1 < 2 → splitsen op bit 2 → `00{00110} 01{01001,01111} 10{10000} 11{11000}`; luik 00 → oud rek, luik 01 →
nieuw rek; beide ab = 2. **Klopt** (core: `["split","place"]`, zelfde indeling).

**Onduidelijk.** (1) `g` werd gebruikt ("vol (g = 2)") zonder uitleg. (2) De tekst zei nooit wat er met de
**pointers** en met **ab** gebeurt — enkel de buizen herschikten zich. Op het examen moet je de pointerarray tekenen,
dus dat is net het belangrijkste. (3) Na Samen stond er "Goed gedaan, met 3 fouten …! Goed!" (dubbel).

**Verbeterd.** Kijk-intro van deel 2: "Vol = g pakjes (hier g = 2). ab op een rek = hoeveel bits dat rek gebruikt; er
wijzen 2^(a−ab) luiken naar." Na elke splitsing (Kijk én Samen) een groene zin, uit het model berekend
(`HDLessons.split_summary`): "Gezaagd: rek 00 + nieuw rek 01, allebei ab = 2. Luiken 010, 011 wijzen nu naar rek 01."
Dubbele "Goed!" weg.
In Kijk is de splitsing nu een **eigen stap** (luik dat nu naar het nieuwe rek wijst licht op), zodat het paneel
niet overloopt; in Samen staat de zin boven de volgende opdracht. Check van dag 2 kreeg een derde vraagsoort: "Welke
luiken wijzen na het zagen naar het nieuwe rek?" (4 opties: juiste helft / andere helft / alle luiken / geen;
antwoord uit `simulate_insert().changed`, nagekeken in `t_lessons.gd`).

## Deel 3 · Verdubbelen

**Wat ik begreep.** Vol rek met `ab = a` (één luik) → eerst de hendel: a + 1, elk luik x wordt x0 en x1 die naar
hetzelfde rek wijzen; rekken/pakjes veranderen niet, kost 0 ritten. Daarna is ab < a en zaag je.

**Examen.** g = 2, a = 1, leeg; voeg 10100, 00111, 11001, 11100, 01010, 10010 toe. Mijn antwoord: bij 11100 verdubbelen
(a = 2) en rek 1 zagen op bit 2 → eindtoestand a = 2: `0{00111,01010} 10{10100,10010} 11{11001,11100}`.
**Klopt** (core: 11100 → `["double","split","place"]`, zelfde eindtoestand, 6 L / 7 S).

**Onduidelijk.** "elk luik wordt er twee" zei niet *welke* twee; voor de pointerarray-tekening moet je weten dat
luik 1 → 10 en 11 wordt (p_n[i] = p_o[⌊i/2⌋] in de notas).

**Verbeterd.** Verteltekst: "a wordt 2: elk luik x wordt x0 en x1 (luik 1 wordt 10 en 11), die naar hetzelfde rek
wijzen; de rekken blijven. Enkel geheugen: 0 ritten." + Kijk-intro "elk nieuw luik krijgt de pointer van het oude luik
zonder zijn laatste bit". (Geen ⌊ ⌋ gebruikt: Fredoka heeft die glyphs niet.)

## Deel 4 · Ritten tellen

**Wat ik begreep.** Pointerarray zit in het geheugen. Plaatsen = 1 L (rek lezen) + 1 S (rek schrijven). Vol rek → 1 L,
na zagen 2 S (oud + nieuw rek), verdubbelen 0.

**Examen.** Kosten van de reeks uit deel 3 → 6 L + 7 S (alleen 11100 kost 1 L + 2 S). **Klopt** (core: reads 6,
writes 7). Ook: 00001 in Oefening 5 (zie deel 6) → twee splitsingen → 1 L + 3 S. **Klopt** (writes 6 → 9).

**Onduidelijk.** De regel noemde enkel "met splitsen: 1 L + 2 S"; dat elke extra splitsing nog 1 S kost moest ik
zelf afleiden (de Samen-voorspelvraag biedt wel "1 L + 3 S" als optie aan).

**Verbeterd.** Regel: "Met splitsen: 1 L + 2 S (elke extra splitsing: + 1 S)."

## Deel 5 · Opzoeken

**Wat ik begreep.** Zelfde regel als toevoegen: luik (h(r))|a, dat ene rek lezen = 1 L; ook als meerdere luiken dezelfde
buis delen.

**Examen.** a = 3: `00{00011,00110} 01{01101} 100{10001} 101{10100,10110} 11{11010,11100}`. Welk rek bevat 10110? →
luik 101 → rek 101, gevonden, 1 L. Zoek 01011 → luik 010 → rek 01, niet gevonden, 1 L. **Klopt** (core `lookup`).

**Onduidelijk.** Een zoekopdracht naar iets dat er *niet* is komt niet voor; dat 1 L dan ook volstaat moest ik zelf
bedenken.

**Verbeterd.** Kijk-intro: "Staat het pakje niet in dat rek, dan staat het nergens: je hoeft geen ander rek te lezen."

## Deel 6 · Nog eens verdubbelen

**Wat ik begreep.** Na zagen kan één kant leeg blijven en het rek nog vol zijn; dan opnieuw dezelfde beslissing
(ab = a → hendel, anders zaag) tot het past. De "Pech: … nog altijd vol"-zin maakt dat goed duidelijk.

**Examen (Oefening 5 uit de notas).** g = 2, a = 1, voeg 00000, 11111, 01001, 10001, 00010, 00001 toe. Mijn antwoord:
00010 → verdubbel + zaag → a = 2; 00001 → verdubbel, zaag (alles links, 001 leeg), verdubbel, zaag → a = 4:
`0000{00000,00001} 0001{00010} 001{} 01{01001} 1{11111,10001}`. **Klopt** (core: `["double","split","double",
"split","place"]`, zelfde indeling).

**Onduidelijk / verbeterd.** Het paneel liep over bij voorspelvraag + splitsingszin + "Pech"-zin (laatste regel viel
weg) → opgelost door de splitsingszin als eigen Kijk-stap.

## Deel 7 · Wanneer het faalt

**Wat ik begreep.** Meer dan g pakjes met dezelfde hashwaarde: elke splitsing stuurt ze naar dezelfde kant; bij
a = n zijn er geen bits meer → de methode faalt. Uitweg (Samen): overloopbak voor het (g+1)-de identieke pakje.

**Examen.** g = 2, a = 1: 01100, 01100, 11000, 01100. Mijn antwoord: de derde 01100 faalt na 4 × (verdubbelen +
zagen) bij a = 5. **Klopt** (core: `["double","split"] × 4, "fail"`, a = 5).

**Onduidelijk.** (1) Na de voorspelvraag "Helpt nog een keer verdubbelen?" (antwoord: nee) zei de chef "Dus opnieuw
de hendel" — tegenstrijdig. (2) De overloopbak verscheen pas in Samen zonder aankondiging. (3) In Samen kwam het
(g+1)-de identieke pakje nog op de band, maar de tekst zei "zit vast"; trok je dan aan de hendel, dan kwam "Er zit
niets vast: verdubbelen is nu niet nodig" (fout).

**Verbeterd.** (1) Bij identieke waarden: "Pech: rek … is nog altijd vol: alle pakjes hebben dezelfde hashwaarde,
dus zagen helpt nooit. De chef doet toch verder (hendel, zaag, ...) tot a = n = 5: dan zijn er geen bits meer."
(2) Kijk-intro kondigt de overloopbak aan (Oefening 4). (3) "pakje … komt eraan. Kijk eerst in zijn rek: wat nu?" en de
foutuitleg verwijst nu naar de bak ("Verdubbelen helpt hier niet: identieke pakjes blijven altijd samen …").

## Check-vragen

Bekeken: dag 2 (`--check=2`): figuur in notasstijl (pointerarray + rekken met ab), nieuw voorbeeld bij fout, uitleg
klopt. Toegevoegd: vraagsoort over de luiken na het zagen (zie deel 2).

## Besluit

Ja: met enkel de game kon ik alle zes examenvragen juist oplossen (incl. Oefening 5 van de notas). De grootste gaten
zaten in wat er met de **pointerarray** gebeurt (welke luiken na zagen/verdubbelen waar naartoe wijzen) — dat toonde
de game enkel met bewegende buizen; nu staat het ook in tekst en wordt het gecheckt.

Open: Zelf-levels (gewone dagen) niet opnieuw gespeeld in deze ronde; de Check-vragen enkel voor dag 2 visueel
bekeken (de andere dagen enkel via `t_lessons.gd`).
