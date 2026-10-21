# Rails & Tails — conceptdocument (v0, nog niet gebouwd)

Een game die het **algoritme van Ukkonen** volledig aanleert: van "wat is een deelstring" tot "waarom is dit O(n)".
Iemand die suffixbomen niet kent, moet na het spelen oefening 27 van de notas met pen en papier kunnen oplossen en
kunnen uitleggen waarom elke stap klopt.

- **Status:** idee/concept. Nog geen code, nog geen GDD. Dit document is de basis voor een latere `GDD.md`.
- **Bron leerstof:** lesnotas AD3 2026, §3.2.1 "Het algoritme van Ukkonen", gedrukte p. 34–48. **Bij twijfel gaan de
  notas voor.** Alle notatie in de game komt uit de notas: S(1,i), σ_{j,i}, iteratie, `it`, situaties (i)/(a)/(ii)/(b)/(iii),
  wijzer (p, x) met p̄/x̄, pw, suffix link l(t), diepte a(t), b(i), afsluitteken `_`. Internettermen zoals "active point",
  "remainder" of "rule 1/2/3" komen **niet** in de game, want de student moet de notas en het examen herkennen.
- **Verhouding tot Trietuin:** Trietuin heeft al een Ukkonen-finale (levels 5-1 t.e.m. 5-3), maar dan als korte afsluiter
  voor spelers die suffixbomen al kennen. Rails & Tails is de diepe versie en hergebruikt de geverifieerde core
  (`games/trietuin/scripts/core/tt_ukkonen.gd`). Zie §16 voor de open vraag hoe beide naast elkaar bestaan.
- **Didactiek:** volgt `design/LEARNING.md` (Kijk / Samen / Zelf / Check per deel) en `design/SHARED_UX.md`.

### Naam: **Rails & Tails**
Ligt goed in de mond en rijmt, net als Hash & Dash. *Rails* zijn de sporen van het metronet (de bogen van de boom),
*tails* zijn staarten, en dat zijn suffixen: de staarten van de tekst. Map `games/rails_tails/`, klasseprefix `Rt`.
Eerdere werktitels: *Spoorboom* (bestaand woord voor de slagboom aan een overweg, dus verwarrend) en *Lijn U* (klonk
niet vlot genoeg).

---

## 1. De pitch

> Je bent seingever van een metronet dat groeit terwijl de dienstregeling binnenkomt, letter per letter.
> Na elke klokslag moet elke rit die in de tekst voorkomt vanuit Centraal te rijden zijn, en geen enkele andere.
> In het begin doe je alles met de hand en ontploft je werkbudget. Elk inzicht van Ukkonen verdien je als een
> werktuig dat je net gemist hebt. Tot je op het einde een tekst van 10 000 letters ziet binnenrazen, terwijl het net
> lineair meegroeit.

De boom wordt een metrokaart. Het railnet past op drie plaatsen perfect bij Ukkonen:
1. **Online:** de tekst komt binnen als klokslagen. Na elke slag moet het net weer kloppen.
2. **"Eens blad, altijd blad":** aan elk eindstation staat een spoorlegger. Bij elke klokslag leggen ze allemaal
   tegelijk één tegel. Dat is `it`.
3. **De wijzer (p, x):** een werktreintje dat op station p staat, of x tegels verder midden op een spoor.

---

## 2. Wat het onderzoek zegt, en wat Rails & Tails ermee doet

