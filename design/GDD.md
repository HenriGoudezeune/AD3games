# Hash & Dash — Game Design Document (v1)

Eigenaar: lead game designer. Lezers: core-engineer (`scripts/core/`), gameplay-engineer (`scripts/game/`, `scenes/`),
art & audio director (`design/ART.md`), QA. Bron van de leerstof: lesnotas AD3 §2.1.1 (gedrukte p. 4–10). **Bij twijfel
gaan de notas voor.** Alle sleutelreeksen en eindtoestanden in dit document zijn nagerekend met een simulator die exact
de regels van de notas volgt (zelfde logica als de JS-referentie `ad3-quest/levels/2-1-1-extendible-hashing.js`).

Stijl: de visuele stijl (palet, vormen, font) bepaalt `ART.md`. Dit document legt alleen **functionele** eisen vast
(leesbaarheid, bitkleuren per positie, wat moet bewegen en wanneer). Komt ART.md met andere kleurwaarden, dan gelden
die, zolang de 6 bitposities onderling duidelijk te onderscheiden blijven.

---

## 1. Pitch & pijlers

**Pitch.** Je runt een pakjesdepot dat nooit groot genoeg is. Pakjes met bitlabels rollen over de band, jij gooit ze
door het juiste luik in de sorteermuur, buizen brengen ze naar de rekken. Als een rek vol zit en er komt toch iets bij,
loeit het alarm en vertraagt de tijd: trek je aan de hendel om de muur te verdubbelen, of zaag je het rek in twee?
Kies verkeerd en je depot loopt vast, raakt pakjes kwijt of je stuurt de heftruck voor niets het magazijn in. Wie
Hash & Dash uitspeelt, heeft extendible hashing een paar honderd keer *gedaan*, niet gelezen.

Referenties voor het gevoel: *Mini Metro* (rustige maar groeiende druk, netwerken die je ziet uitbreiden), *Overcooked*
(drukte, kleine handelingen snel na elkaar), *Papers, Please* (regels toepassen onder tijdsdruk; fouten merk je later).

### Pijlers
1. **De regels zijn het algoritme.** Elk ding in de wereld komt overeen met een begrip uit de notas, en elke
   spelregel volgt een stap van het algoritme. Er is geen spelregel die "ernaast" staat. Wie wint, voert het
   algoritme correct uit.
2. **Fouten hebben gevolgen, geen popups.** Er verschijnt nooit "FOUT!". Een fout luik betekent dat het pakje in het
   verkeerde rek ligt en dat de klant het later niet vindt. Een onnodige verdubbeling maakt je muur breder, je luiken
   kleiner en je huur hoger. Achteraf toont het dagrapport een herbeleving met de juiste zet.
3. **Bits zijn leesbaar.** Elke bitpositie heeft overal dezelfde kleur (pakje, luik, rekbordje). Je ogen leren
   "eerste a bits" te lezen. Die hulp wordt per dag afgebouwd tot je de bits zelf leest.
4. **Juice.** Elke handeling heeft gewicht: squash & stretch, klik-geluid, licht door de buizen, slow-mo bij het
   alarm, een muur die zichtbaar openklapt. Je moet het willen doen, ook als je het al kan.

---

## 2. Core loop

### 2.1 Per seconde (de microlus, ~2–4 s per pakje)
| t | speler | wereld (visueel/audio) |
|---|---|---|
| 0.0 | ziet een pakje binnenrollen, bv. `10110` | pakje ploft op de band (squash 0.12 s), "thunk" |
| 0.3 | leest de eerste *a* bits (a = 3 → `101`) | bits 1..a staan (dag 1–2) onder een gekleurde accolade |
| 0.6 | **muis:** pakt het pakje (klik-en-houd) of **toets:** typt `1`,`0`,`1` | pakje komt omhoog (scale 1.08, schaduw groter); het luik dat bij de getypte bits past licht op, de buis naar het rek gloeit |
| 1.0 | sleept naar luik `101` en laat los / derde bit getypt → valt automatisch | luik klapt open (0.10 s), pakje wordt opgezogen (stretch richting buis), lichtpuls reist door de buis (0.35 s) |
| 1.4 | — | pakje schuift in een vrij vak van het rek (bounce), +10 munten vliegen naar de HUD, combo-teller tikt |
| 1.5 | volgende pakje | — |

**Vol rek** (de macrobeslissing, enkele keren per dag):
1. Pakje valt in een luik waarvan het rek vol zit. Het blijft **in de buis steken** (de buis zwelt op, het rek bolt,
   een oranje zwaailicht draait). De tijd zakt naar **0,35×** (band, klanten en timers vertragen, muziek gaat
   lowpass). Dat is het moment om na te denken, en dat mag ook even duren.
2. Speler kijkt naar het rek. **Hoeveel buizen komen erin?** (= 2^(a−ab), bordje toont ab)
   - **Eén buis** (ab = a): de zaag past niet op één buis. Trek aan de **hendel** (toets `D` of de hendel naar
     beneden slepen) → de muur verdubbelt. Daarna hangen er twee buizen aan het rek.
   - **Twee of meer buizen** (ab < a): klik op het **zaagicoon** op het rek (toets `S`) → het rek splitst.
3. **Verdelen**: de pakjes van het rek springen omhoog naar de **sorteertafel**. Links staat het oude rek
   (bordje eindigt op `0`), rechts het nieuwe (bordje eindigt op `1`). Per pakje: toets `0`/`←` of `1`/`→`, of slepen.
   De te lezen bit is bit nummer ab+1 (dag 1–4 pulseert die bit).
4. Rekken klappen dicht, de heftruck rijdt ze terug (2 schrijfritten). Het **vastzittende pakje probeert opnieuw**
   via zijn luik. Is er nog steeds geen plaats (de 11110-situatie), dan blijft het alarm aan en herhaal je stap 2.

**Klant** (vanaf dag 4): aan de balie verschijnt een klant met een tekstballon `01101?` en een geduldsbalk.
Speler klikt het **luik** (of `Tab`, dan bits typen). De lichtpuls volgt de buis naar het rek, de heftruck haalt het rek
naar de balie (1 leesrit) en de scanner piept groen ("gevonden") of dof ("niet in dit rek"). Bij een fout luik: nog
een rit, en de klant verliest geduld.

### 2.2 Per dag (macrolus, 2–5 min)
Dagkaart → korte dagintro (één zin en een geanimeerde demo, ≤ 6 s, skipbaar) → spelen → einde van de stroom →
**dagrapport** (sterren, munten, ritten t.o.v. optimum, herbeleving van fouten, notas-weergave) → volgende dag of opnieuw.

### 2.3 Volledige besturing
| actie | muis | toetsenbord |
|---|---|---|
| pakje sorteren | slepen van band naar luik | bits typen (`0`/`1`); na *a* bits valt het voorste pakje in dat luik. `Backspace` wist één bit |
| muur verdubbelen | hendel naar beneden slepen (of klikken) | `D` |
| rek splitsen | klik op zaagicoon op het rek | `S` (splitst het rek met het oudste vastzittende pakje) |
| verdelen bij splitsen | pakje naar links/rechts slepen | `0`/`←` = oud rek, `1`/`→` = nieuw rek (voorste pakje op de tafel) |
| klant helpen | klik op het luik | `Tab` (focus op klant), daarna bits typen |
| overloopbak (dag 7+) | pakje naar de bak slepen | `K` |
| loep (dag 5+, niet op dag 6) | `Shift` ingedrukt houden | zelfde. Markeert de eerste *a* bits op alle pakjes; **breekt de combo** |
| pauze | knop links boven | `Esc` |

Keuze: toetsenbord = bits typen. Typen ís h(r)|a uitrekenen, en bij een grotere *a* moet je meer typen, dus voel je
de groei van de pointerarray. De muis blijft volwaardig voor wie liever sleept.

---

## 3. Mapping naar de leerstof (volledig)

