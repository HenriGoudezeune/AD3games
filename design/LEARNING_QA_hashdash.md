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