| inzicht uit onderzoek | bron | gevolg voor Rails & Tails |
|---|---|---|
| **Intrinsieke integratie:** kinderen leerden meer van een spelversie waarin de leerstof de kernmechaniek *is* dan van een versie waarin de game een beloning rond de leerstof is. In vrije tijd speelden ze de intrinsieke versie 7× langer. | Habgood & Ainsworth 2011 | Elke spelhandeling is een stap van het algoritme. Er zijn geen losse minigames of quizvragen als beloning. "Snel spelen" en "Ukkonen correct uitvoeren" zijn hetzelfde. |
| **Kijken naar algoritme-animaties helpt weinig, zelf doen wel.** Visualisatie bleek effectief in ongeveer de helft van de studies. Actieve betrokkenheid (voorspellen, zelf construeren) gaf telkens betere resultaten dan passief kijken. | Hundhausen, Douglas & Stasko 2002; Naps e.a. 2002 (engagement-taxonomie) | De speler bouwt en beslist zelf: hoogste niveau van de taxonomie ("constructing"). Kijk-fases blijven kort en zijn altijd gekoppeld aan een voorspelvraag. |
| **Productief falen:** eerst zelf een probleem proberen en vastlopen, daarna de uitleg krijgen, werkt vaak beter dan omgekeerd. | Sinha & Kapur 2021 (meta-analyse, 53 studies) | Elke lijn begint met de **pijn** (te duur, te traag, botsing). Het werktuig van Ukkonen komt pas daarna. Voorbeeld: lijn 3 laat je alles met de hand doen tot het budget ontploft. |
| **Uitgewerkte voorbeelden, met afbouw:** voorbeelden waarbij stap voor stap meer zelf ingevuld moet worden, werken goed. Adaptief afbouwen (op basis van prestaties) werkt nog beter. Voor wie het al kent, werken voorbeelden juist tegen ("expertise reversal"). | Renkl & Atkinson 2003; Schwonke e.a. 2009 | Kijk → Samen → Zelf, met adaptieve afbouw. Juiste voorspellingen laten hints sneller verdwijnen. Wie de instaptoets van een lijn juist heeft, mag de Kijk-fase overslaan. |
| **Zelfverklaring:** vragen om de reden van een stap (ook uit een keuzemenu) maakte een tutor effectiever. | Aleven & Koedinger 2002 | "Waarom?"-kaartjes na sleutelstappen: kies de reden uit 3 opties (bv. "waarom mag je stoppen na (a)?" → Lemma 5). |
| **Toetsen en spreiden werken het best.** Practice testing en distributed practice kregen als enige "high utility". Interleaving en zelfverklaring scoorden "moderate". | Dunlosky e.a. 2013 | Check-vragen bij elke lijn. **Dagrit:** bij elke start eerst 2–3 korte vragen over vroegere lijnen (gespreid, door elkaar). |
| **Foute voorbeelden laten verbeteren** gaf in één studie beter onthouden na een week (d = 0,62), al vonden leerlingen het minder leuk. Een andere studie vond geen voordeel. | McLaren, Adams e.a. 2012/2015 | Modus **Inspecteur**: vind de fout in de replay van een slordige wisselwachter. Kort houden en optioneel maken, want het bewijs is gemengd en het voelt minder leuk. |
| **Transfer naar papier gebeurt niet vanzelf.** DragonBox leerde spelers het spel, maar in een studie van Carnegie Mellon hielp dat nauwelijks bij gewone vergelijkingen op papier. | Aleven & Long (CMU), via EdSurge 2016 | **Grootste les voor ons.** Het examen is op papier, dus de game bouwt een expliciete brug: notas-zicht, tekenmodus en papieren opdrachten (§9). |
| **Games werken beter samen met ander onderwijs, over meerdere sessies en in groep.** Over het geheel: leren d = 0,29, onthouden d = 0,36, en *niet* motiverender dan gewone instructie. | Wouters e.a. 2013 (meta-analyse, 77 studies) | Korte lijnen van 10–15 min, gemaakt om naast de notas en lessen te gebruiken (verwijzing naar de notaspagina bij elke stap). Duo-modus als extra. Geen overdreven verwachting: de motivatie moet uit goed spelontwerp komen, niet uit "het is een game". |
| **Eenvoudige visuals** werken minstens even goed als complexe. Ondersteuning (scaffolding) helpt vooral in puzzelgames. | Clark e.a. 2016; meta-analyse scaffolding in DGBL 2021 | Strakke, rustige stijl (zoals Mini Metro), met de kleuren alleen waar ze iets betekenen. Hints en afbouw zijn een kernfunctie, geen bijzaak. |

**Conclusie uit het onderzoek:** de game moet (1) het algoritme zelf als mechaniek hebben, (2) de speler laten
construeren in plaats van kijken, (3) eerst laten vastlopen en dan het werktuig geven, (4) hulp adaptief afbouwen,
(5) gespreid toetsen en (6) **expliciet naar papier overbrengen**.

---

## 3. Wat een echte oefensessie ons leerde

Henri maakte oefening 27 (`aabbabc_`) en een oefening op `abaaa` → `abaaab` op papier. De bomen waren juist, maar vier
dingen kwamen naar boven. Elk ervan wordt een ontwerpbeslissing.