| notas (§2.1.1) | in het spel | waarom zo |
|---|---|---|
| record r met hashwaarde h(r), n bits, voorloopnullen (p. 6) | pakje met label van precies **n** bits, altijd met voorloopnullen (`00010`) | notas: "altijd met hetzelfde aantal n bits voorgesteld … misschien ook met nullen in het begin" |
| x\|a = eerste (meest significante) a bits (p. 6: `010011`\|3 = `010`) | luik kiezen = de **linkse** a bits lezen | het spel dwingt MSB-lezen af: de luiklabels zijn prefixen; bits worden links naar rechts ingetypt |
| pointerarray, grootte 2^a (p. 6) | sorteermuur met 2^a luiken, plaat bovenaan "a = 3 · 8 luiken" | luiken staan verticaal in volgorde `000…111`, zoals de figuren in de notas |
| emmer met capaciteit g | rek met g vakken | g staat zichtbaar als aantal vakken |
| ab = aantal geëvalueerde bits van de emmer | **bordje** op het rek met zijn label: de eerste ab bits (bv. `10`) + "ab 2" | label = gemeenschappelijk prefix van alle pakjes erin |
| 2^(a−ab) pointers naar één emmer (p. 6) | evenveel **buizen** komen samen in één verzamelbuis naar het rek, in de kleur van dat rek | gedeelde pointers zie je echt; tellen = 2^(a−ab) |
| opzoeken: vakje (h(r))\|a volgen (p. 7) | klant: klik het **luik**, niet het rek; de heftruck volgt de buis | opzoeken gebeurt via de pointerarray |
| toevoegen in volle emmer, ab = a → verdubbel (p. 7) | rek met **één** buis kan niet gezaagd worden; hendel → muur verdubbelt | notas: "voor 2 emmers hebben wij ook 2 pointers nodig" → fysiek: één buis kun je niet over twee rekken verdelen |
| verdubbelen: a := a+1, pn[i] = po[⌊i/2⌋] (p. 7) | elk luik `i` splijt in twee luiken `i0` en `i1` die **dezelfde** buis delen (Y-stuk). Rekken bewegen niet | het oude label + één nieuwe bit; beide kinderen wijzen naar wat het ouderluik aanwees |
| verdubbelen kost geen schijf-I/O (p. 9: "gebeurt in het geheugen") | verdubbelen kost **0 ritten**, wel muurhuur (zie §6) | de les "verdubbelen is niet duur in I/O, maar de array groeit" |
| ab < a → splitsen; bit ab+1 = 0 blijft in oude emmer b, = 1 naar nieuwe b′ (p. 7–8) | zaag; sorteertafel: **links = oud rek = bit 0, rechts = nieuw rek = bit 1** | links/0 en rechts/1 zijn vast, zodat het een reflex wordt |
| pointers met i\|(ab+1) = 2·(h(r)\|ab)+1 wijzen nu naar b′ (p. 8, Oef. 2) | de **onderste helft** van de buisbundel van het rek klapt om naar het nieuwe rek (automatisch, geanimeerd) | het blok is aaneengesloten: indices met volgende bit 1 = onderste helft. De animatie toont Oef. 2 |
| ab en ab′ worden ab+1 | beide bordjes krijgen er een bit bij (`1` → `10` en `11`) | — |
| daarna de nieuwe record plaatsen "volgens dezelfde regel (als dat kan…)" | vastzittend pakje valt **automatisch** opnieuw door zijn luik | het pakje volgt opnieuw de pointer; lukt dat niet, dan blijft het alarm aan |
| na herverdelen kan één emmer leeg blijven → nog eens verdubbelen (p. 8, Fig. 5, 11110) | kettingreactie: na het zagen staat er een leeg rek en het pakje zit nog vast | dag 5 is exact Figuur 2 → 4 → 5 → oplossing |
| meer dan g identieke hashwaarden → uitbreiden tot geen bits meer, methode faalt (p. 8, Oef. 4) | dag 7 "De Klonen": de hendel loopt vast op de **eindaanslag** (a = n), de buis barst | de muur kan fysiek niet breder dan n bits |
| kosten: 1 lees- + 2 schrijfoperaties per splitsing (p. 9) | **ritten** van de heftruck: L (lezen) en S (schrijven), zie §6.2 | efficiëntie wordt een zichtbare score |
| verwijderen | **bestaat niet**. Klanten nemen niets mee: ze komen hun pakje **inzien** (scan) en het blijft liggen | verwijderen staat niet in de notas |

**Rekvolgorde op het scherm.** Rekken staan in de volgorde van de pointerarray (zoals `layout()` in de JS-referentie):
rek op de hoogte van het midden van zijn luikbereik, met minimum 72 px tussenafstand. Een nieuw rek b′ verschijnt
dus altijd net **onder** het oude. Het scherm lijkt zo op Figuur 3–5, en dat helpt op het examen.

**Wat wij bewust automatiseren** (met reden): het omzetten van de pointers bij splitsen en de kopie pn[i] = po[i/2]
bij verdubbelen. Die zijn deterministisch, en de speler *ziet* ze gebeuren (buizen klappen om, luiken splijten). Ze
manueel laten doen zou 2^(a−ab−1) klikjes per split kosten zonder nieuwe beslissing. De **beslissingen** (welk luik,
hendel of zaag, welke kant) liggen allemaal bij de speler.

---

## 4. Fouten & gevolgen

**Principe:** fouten die in de notas-wereld *kunnen* gebeuren (een record in de verkeerde emmer zetten, onnodig
verdubbelen) mogen in het spel ook. Handelingen die in de datastructuur *onmogelijk* zijn, zijn fysiek onmogelijk in
de wereld (zaag op één buis, muur breder dan n bits), met een korte fysieke reactie ("klonk") en zonder tekst. Zo
leer je de regel uit het materiaal zelf en blijven de gevolgen eerlijk.

| fout | mogelijk? | wat gebeurt er in de wereld | wanneer merkt de speler het |
|---|---|---|---|
| **verkeerd luik** | ja | pakje ligt in een rek waarvan het bordje-prefix niet past ("verdwaald"). Neemt een vak in, kan dat rek sneller laten vollopen | dag 1–3: inspectielampje op het rek knippert 0,6 s amber, met een dof piepje (geen tekst). Vanaf dag 4 niets meteen: de klant vindt het later niet en wordt boos, en het dagrapport toont het |
| **verkeerde kant bij verdelen** | ja | zelfde als verdwaald (het pakje is onbereikbaar via zijn luik) | dag 1–4: amber lampje bij dichtklappen; daarna via klant of rapport |
| **onnodig verdubbelen** (geen vastzittend pakje, of het vastzittende rek heeft ab < a) | ja | de muur wordt breder: dubbel zoveel luiken, die kleiner zijn, en je moet een bit meer typen. Muurhuur aan het einde. Lost het vastzittende pakje **niet** op als ab < a was (het alarm blijft) | meteen: alarm blijft loeien; aan het einde: huur + rapport |
| **zagen terwijl ab = a** | **nee** (fysiek) | zaag zakt, raakt de enkele buis, "klonk", de zaag veert terug (0,25 s), kleine camerashake 2 px. Kost niets | meteen, zonder woorden: één buis kun je niet verdelen |
| **verdubbelen als a = n** | **nee** (fysiek) | hendel stuit op de eindaanslag, metalen dreun, muurplaat knippert "a = n" | meteen |
| **onnodig splitsen** (rek niet vol / geen vastzittend pakje erin) | ja (als ab < a) | de heftruck maakt 1 L + 2 S ritten, je krijgt een extra rek (rekhuur), meestal half leeg | ritten-teller tikt zichtbaar; rapport |
| **rek laten overlopen** (niets doen terwijl een pakje vastzit) | ja | realtime-dagen: na **12 s speltijd** (= ~34 s echte tijd door de slow-mo) barst de buis: pakje kwijt, screen shake, −1 reputatie. Het rek blijft vol | meteen, en hard |
| **pakje van de band laten vallen** | ja (realtime) | aan het einde van de band valt het in de retourbak: kwijt, −1 reputatie | meteen |
| **klant: verkeerd luik** | ja | heftruck haalt een verkeerd rek (1 L extra), de scanner piept dof, de klant verliest 25 % geduld | meteen |
| **klant laten wachten** | ja | geduld op → klant loopt boos weg, −1 reputatie | meteen |
| **kloon in een rek gooien terwijl het al g identieke heeft** (dag 7+) | ja | het pakje zit vast, en elke verdubbeling + splitsing houdt de klonen samen tot de eindaanslag; dan barst de buis | na de kettingreactie |
| **gezond pakje in de overloopbak** | ja | het pakje telt als kwijt (−1 reputatie), +€5 bakkosten | rapport |

**Geen blokkades waar de notas het algoritme toelaten.** De enige twee fysieke blokkades zijn exact de twee
onmogelijkheden uit de notas: splitsen vereist ≥ 2 pointers, en a kan niet groter worden dan n.

### 4.1 Hoe het spel achteraf leert (zonder quiz-gevoel)
- **Herbeleving in het dagrapport.** Een tijdlijn met elk event als stip (groen = goed, amber = fout). Klik op een
  amber stip: het depot van dat moment wordt opnieuw opgebouwd (snapshot uit de event-log). De zet van de speler
  speelt af in rood-transparant, daarna de **juiste zet** als groene "spookhand" die het echt doet. Onderaan staat één
  zin van de depotchef (max. 12 woorden, geen jargonmuur), bv.:
  - "`10110` begint met `101`. Luik `101`, niet `100`."
  - "Twee buizen naar dit rek → zagen volstond. Hendel was niet nodig."
  - "Bit 3 van `11100` is `1` → rechts, naar het nieuwe rek."
  - "Rek bleef leeg en het pakje zat nog vast → nog eens de hendel."
- **Oorzaakketens**: een boze klant linkt naar het event waar zijn pakje verdwaalde ("← 0:42 luik `00`").
- **Notas-weergave** (toggle in het rapport): het eindtoestand-depot getekend als Figuur 4/5 uit de notas (pointerarray
  met binaire indices, pijlen, emmers met hashwaarden, ab-kolom). Zo herken je het op het examen.
- **Spiekbrief** (in pauzemenu, altijd beschikbaar): 4 pictogrammen, geen tekstmuur: *eerste a bits → luik*;
  *vol + 1 buis → hendel*; *vol + ≥ 2 buizen → zaag*; *bit ab+1: 0 links / 1 rechts*.

---

## 5. Campagne

### 5.1 Beslissingen
**Realtime vs. rustig.** Dag 1–3 en 6 zijn **rustig**: de band stopt als het voorste pakje het einde bereikt, er is
geen burst-timer en geen reputatieverlies door tijd. Dag 4, 5, 7 en endless zijn **realtime**. Motivatie: wie een regel
leert, heeft zijn werkgeheugen nodig voor die regel (cognitieve belasting). Tijdsdruk komt pas als de regels gekend zijn,
en dan vooral op het *bits lezen*, dat automatisch moet worden. De algoritmische beslissing (hendel/zaag/verdelen) krijgt
ook in realtime altijd **slow-mo 0,35×**: de druk blijft voelbaar, maar wie nadenkt wordt niet gestraft. Dag 6
(Oefening 5) is rustig omdat het een examenoefening is: daar gaat het om correctheid.

**Bits-markering die afbouwt** (`DaySpec.bit_hint`):
| niveau | dagen | op pakjes | bij splitsen |
|---|---|---|---|
| `FULL` | 1–2 | bits in positiekleur + accolade onder de eerste *a* bits + ghost-tekst van het luik (`→ 101`) | bit ab+1 pulseert (schaal 1.25, 0.6 s loop) |
| `COLORS` | 3–4 | alleen positiekleuren, geen accolade | bit ab+1 pulseert |
| `NONE` | 5–7, endless | alle bits wit; loep (`Shift`) toont `FULL`-markering maar breekt de combo. Dag 6: geen loep | geen markering |
Motivatie: de positiekleur koppelt "derde bit" aan "derde teken van het luiklabel". De accolade laat zien hoeveel bits
tellen, en die hulp verdwijnt als *a* gaat variëren. De loep blijft beschikbaar als vangnet (je hoeft niet vast te
zitten), maar wie snel en zonder hulp leest, wordt beloond met de combo.

**Bitkleuren** (functionele eis, waarden aanpasbaar door ART.md): pos 1 `#FF6B6B` koraal, 2 `#FFC145` amber,
3 `#3DDC97` mint, 4 `#4CC9F0` cyaan, 5 `#B892FF` lila, 6 `#FF5DA2` roze. Daarnaast heeft elk cijfer een vaste
kolombreedte en staat er 4 px extra ruimte tussen posities, zodat het ook zonder kleur leesbaar blijft (kleurenblind).

**Tutorial-stijl**: geen tekstvakken. Elke nieuwe mechaniek krijgt (1) een **spookhand** die de handeling één keer
voordoet, (2) een **pulserende affordance** (alleen het ding dat je nu moet gebruiken gloeit) en (3) hoogstens één
korte regel van de depotchef (≤ 8 woorden) in een ballon die zelf verdwijnt. Hints komen alleen bij de **eerste**
keer, en enkel als de speler 4 s niets doet (`TutorialHint.idle_delay`).

### 5.2 Dagen
Notatie: sleutels zijn n-bit hashwaarden in volgorde van aankomst. Starttoestand = rekken in pointerarray-volgorde,
`label{inhoud}` (label = eerste ab bits). Optimum L/S = ritten bij perfect spel (zie §6.2). Alles gesimuleerd.

#### Dag 1 — "Eerste werkdag" (één bit lezen)
- **Doel:** het eerste bit lezen en slepen/typen. Nieuwe mechaniek: band, luik, rek.
- **Config:** n = 5, g = 3, a = 1, start: `0{}`, `1{}`. Modus RUSTIG, `bit_hint FULL`.
- **Sleutels:** `00110 10101 01011 11000 00011 10010` (3 + 3, geen overloop). Spawn elke 2,5 s (band stopt als vol).
- **Introductie:** spookhand sleept `00110` naar luik `0`; de 0 is koraal, net als het label van luik `0`. Chef:
  "Eerste bit. Dat is het luik." Het tweede pakje: luik `1` pulseert, enkel bij 4 s idle.
- **Sterren:** ★ alle pakjes geplaatst · ★★ 0 verdwaald · ★★★ binnen 40 s.
- **Eind:** a = 1; `0{00110,01011,00011}` `1{10101,11000,10010}`; L 6 / S 6.

#### Dag 2 — "De muur schuift" (eerste verdubbeling = Figuur 2 → 3 → 4)
- **Doel:** vol rek met één buis → hendel; daarna verdelen. Nieuw: alarm, slow-mo, hendel, sorteertafel.
- **Config:** n = 5, g = 2, a = 1, start leeg. RUSTIG, `FULL`.
- **Sleutels:** `00100 01111 10010 11100 11111 10111`. (De eerste vier = Figuur 2; `11111` → Figuur 3 en 4.)
- **Introductie:** `11111` zit vast. Alleen de hendel gloeit. Probeert de speler eerst te zagen: "klonk" (het lesmoment:
  één buis, kan niet). Chef bij idle: "Eén buis. Maak er twee." Na het verdubbelen gloeit de zaag: "Nu kan het."
  Op de sorteertafel pulseert bit 2: `10010` → links, `11100` → rechts (spookhand doet de eerste).
- **Sterren:** ★ uitgespeeld · ★★ 0 fouten (verdwaald, verkeerde kant, onnodig) · ★★★ ritten = optimum (L 6 / S 7).
- **Eind:** a = 2; `0{00100,01111}` (ab 1, 2 buizen) `10{10010,10111}` `11{11100,11111}`. Dit is Figuur 4 plus `10111`.

#### Dag 3 — "Bijbouwen" (splitsen zonder verdubbelen)
- **Doel:** zien dat een rek met ≥ 2 buizen gezaagd kan worden zonder de muur te raken. Nieuw: buizen tellen.
- **Config:** n = 5, g = 2, a = 3, start: `0{00100,01111}` (ab 1, 4 buizen) `10{10010}` (2 buizen) `110{11000}`
  `111{11100}`. RUSTIG, `COLORS`.
- **Sleutels:** `00110 10111 10000 01001 00010 11001 01110 11111`. Vier splitsingen, **geen enkele verdubbeling** nodig.
  Bij `00010` blijft het oude rek leeg en past het pakje toch (een voorproefje van dag 5).
- **Introductie:** bij de eerste vastloper gloeien de **4 buizen** van het rek een voor een op (tel-animatie 4 × 0,15 s)
  en dan de zaag. Geen woorden. De hendel blijft bruikbaar (een fout moet mogelijk zijn).
- **Sterren:** ★ · ★★ 0 fouten · ★★★ 0 verdubbelingen en ritten = optimum (L 8 / S 12).
- **Eind:** a = 3, 8 rekken met ab = 3: `000{00010}` `001{00100,00110}` `010{01001}` `011{01111,01110}`
  `100{10010,10000}` `101{10111}` `110{11000,11001}` `111{11100,11111}`.

#### Dag 4 — "Klanten aan de balie" (opzoeken + realtime)
- **Doel:** opzoeken via het luik, onder tijdsdruk. Nieuw: balie, realtime band, reputatie.
- **Config:** n = 5, g = 2, a = 2, start: `0{00011}` (ab 1) `10{10100}` `11{11010}`. REALTIME, `COLORS`.
  Spawn elke 4,0 s; band-looptijd 14 s; burst-timer 12 s speltijd; reputatie 5.
- **Sleutels:** `01101 10001 00110 11100 10110 01000 00000 11111 10011 01011 00101 11000` (1 verdubbeling, 5 splitsingen).
- **Klanten** (t = seconden sinds start, geduld 15 s): 20 s `01101`, 32 s `10001`, 44 s `10110`, 56 s `00000`, 68 s `11111`.
- **Introductie:** eerste klant: spookhand klikt het **luik** (niet het rek); de puls volgt de buis en de heftruck
  rijdt. Chef: "Zoeken = zelfde luik." Klikt de speler meteen op een rek: dat rek wiebelt maar doet niets (rekken
  zijn niet klikbaar voor klanten, je moet langs de pointerarray).