| observatie | ontwerpgevolg |
|---|---|
| Bij it=3 was er een tussentekening in de verkeerde volgorde: eerst het blad `b` aan de wortel, pas daarna de splitsing. Ukkonen behandelt de **langste** niet-blad-suffix eerst. | De σ-rij (perron) is altijd zichtbaar, met een pijl bij de suffix die nu aan de beurt is. Er komt een Check-vraag "welke suffix nu?" in lijn 6. |
| Suffix links stonden niet op de tekening. | In de tekenmodus tellen suffix links mee voor de score. Lijn 10 laat ze zelf vastmaken en tekenen. |
| Vraag: "Bij it=6 moet er toch niets speciaals gebeuren?" De vorm verandert niet, maar de **wijzer springt**, en dat is nodig voor it=7. | Nieuw begrip in de game: de **stille klokslag**. De boom blijft gelijk, maar het treintje verplaatst. Dat krijgt een eigen Check-vraag in lijn 9. |
| Vraag: "Waarvoor dienen suffixpointers?" Het doel van de links was niet vanzelfsprekend. | Lijn 8–9 laten eerst voelen hoe duur het is om telkens vanuit Centraal te lopen. Lijn 10 geeft dan de buis als oplossing, plus een "waarom?"-kaart. |

---

## 4. Pijlers

1. **De mechaniek ís het algoritme.** Geen quiz rond de game, geen punten voor iets anders dan Ukkonen goed uitvoeren.
2. **Eerst de pijn, dan het werktuig.** Elk inzicht is een upgrade die je pas krijgt nadat je het probleem gevoeld hebt.
3. **Kost = complexiteit.** Werkuren maken O(n³) → O(n²) → O(n) voelbaar als een grafiek die je zelf omlaag duwt.
4. **De metafoor verdwijnt geleidelijk.** Van metrokaart naar de tekeningen van de notas. Op het einde speel je in
   notas-notatie (§9).
5. **Meesterschap wordt automatisering.** Wat je beheerst, gebeurt vanaf dan automatisch. Zo blijft het overzichtelijk.
6. **Tempo pas na beheersing.** Tijdsdruk zit alleen in Spitsuur, nooit in een leerdeel.

---

## 5. De wereld: elk beeld = precies één begrip

| notas | Rails & Tails | zichtbaar als |
|---|---|---|
| tekst s₁…sₙ_ | **dienstregeling**: strook bovenaan, letters met positienummer | strook met tegels, posities eronder |
| iteratie i+1 | **klokslag** | stationsklok tikt, nieuwe tegel schuift binnen |
| deelstringboom S(1,i) | het net, geldig tussen klokslagen | groene seinen; reizigers (zoekvragen) rijden alleen nu |
| stringboom S(1,i)ⱼ (midden in iteratie) | net in werken | rode seinen, reizigers wachten |
| boog met label (b,e) | spoor met **kaartje (b,e)** | kaartje op het spoor; hoveren licht de tegels in de strook op |
| interne top | **wisselstation** | ≥ 2 sporen, elk met een andere eerste tegel |
| blad j | **eindstation j** | station met nummer j |
| `it` | spoorleggers | aan elk eindstation een machine die op elke klokslag synchroon één tegel legt |
| σ_{j,i} | **reiziger j** | figuurtje op het perron met kaartje "j → i" |
| b(i) | perrongrens | links: reizigers die al een eindstation hebben (zitten in de trein); rechts: de rest |
| situatie (a)/(b) | "Rijdt al" | stopbord; de klokslag eindigt |
| situatie (ii) | nieuw eindstation aan een wissel | |
| situatie (iii) | wissel inbouwen midden in een spoor + eindstation | het spoor splijt |
| wijzer (p, x) | **werktreintje** | staat op station p; een lichtspoor toont de x tegels verder |
| pw | **Centraal** | |
| springen (enkel eerste letter + lengte) | treintje leest **lengtebord en eerste tegel** | snelle sprong van station naar station |
| suffix link l(t) | **snelbuis** | buis met bolletje aan het einde (zoals de pijlen in Fig. 22) |
| diepte a(t) | **dieptemeter** | meter naast het treintje |
| `_` | **de laatste trein** | |
| kost | **werkuren** | teller + budgetbalk; kostgrafiek per lijn |