- **Sterren:** ★ uitgespeeld met reputatie > 0 · ★★ 0 fouten en alle klanten bediend · ★★★ ritten ≤ optimum
  (L 12 + 5 klanten = **17** / S 17).
- **Eind:** a = 3, 8 rekken ab 3: `000{00011,00000}` `001{00110,00101}` `010{01000,01011}` `011{01101}`
  `100{10001,10011}` `101{10100,10110}` `110{11010,11000}` `111{11100,11111}`.

#### Dag 5 — "De 11110-storm" (lege emmer → nog eens verdubbelen; Figuur 4 → 5 → verder)
- **Doel:** de kettingreactie uit de notas beleven. Nieuw: het pakje zit **nog steeds** vast na een correcte zaag.
- **Config:** n = 5, g = 2, a = 2, start = **Figuur 4**: `0{00100,01111}` (ab 1) `10{10010}` `11{11100,11111}`.
  REALTIME, `NONE` (loep mag). Spawn 3,5 s; klanten elke 10 s vanaf 25 s (willekeurig opgeslagen pakje, seed 5,
  geduld 14 s).
- **Sleutels:** `11110 00110 10011 01010 11010 10100 00001 01100 10111 11001`.
  - `11110`: rek `11` vol, 1 buis → hendel (a = 3) → zaag op bit 3: `11100` en `11111` hebben allebei bit 3 = 1 →
    **oude rek `110` blijft leeg** (= Figuur 5), pakje zit nog vast → hendel (a = 4) → zaag op bit 4: `11100` links,
    `11111` rechts → `11110` valt in `1111`.
  - `11010` valt later in het lege rek `110`: het lege rek was geen verspilling.
- **Introductie:** het spel begint meteen met `11110` (de storm). Na de eerste zaag: dramatische pauze, het lege rek
  "galmt" (hol geluid), het alarm blijft draaien. Pas na 4 s idle gloeit de hendel. Geen woorden. Dit is het
  aha-moment en dat mag de speler zelf vinden.
- **Sterren:** ★ · ★★ 0 fouten · ★★★ ritten ≤ optimum (L 10 + klanten / S 16).
- **Eind:** a = 4; `000{00001}` `001{00100,00110}` `010{01010}` `011{01111,01100}` `100{10010,10011}`
  `101{10100,10111}` `110{11010,11001}` (ab 3, 2 buizen) `1110{11100}` `1111{11111,11110}` (ab 4).

#### Dag 6 — "Oefening 5" (de examenopgave)
- **Doel:** Oefening 5 uit de notas (p. 10) foutloos spelen. Nieuw: pakjes tonen sleutel én hashwaarde.
- **Config:** n = 5, g = 2, a = 1 ("lege tabel met twee emmers in het begin"), start `0{}` `1{}`. RUSTIG, `NONE`,
  **geen loep**. Pakjes tonen groot `#45` en eronder `h = 10001`.
- **Sleutels (notas):** 3 → `00000`, 7 → `11111`, 12 → `01001`, 45 → `10001`, 44 → `00010`, 1 → `00001`.
  - 44 (`00010`): rek `0` vol, ab = a = 1 → verdubbel (a = 2) → zaag: `00000` blijft, `01001` naar `01` → plaats in `00`.
  - 1 (`00001`): rek `00` {00000,00010} vol, ab = a = 2 → verdubbel (a = 3) → zaag op bit 3: allebei 0 → **nieuw rek
    `001` blijft leeg**, nog vast → verdubbel (a = 4) → zaag op bit 4: `00000` blijft, `00010` naar `0001` → plaats `00001` in `0000`.
- **Introductie:** titelkaart "Oefening 5 — lesnotas p. 10". Geen hints. Na afloop opent het rapport standaard in
  **notas-weergave**, zodat je de tekening van je examenantwoord ziet.
- **Sterren:** ★ uitgespeeld · ★★ eindtoestand correct · ★★★ 0 fouten (geen enkele herbeleving-stip amber).
- **Eind (= oplossing Oef. 5):** a = 4, 5 emmers: `0000{00000,00001}` (ab 4) `0001{00010}` (ab 4) `001{}` (ab 3,
  leeg) `01{01001}` (ab 2) `1{11111,10001}` (ab 1, 8 pointers). L 6 / S 9 (3 splitsingen, 3 verdubbelingen).

#### Dag 7 — "De Klonen" (identieke hashwaarden → het algoritme faalt; Oef. 4)
Twee shifts.
- **Ochtend (beleven):** n = 5, g = 2, a = 1, leeg. RUSTIG. Sleutels `01001 10110 10110 10110`. De derde `10110`
  zit vast. Bij elke zaag gaan beide klonen naar dezelfde kant. Na twee cycli verschijnt de knop **"Doorspoelen ⏩"**
  (bot doet `correct_move` op 3× snelheid): a = 2, 3, 4, 5, de hendel ramt de eindaanslag, de buis barst, het licht
  valt uit. Chef: "Geen bits meer. Dit lost hendel noch zaag op." Eind ochtend: a = 5, 6 rekken, waarvan 4 leeg
  (verspilling, zichtbaar). Geen sterreneffect, wel verplicht.
- **Middag (herkennen):** reset n = 5, g = 2, a = 1, leeg. REALTIME (spawn 4 s), `NONE`. Nieuw: **overloopbak**
  (`K`). Sleutels: `11001 00111 11001 01100 10010 11001* 00111 11010 00000 00111* 01110` (* = derde kloon → bak).
  Let op: `11010` veroorzaakt toch een kettingreactie (2× verdubbelen) omdat het dicht bij de klonen `11001` ligt.
  Dat is correct volgens het algoritme en geen fout.
- **Ontwerpkeuze (geen notas-stof):** de notas zeggen alleen dat de methode faalt; Oef. 4 vraagt "hoe kan je het
  probleem oplossen?" zonder antwoord. De overloopbak is een **spelmiddel** om het *herkennen* te belonen. In het
  rapport staat: "Hoe je dit echt oplost: Oefening 4, zelf bedenken." We presenteren de bak niet als de oplossing.
- **Sterren:** ★ · ★★ 0 fouten (beide klonen in de bak, niets anders in de bak) · ★★★ ritten = optimum (L 9 / S 14).
- **Eind middag:** a = 4; `000{00000}` `001{00111,00111}` `01{01100,01110}` `10{10010}` `1100{11001,11001}`
  `1101{11010}` `111{}` (ab 3, leeg); bak = 2 pakjes.

#### ∞ Endless — "Piekdag" (ontgrendeld na dag 5 met ≥ 1 ster)
- n = 6, g = 4, a = 1, leeg, REALTIME, `NONE` (loep mag). Reputatie 5, geen herstel behalve +1 per 25 correcte
  pakjes op rij (max 5).
- **Generator** (`KeyStream`, seed = tijd): uniform 6-bit; tot 180 s wordt herrold als het ≥ g identieke zou geven.
  Vanaf 180 s komt elke 40 s een kloonburst: 1 waarde die al g keer in één rek ligt, nog 1–2 keer.
- **Tempo** (niveau L = ⌊t/30 s⌋): spawn-interval = max(1,3; 4,0 − 0,25·L) s; band-looptijd = max(8; 14 − 0,5·L) s;
  klanten elk max(5; 11 − 0,5·L) s vanaf 30 s, geduld max(8; 15 − 0,5·L) s.
- **Einde** bij reputatie 0. Highscore = munten; lokaal top-10 met datum. Muurlayout: a ≤ 5 één kolom; a = 6 twee
  kolommen van 32 (de muur verbreedt letterlijk). a = n = 6 = eindaanslag.

---

## 6. Economie & scoring

### 6.1 Valuta en meters
- **Munten (€)**: score en highscore. **Reputatie** (5 harten): op 0 sluit het depot, de dag is mislukt.
- **Ritten L/S**: efficiëntiemaat, altijd zichtbaar (heftruck-icoon + twee tellers + optimum in het grijs).

### 6.2 Rittenmodel (gebaseerd op het notasmodel: "elk vakje in één stap lezen en in één stap schrijven")
| handeling | L | S | toelichting |
|---|---|---|---|
| pakje valt in een rek (ook als het vastloopt) | 1 | — | emmer lezen |
| invoeging afgerond zonder split | — | 1 | emmer terugschrijven |
| invoeging afgerond met k splitsingen | — | 1 + k | elk aangeraakt rek één keer schrijven. k = 1 geeft **1 L + 2 S** (p. 9) |
| onnodige splitsing (geen invoeging) | 1 | 2 | — |
| verdubbelen | 0 | 0 | "gebeurt in het geheugen" (p. 9) |
| klant: rek ophalen (per poging) | 1 | — | opzoeken = 1 leesoperatie |
| pakje naar overloopbak / kwijt | 0 | 0 | — |
De conventie voor kettingen (11110: 1 L + 3 S) is onze eigen veralgemening. De notas noemen alleen het geval met één
splitsing. Zie twijfels onderaan.