**Drie weergaven** (de speler kan wisselen, de game stuurt geleidelijk naar de laatste):
1. **Metro:** de wereld zoals hierboven.
2. **Hybride:** metro, maar met (b,e), σ_{j,i} en (p̄, x̄) als labels erbij.
3. **Notas-zicht:** exact de tekenstijl van de notas: strings op de bogen, pijlen met bolletje, de dikke pijl met getal
   voor (p̄, x̄).

---

## 6. Kernlus

### 6.1 Per stap (seconden)
Het treintje staat op een positie. De speler kiest:
1. **Spring** (zolang x ≥ booglengte): klik het station aan het einde van het juiste spoor.
2. **Situatie:** "Rijdt al" (a/b) of "Bouw" (ii/iii). De vorm van het bouwwerk volgt uit de positie.
3. **Buis vastmaken:** hing er een buis van de vorige stap, sleep die dan naar het juiste station.
4. **Volgende reiziger:** "Neem de buis" (p ≠ pw) of "x − 1" (p = pw).

Automatisch: `it` (vanaf lijn 4), labels, het beëindigen van de klokslag na "Rijdt al", (pw, 0) na het laatste blad.

### 6.2 Per klokslag (±20 s)
Nieuwe tegel → spoorleggers leggen → perron bijwerken → stappen tot "Rijdt al" of tot de laatste reiziger een
eindstation heeft → seinen op groen → 0–2 reizigers vragen een rit ("bestaat `bab`?"). Rijden ze juist, dan levert dat punten op.

### 6.3 Per lijn (10–15 min)
Instapvraag → (Kijk) → Samen → Zelf-level → Check → kostgrafiek bijwerken → nieuw werktuig of nieuwe lijn op de kaart.

### 6.4 Kostmodel (werkuren)
| handeling | kost |
|---|---|
| één tegel lezen/vergelijken | 1 |
| één station verder springen | 1 |
| buis nemen | 1 |
| nieuw station of nieuw spoor | 1 |
| één letter op een spoor schilderen (alleen lijn 2) | 1 verf |

De naïeve aanpak van lijn 3 (elke σ_{j,i} letter per letter vanuit Centraal) kost in totaal n(n+1)(n+2)/6
tegelstappen: **120** voor n = 8, **1540** voor n = 20, **171 700** voor n = 100. Ukkonen blijft lineair. Het budget
van elk level wordt zo gekozen dat de methode van die lijn net past en de vorige niet.

### 6.5 Sterren
★ net correct · ★★ binnen budget · ★★★ zonder hint én Check juist.
Sterren openen de volgende lijn niet af (iedereen mag verder), maar wel Spitsuur en het Atelier.

---

## 7. Leerpad: 13 lijnen en een examen

Elke lijn = één nieuw idee, met Kijk / Samen / Zelf / Check. De Kijk is overslaanbaar als de instapvraag juist is.

| # | lijn | pijn → inzicht | Zelf-level | Check-vraag (voorbeeld) | notas |
|---|---|---|---|---|---|
| 0 | **Kaartjes** | Reizigers kopen ritten (j,k). Ontdekking: elke deelstring is het begin van een suffix. | korte tekst, alle ritten vinden | "Van welke suffix is `ca` het begin in `acgacg`?" | σ_{j,i} |
| 1 | **Het net** | Leg sporen zodat elke gevraagde rit kan en geen verboden rit. Twee sporen met dezelfde eerste tegel botsen. Een wissel met één uitgang wordt weggewerkt. Een rit mag midden op een spoor stoppen. | `acgacg` | "Is dit net een deelstringboom?" (met valse rit) | Def. 3, Fig. 20–21 |
| 2 | **Verf is duur** | Letters schilderen ontploft bij lange teksten; een kaartje (b,e) kost een constante. | lange tekst met verfbudget | "Welk kaartje hoort bij dit spoor?" | labels (b,e) |
| 3 | **De klok tikt** | De tekst komt letter per letter binnen. Alles met de hand vanuit Centraal: 120 werkuren voor 8 letters lukt nog, maar 1540 voor 20 letters niet meer. | 6 letters ok, dan 20 letters: budget ontploft (bewust) | "Hoeveel suffixen moet je in iteratie 5 verlengen?" | S(1,i), iteratie |
| 4 | **Eens blad, altijd blad** | Voorspel wat er met eindstation-reizigers gebeurt: altijd één tegel erbij → spoorleggers + `it`. Ze staan ook altijd vooraan op het perron (Lemma 4, als schaduwpuzzel). | | "Waar ligt de perrongrens b(i) in deze boom?" | (i), `it`, Lemma 4 |
| 5 | **Rijdt al!** | De eerste "zit er al": de game laat je de kortere reizigers nog zelf controleren. Ze zitten er telkens allemaal al in → stopbord. De drie groepen van p. 37 staan als accolades op het perron. | Atelier-puzzel Oef. 22 | "Waarom mag je hier stoppen?" (3 opties) | (a)/(b), Lemma 5 |
| 6 | **Wissels bouwen** | (ii) en (iii), labels (i+1, `it`), splitsen in (b, b+k−1)/(b+k, e). De perrongrens schuift alleen naar rechts. Telling: bouwen is nu O(n), maar de kostgrafiek blijft kwadratisch, want de tijd gaat naar het zoeken vanuit Centraal. | Oef. 24 `aabbabc_` | "Welke suffix wordt nu behandeld?" (volgorde-valkuil uit §3) | p. 38–39 |
| 7 | **De laatste trein** | Zonder `_` blijven reizigers op het perron staan zonder eindstation. Met `_` krijgt iedereen er een. **Mijlpaal: je kan nu een correcte suffixboom bouwen. Nu nog snel.** | `acgacg` vs `acgacg_` | "Welke suffixen eindigen niet in een blad?" | Fig. 20, Oef. 21 |
| 8 | **Het werktreintje** | Wijzer (p, x). Na een stop: p̄ = p, x̄ = x+1. Na het laatste blad: (pw, 0). Bij Centraal valt de eerste letter weg: x̄ = x−1. | `aabbabc_`, iteraties 1–5 (alleen stappen bij Centraal) | "Wat is de wijzer na deze stap?" | p. 40–41 |
| 9 | **Lees het bord, niet de tegels** | Springen: alleen eerste letter + lengte, want de rit bestaat gegarandeerd. Kost = aantal stations. Inclusief de **stille klokslag**. | `aabbabc_` it 6 | "De boom verandert niet. Wat verandert er wel?" | p. 41–42, Oef. 25 |
| 10 | **Snelbuizen** | Suffix links. Puzzel "waarom bestaat het doel altijd?" (Opm. 6). Na (ii)/(iii) bij p ≠ pw: neem de buis met x̄ = x. De kostgrafiek zakt naar lineair. | `aabbabc_` it 7; `abaaa` → `abaaab` | "Waarom blijft x gelijk na de buis?" | Fig. 22, Opm. 6 |
| 11 | **Buizen onderhouden** | Een nieuwe wissel krijgt een hangende buis, die je in de volgende stap vastmaakt (aan een bestaand of net gebouwd station). Spektakel: `acacacgt_`, met 4 wissels en een buizenketting in één klokslag. | `acacacgt_`; Atelier Oef. 23 | "Aan welk station hangt deze buis?" | p. 43 |
| 12 | **Waarom lineair?** | Dieptemeter: een buis kost hooguit 1 diepte (Opm. 7, a(l(t)) ≥ a(t) − 1), en de diepte is begrensd door n → Σmⱼ ≤ 4n. | Atelier: "Breek de begroting" | "Waarom kan de diepte niet blijven dalen?" | p. 42, aggregaatmethode |
| ★ | **Centrale post (examen)** | (1) `abacabc_` (notas p. 44–48) en Oef. 27 `aabbabc_` volledig zonder hulp, elke S(1,i) getekend in notas-zicht. (2) Een nieuwe tekst uit de generator. (3) Programmeer de seingever met instructiekaarten en laat hem los op 10 000 letters, met de kostgrafiek ernaast. | | papieren opdracht (§9) | Stelling 2 |

Volgorde: lijnen 0–7 = "correct bouwen", lijnen 8–12 = "snel bouwen". Na lijn 7 is er een duidelijke mijlpaal.

---

## 8. Herhaling, toetsing en afbouw