### 6.3 Munten
| event | € |
|---|---|
| pakje correct geplaatst | +10 × combo |
| klant correct geholpen | +15 + fooi (0–10, lineair met resterend geduld) |
| elke rit (L of S) | −1 |
| pakje kwijt (band, burst, gezond pakje in bak) | −5 en −1 ♥ |
| klant boos weg | −1 ♥ |
| kloon correct in bak | +5 (herkenning) |
| einde dag: **muurhuur** | −0,5 per luik (2^a) |
| einde dag: **rekhuur** | −1 per rek |
Een leeg rek dat het algoritme legitiem oplevert (Fig. 5) kost wel rekhuur, maar de ★★★-norm vergelijkt met het
optimum, zodat correct spel nooit gestraft wordt.

### 6.4 Combo
- Opeenvolgende **correcte** plaatsingen met elk < 3,0 s (echte tijd) tussen → combo ×1 … ×5.
- Breekt bij: verdwaald pakje, loep gebruikt, 3 s niets geplaatst (de tijd tijdens een alarm telt niet, daar pauzeert
  de combo), pakje kwijt.
- ×5 bereikt → "DASH!": hitstop 80 ms, 0,4 s slow-mo 0,5× met chromatische schok, muziek-stinger. Combo blijft ×5.

### 6.5 Sterren
Per dag 3 sterren, gedefinieerd in §5.2. Algemeen patroon: ★ uitspelen (reputatie > 0), ★★ **0 algoritmische fouten**
(verdict ≠ OK in de log, behalve als de juiste actie zelf faalt), ★★★ efficiëntie (ritten ≤ optimum, of tijd/klanten).
Het optimum berekent de core door de sleutelreeks met `correct_move` te spelen (`Days.optimum(spec)`).

---

## 7. Schermen & UI-flow

```
Titel ──► Dagenkaart ──► Dagintro (≤6 s) ──► Spel ──► Dagrapport ──► Dagenkaart / volgende dag
  │            │                               │ Esc
  │            └──► Endless (slot tot dag 5)   └──► Pauze (Verder · Opnieuw · Spiekbrief · Instellingen · Kaart)
  └──► Instellingen (volume muziek/sfx, schermschok aan/uit, volledig scherm)
```
- **Titel:** logo "HASH & DASH" (letters vallen als pakjes, squash bij landen). Op de achtergrond speelt een bot endless
  (attract-mode, gedimd). Knoppen: Spelen, Eindeloos (slot-icoon), Instellingen, Stoppen.
- **Dagenkaart:** een stadskaart met 7 depots langs een weg; elk depot toont zijn sterren en een één-woord-pictogram
  van zijn mechaniek (luik, hendel, zaag, balie, storm, boek, klonen); ∞ als laatste. De volgende dag gaat open met ≥ 1 ster.
- **Dagrapport:** sterren klappen één voor één in (0,35 s, overshoot), tellers rollen op. Daarna: ritten vs. optimum
  (balkjes), munten-uitsplitsing, **herbeleving-tijdlijn**, knop "Notas-weergave", knoppen Volgende / Opnieuw / Kaart.
- **Endless-einde:** rapport + highscorelijst; nieuw record = confetti + naam (3 letters).

### 7.1 HUD-layout 1920×1080
```
x: 0        120       380 400              900  960                 1500 1560               1920
y=0  ┌──────────────────────────────────────────────────────────────────────────────────────────┐
     │[II] DAG 5 · De 11110-storm     ♥♥♥♥♡     € 245     🚚 L 9 S 12 (opt 10/16)     COMBO ×3 │ HUD 0–64
y=72 ├──────────────────────────────────────────────────────────────────────────────────────────┤
     │ RETOUR◄─[11010]──[01010]──────[10011]──────────────────────────────────◄ instroom         │ BAND 80–220
     │  bak                     typbuffer: 1 0 _ _   (boven voorste pakje)                         │ pakjes 120×80
y=230├──────────┬──────────────────────────────────┬───────────────────────────┬─────────────────┤
     │ ┌HENDEL┐ │  a = 4 · 16 luiken               │                           │   BALIE         │
     │ │  ▼   │ │ ┌────┐                            │ ┌bordje 000·ab3┐          │  ┌─────────┐    │
     │ └──────┘ │ │0000│═══╗                        │ │[00001][  ·  ]│          │  │ klant 🙂 │    │
     │          │ │0001│═══╩═══════════════════════►│ └──────────────┘          │  │ "01010?"│    │
     │          │ │0010│═══╗                        │ ┌bordje 001·ab3┐          │  │ ████░░  │    │
     │          │ │0011│═══╩═══════════════════════►│ │[00100][00110]│          │  └─────────┘    │
     │          │ │ …  │                            │ └──────────────┘          │  wachtrij: 2    │
     │          │ │1110│═══════════════════════════►│ ┌1110·ab4┐ …              │                 │
     │          │ │1111│═══════════════════════════►│ ┌1111·ab4┐ ⚠ zwaailicht  │                 │
     │ ┌BAK─K┐  │ └────┘     MUUR x 400–560          │  REKKEN x 960–1500        │                 │
y=1040└──────────┴──────────────────────────────────┴───────────────────────────┴─────────────────┘
```
- **Sorteertafel** (bij splitsen): verschijnt als paneel 700×260 boven het gesplitste rek (geklemd binnen
  y 240–1040), links "OUD · …0", rechts "NIEUW · …1", met de pakjes in het midden in een rij.
- **Muur**: kolom y 260–1040 (780 px). Luikhoogte = 780 / 2^a (a = 1: 390 → max 120 px, a = 4: 48,75 px, a = 5:
  24 px). Bij a = 6 twee kolommen (x 400–560 en 580–740).