- **Instapvraag** bij elke lijn (voorspel wat er gebeurt). Juist → Kijk mag overgeslagen worden (expertise reversal).
- **Samen:** eerst bij elke stap een tip, daarna alleen op vraag. De afbouw gaat sneller na juiste voorspellingen (adaptieve fading).
- **"Waarom?"-kaartjes** na sleutelstappen: stoppen na (a)/(b), x gelijk na een buis, x − 1 bij Centraal, het doel van een buis.
- **Dagrit:** bij elke start eerst 2–3 vragen uit vroegere lijnen, door elkaar (gespreid + interleaving). Maximaal 1 minuut.
- **"Begrepen"-badge per lijn:** alleen als de Check op een *nieuw* voorbeeld juist is, niet alleen het level.

---

## 9. Transfer naar papier (de DragonBox-les)

Het examen is op papier. Een game die alleen in de game werkt, faalt dus. Daarom:

1. **Notas-zicht** wordt vanaf lijn 6 steeds vaker de standaard. In het examen is het verplicht.
2. **Tekenmodus:** de speler tekent S(1,i) zelf op een raster: toppen, bogen, labels, suffix links en de wijzer.
   De game controleert de tekening als een verbeteraar en markeert ontbrekende links of verkeerde labels.
3. **Snelschets-vraag:** "welke van deze vier tekeningen is S(1,5)?" Snel, en het traint het herkennen.
4. **Papieren opdracht na lijn 7, 10 en het examen:** "Neem pen en papier. Bouw de boom voor deze tekst." Daarna
   voert de speler zijn antwoord in (of klikt de juiste tekening aan) en krijgt hij een stap-voor-stap vergelijking.
5. **Spiekbriefje** (printbaar): het stappenplan van Ukkonen op één pagina, in notas-notatie, met de paginanummers.
6. **Elke zin van de mentor** vermeldt de notaspagina ("zie p. 41").

---

## 10. Fouten

- **Samen:** een foute stap wordt geweigerd, met een korte uitleg in de wereld (zoals in Trietuin: het treintje
  probeert het en botst lokaal).
- **Zelf:** de fout mag blijven staan. Aan het einde van de klokslag rijdt er een **inspectierit**. Faalt die, dan springen
  de seinen op rood en spoelt de game terug naar het begin van die klokslag, met de foute stap gemarkeerd en een
  "waarom?"-kaartje. Zo zie je echte gevolgen, maar de schade loopt nooit verder dan één iteratie.
  (Bewuste afwijking van Trietuin, waar Ukkonen-fouten altijd geweigerd worden.)

**Typische fouten die de game expliciet opvangt** (en die in de Inspecteur-modus terugkomen):
- de langste suffix niet eerst behandelen (volgorde-valkuil, §3)
- x − 1 vergeten na een stap bij Centraal
- een buis nemen vanuit Centraal
- doorgaan na (a)/(b)
- niet springen terwijl x ≥ booglengte, of tegels vergelijken tijdens het springen
- de hangende buis vergeten of aan het verkeerde station hangen
- een nieuw blad labelen als (j, it) in plaats van (i+1, it)
- suffix links weglaten op de tekening

---

## 11. Modi

| modus | wat | onderzoek | prioriteit |
|---|---|---|---|
| **Campagne** | lijnen 0–12 + examen | alle pijlers | P0 |
| **Atelier** | ontwerppuzzels: typ zelf een tekst die iets moet laten gebeuren (Oef. 22, 23, 25, "Breek de begroting") en een sandbox met vrije invoer | constructing (Naps) | P1 |
| **Inspecteur** | vind de eerste foute stap in de replay van een slordige wisselwachter | foute voorbeelden (McLaren) | P1 |
| **Spitsuur** | eindeloze tekst, klok versnelt. Elke klokslag stort een vast bedrag in een **spaarpot**, duur zoekwerk haalt eruit, een lege pot = failliet. Zo voel je amortisatie. | Stelling 8 (online) | P2 |
| **Duo** | één speler bestuurt, de ander voorspelt elke stap vooraf. Punten voor beiden als het klopt. | spelen in groep (Wouters) | P2 |

**Let op bij Spitsuur:** de spaarpot lijkt op de bankrekening-/boekhoudmethode, terwijl de notas de
**aggregaatmethode** gebruiken. De uitleg moet dat expliciet zeggen. De juiste constante moet nog met de core bepaald worden.

---

## 12. Gevoel: art, audio, juice

- **Stijl:** strak en rustig, zoals Mini Metro. Kleur alleen waar ze betekenis heeft: spoorleggers (`it`), het
  treintje (wijzer), buizen (suffix links), rood/groen voor seinen.
- **Muziek uit de tekst:** elke letter is een noot; de dienstregeling wordt een melodie. Bij een klokslag spelen alle
  spoorleggers samen een akkoord (meer bladen = voller akkoord).
- **Hoogtepunten:** de synchrone tegel van alle spoorleggers; een wissel die midden in een spoor openklapt; een buis
  die met een "pfoep" vastklikt; de cascade van `acacacgt_`; de kostgrafiek die zakt na lijn 10.

---

## 13. Techniek

- **Engine:** Godot, zoals de andere games in de speelhal. Prefix `Rt`.
- **Core hergebruiken:** `TtUkkonen` (`games/trietuin/scripts/core/tt_ukkonen.gd`) heeft de juiste stappen al: springen,
  regel kiezen, link vastmaken, link volgen of x − 1 doen, met `trace()`, `cursor()` en `sigmas()`. Volgens de
  Trietuin-status is die core nagerekend: Ukkonen == naïef voor alle 254 {a,c}-teksten. Te bekijken: verhuizen naar
  `scripts/shared/` of een dunne adapter in Rails & Tails.
- **Orakel** (`correct_move()`) voor Kijk (afspelen met verteltekst), Samen (hints, foutcontrole) en Inspecteur
  (replays met geplante fouten).
- **Kostmodel** als aparte teller boven de core (telt tegels, sprongen, buizen).
- **Gedeeld:** `HubNav`, `HubGuide`, eventlog en coachzinnen zoals in de andere games.

---

## 14. Scope

- **P0:** lijnen 0–10 + examen deel 1, notas-zicht, Samen/Zelf/Check, kostmodel, papieren opdrachten.
- **P1:** lijnen 11–12, tekenmodus, Atelier, Inspecteur, dagrit.
- **P2:** Spitsuur, Duo, de programmeerbare seingever (examen deel 3), muziek uit de tekst.

## 15. Meten of het werkt

- **Voor- en natoets op papier**, met een nieuwe tekst van 7–8 letters + `_`: bouw de boom, teken de suffix links,
  noteer de wijzer na elke iteratie, en leg één stap uit.
- **Nieuwe-speler-test** volgens `design/LEARNING.md`: een tester die het algoritme niet kent, speelt alleen wat de game
  toont en lost daarna Oef. 27 op papier op.
- **Logs:** waar vragen spelers hints, welke fouten komen terug, waar haken ze af.

---

## 16. Risico's en open vragen

1. **Overlap met Trietuin.** Blijft Trietuin 5-1 t.e.m. 5-3 bestaan als korte versie, of verwijst die naar Rails & Tails?
2. **Lemma 5 en het onderhoud van de suffix links** zijn het moeilijkst om intuïtief te maken. Die moeten het eerst getest worden.
3. **"Breek de begroting" is misschien saai.** Ik telde de sprongen (stations die het treintje voorbij springt) over
   alle {a,b}-teksten t.e.m. lengte 14 (+ `_`). Het maximum was telkens **n − 3**, ver onder de grens 4n. Spelers zullen
   die grens dus nooit benaderen. Mogelijke aanpak: maak er een "zoek het maximum"-puzzel met ranglijst van, en toon pas
   daarna de grens 4n als "veilige bovengrens". Dat sluit ook aan bij Oef. 26 ("kan je iets beters bewijzen?").
   Opgelet: dat is mijn eigen telling van sprongen, niet exact de mⱼ van de notas (die telt de toppen op het pad, dus ongeveer sprongen + 1 per opzoeking).
4. **Transfer naar papier** blijft het grootste risico (DragonBox). Daarom moet §9 al in P0 zitten.
5. **Tijd:** dit is een grote game. P0 alleen is al ongeveer zo groot als een volledig hoofdstuk van Trietuin.

---

## 17. Antwoordsleutels (nagerekend)

Nagerekend met een Python-implementatie van het stappenplan (notas p. 38–43). Die geeft voor alle {a,b}-teksten
t.e.m. lengte 8 (+ `_`) en voor `acacacgt_`, `mississippi_`, `abcabxabcd_` en `aabbabc_` de juiste suffixboom, en volgt
voor `abacabc_` exact de stappen van de notas (p. 44–48).