- **Lettergroottes** (mono, vet, ART.md kiest het font; tabular cijfers verplicht):
  pakje op de band **40 px**; pakje in rek 26 px; luiklabel 28 px (a ≤ 4), 18 px (a = 5–6); rekbordje 26 px;
  klantballon 36 px; HUD 28 px; bits altijd met positiekleur (behalve `NONE`: wit #F2F2F2 op donker).
  Minimaal contrast 4.5:1. Geen bitlabel kleiner dan 18 px.
- **Hover/focus**: hover over een luik licht ook zijn buis en rek op (en omgekeerd: hover op een rek licht al zijn
  luiken op). Dat is het belangrijkste leermiddel voor 2^(a−ab).

---

## 8. Juice-lijst (timing / easing)
| # | moment | effect |
|---|---|---|
| 1 | pakje spawnt op band | valt van boven 0,25 s `EASE_IN`, landt met squash (1.2, 0.8) → (1,1) in 0,12 s `TRANS_BACK` |
| 2 | band | textuur scrolt; rolletjes draaien; snelheid hoorbaar als zacht gezoem (pitch ∝ snelheid) |
| 3 | pakje oppakken | scale 1.08, schaduw-offset 6 → 14 px in 0,08 s, lichte rotatie ±3° volgend op muisvelocity |
| 4 | slepen | pakje volgt de muis met lerp 0,35/frame (zwierig, niet stijf); boven een luik: luik "ademt" (scale 1.05) |
| 5 | bits typen | elk getypt bit springt in de typbuffer (pop 0,1 s); de matchende luiken krimpen tot één (niet-matchende dimmen naar 30 %) |
| 6 | luik opent | klepje roteert 0 → 80° in 0,10 s `TRANS_QUAD EASE_OUT`, valt terug met 0,2 s bounce |
| 7 | opzuigen | pakje stretch (0.7, 1.3) richting buis, 0,12 s, dan verdwijnt het in de buis |
| 8 | buis-puls | lichtvlek reist luik → rek in 0,35 s langs de bezier; gedeelde verzamelbuis licht helemaal op |
| 9 | aankomst in rek | pakje schuift in vak 0,15 s `TRANS_BACK`, rek wiebelt 2° 0,2 s, stofwolkje (6 partikels) |
| 10 | munten | +10 tekst stijgt 40 px en vervaagt 0,6 s; 3 muntsprites vliegen in een boog naar de HUD-teller, die bij aankomst pulst |
| 11 | rek bijna vol (g−1) | bordje krijgt een amber rand, subtiel (geen geluid) |
| 12 | vastloper | buis zwelt op (scale-y 1.3 sinus 4 Hz), rek bolt (1.06), oranje zwaailicht draait, rood vignet 15 % in 0,3 s |
| 13 | slow-mo in | `Engine.time_scale`-gelijk (alleen wereldnodes) naar 0,35 in 0,25 s `EASE_OUT`; muziek lowpass 800 Hz, pitch −2 st |
| 14 | zaag op één buis ("klonk") | zaag zakt 0,12 s, raakt, veert terug 0,25 s `TRANS_ELASTIC`, vonkjes (8), shake 2 px 0,1 s |
| 15 | hendel | hendel volgt de muis met weerstand; voorbij 70 % klikt hij door (snap 0,06 s), camera-punch 1.02 zoom |
| 16 | **muur verdubbelt** | muur schuift 24 px naar links en terug (0,15 s); elk luik splijt in twee helften van boven naar onder, staggered 30 ms/luik, elk 0,35 s `TRANS_BACK`; nieuwe bit verschijnt achteraan het label met pop in kleur van positie a+1; buizen krijgen een Y-stuk (lijn groeit 0,25 s) |
| 17 | verdubbeling = 0 ritten | heftruck-icoon schudt "nee" en "0" floater naast de rittenteller (leert: geen I/O) |
| 18 | eindaanslag (a = n) | hendel stuit, metalen dreun, shake 6 px 0,25 s, muurplaat knippert rood 3× |
| 19 | **zagen** | zaagblad draait in (0,2 s), lijn over het rek, rek splijt: onderste helft schuift 72 px naar beneden 0,35 s `TRANS_CUBIC`, nieuw bordje klapt open |
| 20 | pointers omzetten | onderste helft van de buisbundel losgemaakt (klik), zwaait naar het nieuwe rek in 0,45 s `TRANS_ELASTIC EASE_OUT`, staggered 40 ms per buis; elke buis licht op bij het vastklikken |
| 21 | sorteertafel | pakjes springen uit het rek in een boog (0,3 s, staggered 60 ms); te lezen bit pulseert |
| 22 | pakje links/rechts | snelle zwiep 0,15 s met motion-trail; bij aankomst squash; kant-geluid hoog (1) of laag (0) |
| 23 | split klaar | rekken klappen dicht (0,15 s), heftruck rijdt beide naar hun plek (0,4 s), S-teller +2 met tik per rit |
| 24 | herpoging | vastzittend pakje "schiet los" uit de buis (pop + luchtstoot), opnieuw buis-puls (#8); alarm stopt, slow-mo uit 0,3 s |
| 25 | kettingreactie | als het pakje na een zaag nog vastzit: alarm gaat een toon hoger, vignet +10 %, het lege rek galmt (holle echo, stof daalt) |
| 26 | verdwaald (dag 1–3) | inspectielampje boven het rek knippert amber 2× (0,3 s), dof piepje; verder niets |
| 27 | burst / kwijt | buis barst: 20 kartonsnippers, pakje tuimelt uit beeld met rotatie, shake 10 px 0,3 s (decay), hart breekt in HUD (0,4 s) |
| 28 | pakje van band | kantelt over de rand, valt in retourbak met plof, bak wiebelt; shake 4 px |
| 29 | klant komt | schuift in 0,3 s `TRANS_BACK`, ballon pop; geduldsbalk wordt bij < 30 % rood en de klant tikt met zijn voet |
| 30 | heftruck voor klant | heftruck rijdt rek → balie en terug (0,5 s elk), scannerstraal 0,2 s; groen = konfetti 10 + "ding", dof = klant schudt hoofd |
| 31 | combo | teller pop per stap (scale 1.3 → 1); ×5 "DASH!": hitstop 80 ms, slow-mo 0,5× 0,4 s, radial blur, achtergrond licht op op de beat |
| 32 | sterren rapport | elke ster vliegt in vanaf boven, overshoot 1.3 → 1 (0,35 s), partikelburst, toonhoogte stijgt per ster |
| 33 | idle | rekken ademen zacht (0,5 %), lampjes knipperen af en toe; het depot leeft |
| 34 | hover luik ↔ rek | buis-highlight 0,1 s fade; alle luiken van een rek lichten op bij hover op rek |
Instelling "schermschok" schaalt alle shakes (0 / 50 / 100 %). Slow-mo geldt alleen voor wereld-nodes, niet voor UI.

---

## 9. Audio
**Muziekgevoel:** speels-funky, 100 BPM, lo-fi synth + slap bass + houten percussie ("magazijn met groove").
Adaptief in 3 lagen (zelfde tonaliteit, synchroon gestart): **basis** (altijd), **drukte** (percussie, aan zodra de band
> 50 % gevuld is of klanten wachten), **spanning** (zinderende pad, aan tijdens een alarm; basis gaat lowpass).
Rustige dagen: alleen basis + zachte drukte. Titel: rustige versie. Rapport: korte jingle (3 varianten per sterrental).
Alles CC0 of procedureel (sfxr-achtig) → `assets/CREDITS.md`.

| event | geluid |
|---|---|
| pakje landt op band | doffe kartonplof, licht gerandomiseerde pitch |
| oppakken / loslaten | korte kartonwrijving / tik |
| bit getypt | mechanische toets-klik; toonhoogte per bitpositie oplopend |
| luik open | metalen klep-klak |
| buis-puls | pneumatische "fwoemp" (stereo-pan volgt de buis) |
| aankomst in rek | houten tok + kleine bel |
| munten | muntjes-tinkel (2–3 lagen) |
| combo-stap / DASH | stijgende pluk-noot / whoosh + gitaar-stinger |
| rek bijna vol | — (bewust stil) |
| vastloper / alarm | zwaailicht-sirene (lus, zacht), buis-kreun |
| slow-mo in/uit | tape-stop / tape-start |
| hendel | ratel + zware klik; muur: hydraulische schuif + per luik een klik (staggered) |
| eindaanslag | metalen dreun + kort feedback-gekraak |
| zaag | cirkelzaag-zing (0,3 s) |
| zaag op één buis | "klonk" + boing |
| buizen omzetten | snelle klik-klik-klik (één per buis) |
| verdelen 0 / 1 | lage zwiep / hoge zwiep |
| heftruck rit | elektrische zoem + piep bij achteruit; elke rit een teller-tik |
| leeg rek na zaag | holle galm |
| verdwaald (dag 1–3) | dof piepje |
| burst / kwijt | knal + scheurend karton + hart-breek |
| klant komt / blij / boos | deurbel / "ding" + kassa / gefrustreerde zucht |
| sterren | drie stijgende klokjes |

---

## 10. Interface-contract core ↔ gameplay

Alles in `scripts/core/` is **puur** (`RefCounted`/static, geen nodes, geen `Engine`-calls), deterministisch en
headless testbaar. Gameplay luistert naar signalen en roept methodes aan. Hashwaarden zijn `int`. Bitposities zijn
**1-gebaseerd vanaf de meest significante bit** (zoals de notas: "bit nummer ab+1").

### 10.1 `hash_util.gd`
```gdscript
class_name HashUtil
static func bits(x: int, w: int) -> String          # bits(2,5) == "00010"; w<=0 -> ""
static func prefix(x: int, n: int, k: int) -> int   # x|k ; prefix(0b010011,6,3) == 2
static func bit_at(x: int, n: int, pos: int) -> int # pos 1..n vanaf MSB
static func from_bits(s: String) -> int
```

### 10.2 `parcel.gd`, `bucket.gd`
```gdscript
class_name Parcel extends RefCounted
var id: int; var hv: int; var key_label: String = ""   # "45" op dag 6
var is_clone: bool = false
class_name Bucket extends RefCounted
var id: int; var ab: int; var parcels: Array[Parcel] = []
func is_full(g: int) -> bool
```

### 10.3 `ext_hash_model.gd`
```gdscript
class_name ExtHashModel extends RefCounted
enum Verdict { OK, MISROUTED, UNNEEDED_DOUBLE, UNNEEDED_SPLIT, WRONG_SIDE, WRONG_LOOKUP, UNNEEDED_DUMP, LOST }
enum Drop { PLACED, BLOCKED }

signal parcel_placed(parcel: Parcel, bucket_id: int, dir_index: int, verdict: int)  # verdict OK of MISROUTED
signal parcel_blocked(parcel: Parcel, bucket_id: int, dir_index: int)
signal still_blocked(parcel: Parcel, bucket_id: int)          # herpoging na split mislukt (kettingreactie)
signal directory_doubled(old_a: int, new_a: int, verdict: int) # nieuwe dir[i] == oude dir[i >> 1]
signal double_refused()                                        # a == n (eindaanslag)
signal split_started(bucket_id: int, new_bucket_id: int, bit_pos: int, changed: PackedInt32Array, to_sort: Array[Parcel], verdict: int)
signal split_refused(bucket_id: int)                           # ab == a ("klonk")
signal parcel_assigned(parcel: Parcel, side: int, verdict: int) # side 0 = oud, 1 = nieuw
signal split_finished(bucket_id: int, new_bucket_id: int)
signal lookup_done(dir_index: int, bucket_id: int, wanted_hv: int, found: bool, verdict: int)
signal parcel_lost(parcel: Parcel, reason: String)             # "belt" | "burst" | "dump_healthy"
signal parcel_dumped(parcel: Parcel, verdict: int)             # overloopbak
signal io_changed(reads: int, writes: int)
signal event_logged(entry: Dictionary)

var n: int; var g: int; var a: int
var buckets: Array[Bucket]          # index == bucket id; ids worden nooit hergebruikt
var dir: PackedInt32Array           # grootte 2^a, waarden = bucket id
var blocked: Array[Dictionary]      # FIFO: {parcel, bucket_id, via_index}
var splitting: Dictionary           # {} of {bucket_id, new_bucket_id, bit_pos, pending: Array[Parcel]}
var reads: int; var writes: int
var now: float                      # gameplay zet dit elke frame (tijdstempel voor de log)
var log: EventLog

func setup(n_: int, g_: int, a_: int) -> void                 # 2^a lege emmers, ab = a
func load_layout(spec: Array) -> void   # [{"label":"0","hvs":["00100","01111"]}, ...] in dir-volgorde; zet ab = len(label)
func index_of(hv: int) -> int                                  # prefix(hv, n, a)
func bucket_at(dir_index: int) -> Bucket
func span(bucket_id: int) -> int                               # 2^(a-ab)
func dir_range(bucket_id: int) -> Vector2i                     # (start, count), aaneengesloten
func label_of(bucket_id: int) -> String                        # eerste ab bits
func layout() -> Array[Dictionary]                             # [{bucket_id, start, span, ab, label}] in dir-volgorde
func is_misplaced(parcel: Parcel, bucket_id: int) -> bool

func drop(parcel: Parcel, dir_index: int) -> Dictionary
	# -> {status: Drop, bucket_id, verdict, correct_index}. L += 1. Bij PLACED: S += 1.
	# Tijdens een split naar het splitsende rek: altijd BLOCKED.
func can_double() -> bool                                      # a < n
func double_dir() -> bool        # false + double_refused als a == n; remapt blocked.via_index = (via<<1)|bit_at(hv,n,a)
func can_split(bucket_id: int) -> bool                         # ab < a en geen andere split bezig
func begin_split(bucket_id: int) -> bool  # maakt b', zet pointers om, ab=ab'=ab+1, haalt parcels eruit -> splitting.pending
func assign(parcel_id: int, side: int) -> int                  # verdict; als pending leeg -> finish_split()
func auto_assign_rest() -> void                                # correct verdelen (bots, doorspoelen)
func finish_split() -> void      # schrijft ritten, daarna retry_blocked()
func retry_blocked() -> void     # FIFO: plaats via dir[via_index] als er ruimte is, anders still_blocked
func lookup(dir_index: int, wanted_hv: int) -> Dictionary      # {bucket_id, found, verdict}; L += 1
func dump(parcel: Parcel) -> int                               # overloopbak; uit blocked of van band
func lose(parcel: Parcel, reason: String) -> void

# --- orakel ---
func correct_move(front: Parcel = null) -> Dictionary
	# prioriteit: split bezig -> {action:"assign", parcel_id, side}
	#             blocked -> {action:"dump"} als >= g identieke hv in dat rek
	#                        {action:"split", bucket_id} als ab < a
	#                        {action:"double"} als a < n, anders {action:"fail"}
	#             front   -> {action:"drop", dir_index}
	#             anders  -> {action:"none"}
func correct_side(parcel: Parcel) -> int                       # bit_at(hv, n, ab_oud + 1)
func simulate_insert(hv: int) -> Array[Dictionary]             # niet-muterend; stappen {act:"place"|"double"|"split"|"fail", idx, a, bucket_id, ab, stay, move, changed}
func invariants() -> PackedStringArray                         # leeg = ok (zoals JS invariants(), verdwaalde pakjes apart gemeld)
func snapshot() -> Dictionary                                  # volledige toestand, JSON-serialiseerbaar
func restore(d: Dictionary) -> void
```
**Verdict-regels** (bepaald *voor* de actie wordt toegepast, op basis van `correct_move()`):
`double_dir` = OK enkel als het oudste vastzittende rek vol is met ab == a; anders UNNEEDED_DOUBLE.
`begin_split(b)` = OK enkel als b een vastzittend pakje heeft en ab < a; anders UNNEEDED_SPLIT (L+1, S+2 bij finish).
`assign` = OK als side == correct_side. `drop` = OK als dir_index == index_of(hv). `lookup` = OK als
dir_index == index_of(wanted_hv) (found kan dan toch false zijn door een eerdere fout; de log linkt naar die fout).
`dump` = OK als `correct_move` "dump" zegt, anders UNNEEDED_DUMP (en het pakje telt als kwijt).

### 10.4 `event_log.gd`
```gdscript
class_name EventLog extends RefCounted
func add(type: String, data: Dictionary, verdict: int, hint: Dictionary, before: Dictionary) -> Dictionary
var entries: Array[Dictionary]  # {seq, t, type, data, verdict, hint (correct_move vóór de actie), before (snapshot, alleen bij verdict != OK en bij DOUBLE/SPLIT)}
func mistakes() -> Array[Dictionary]
func cause_of(parcel_id: int) -> Dictionary   # het event waar dit pakje verdwaalde, of {}
func coach_line(entry: Dictionary) -> String  # één zin van de chef (§4.1), gegenereerd uit data + hint
```
Types: `SPAWN DROP BLOCK DOUBLE DOUBLE_REFUSED SPLIT_BEGIN SPLIT_REFUSED ASSIGN SPLIT_END RETRY LOOKUP LOST DUMP CUSTOMER_IN CUSTOMER_OK CUSTOMER_ANGRY DAY_END`.

### 10.5 `day_spec.gd`, `days.gd`
```gdscript
class_name DaySpec extends RefCounted
enum Mode { CALM, REALTIME }
enum BitHint { FULL, COLORS, NONE }
var id: String; var title: String; var n: int; var g: int; var a0: int
var start_layout: Array          # formaat van load_layout; [] = leeg
var keys: Array[Dictionary]      # [{"hv":"11110", "label":""}]; leeg -> generator
var generator: Dictionary        # endless: {seed, clone_after, clone_every}
var mode: int; var bit_hint: int; var loupe_allowed: bool; var overflow_bin: bool
var spawn_interval: float; var belt_time: float; var burst_time: float  # burst_time <= 0: geen burst
var customers: Array[Dictionary] # [{"t":20.0, "hv":"01101", "patience":15.0}]
var customer_gen: Dictionary     # {start, every, patience, seed} of {}
var reputation: int = 5
var stars: Array[Dictionary]     # [{"kind":"done"}, {"kind":"no_mistakes"}, {"kind":"io_optimal"} | {"kind":"time","max":40} | {"kind":"no_doubles"}]
var hints: Array[Dictionary]     # [{"trigger":"first_block", "anchor":"lever", "ghost":"drag_lever", "text":"Eén buis. Maak er twee."}]
var phases: Array[DaySpec]       # dag 7: ochtend + middag
var expect_end: Dictionary       # acceptatie (§11): {a, layout:[{label, hvs}], reads, writes}
class_name Days
static func get_day(i: int) -> DaySpec   # 1..7; 0 = endless
static func count() -> int
static func optimum(spec: DaySpec) -> Dictionary  # {reads, writes, doubles, splits} via correct_move-bot
```

### 10.6 `day_director.gd` (tijdlijn, headless)
```gdscript
class_name DayDirector extends RefCounted
signal parcel_spawned(parcel: Parcel)
signal parcel_fell_off(parcel: Parcel)          # band-einde (REALTIME) -> roept model.lose
signal customer_arrived(c: Dictionary)          # {id, hv, patience}
signal customer_left(c: Dictionary, happy: bool)
signal burst(parcel: Parcel)
signal day_finished(report: Dictionary)
var model: ExtHashModel; var scoring: Scoring; var spec: DaySpec
func start(spec: DaySpec) -> void
func tick(dt_world: float, dt_real: float) -> void   # world = geschaald door slow-mo
func world_time_scale() -> float                    # 0.35 als blocked/splitting, anders 1.0 (gameplay past dit toe)
func belt() -> Array[Parcel]                        # voorste eerst
func take_front() -> Parcel                         # speler pakt het voorste (of slepen: take(parcel_id))
func take(parcel_id: int) -> Parcel
func serve(customer_id: int, dir_index: int) -> Dictionary  # roept model.lookup
```

### 10.7 `scoring.gd`, `save_data.gd`
```gdscript
class_name Scoring extends RefCounted
signal coins_changed(coins: int, delta: int, reason: String)
signal combo_changed(combo: int)            # 1..5
signal dash()                               # combo bereikt 5
signal reputation_changed(rep: int)
var coins: int; var combo: int; var rep: int
func bind(model: ExtHashModel) -> void      # luistert zelf naar event_logged
func on_loupe_used() -> void
func on_customer(happy: bool, patience_frac: float) -> void
func tick_real(dt: float) -> void           # combo-timeout (gepauzeerd tijdens alarm)
func final_report(model: ExtHashModel, spec: DaySpec, time_s: float) -> Dictionary
	# {stars:[bool,bool,bool], coins, breakdown:[{label, amount}], reads, writes, opt:{...}, mistakes:[entry], parcels, customers_ok, customers_total}
class_name SaveData                          # user://save.json
static func load_data() -> Dictionary; static func save_data(d: Dictionary) -> void
static func set_stars(day: int, stars: int) -> void; static func add_highscore(score: int, name: String) -> void
```

### 10.8 Gameplay-zijde (ter info, niet bindend)
`scripts/game/`: `depot.gd` (hoofdscène, bouwt nodes in `_ready`), `wall_view.gd`, `pipe_view.gd` (bezier-buizen,
verzamelbuizen per rek), `rack_view.gd`, `belt_view.gd`, `sort_table.gd`, `counter_view.gd`, `hud.gd`,
`report_screen.gd` (herbeleving: `model.restore(entry.before)` in een tweede, read-only `ExtHashModel` + views),
`juice.gd` (autoload: shake, hitstop, slowmo, floaters), `sfx.gd` (autoload). Een **bot** (`tests/bot.gd`) speelt elke dag
via `correct_move()` en is ook de "Doorspoelen"-knop op dag 7.

---

## 11. Testbare acceptatiecriteria
Algemeen (core-tests, headless `tests/run_tests.gd`):
- A1 `HashUtil.prefix(0b010011, 6, 3) == 2` (notas p. 6). `bits(2,5) == "00010"`.
- A2 Na `double_dir()`: voor alle i geldt `dir_new[i] == dir_old[i >> 1]`, a + 1, geen ritten.
- A3 `begin_split` op een emmer met ab == a → false + `split_refused`; op ab < a: `changed` = de 2^(a−ab−1) indices
  met `i|(ab+1) == 2·(h|ab)+1`, aaneengesloten.
- A4 Notas-reeks vanaf leeg (n 5, g 2, a 1): `00100 01111 10010 11100` = Fig. 2; + `11111` = Fig. 4
  (a 2; `0{00100,01111}` ab 1, `10{10010}`, `11{11100,11111}`); + `11110` via bot: tussentoestand na de eerste split
  = Fig. 5 (a 3, rek `110` leeg ab 3, `111{11100,11111}` ab 3, `still_blocked` geëmit); eind a 4, `1110{11100}`,
  `1111{11111,11110}`.
- A5 `invariants()` leeg na elke bot-stap op alle dagen. Bot haalt op elke dag 3 sterren.
- A6 Een bot die op dag 3 bij elke vastloper eerst `double_dir()` doet → log bevat UNNEEDED_DOUBLE en ★★ ontbreekt.
- A7 `simulate_insert` geeft voor elke dag dezelfde stappen als de JS-referentie `insert()` (zelfde volgorde place/double/split).
- A8 Snapshot → restore → snapshot is identiek.

Per dag (bot = perfect spel; `expect_end` in DaySpec):
| dag | a | eindtoestand (label{inhoud}) | L / S optimum |
|---|---|---|---|
| 1 | 1 | `0{00110,01011,00011}` `1{10101,11000,10010}` | 6 / 6 |
| 2 | 2 | `0{00100,01111}` `10{10010,10111}` `11{11100,11111}`; 1 dubbel, 1 split | 6 / 7 |
| 3 | 3 | 8 rekken ab 3 (zie §5.2); **0 dubbels**, 4 splits | 8 / 12 |
| 4 | 3 | 8 rekken ab 3 (zie §5.2); 1 dubbel, 5 splits; 5 klanten gevonden | 12 + 5 / 17 |
| 5 | 4 | 9 rekken (zie §5.2), `110` ab 3 met `{11010,11001}`; 2 dubbels, 6 splits | 10 + klanten / 16 |
| 6 | 4 | `0000{00000,00001}` `0001{00010}` `001{}` `01{01001}` `1{11111,10001}`; 3 dubbels, 3 splits | 6 / 9 |
| 7 ochtend | 5 | `0{01001}` `100{}` `1010{}` `10110{10110,10110}` `10111{}` `11{}`; eindigt met `fail` + `double_refused` | — |
| 7 middag | 4 | zie §5.2; overloopbak = 2 klonen (`11001`, `00111`); 3 dubbels, 5 splits | 9 / 14 |
| ∞ | — | 10 min bot zonder fouten: geen invariant-fouten; spawn-interval op t = 6 min (L = 12) == 1,3 s, op t = 3 min (L = 6) == 2,5 s | — |

Gameplay/QA (frame-opnames): bitlabels ≥ 18 px; bij a = 5 alle 32 luiklabels leesbaar; slow-mo actief binnen 0,3 s na
vastloper; geen tekstpopup met "fout"; elke handeling in §2.3 werkt met muis én toetsenbord.

---

## 12. Scope
**MOET (v1):**
- Core volledig (§10) + tests §11 (A1–A8, dag 1–7).
- Dagen 1–7 + endless, dagenkaart, dagrapport met herbeleving (tijdlijn + spookzet + chefzin), notas-weergave, pauze
  met spiekbrief, opslag van sterren/highscore.
- Besturing muis + toetsenbord (§2.3), slow-mo, bits-markering 3 niveaus, loep.
- Juice-items 1–10, 12–24, 26–28, 30–32 (minstens 27 van de 34); audio: alle cues uit §9 (sfxr-achtig mag), 1 muzieklus
  met de lagen basis en spanning.

**Nice-to-have:**
- Muzieklaag "drukte" en adaptieve mix; titel-attract-mode met bot; juice 11, 25, 29, 33, 34.
- Klanten die naar een **niet-bestaand** pakje vragen (correct antwoord: juiste luik → "niet hier"-stempel).
- Chef-personage met animaties; "Brinkmanns notaboekje" als verzamelbare pagina's per dag.
- Optiemenu met kleurenblind-palet; ghost-replay van de eigen beste run.
- Dag-specifieke achtergronden (ochtend → nacht).

**Bewust NIET:** verwijderen (staat niet in de notas), linear hashing (§2.1.2, later spel), online leaderboards.

---

## Samenvatting voor het team
- **Realtime?** Dag 1–3 en 6 rustig, dag 4–5, 7 en endless realtime. Elke algoritmische beslissing (vol rek) zet de
  wereld op slow-mo 0,35×: de druk zit op het snel bits lezen, niet op het nadenken over het algoritme.
- **Foute zetten mogelijk?** Ja, alles wat in de notas-wereld kan mislopen (fout luik, verkeerde kant, onnodig
  verdubbelen/splitsen, overlopen). Gevolgen zitten in de wereld (verdwaalde pakjes, boze klanten, ritten, huur). Enkel
  de twee echte onmogelijkheden zijn fysiek geblokkeerd: zagen bij ab = a (één buis) en verdubbelen voorbij a = n.
- **Bits-markering:** FULL (dag 1–2) → COLORS (3–4) → NONE (5+) met loep als vangnet die de combo breekt. De
  positiekleuren zijn overal gelijk.
- **Leren zonder quiz:** de dagrapport-herbeleving toont de juiste zet als spookhand plus één chefzin. De
  notas-weergave tekent je depot als Figuur 4/5.
- **Twijfels bij de leerstof:**
  1. Rittentelling bij kettingen (1 L + (1+k) S) is onze veralgemening. De notas zeggen alleen "misschien met maar één
     leesoperatie en twee schrijfoperaties" (p. 9) voor het gewone geval.
  2. Gewone invoeging = 1 L + 1 S is afgeleid uit het model ("elk vakje in één stap kan lezen en in één stap er iets in
     schrijven", p. 4), niet expliciet geteld.
  3. Dag 1 start met a = 1 i.p.v. a = 0 (TEAM.md): met a = 0 valt er geen bit te lezen. De notas: "In onze voorbeelden
     beginnen wij met a = 1" (p. 7).
  4. De overloopbak (dag 7) is geen notas-oplossing. Oef. 4 vraagt "Hoe kan je het probleem oplossen?" zonder antwoord.
  5. Klanten "halen op" werd "inzien", want verwijderen staat niet in de notas.