| opgave | antwoord |
|---|---|
| **Oef. 22** (alle drie de groepen in de laatste iteratie) | kortste voorbeelden hebben lengte 4, bv. `abaa`: σ₁ en σ₂ eindigen in bladen, σ₃ = `a` + `a` vraagt (iii), σ₄ = `a` zit er al (a) |
| **Oef. 23** (Θ(n) nieuwe toppen in één iteratie) | `(ac)^m g`: in de laatste iteratie ontstaan **2m − 2** nieuwe toppen (m = 2…6 nagerekend: 2, 4, 6, 8, 10) |
| **Oef. 25** (na een suffix link nog ≥ 2 toppen overlopen) | `aababbab_`, iteratie 9: (iii) vanuit een interne top met x = 2 → volg de link → het treintje springt over 2 stations, daarna (ii). (Kortste {a,b}-voorbeeld. Valkuil: bij `abbbabb_` springt het ook 2 keer, maar daar kom je via x − 1 aan de wortel, niet via een link.) |
| **Oef. 27** `aabbabc_` | per iteratie: (ii) · (a) · (iii),(ii) · (a) · (iii),(a) · spring + (a) · (iii), spring + (ii), (ii) · (ii). Eind: 8 bladen, interne toppen [a], [ab], [b], links [a]→w, [ab]→[b], [b]→w |

---

## Bronnen

- Habgood, M. P. J. & Ainsworth, S. E. (2011). *Motivating children to learn effectively: exploring the value of intrinsic
  integration in educational games.* Journal of the Learning Sciences 20(2). <https://shura.shu.ac.uk/3556/>
- Hundhausen, C., Douglas, S. & Stasko, J. (2002). *A meta-study of algorithm visualization effectiveness.* Journal of
  Visual Languages and Computing 13(3). Samenvatting via <https://www.scitepress.org/Papers/2009/18251> en
  <https://cs.uef.fi/pub/Dissertations/myller.pdf>
- Naps, T. e.a. (2002). *Exploring the role of visualization and engagement in computer science education* (ITiCSE
  working group). Zie <https://cs.uef.fi/pub/Dissertations/myller.pdf>
- Sinha, T. & Kapur, M. (2021). *When problem solving followed by instruction works.* Review of Educational Research.
  Persbericht: <https://www.weforum.org/stories/education-and-skills/students-who-productively-fail-learn-more/>
- Renkl & Atkinson (fading); Schwonke e.a. (2009); Aleven & Koedinger (2002):
  <https://en.wikipedia.org/wiki/Worked-example_effect>,
  <https://learnlab.org/research/wiki/index.php/Does_learning_from_worked-out_examples_improve_tutored_problem_solving%3F>
- Dunlosky, J. e.a. (2013). *Improving students' learning with effective learning techniques.* Psychological Science in
  the Public Interest. <https://www.psychologicalscience.org/news/releases/which-study-strategies-make-the-grade.html>
- McLaren, B., Adams, D. e.a.: foute voorbeelden bij decimale getallen.
  <https://www.dfki.de/web/forschung/projekte-publikationen/publikation/8663>,
  <https://www.learningscientists.org/blog/2023/7/27>
- DragonBox en transfer: <https://edsurge.com/news/2016-03-13-enter-the-dragonbox-can-a-game-really-teach-third-graders-algebra>
- Wouters, P. e.a. (2013). *A meta-analysis of the cognitive and motivational effects of serious games.* Journal of
  Educational Psychology 105(2). <https://research-portal.uu.nl/en/publications/a-meta-analysis-of-the-cognitive-and-motivational-effects-of-seri/>
- Clark, D., Tanner-Smith, E. & Killingsworth, S. (2016). *Digital games, design, and learning.* Review of Educational
  Research. <https://www.sri.com/publication/education-learning-pubs/digital-learning-pubs/digital-games-design-and-learning-a-systematic-review-and-meta-analysis-brief/>
- Meta-analyse scaffolding in game-based learning (2021): <https://link.springer.com/article/10.1007/s10648-021-09655-0>
- Zachtronics in het onderwijs: <https://zachtronics.com/zachademics>

Kanttekening: van de meeste studies heb ik alleen de samenvatting of secundaire bronnen gelezen, niet de volledige tekst.
De cijfers hierboven komen uit die samenvattingen.
