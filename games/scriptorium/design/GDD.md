# Kortschrift — Game Design Document (v1)

Eigenaar: game designer. Lezers: core-engineer (`games/scriptorium/scripts/core/`), gameplay/front-end-engineer
(`games/scriptorium/scripts/game/`, `games/scriptorium/scenes/`), art & audio director (`design/ART.md`), QA.
Werktitel was *Scriptorium*; de map, de scènes en het klasseprefix `Sc` blijven zo heten.
Bron van de leerstof: lesnotas AD3 2026, **hoofdstuk 4 "Compressiealgoritmen"** (r. 4178–6329, gedrukte p. 81–122).
Pdf-pagina = gedrukte pagina. "r." = regel in het tekstextract `lesnotas_layout.txt`. **Bij twijfel gaan de notas voor.**

Elke boom, elke code, elk interval, elke bitstring, elk drietal, elk woordenboek, elke gesorteerde matrix en elk
move-to-front-getal in dit document werd nagerekend met een Python-referentie die de notas letterlijk volgt (Algoritme
9–14, de LZW-pseudocode, de Burrows-Wheeler-schetsen en move-to-front; staat niet in de repo). Die referentie
reproduceert cijfer voor cijfer: de stappen en de code van `boosdoeer` (p. 85, string `0001010001010101111011`), de
[gewicht, ordenummer]-boom van p. 90, de updates na `e` en `s` (p. 91–93), het volledige `graag`-voorbeeld (p. 96–98),
de partitie van x/y/z (p. 99–100), `banaan-baan` en `aanvaardbaar` (p. 106–108), `banaanaanval` en `97 110 256 258 115`
(p. 111–114), `geen loon` → `(1 ngen eool)` met de terugweg (p. 115–118), Figuur 26 (p. 120) en de move-to-front-reeks
`1,1,7,7,6,2,3,2,8,0,9` (p. 121–122). Twijfels en onregelmatigheden staan in §11.

Stijl (palet, vormen, fonts) bepaalt `ART.md`. Dit document legt enkel **functionele** eisen vast: wat leesbaar moet
zijn, wat beweegt en wanneer, wat de speler beslist.

Inhoud: 1 Pitch & pijlers · 2 Wereld & kernlus · 3 Mapping leerstof (per algoritme: speler/automatisch/fouten) ·
4 Bediening, schermen, HUD · 5 Campagne (alle levels) + Nachtwake · 6 Scoring, sterren, terugblik · 7 Juice & audio ·
8 Interface-contract core ↔ front-end · 9 Testgevallen · 10 Scope & prioriteiten · 11 Open vragen · Samenvatting.

---

## 1. Pitch & pijlers

### 1.1 Titel en genre
**Definitieve titel: KORTSCHRIFT** (ondertitel in het spel: *Het scriptorium van Zuinigem*). "Kortschrift" is het oude
Nederlandse woord voor stenografie: korter schrijven zonder dat er iets verloren gaat. Dat is precies hoofdstuk 4. Het
woord past naast "Hash & Dash", "Trietuin" en "TELEX" op de hubkaart. Voorstel aan de lead (§11 vraag 1); valt de keuze
op "Scriptorium", dan verandert er niets aan het ontwerp.

**Genre: ambachtelijke codeerpuzzel met briefwisseling.** De concept-richting van de lead (middeleeuwse
kopiistenwerkplaats, perkament en inkt zijn duur, elk algoritme is een ambacht) blijft. Ik heb ze op vier punten
aangescherpt:
1. **Elke brief wordt voorgelezen.** Elk level eindigt met *De Voorlezing*: aan de overkant leest **Broeder Letterlijk**
   je kortschrift hardop voor, letter per letter. Hij volgt de regels van de notas blind en raadt nooit. Een fout van jou
   wordt bij hem zichtbare onzin ("graggga", "eeeeeeeee", "aanvanrdbanr"). Daarom is decoderen even belangrijk als
   coderen. In bijna een derde van de levels zit je zelf aan de ontvangende kant.
2. **Twee abdijen, één structuur.** Bij de adaptieve algoritmen (adaptieve Huffman, LZ77, LZW, move-to-front) bouwen
   zender en ontvanger elk hun eigen boom, raam, stempelkast of letterplank op. Een venster *De Overkant* toont die van
   de ontvanger. Wijk je één keer af van het algoritme, dan lopen de twee structuren uit elkaar, en alles wat daarna
   komt, wordt onzin. Je ziet dat gebeuren.
3. **Inkt is de score, en ze zit in de wereld.** Elke bit is een druppel inkt. Bij Huffman is het **bindtouw** dat je
   verbruikt exact het aantal bits van het bericht: het gewicht van elke knoop telt één keer per bundel waarin hij zit.
   Zo ziet de speler Q(T) = Σ l(x)·a(x) (Stelling 21) groeien terwijl hij bindt. Het kortschrift moet in de **koker**
   van de postduif passen. Te lang betekent dat er een tweede duif nodig is.
4. **Gereedschap, geen formulieren.** Je bindt stapels perkament, laat een processie monniken van plaats wisselen,
   knipt een meetlat in, legt een leesraam over de tekst, snijdt stempels, draait een trommel en schuift blokken op een
   plank. Je typt nergens een antwoord in een vakje.

Waarom anders dan de andere games: **Hash & Dash** is een drukke management-arcade, **Trietuin** rustig organisch bouwen
met een testrun, **TELEX** een mechanische spionagethriller met tijdsdruk en machines. **Kortschrift** is
*handwerk aan een schrijftafel bij kaarslicht*: traag, tactiel, stil. De spanning zit niet in een klok maar in het
moment waarop de duif aankomt en een andere monnik leest wat jij schreef. Referenties: *Opus Magnum* (precies
gereedschap), *Return of the Obra Dinn* (rustig deduceren, het antwoord klopt of niet), *Cozy Grove*/*Unpacking*
(gezellig, tastbaar), *Papers, Please* (gevolgen pas later zichtbaar).

### 1.2 Pitch
Vlaanderen, ergens in de twaalfde eeuw. In de abdij van **Zuinigem** is perkament duur en inkt nog duurder, en de
postduiven dragen maar een kokertje. Jij bent de nieuwe **novice** in het scriptorium. **Broeder Zeno**, de oude
bibliothecaris, leert je het kortschrift: berichten zo kort mogelijk opschrijven *zonder één letter te verliezen*.
Kelner **Gommaar** telt elke druppel inkt. Doorheen het kloosterjaar ontvang je brieven en opdrachten van zes andere
huizen, en elk huis brengt je een nieuw werktuig: de **binderij** (Huffman), de **levende boom** (adaptieve Huffman),
de **meetlat** (aritmetisch coderen), het **leesraam** (LZ77), de **stempelkast** (LZW) en de **draaitrommel** met de
**letterplank** (Burrows-Wheeler en move-to-front). Op Allerheiligen schrijf je de **Codex**: één gezang door de hele
keten van trommel, plank en binderij, korter dan alles wat de abdij ooit verstuurde.

Wie Kortschrift uitspeelt, heeft zelf Huffman-bomen gebonden (Algoritme 9, en de twee-plankenmethode van Oef. 85), de
sibling property bewaakt en het speciale geval van Algoritme 11 meegemaakt, intervallen ingeknipt en de kortste
bitstring gezocht (Algoritme 12/13), langste matches gevonden die buiten het raam doorlopen (Algoritme 14), stempels
gesneden, inclusief de stempel die nog niet bestaat (LZW), rotaties gesorteerd en de magische terugweg gelopen (BWT),
en de letterplank leren tellen (move-to-front). Het spel vraagt dat nergens als quiz. Je doet het omdat Broeder
Letterlijk anders onzin voorleest.

### 1.3 Pijlers
1. **Het werktuig ís het algoritme.** Elk onderdeel komt overeen met een begrip uit de notas: stapel = boom met
   frequentie a(x), bundel = nieuwe wortel Z met a(Z) = a(X) + a(Y), processie = de ordenummers o(t), nng-zaadje =
   het teken nng, meetlat = [links, links+lengte), binaire naald = Algoritme 13, leesraam = sliding window van grootte G,
   zegel = drietal (p, l, x), stempel = woordenboekcode, trommel = cyclische tekst, rek = gesorteerde rotaties,
   plank = move-to-front-lijst. Er bestaat geen spelregel naast de leerstof.
2. **Gevolgen in de wereld, nooit "fout".** Een verkeerde keuze kost inkt (de koker raakt te vol en er moet een tweede
   duif uitvliegen) of maakt de voorlezing aan de overkant tot onzin (de kok kookt "graggga"). Wat in het algoritme
   onmogelijk is, kan ook in het spel niet: een top wisselen met zijn eigen voorouder, een stempel gebruiken die nog
   niet gesneden is, buiten het leesraam beginnen. Dan hoor je een **klem** (het gereedschap weigert en veert terug) en
   er verschijnt geen tekst.
3. **Inkt is zichtbaar en eerlijk.** De inktpot loopt leeg per bit. Naast je inkt staan altijd twee geesten: *gewoon
   schrift* (8 bits per letter, of de vaste lengte ⌈log₂ k⌉) en het *optimum*. Na elk level weet je precies hoeveel
   druppels je bespaarde en hoeveel je verspilde.
4. **Coderen en decoderen zijn één ambacht.** Elk hoofdstuk heeft levels aan de zendende én aan de ontvangende kant.
   De voorlezing toont altijd beide kanten naast elkaar: wat jij bedoelde en wat er gelezen werd.
5. **Gezellig, maar met gewicht.** Kaarslicht, krassende ganzenveer, het knarsen van bindtouw, het ploffen van een
   stempel, een draaiende houten trommel, koerende duiven en een klok bij een geslaagde voorlezing. Geen tijdsdruk in de
   campagne. De spanning komt van het wachten op de voorlezing. Enkel de eindeloze **Nachtwake** heeft een kaars die
   opbrandt.

### 1.4 Doelgevoel (wat de speler na afloop zegt)
- "Een prefixcode: geen codewoord is het begin van een ander. Dan weet de lezer altijd waar een letter stopt."
- "Huffman: bind telkens de twee lichtste stapels. Het touw dat je verbruikt, is het aantal bits."
- "Bij gelijke gewichten maakt het niet uit welke je kiest. Elke boom is even goed (p. 84)."
- "Adaptief: eerst schrijven met de oude boom, dan de boom aanpassen. Bij elke stap wissel ik met de top met hetzelfde
  gewicht en het hoogste ordenummer. Is dat mijn ouder, dan wissel ik niet."
- "Een nieuwe letter: eerst de code van nng, dan de letter zelf in acht bits."
- "Aritmetisch: links += f·lengte, lengte ×= p. Daarna ga ik van onder naar het interval toe met halve stappen,
  en ik stap nooit boven de bovengrens."
- "Veertig letters in één bit: het interval bevat 0,5."
- "LZ77: de match moet in het raam beginnen, maar mag erbuiten doorlopen. (0,9,EOF) na `bla` geeft `blablablabla`."
- "LZW: verlengen zolang het woord in de kast zit. Bij decoderen: is de code er nog niet, dan is het w plus w[0]."
- "BWT: sorteer de rotaties en neem de laatste kolom. De k-de e in de laatste kolom is de k-de e in de eerste."
- "Move-to-front: de positie in de lijst van dát moment, vanaf 0, en daarna naar voren."

### 1.5 Waarom dit leuk is (en geen quiz)
- **De voorlezing is een beloning én een spiegel.** Het mooiste moment van elk level: de duif landt, Letterlijk schraapt
  zijn keel en leest. Klopt alles, dan luidt de klok en zingen de broeders. Klopt het niet, dan hoor je precies waar het
  misgaat, en de terugblik toont de oorzaak.
- **Tastbaar ambacht met variatie in gevoel:** binden (gewicht, touw), de processie herschikken (een levende boom),
  knippen en inzoomen op een meetlat (duizelingwekkend klein), patroonzoeken in een raam (de "aha" van overlappende
  matches), stempels snijden (een kast die groeit), rollen en sorteren (een gezang dat in blokken uiteenvalt).
- **Ontdekken in plaats van lezen.** In het Duiventil ontdek je zelf dat geen enkel algoritme alles korter maakt
  (Oef. 76). In "Veertig letters, één bit" zie je aritmetisch coderen Huffman vernederen. In de Codex zie je dat een
  transformatie die niets korter maakt (BWT, move-to-front) de binderij plots veel beter laat werken.
- **Verhaal en verzamelen.** Elk huis in het kloosterjaar stuurt een brief (een receptuur, een gezang, een uitnodiging).
  Geslaagde brieven komen als verluchte initialen in je **getijdenboek** (de kaart). Op Allerheiligen volgt de Codex.
- **Meesterschap.** De *Nachtwake*: een eindeloze bindsessie bij een opbrandende kaars, met combo's en een highscore.

---

## 2. Wereld & kernlus

### 2.1 De wereld
- **Het scriptorium van Zuinigem:** één grote schrijftafel bij een raam (de **werkbank**). Bovenaan ligt de opdracht op
  een perkamentband, onderaan het **kortschrift** (de uitvoer) op een smalle strook. Rechts het **venster naar de
  Overkant**: de lessenaar van de ontvangende abdij met Broeder Letterlijk, zijn kopie en (bij adaptieve werktuigen)
  zijn eigen boom, raam, kast of plank in het klein.
- **Broeder Zeno** (mentor): oude bibliothecaris, droog en vriendelijk. Hoogstens één zin (≤ 12 woorden) per keer, enkel
  in briefings, tutorials, hints en de terugblik.
- **Broeder Letterlijk** (de lezer): leest elk kortschrift exact volgens de regels. Hij is de referentie-decoder
  (`ScReader`, §8). Hij raadt nooit, verbetert nooit en leest bij een niet-prefixcode het eerste codewoord dat hij
  herkent (§3.2).
- **Kelner Gommaar** (de boekhouder): telt inkt en duiven. Hij verschijnt in de terugblik met zijn kasboek (de tellers).
- **De huizen** (één per hoofdstuk; fictief):

| hoofdstuk | huis | werktuig (spel) | algoritme (notas) |
|---|---|---|---|
| Proloog · Advent | Zuinigem zelf | **codeboom**, **codebord**, **duiventil** | prefixcodes, Def. 20, Fig. 24/25, Oef. 76–79 (p. 81–84) |
| 1 · Kerstmis | Priorij Bindervoort | **binderij** | Huffman, Algoritme 9, Stelling 21, Oef. 80–86 (p. 84–88) |
| 2 · Vasten | Klooster Groeiendonk | **levende boom** + **processie** | adaptieve Huffman, Lemma 22, Algoritme 10/11, Oef. 88–91 (p. 89–98) |
| 3 · Pasen | Kartuis Meetendaal | **meetlat** + **binaire naald** | aritmetisch coderen, Algoritme 12/13, Lemma 24, Oef. 92–96 (p. 98–104) |
| 4 · Pinksteren | Priorij Zoalsboven | **leesraam** (+ **register**) | LZ77, Algoritme 14, §4.3.1, Oef. 97–100 (p. 104–110) |
| 5 · Hooimaand | Abdij Stempelrode | **stempelkast** | LZW, coderen/decoderen + speciaal geval, Oef. 101–103 (p. 110–115) |
| 6 · Wijnmaand | Kluis Ter Rolle | **draaitrommel** + **letterplank** | Burrows-Wheeler, move-to-front, Oef. 104–110 (p. 115–122) |
| Allerheiligen | de hele orde | alles samen: **de Codex** | BWT → move-to-front → Huffman (p. 122) |

### 2.2 Gemeenschappelijke onderdelen van de werkbank (functioneel bindend)
| onderdeel | betekenis (notas) | gedrag |
|---|---|---|
| **opdrachtband** | de tekst s[0..n−1] die gecodeerd moet worden | perkamentband bovenaan, één teken per vakje (mono), positie eronder (0-gebaseerd). Cursor op het volgende teken. Spatie toont als `␣`, een liggend streepje als `_` (§3.0) |
| **kortschrift** | de uitvoer: bits, drietallen, codes, (p, laatste kolom), getallen | smalle strook onderaan. Bits als kleine inktstreepjes (0 = kort, 1 = lang, plus het cijfer), ruwe letters als **lakzegel** met de letter, drietallen als **wassen zegel** "(p,l,x)", LZW-codes als **stempelafdruk** met het getal |
| **inktpot + koker** | kost (bits of zegels of stempels) | inktpot met druppelteller. Rechts de **koker** van de duif: zijn lengte = het optimum van het level. Steekt de strook uit de koker, dan vliegt er een tweede duif (gevolg, §6) |
| **geesten** | vergelijkingswaarden | twee grijze streepjes op de inktmeter: *gewoon schrift* (8 bits per teken) en, bij Huffman, *vaste lengte* (⌈log₂ k⌉ bits per teken) |
| **venster De Overkant** | de ontvanger | lessenaar met Letterlijks kopie. Bij adaptieve werktuigen ook zijn structuur (boom, raam, kast, plank) in het klein, telkens bijgewerkt **nadat** jij een teken afgewerkt hebt |
| **Zeno-ballon** | hint/tutorial | ≤ 12 woorden |
| **inkthand** (spookhand) | hint of tutorial | een doorschijnende hand doet de juiste zet voor (`correct_move()`) |

### 2.3 Kernlus per level ("een brief", 2–6 min)
1. **Brief (≤ 8 s, skipbaar):** een gezegelde brief van het huis van dit hoofdstuk gaat open: de opdracht (de tekst of
   het kortschrift dat je krijgt), één zin van Zeno, notasverwijzing ("Oefening 80 · notas p. 86"). Bij een nieuw
   werktuig gaat eerst een **houten kist** open met het werktuig (1,5 s).
2. **Werk:** je gebruikt het werktuig. Wat automatisch gaat (tellen, het kopiëren van bits, het doorlopen van een
   match, het hernummeren), doet de **kopiist** (een helper aan de tafel). De speler neemt enkel de beslissingen van het
   algoritme.
3. **Verzegelen en verzenden** (zendlevels): het kortschrift wordt opgerold. Past het in de koker, dan vertrekt één duif,
   anders twee. De duif vliegt naar het venster De Overkant (2 s, skipbaar).
4. **De Voorlezing:** Letterlijk leest. Zijn kopie verschijnt letter per letter onder het origineel. Een gelijke letter
   krijgt een gouden stip, een verschillende wordt in bruine inkt geschreven met een inktvlek. In ontvangstlevels lees je
   zelf, en na afloop legt Zeno het origineel van de afzender naast je kopie.
5. **Terugblik (Kapittel):** sterren als lakzegels, inkt vs. optimum vs. gewoon schrift, je structuur naast de juiste,
   een tijdlijn met je misstappen. Klik op een misstap om dat moment opnieuw te zien (jouw zet, dan de juiste als
   inkthand), met één coachzin en een notasverwijzing (§6.5).

### 2.4 Microlus (voorbeeld: binderij, `boosdoeer`, notas p. 84–85)
Op de tafel liggen zes stapels perkamentstrookjes in de volgorde van de notas: **b:1 o:3 e:2 s:1 d:1 r:1**. De speler
klikt `b` en dan `s` (de twee lichtste). De kopiist bindt ze met touw tot een bundel met gewicht 2. De bundel komt op de
plaats van `b`, met `b` links (0) en `s` rechts (1). De touwteller springt van 0 naar 2. Daarna `d` + `r` (touw 4), dan
de twee bundels van gewicht 2 (touw 8; `e` kon ook, Zeno: "Niet uniek. Elke keuze is even goed."), dan `o` + `e`
(touw 13) en ten slotte de twee grote bundels (touw **22**). Het codeboek ontrolt zich: b 000, s 001, d 010, r 011,
o 10, e 11, precies p. 85. De kopiist schrijft `0001010001010101111011` (22 druppels, dezelfde 22 als het touw). De
strook past exact in de koker. Aan de overkant leest Letterlijk "b-o-o-s-d-o-e-e-r". De klok luidt.

---

## 3. Mapping spel ↔ leerstof (volledig)

Per werktuig: (a) tabel notas ↔ spel, (b) wat de speler doet en wat automatisch gaat, (c) fouten en hun gevolg.

### 3.0 Algemene conventies (functioneel bindend)
- **Posities zijn 0-gebaseerd**, zoals de notas waar die posities gebruiken: sliding window "het eerste teken krijgt de
  positie 0" (p. 106), de rijen van de gesorteerde BWT-matrix "als wij met 0 beginnen te tellen" (p. 117), de
  move-to-front-codes c( ) = 0 (p. 121). LZW-codes zijn ASCII-waarden (a = 97), nieuwe woorden vanaf 256 (p. 110–111).
- **Tekens:** kleine letters, cijfers, `-`, `_` en de spatie. **De spatie** (code 32) toont als `␣`. Ze is kleiner dan
  alle letters en cijfers (p. 116: "een blank is kleiner dan de lettertekens"; p. 121: code 32 komt vóór de cijfers).
  **Het liggend streepje `_`** (code 95) staat letterlijk in Oef. 81, 97 en 101 (`zaken_nemen_geen_keer`,
  `swiss_miss_missing`, …) en blijft daar een gewoon teken. In Oef. 104/105 drukken de notas de spatie als een zichtbaar
  streepje af (`toon_gaat`, lijst `(_,0,1,…)`); het spel gebruikt daar de spatie (§11 vraag 4).
- **Bits:** links = 0, rechts = 1 in elke boom (p. 83, Fig. 24/25). Een ruwe letter na nng kost **8 bits** ("bv. één
  byte", p. 94). Een LZW-code kost 12 bits ("meestal 12 bits", p. 110); het spel telt LZW in **stempels** en vermeldt de
  bits in de terugblik.
- **Inkt** = de kost van de uitvoer, in de natuurlijke eenheid van het werktuig: bits (codeboom, binderij, levende
  boom, meetlat, Codex), **zegels** (drietallen, leesraam) of **stempels** (codes, stempelkast). Draaitrommel en
  letterplank maken niets korter (p. 119, p. 122). Daar telt het spel geen inkt, maar wel **nullen** en "kleine
  getallen" (≤ 2).
- **Klem** (`ok = false`) = fysiek of algoritmisch onmogelijke zet. De staat verandert niet. Klemmen tellen niet als
  misstap, maar worden wel geteld. ★★★ vraagt er 0 in de levels waar dat in de voorwaarde staat.
- **Misstap** = een uitgevoerde zet met verdict ≠ OK. Het gevolg speelt zich af in de wereld (inkt of onzin). Het
  oordeel is **lokaal**: de core vergelijkt met `correct_move()` gerekend op de **toestand van de speler**, zodat één
  fout één misstap blijft. De gevolgen lopen wel door.
- **Zender/ontvanger:** zendlevels (`side = "send"`): de speler codeert, Letterlijk (de referentie-decoder) leest de
  uitvoer. Ontvangstlevels (`side = "receive"`): de speler decodeert een correct kortschrift. Zijn kopie wordt na afloop
  met het origineel vergeleken.
- **Verliesloos is de lat.** ★ vraagt altijd dat de voorlezing (of je kopie) exact gelijk is aan het origineel. Wie
  onzin liet lezen, krijgt 0 sterren maar kan vanuit de terugblik **hernemen vanaf vóór de misstap** (telt als hulp).

### 3.1 Prefixcodes lezen (Definitie 20, Fig. 24/25, r. 4273–4345, p. 82–84) — werktuig *codeboom*
| notas | in het spel | waarom zo |
|---|---|---|
| prefixcode: geen woord is het begin van een ander (Definitie 20) | een **codeboom** uit hout: letters hangen enkel aan bladeren | de prefixeigenschap = "een blad heeft geen kinderen" (p. 83) |
| decoderen: volg de takken tot een blad, schrijf het teken, begin opnieuw bij de wortel (p. 83) | de **leesvinger** volgt de bits. De speler klikt het blad waar de volgende bits naartoe leiden. De vinger loopt het pad af, de strook wordt na dat codewoord afgeknipt en de letter komt in de kopie | de beslissing is "waar eindigt dit codewoord?" |
| Fig. 25, `00010011` = `oud`; Oef. 79, `100001011` | level 0-1 | — |

**Speler doet:** per codewoord het blad kiezen. **Automatisch:** de vinger, het knippen, de kopie.
**Fouten → gevolg:** een blad kiezen waar de bits niet naartoe leiden, kan niet: de vinger vindt het pad niet (klem
`no_path`). De codeboom kent dus enkel klemmen. Hij is de tutorial voor het lezen, de echte keuzes komen later (de boom
die je bijhoudt in hoofdstuk 2).

### 3.2 Waarom prefix? (de "eerste aanzet", r. 4273–4286, p. 82) — werktuig *codebord*
| notas | in het spel | waarom zo |
|---|---|---|
| codes met variabele lengte zonder prefixeigenschap: "Waar zijn bv. de grenzen in 1111101101010111010111?" | stage *Grenzen*: de kelner stuurt een kortschrift in zijn eigen code (e = 0, n = 1, b = 10). De speler **knipt** de strook in codewoorden. Een knip waarvoor het stuk geen codewoord is, klemt. Elke volledige lezing komt op een lijst | de speler ontdekt zelf dat één strook meerdere betekenissen heeft |
| prefixcode ↔ boom met letters aan de bladeren (Fig. 24/25) | stage *Codebord*: een leeg houten boomraam (diepte ≤ 3). De speler hangt lettertegels aan knopen; het pad is het codewoord | ontwerpen vóór Huffman: frequente letters hoog |
| Σ a(x)·l(x) minimaliseren (p. 84) | de inktpot telt Σ a(x)·l(x) live mee | — |

**Broeder Letterlijk en niet-prefixcodes** (spelafspraak, §11 vraag 8): hij leest van links naar rechts en neemt telkens
het **kortste** codewoord dat hij herkent. Bij een prefixcode is dat de enige juiste lezing. Bij een andere code
leest hij vaak iets anders dan bedoeld.

**Speler doet:** knippen (stage A); tegels hangen en verzenden (stage B). **Automatisch:** de lezingenlijst, de
inktteller, de voorlezing.
**Fouten → gevolg:** een code die geen prefixcode is (`NOT_PREFIX`): Letterlijk leest onzin (bv. `benen` → `neenen`).
Een prefixcode die duurder is dan nodig (`LONG_CODE`): het bericht past niet in de koker en er vliegt een tweede duif.

### 3.3 Huffman (Algoritme 9, Stelling 21, r. 4360–4593, p. 84–88) — werktuig *binderij*
| notas | in het spel | waarom zo |
|---|---|---|
| "bepaal voor elk teken x de frequentie a(x)" | de kopiist turft de opdracht en legt per teken een **stapel** strookjes met het getal a(x). Volgorde van de rij = volgorde van eerste voorkomen in de tekst, behalve waar het level de volgorde van de notas overneemt (1-1: b o e s d r zoals p. 85) | tellen is geen beslissing |
| kies X met de kleinste frequentie, dan Y met de kleinste van de rest; nieuwe wortel Z, a(Z) = a(X) + a(Y) | **binden**: klik twee stapels. De kopiist bindt ze tot een bundel met het somgewicht. De bundel komt op de plaats van de meest linkse van de twee; de linkse wordt het 0-kind, de rechtse het 1-kind (zo staan ze in de figuur op p. 85) | de keuze van het paar is de beslissing |
| "De boom zal niet uniek bepaald zijn, maar alle bomen … zijn even goed" (p. 84), "derde stap (niet uniek!)" (p. 85) | **elk** paar dat Algoritme 9 toelaat, is correct. De inkthand en het orakel volgen één vaste keuze: de **twee-plankenregel** van Oef. 85 (bij gelijk gewicht eerst een al gebonden bundel, de oudste eerst, dan losse stapels van links naar rechts). Die reproduceert p. 85 exact | getrouw aan "niet uniek", en de spookhand toont de figuur van de notas |
| Q(T) = Σ l(x)·a(x) is minimaal (Stelling 21) | het **bindtouw**: elke binding kost a(Z) touw. Totaal touw = Σ gewichten van de interne toppen = Q(T) = het aantal bits van het bericht | Stelling 21 wordt een voelbare grootheid |
| de code = de boom + de string (p. 86) | na de laatste binding: het codeboek ontrolt zich (codes van de bladeren). De kopiist schrijft het bericht. De duif neemt boom en strook mee | — |
| Oef. 83/86: samenvoegen met kost d1 + d2 | level 1-4 (bundels zonder letters, enkel gewichten) | dezelfde handeling, ander verhaal |
| Oef. 85: twee lijsten (a) gesorteerd, (b) nieuwe bomen achteraan | level 1-5 *Twee planken*: plank A (gesorteerde stapels) en plank B (nieuwe bundels achteraan). Je mag enkel van de **voorkant** van een plank nemen. Een teller **zoekwerk** toont hoeveel stapels je moest vergelijken | O(n) na het sorteren, zichtbaar |

**Speler doet:** per binding twee stapels kiezen. **Automatisch:** tellen, binden, het codeboek, het schrijven, de
voorlezing.

**Fouten → gevolg**

| fout | kan het? | gevolg | wanneer zie je het |
|---|---|---|---|
| een paar dat Algoritme 9 niet toelaat (een te zware stapel) | ja | `WRONG_PAIR`: de boom blijft een prefixcode, dus Letterlijk leest alles juist, maar het touw (= de bits) loopt op. Bv. `boosdoeer` met eerst b + o: 23 in plaats van 22 → de strook steekt uit de koker, er vliegt een tweede duif | de touwteller kleurt amber zodra het touw boven de optimale lijn komt; de koker bij het verzenden |
| een stapel met zichzelf binden | **nee** | klem `same` | — |
| (twee planken) een stapel nemen die niet vooraan ligt | **nee** | klem `not_front` | — |

### 3.4 Adaptieve Huffman (Lemma 22, Algoritme 10/11, r. 4594–5121, p. 89–98) — werktuig *levende boom*
| notas | in het spel | waarom zo |
|---|---|---|
| bij elke top [g, o]: gewicht en ordenummer (p. 89–90) | elke top is een **monnik** met een kaartje [gewicht, nummer]. Onder de boom loopt de **processie**: dezelfde monniken op één rij, gesorteerd op ordenummer (1 links … 2n−1 rechts) | eigenschap (b) wordt zichtbaar als een trap die nooit daalt |
| (a) gewicht = som van de kinderen; (b) o(t) < o(t′) ⇒ a(t) ≤ a(t′); (c) 2j−1 en 2j zijn broers (Lemma 22) | (a) automatisch; (b) de processie: daalt de trap ergens, dan **struikelt** een monnik (gevolg); (c) broers lopen in de processie hand in hand | Lemma 22 als beeld |
| eerst coderen met de boom **vóór** de wijziging (p. 92) | fase **SCHRIJF**: klik het blad van het teken (of het **nng-zaadje** bij een nieuw teken). De kopiist schrijft het pad, bij nng gevolgd door een lakzegel met de letter (8 bits). Het eerste teken van een tekst gaat ruw, zonder nng-code (`"g"`, p. 96) | de volgorde coderen → bijwerken is de les |
| nieuw teken: nng wordt een boompje (o met nng en het teken), nng houdt 1, het teken 2, o 3, alle andere +2; o "alsof van 0 naar 1"; start bij de ouder van o (p. 95) | fase **GROEI** (automatisch): het zaadje splitst in twee monniken, de processie schuift twee plaatsen op | geen beslissing in de notas |
| `t′ = de top x met a(x) = a(t) en o(x) maximaal; als t′ niet de ouder is van t: wissel t en t′ (en hun ordenummers); verhoog a(t); t = ouder` (Algoritme 11) | fase **KLIM**: een lantaarn hangt bij t. De speler klikt de **wisselpartner** t′ (de monnik met hetzelfde gewicht die het verst in de processie staat), of klikt t zelf ("blijf staan") als t al de verste is of als die verste zijn ouder is. Daarna: wissel (de twee deelbomen ruilen van plaats in boom en processie), gewicht +1, de lantaarn gaat naar de ouder. Bij de wortel: +1 automatisch | het hart van het algoritme is de keuze van t′ |
| "je kan de top niet vervangen door een boom waar die zelf inzit" (p. 95) | wisselen met een voorouder of een nakomeling kan niet: klem `ancestor` | het speciale geval wordt fysiek gevoeld |
| decoderen: hetzelfde, eerst lezen, dan dezelfde wijziging (p. 98) | ontvangstlevels: fase **LEES** (zoals de codeboom: klik het blad waar de bits naartoe leiden; nng → het lakzegel gaat open), daarna GROEI en KLIM | beide abdijen houden dezelfde boom bij |
| Algoritme 10 op een gegeven boom (p. 91–93: `boosdoeer` + `e`, + `s`) | level 2-1 | — |
| `graag` (p. 96–98), Oef. 90, 91 | levels 2-2, 2-4, 2-5 | — |

**Speler doet:** per teken het blad kiezen (zenden) of het pad volgen (ontvangen); per stap van de klim t′ kiezen of
blijven staan. **Automatisch:** schrijven, groeien en hernummeren, gewichten, de wortel, De Overkant.

**Fouten → gevolg**

| fout | kan het? | gevolg | wanneer |
|---|---|---|---|
| zenden: een ander blad dan het teken | ja | `WRONG_LEAF`: Letterlijk leest dat andere teken en werkt **zijn** boom met dat teken bij, jij met het echte. Vanaf dan lopen de bomen uiteen | meteen in zijn kopie; zijn miniboom verschilt |
| zenden: nng kiezen voor een teken dat al in de boom zit | ja | `WRONG_LEAF`, maar onschadelijk: Letterlijk leest nng + de letter, ziet dat de letter al bestaat en werkt dezelfde top bij (Algoritme 11: "als z in de boom zit"). Kost: code(nng) + 8 bits in plaats van de korte code | inktpot |
| zenden: een bestaand blad kiezen voor een nieuw teken | ja | `WRONG_LEAF`: hij leest een oude letter, jij voegt een nieuwe toe → uiteen | meteen |
| klim: blijven staan terwijl er een verdere monnik met hetzelfde gewicht is | ja | `MISSED_SWAP`: jouw boom is niet meer die van Algoritme 11 (vaak breekt eigenschap (b): een monnik struikelt). Jouw volgende codes worden met een andere boom gelezen → onzin. Bv. `graag` zonder de wissel bij de eerste `a`: jij schrijft `"g"0"r"00"a"001001`, Letterlijk leest **`graggga`** | meteen (processie, miniboom), de onzin bij de volgende letters |
| klim: wisselen met een verkeerde monnik (ander gewicht of niet de verste) | ja | `WRONG_SWAP`: idem | idem |
| klim: wisselen met de ouder (het speciale geval) of een andere voorouder/nakomeling | **nee** | klem `ancestor` (Zeno, eerste keer: "Een monnik kan niet ruilen met zijn eigen stoet.") | — |
| ontvangen: een blad kiezen waar de bits niet naartoe leiden | **nee** | klem `no_path` (de bits beslissen) | — |
| ontvangen: een klimfout | ja | jouw boom wijkt af van die van de afzender. De volgende bits leiden in jouw boom naar andere bladeren → jouw kopie wordt onzin, of de strook raakt "onleesbaar" (een lakzegel midden in een pad) | in je eigen kopie |

### 3.5 Aritmetisch coderen (Algoritme 12/13, Lemma 24, r. 5122–5434, p. 98–104) — werktuig *meetlat*
| notas | in het spel | waarom zo |
|---|---|---|
| model: tekens in een vaste volgorde, kansen p(t), f(t_i) = Σ_{j<i} p(t_j) (p. 99, 101) | de **meetlat**: een staande el van 0 (onder) tot 1 (boven), zoals de figuren op p. 99–100. Het huidige interval vult altijd de hele lat. Het is verdeeld in gekleurde vakken in de volgorde van het model (x onder, dan y, dan z) met hoogte p(t) | de partitie van p. 99–100 |
| `links = links + f(s[i])·lengte; lengte = lengte·p(s[i])` (Algoritme 12) | **knippen**: klik het vak van het volgende teken. De schaar knipt het uit en de lat zoomt in (het vak wordt de nieuwe lat). Het **rekenboek** naast de lat noteert i, teken, links, lengte | — |
| [a, b) halfopen (p. 99) | de onderrand van een vak is een volle lijn, de bovenrand een stippellijn | belangrijk bij het decoderen (0,9 → z) |
| Algoritme 13: getal = 0, next = ½; `if getal+next < up: output 1, getal += next, stop als getal ≥ low; else output 0`; next /= 2; `low = 0 → output 0` | de **binaire naald**: een getallenlijn [0, 1) met het eindinterval [low, up) in goud. De naald staat op `getal`, een spookstreep op `getal + next`. De speler kiest **1 (stap)** of **0 (blijf)**. De naald stopt vanzelf zodra ze in het goud staat. Bij low = 0 schrijft de kopiist meteen `0` | "wij letten alleen op dat wij nooit een te groot getal kiezen" wordt een fysieke grens |
| decoderen (Oef. 94/95): bits → getal r, telkens het deelinterval dat r bevat | ontvangstlevels: een **speld** steekt op r (de waarde van de bits). De speler klikt het vak waarin de speld zit. De lat zoomt in | het lezen van een getal |
| n moet mee (p. 102, (a)) | de brief vermeldt de lengte n | — |
| precisie (p. 103, (b)) | de core rekent **exact** (decimale grote getallen, `ScDec`, §8). De lat toont tot 12 beduidende cijfers, met een vergrootglas voor alle cijfers | de 40-letter-tekst heeft 40 decimalen nodig |
| Lemma 24: ⌈log₂(1/l)⌉ bits volstaan | de terugblik toont de grens naast het werkelijke aantal bits | — |

**Speler doet:** per teken een vak knippen; de naald stap voor stap; (ontvangen) per teken het vak van de speld.
**Automatisch:** het rekenwerk, het inzoomen, het rekenboek, de stop van de naald.

**Fouten → gevolg**

| fout | kan het? | gevolg |
|---|---|---|
| een ander vak knippen dan het teken | ja | `WRONG_SEGMENT`: je codeert een ander teken. Letterlijk leest het ook zo (onzin op die plaats, de rest klopt weer) |
| naald: **1** terwijl getal + next ≥ up | ja | `OVERSHOOT`: de naald schiet boven het goud uit. De strook is meteen af (getal ≥ low) maar stelt een getal buiten het interval voor → Letterlijk leest een andere tekst. Bv. `cag` met als eerste bit 1: hij leest **`gaa`** |
| naald: **0** terwijl de stap paste en getal + next ≥ low | ja | `LONG_BITS`: je had kunnen stoppen. De naald gaat verder met kleinere stappen; de strook wordt langer maar blijft correct |
| naald: **0** terwijl de stap paste en getal + next ≤ low | ja | `UNREACHABLE`: alle resterende halve stappen samen (= next) halen het goud niet meer. De naald zakt terug naar 0 en de strook wordt gewist (de inkt is wel op) |
| ontvangen: een vak waarin de speld niet zit | **nee** | klem `no_pin` |
| ontvangen: het vak **onder** de speld als de speld exact op een grens staat | ja | `WRONG_EDGE`: [a, b) bevat b niet. Je schrijft het verkeerde teken; daarna hangt de speld aan de open bovenrand en leest elk volgend vak als het bovenste teken → onzin |

### 3.6 LZ77 (Algoritme 14, r. 5435–5683, p. 104–109) en §4.3.1 (r. 5684–5724, p. 109–110) — werktuig *leesraam*
| notas | in het spel | waarom zo |
|---|---|---|
| sliding window van de laatste G tekens, in het begin leeg (p. 105) | het **leesraam**: een houten raam van G vakjes over het al geschreven stuk. Posities in het raam van links, vanaf 0 (p. 106: "In de les gebruiken wij alleen deze codering") | — |
| langste match die **in het raam begint**, maar erbuiten mag eindigen (p. 105, Oef. 97: "Denk eraan …") | **beginnen**: klik een letter in het raam. Een draad loopt van daar letter per letter mee met de tekst die gecodeerd moet worden, zolang ze gelijk zijn. Hij loopt zonder pauze over de rand van het raam heen | de overlap is de "aha" |
| drietal (p, l, x), x = het teken na de match (of EOF) | de kopiist drukt het zegel "(p,l,x)" | — |
| geen match → (0, 0, x) ("neem gewoon p = 0", p. 106) | knop **"Geen match"** (zegel (0,0,x)) | — |
| volgende positie k + l + 1 | het raam schuift mee | — |
| meerdere langste matches | de notas kiezen er geen. Elke positie met de maximale lengte is correct; de inkthand neemt de kleinste p (§11 vraag 6) | — |
| decoderen: hetzelfde raam, het woord staat altijd ter beschikking (p. 107–108) | ontvangstlevels: een zegel (p, l, x) komt binnen. De speler klikt positie p in het raam. De kopiist kopieert l letters **één voor één** (zodat een overlap zichtbaar zichzelf voedt) en schrijft x. Zegels met l = 0 gaan automatisch | — |
| §4.3.1: zonder raam, deelstringboom, O(1) per teken | P1-level 4-6 *Het register*: het raam is oneindig en de **registerboom** (de deelstringboom van wat al geschreven is) zoekt mee. Teller *zoekwerk*: vergelijkingen met register (één per letter) vs. zonder (het hele raam aflopen) | de winst van §4.3.1 als getal |

**Speler doet:** per drietal de beginpositie kiezen of "Geen match" (zenden); per drietal met l > 0 de positie p
aanwijzen (ontvangen). **Automatisch:** de draad, de lengte, het zegel, het schuiven van het raam, het kopiëren.

**Fouten → gevolg**

| fout | kan het? | gevolg |
|---|---|---|
| een beginpositie met een kortere match dan de langste | ja | `SHORT_MATCH`: meer zegels, dus meer inkt. Letterlijk leest alles nog juist |
| "Geen match" terwijl er een match is | ja | `SHORT_MATCH` (idem) |
| een beginletter die niet gelijk is aan de volgende letter | **nee** | klem `no_match` (de draad kan niet vertrekken) |
| buiten het raam klikken | **nee** | klem `out_of_window` |
| ontvangen: een verkeerde p (bv. tellen vanaf het begin van de tekst, of vanaf 1) | ja | `WRONG_POS`: verkeerde letters gekopieerd. Het raam bevat daarna onzin die verder gekopieerd wordt. Bv. `aanvaardbaar` met p = 1 in plaats van 0 bij (0,2,r): **`aanvanrdbanr`** |

### 3.7 LZW (r. 5725–5941, p. 110–115) — werktuig *stempelkast*
| notas | in het spel | waarom zo |
|---|---|---|
| beginwoordenboek: alle tekens met hun code (0…255) | de **stempelkast**: 256 laden met lettertjes. Vooraan hangen enkel de tekens die in het level voorkomen, met hun nummer (`a 97`, `b 98`, `␣ 32`, `_ 95`, `- 45`); de rest zit achter een luikje | de codes van de notas (b = 98) |
| `k = volgend teken; if wk in woordenboek: w = wk; else output code(w), voeg wk toe met de volgende code, w = k` | de **zetstok** houdt w, het volgende teken k licht op. Twee hendels: **Verleng** (w = wk) en **Stempel** (stempel code(w) op de strook, snijd een nieuwe stempel wk met het volgende nummer, w = k). Het eerste teken komt vanzelf in de zetstok. Aan het einde stempelt de kopiist code(w) | de beslissing "zit wk al in de kast?" |
| decoderen: hetzelfde woordenboek; `if c in woordenboek: volgend = woord(c) else volgend = [w, w[0]]; voeg [w, volgend[0]] toe` (p. 113) | ontvangstlevels: een code komt binnen. Bestaat de lade, dan gaat ze vanzelf open (volgend). De speler **snijdt** de nieuwe stempel: w plus één letter van volgend (klik de letter). Bestaat de lade nog niet (het **speciale geval**), dan is ze leeg: de speler maakt volgend zelf als w plus één letter van w | de twee beslissingen van de decoder |
| "Er is dus een probleem als (en slechts als) een woord onmiddellijk nadat het … toegevoegd wordt als code geschreven wordt" | de lege lade glanst; Zeno (eerste keer): "Die stempel snijd je nu pas. Hoe begint hij?" | — |
| volle kast (p. 112) | niet gespeeld (teksten zijn kort); vermeld in het spiekbriefje | — |

**Speler doet:** per teken verlengen of stempelen (zenden); per code de letter voor de nieuwe stempel kiezen (ontvangen).
**Automatisch:** opzoeken, laden openen, nummeren, de slotstempel, de eerste code.

**Fouten → gevolg**

| fout | kan het? | gevolg |
|---|---|---|
| Verleng terwijl wk niet in de kast zit | **nee** | klem `no_stamp` (die stempel bestaat niet) |
| Stempel terwijl wk al in de kast zit | ja | `EARLY_STAMP`: de kopiist snijdt wk een tweede keer (een dubbele lade met een nieuw nummer, zoals de else-tak voorschrijft). Letterlijk doet bij het decoderen hetzelfde, dus de tekst blijft juist. Maar er gaat een lade verloren (de kast is sneller vol, p. 112) en het kortschrift is meestal langer. Bv. `banaanaanval` met Stempel bij de eerste `an`: 98 97 110 97 **97 258 257** 118 97 108, met lade 260 = `an` dubbel |
| ontvangen: een andere letter dan volgend[0] aan w toevoegen | ja | `WRONG_CARVE`: de nieuwe stempel klopt niet. Wordt hij later gebruikt, dan wordt je kopie onzin; zo niet, dan staat er een fout woord in je kast (zichtbaar in de terugblik, Oef. 102 vraagt de woorden) |
| ontvangen, speciaal geval: volgend = w + een andere letter dan w[0] | ja | `WRONG_CARVE`: de uitvoer is fout en w ook, en de fout loopt door. Bv. `97 110 256 258 115` met `an` + `n`: **`anananns`** |

### 3.8 Burrows-Wheeler (r. 5942–6216, p. 115–120) — werktuig *draaitrommel*
| notas | in het spel | waarom zo |
|---|---|---|
| de tekst als cyclus; n strings door op elke positie te beginnen | de tekst gaat rond een houten **trommel**. Bij elke slag drukt de trommel één rotatie op een strook (rotatie i begint bij s[i]) | — |
| sorteren (bytewaarden; de spatie is het kleinst) | het **rek**: elke nieuwe strook schuif je tussen de juiste twee stroken (invoegen). Gelijke rijen (Fig. 26) mogen in elke volgorde onder elkaar | sorteren is een reeks echte beslissingen |
| output het nummer van de rij die met s[0] eindigt, dan de laatste kolom (p. 117) | **markeren**: klik de rij waarvan de laatste letter het eerste teken van de tekst is (de rotatie die bij s[1] begint). De kopiist schrijft `p ␣ laatste kolom` | de notas-conventie, niet die van internet |
| terugweg: e[] = gesorteerde c[]; indices in volgorde van voorkomen; begin met c[p]; herhaal n keer: output, zoek i met c[i] = x_j, x_j = e[i] (p. 118–119) | ontvangstlevels: twee kolommen zoals p. 117 (links e, rechts c). De kopiist sorteert e. Te beginnen bij c[p]: de letter gaat naar de kopie, een pijl wijst naar e op dezelfde rij. De speler klikt in kolom c **dezelfde letter met dezelfde rang** (de k-de e in e = de k-de e in c). In het eerste level staan de indices erbij (e₁, e₂), daarna niet meer | het bewijs op p. 118 als handeling |
| n stappen, niet "tot je terug bent" (p. 119, Fig. 26) | de lus loopt altijd n keer; bij herhalingen draait ze zichtbaar meermaals rond | — |

**Speler doet:** invoegen in het rek, de rij p markeren (zenden); per stap de juiste rang kiezen (ontvangen).
**Automatisch:** rotaties drukken, de laatste kolom afschrijven, e sorteren, de eerste stap (c[p] zelf).

**Fouten → gevolg**

| fout | kan het? | gevolg |
|---|---|---|
| een strook op de verkeerde plaats in het rek | ja | `WRONG_ORDER`: de laatste kolom klopt niet. Letterlijks terugweg loopt in een kringetje of springt rond. Bv. `geen loon` met rij 1 en 2 omgewisseld: c = `negn eool`; met de strook `een loong` gemarkeerd (nu rij 2) leest hij **`gen loong`**, met rij 1 **`eeeeeeeee`** |
| een andere rij markeren | ja | `WRONG_P`: Letterlijk begint op de verkeerde plaats. Hij leest een rotatie of onzin. Bv. p = 2 in plaats van 1: **`een loong`** |
| ontvangen: dezelfde letter, verkeerde rang | ja | `WRONG_RANK`: de weg springt naar een ander stuk van de tekst → onzin in je kopie |
| ontvangen: een andere letter klikken | **nee** | klem `letter` |

### 3.9 Move-to-front (r. 6217–6282, p. 121–122) — werktuig *letterplank*
| notas | in het spel | waarom zo |
|---|---|---|
| een vaste lijst; c(x) = positie in de lijst; daarna x vooraan | de **letterplank**: houten blokjes op een rij. Onder de plank hangen in het eerste level positienummertjes (0, 1, …), daarna niet meer | tellen vanaf 0 is de valkuil |
| coderen: schrijf c(x), zet x vooraan | zenden: de speler zet het getal met de **cijferstempels** (0…lengte−1). Daarna schuift de kopiist het blokje naar voren | — |
| decoderen: dezelfde beginlijst, positie k → teken, vooraan zetten | ontvangen: de speler klikt het blokje op positie k. Het gaat naar de kopie en schuift naar voren | — |
| ook het getal p en de spatie van de BWT-uitvoer worden gecodeerd (`(1 ngen eool)` → 1,1,7,…) | idem | letterlijk de notas |
| veel nullen en kleine getallen → geschikt voor Huffman (p. 122) | teller **nullen** en een staafje "kleine getallen" | de brug naar de Codex |

**Speler doet:** per teken het getal stempelen (zenden) of het blokje kiezen (ontvangen). **Automatisch:** het
verschuiven.

**Fouten → gevolg**

| fout | kan het? | gevolg |
|---|---|---|
| zenden: een ander getal dan de positie | ja | `WRONG_INDEX`: Letterlijk neemt het blokje op die positie en zet **dat** vooraan; jij zette het echte teken vooraan. De planken lopen uiteen → onzin |
| ontvangen: het blokje ernaast (tellen vanaf 1) | ja | `WRONG_INDEX`: verkeerde letter in je kopie, en jouw plank wijkt af van die van de afzender → onzin. Bv. `1,1,7,…` met 8 in plaats van 7 bij het derde getal: **`1 ogeo ennl`** |
| een getal ≥ lengte van de plank | **nee** | klem `range` |

### 3.10 Geen algoritme comprimeert alles (Oef. 76–78, r. 4178–4272, p. 81–82) — werktuig *duiventil* (P1)
| notas | in het spel |
|---|---|
| een compressie moet een bijectie zijn; minder bytes = minder mogelijke bestanden | de **duiventil**: acht duiven (alle berichten van 3 bits: 000…111) en de hokken van de kortere codes: één hok zonder naam (ε), 0, 1, 00, 01, 10, 11 = **zeven** hokken. Elke duif moet in een eigen, korter hok |
| als één bestand echt korter wordt, wordt er ook één langer (Oef. 76) | de achtste duif past nergens. Ze moet naar de zolder met de lange hokken (4 bits) |
| ten hoogste ≈ 1/255 van de bestanden (p. 81), Oef. 77 | de terugblik tekent de telling: Σ_{i≤n} 256^i = (256^{n+1} − 1)/255 hokken voor 256^{n+1} duiven |

**Speler doet:** duiven in hokken slepen. **Fouten:** twee duiven in één hok (klem `taken`); een duif in een hok dat niet
korter is (klem `not_shorter`, tot er geen korter hok meer vrij is).

---

## 4. Bediening, schermen & HUD

### 4.1 Besturing (muis volwaardig, toetsenbord waar het sneller is)
| actie | muis | toetsenbord |
|---|---|---|
| blad kiezen (codeboom, levende boom: schrijven/lezen) | klik het blad (of het nng-zaadje) | `←`/`→` kiest een blad, `Enter` |
| knippen (codebord, stage *Grenzen*) | klik tussen twee bits | `←`/`→` + `Enter`; `R` = opnieuw lezen |
| tegel hangen (codebord) | sleep een lettertegel op een knoop; rechtsklik = weghalen | — |
| binden (binderij) | klik twee stapels na elkaar (of sleep de ene op de andere) | `←`/`→` + `Spatie` markeert, de tweede `Spatie` bindt |
| wisselpartner / blijven staan (levende boom) | klik een monnik in boom of processie; klik de monnik met de lantaarn = blijven staan | `←`/`→` door de processie, `Enter`; `B` = blijven staan |
| vak knippen (meetlat) | klik het vak | de letter van het vak typen, of `↑`/`↓` + `Enter` |
| binaire naald | knoppen **1 · stap** en **0 · blijf** | `1` / `0` |
| beginpositie (leesraam) | klik een letter in het raam | `←`/`→` + `Enter`; `G` = Geen match |
| verlengen / stempelen (stempelkast) | twee hendels | `V` / `S` |
| letter voor de nieuwe stempel | klik de letter | `1`…`9` = de zoveelste letter |
| invoegen in het rek (trommel) | klik de spleet tussen twee stroken (de strook volgt de muis) | `↑`/`↓` + `Enter` |
| rij markeren (trommel) | klik de rij | `↑`/`↓` + `Enter` |
| terugweg (trommel) | klik de letter in kolom c | `↑`/`↓` + `Enter` |
| getal stempelen (plank, zenden) | klik een cijferstempel | cijfertoetsen + `Enter` |
| blokje kiezen (plank, ontvangen) | klik het blokje | `←`/`→` + `Enter` |
| duif in hok | sleep | — |
| hint (Zeno's inkthand) | Zeno-icoon | `F1` (kost ★★★) |
| zet terugnemen | ⟲-knop | `Ctrl+Z` (kost ★★★) |
| kopiist sneller (automatische stappen) | ingedrukt houden op de tafel | `Spatie` ingedrukt (3×) |
| pauze | knop links boven | `Esc` |
| terugblik: misstap herbeleven | klik een stip | `←`/`→` + `Enter` |

Er is geen tijdsdruk in de campagne. Elke zet is één klik of één toets. Alle toetsen staan op een kaartje in de
pauze-notas.

### 4.2 Schermen & flow
```
Titel ──► Getijdenboek (kaart) ──► Brief (≤ 8 s) ──► Werkbank (level, 1..3 stages) ──► Voorlezing ──► Kapittel (terugblik)
  │ Esc→hub      │                                         │ Esc                                         │
  │              ├──► Nachtwake (slot: 1-2 ≥ 1★)           └──► Pauze (Verder · Opnieuw · Notas · Instellingen · Kaart)
  └──► Instellingen                                                                              Volgende / Opnieuw / Kaart
```
- **Titel** (`res://games/scriptorium/scenes/title.tscn`): een ganzenveer schrijft **Kortschrift** in een verluchte
  initiaal. Daarna wordt het woord korter: de letters schuiven samen tot een klein codeteken en ontrollen weer (2 s).
  Ondertitel *Het scriptorium van Zuinigem*. Knoppen: **Het kloosterjaar** (campagne), **Nachtwake** (met slot),
  **Instellingen**, **Terug naar de speelhal**. `Esc` en "Terug" gaan naar `res://scenes/hub.tscn` (via `Transition`).
  Op de achtergrond (gedimd) bindt de kopiist in een lus een Huffman-boom (attract, gespeeld door de bot).
- **Getijdenboek (kaart):** een opengeslagen getijdenboek met een kalenderpagina per hoofdstuk (Advent, Kerstmis,
  Vasten, Pasen, Pinksteren, Hooimaand, Wijnmaand, Allerheiligen). Elk level is een **verluchte initiaal** met 0–3 lakzegels
  en het pictogram van het werktuig. Hover toont de leerstof ("Oefening 80 · notas p. 86"). Ontsluiten: het volgende
  level gaat open met ≥ 1 ★ op het vorige P0-level. Een hoofdstuk gaat open als alle P0-levels van het vorige hoofdstuk
  ≥ 1 ★ hebben. De Codex gaat open als alle P0-levels ≥ 1 ★ hebben. P1/P2-levels sluiten nooit iets af. Rechtsboven
  het kaarsje **Nachtwake**.
- **Brief:** de brief van het huis ontrolt: titel, opdracht (tekst of kortschrift en, waar nodig, model, raamgrootte G of
  beginlijst), modus (verzenden/ontvangen), notasverwijzing, één zin van Zeno. Bij een nieuw werktuig gaat eerst de kist
  open.
- **Werkbank:** HUD §4.3. Een level kan meerdere **stages** hebben (bv. 6-1: trommel → plank). Een stage-wissel is een
  korte animatie (de kopiist schuift het resultaat naar het volgende werktuig, 0,6 s).
- **Voorlezing:** de duif vliegt (of in ontvangstlevels: Zeno brengt het origineel) en Letterlijk leest (§2.3, §6.5).
- **Kapittel (terugblik):** §6.5.
- **Pauze:** Verder, Opnieuw, **Notas** (spiekbriefje), Instellingen, Kaart.
- **Instellingen:** muziek, geluid, schermschok 0/50/100 %, tekstgrootte 100/125 %, kopiistsnelheid (normaal/snel),
  kleurenblindmodus (goud/bruin krijgen ook ✓/✕-vormen; vakken op de meetlat krijgen arceringen), **hulplijnen** (toont
  altijd positienummers onder raam, plank en kolommen en de rangen in de trommel; telt als hulp voor ★★★), volledig
  scherm.
- **Notas (spiekbriefje):** een wastafeltje met een tabblad per werktuig. Elk tabblad verschijnt zodra het werktuig
  binnen is. Per tab een mini-diagram en ≤ 5 regels met paginaverwijzing:
  - *Codeboom:* "prefixcode: geen codewoord is het begin van een ander" (Def. 20, p. 83) · "lees tot een blad, begin
    opnieuw bij de wortel" (p. 83).
  - *Binderij:* "bind de twee lichtste; gewicht = som" (Alg. 9, p. 84) · "bij gelijk gewicht: elke keuze is even goed"
    (p. 84–85) · "touw = Σ l(x)·a(x) = bits" (Stelling 21, p. 86) · "twee planken: neem vooraan het lichtste" (Oef. 85).
  - *Levende boom:* "eerst schrijven met de oude boom" (p. 92) · "nieuw teken: code(nng) + 8 bits" (p. 94) · "t′ = zelfde
    gewicht, hoogste nummer; is t′ je ouder: niet wisselen" (Alg. 11, p. 95) · "(a) som (b) gewicht stijgt met het nummer
    (c) 2j−1 en 2j zijn broers" (Lemma 22, p. 90).
  - *Meetlat:* "links += f·lengte; lengte ×= p" (Alg. 12, p. 101) · "[a, b): onder dicht, boven open" (p. 99) · "naald:
    stap als getal + next < up; stop als getal ≥ low; low = 0 → 0" (Alg. 13, p. 101–102).
  - *Leesraam:* "langste match die in het raam begint; mag erbuiten eindigen" (p. 105) · "(p, l, x); p vanaf links, vanaf
    0" (p. 106) · "geen match: (0,0,x)" (p. 106) · "decoderen: letter per letter kopiëren" (p. 107).
  - *Stempelkast:* "wk in de kast: verlengen; anders code(w) stempelen, wk snijden, w = k" (p. 111) · "decoderen: nieuwe
    stempel = w + eerste letter van het volgende woord" · "code bestaat nog niet: volgend = w + w[0]" (p. 113).
  - *Draaitrommel:* "alle rotaties, sorteer, laatste kolom" (p. 116–117) · "p = de rij die eindigt op het eerste teken"
    (p. 117) · "k-de x in de eerste kolom = k-de x in de laatste kolom" (p. 118) · "terug: n keer: schrijf, zoek dezelfde
    in c, ga naar e" (p. 118–119).
  - *Letterplank:* "schrijf de positie (vanaf 0), zet de letter vooraan" (p. 121) · "decoderen: zelfde beginlijst"
    (p. 121).
  - *Duiventil:* "minder bits = minder hokken; wie iets korter maakt, maakt iets anders langer" (p. 81, Oef. 76).

### 4.3 HUD en layout (1920×1080)
```
y=0   ┌───────────────────────────────────────────────────────────────────────────────────────────────┐
      │[II] PASEN · 3-2 Oefening 93   ▓▓▓▓▓░░ INKT 5 ▕gewoon: 24▏▕optimum: 5▏  koker ▭▭▭▭▭  ★☆☆        │ 0–72
y=80  ├───────────────────────────────────────────────────────────────────────────────────────────────┤
      │ OPDRACHT  c a g                                                       (n = 3, model a c g t)     │ 80–190
      │           0 1 2      ▲ cursor                                                                    │
      ├──────────────────────────────────────────────────────────────┬────────────────────────────────┤
      │                                                              │  DE OVERKANT                    │
      │                                                              │  (Letterlijk, kopie,            │
      │                 WERKBANK (werktuig, §4.4)                    │   miniboom / -raam / -kast /    │ 200–880
      │                                                 ┌Zeno┐       │   -plank)                       │
      │                                                              │                                 │
y=890 ├──────────────────────────────────────────────────────────────┴────────────────────────────────┤
      │ KORTSCHRIFT  0 1 0 1 1 ▏                          [koker ▭▭▭▭▭|]   contextknoppen               │ 890–1080
y=1080└───────────────────────────────────────────────────────────────────────────────────────────────┘
```
- **Opdrachtband:** mono, tekens 44 px (n ≤ 30) of 32 px (langer), positie eronder 18 px. Al gecodeerd = gedimd met
  een gouden streepje eronder. In ontvangstlevels toont de band **de kopie** die je maakt (in plaats van de opdracht).
- **Werkbank:** x 0–1260. **De Overkant:** x 1280–1920 (smal paneel; in levels zonder ontvanger toont het Zeno's lessenaar
  met het notasvoorbeeld).
- **Kortschrift:** bits 28 px, met een dun streepje tussen codewoorden (enkel waar de speler ze knipte of de kopiist ze
  schreef), lakzegels 36 px, wassen zegels 40 px, stempelafdrukken 40 px. Scrolt horizontaal.
- **Inktmeter:** druppelteller (rolcijfers) met de grijze geesten "gewoon" en "optimum". Overschrijdt de inkt het
  optimum, dan wordt de meter amber; de koker toont een strook die uitsteekt.
- **Tellers per werktuig** (klein, naast de inkt): touw (binderij), zoekwerk (twee planken, register), klemmen, nullen
  (plank).
- Lettergroottes: nergens < 16 px; contrast ≥ 4,5:1; goud/bruin altijd ook met een vorm (✓/inktvlek).

### 4.4 Werkbanken (functionele layout per werktuig)
- **Codeboom / codebord:** de boom bovenaan (wortel boven, zoals Fig. 24/25), bladeren met lettertegels; de bitstrook
  loopt eronder. Codebord: een leeg raam met 14 knopen (diepte 1–3), lettertegels in een bakje links met hun frequentie.
  Tegels hangen = codewoord verschijnt naast de knoop.
- **Binderij:** de rij stapels (hoogte ∝ gewicht, getal erop) over de hele breedte. Gebonden bundels hangen als kleine
  boompjes boven hun plaats (bladeren zichtbaar). Touwklos met teller rechts. Het codeboek ontrolt na de laatste binding
  als tabel (letter · code · a(x) · l(x)·a(x)). Twee-plankenmodus: plank A (gesorteerde stapels, voorkant links) en plank
  B eronder.
- **Levende boom:** de boom over de bovenste 70 % (topjes als monniken met kaartje [g, o]), de **processie** als rij
  onderaan (nummer 1 … 2n−1, gewicht erboven; broers 2j−1/2j met een handje verbonden). Het nng-zaadje is een klein
  groen zaadje [0,1]. Lantaarn bij t. Bij een wissel lopen de twee monniken (met hun deelbomen) in een boog van plaats
  en wisselen ze hun kaartjes.
- **Meetlat:** links de staande lat (hoogte 700 px) met de vakken, rechts het **rekenboek** (tabel i · teken · links ·
  lengte), daaronder een klein "zoomladdertje" met de geneste intervallen. Fase naald: een liggende getallenlijn
  [0, 1) die mee inzoomt rond het goud, met de naald en de spookstreep; knoppen 1/0.
- **Leesraam:** één regel geschreven tekst (mono 44 px) met het houten raam over de laatste G tekens, posities 0…G−1
  erboven (enkel tutorial/hulplijnen). Rechts ervan, iets lager, de nog te coderen tekst (zenden) of het binnengekomen
  zegel (ontvangen). De draad loopt in een boog van bron naar doel.
- **Stempelkast:** links het leeslint met de zetstok (w) en het oplichtende volgende teken k, rechts de kast:
  bovenaan de ladenrij met de basistekens van dit level (letter + nummer), daaronder de nieuwe laden 256, 257, … in de
  volgorde waarin ze gesneden worden (nummer + woord). Ontvangen: de binnenkomende codes op een strook, de lade die
  opengaat, de snijbank met de letters van volgend.
- **Draaitrommel:** links de trommel met de tekst, in het midden het rek (n stroken, mono 36 px, eerste en laatste
  kolom extra gemarkeerd), rechts het kortschrift `p ␣ laatste kolom`. Terugweg: twee kolommen e (links) en c (rechts)
  met n rijen, rijnummers 0…n−1, een pijl c[i] → e[i] per stap, de kopie bovenaan.
- **Letterplank:** de plank met blokjes (60 px), daaronder de cijferstempels 0…lengte−1 (zenden) of de binnenkomende
  getallen (ontvangen); de invoerstrook erboven met de cursor.
- **Duiventil:** een duiventoren met zeven hokken (ε, 0, 1, 00, 01, 10, 11) en een zolder met 16 lange hokken; acht
  duiven met hun bericht op een ringetje.

---

## 5. Campagne

### 5.1 Algemene beslissingen
- **Proloog + zes hoofdstukken + de Codex + de Nachtwake.** 36 levels, waarvan 25 P0 (§10). Elk hoofdstuk begint met het
  voorbeeld uit de notas (herkenbaar) en eindigt met de oefeningen uit de notas (examenvorm), zowel zenden als ontvangen.
- **Tutorialstijl** (zoals de andere games): de eerste keer doet de inkthand de handeling voor. Enkel het onderdeel dat
  je nu nodig hebt, gloeit. Zeno zegt ≤ 12 woorden. Een hint verschijnt pas na 8 s niets doen, en enkel de eerste keer.
- **Hulpafbouw:** positienummers onder raam/plank, rangen (e₁, e₂) in de trommel en de markering van alle monniken met
  hetzelfde gewicht in de processie zijn er enkel in het eerste level van hun hoofdstuk (en altijd met *hulplijnen*).
- **Sterren** zijn cumulatief (★★ vereist ★, ★★★ vereist ★★). ★ = de voorlezing (of je kopie) is exact het origineel
  (en het level-specifieke minimum). ★★ = 0 misstappen (een logentry met verdict ∉ {OK, BUMP}); dan is de inkt exact
  het optimum. ★★★ = zonder hulp (hint, terugnemen, hernemen, hulplijnen) plus wat het level vraagt (0 klemmen, tijd,
  alle lezingen).
- **Notatie in dit hoofdstuk:** bomen als `[g,o]` (ordenummer o) of `label:g`; `X+Y` = binding van stapels X en Y; codes
  links = 0. Een adaptieve boom als `[g,o](linkerkind rechterkind)`; `*` = interne top. "uit" = wat de kopiist schrijft:
  bits, `"x"` = lakzegel met letter x (8 bits). Spatie = `␣`.
- **Stage-namen → stage-spec (§8.5):** `read` = `prefix_read`; `cuts`/`design` = `code_board`; `bind` = `bindery`;
  `adapt` = `living_tree`; `ruler` = `ruler`; `window` = `window`; `stamps` = `stampcase`; `drum` = `drum`; `shelf` =
  `shelf`; `dovecote` = `dovecote`.

### 5.2 PROLOOG — Advent: "Het kortschrift" (prefixcodes)

#### 0-1 "Oud en fout" (P0) — Figuur 25 en Oefening 79
- **Nieuw:** codeboom, leesvinger, kortschrift, kopie, voorlezing (hier: Zeno leest je kopie na).
- **Stage A:** read, code van Fig. 25: **o = 00, u = 010, d = 011, f = 10, t = 11**, strook `00010011`. Verwacht: o (00) ·
  u (010) · d (011) → **`oud`**. 3 keuzes.
- **Stage B:** read, zelfde boom, strook `100001011` (Oef. 79). Verwacht: f (10) · o (00) · u (010) · t (11) →
  **`fout`**. 4 keuzes.
- **Intro (Zeno):** "Volg de takken tot een blad. Dan begin je opnieuw." Bij stage B, na het lezen: "Fout? Nee hoor.
  Dat is het juiste antwoord."
- **Sterren:** ★ beide kopieën juist · ★★ 0 klemmen · ★★★ zonder hint.
- **Terugblik-extra:** de boom van Fig. 25 met beide paden ingekleurd; "Oefening 79: `100001011` = f·o·u·t."

#### 0-2 "Neeen!" (P0) — waarom prefixcodes (de eerste aanzet, p. 82; Definitie 20)
- **Nieuw:** knippen, lezingenlijst, codebord, Letterlijk leest gulzig.
- **Stage A "Grenzen":** cuts, de code van de kelner: **e = 0, n = 1, b = 10** (geen prefixcode: `1` is het begin van
  `10`). De abt schreef `benen`; de strook is `100101`. Mogelijke lezingen (exhaustief): **`benen`, `bebn`, `neebn`,
  `neenen`**. De speler knipt tot hij **2** verschillende lezingen gevonden heeft (★★★: alle 4). Daarna leest Letterlijk
  gulzig voor: **`neenen`**. De kelner bloost.
- **Stage B "Codebord":** design, bericht `een␣been␣en␣een␣benen` (n = 21, a(x): **e 9, n 6, ␣ 4, b 2**). De speler
  hangt de vier tegels in het boomraam (diepte ≤ 3) en verzendt. Verwacht optimum: **39 bits** (bv. e = 0, n = 10,
  ␣ = 110, b = 111; elke boom met diepten e 1, n 2, ␣ 3, b 3 is optimaal). Vaste lengte (2 bits): 42; gewoon schrift:
  168.
- **Intro:** "Waar stopt een letter? Dat moet de lezer altijd weten." (stage B) "Hang letters enkel aan bladeren."
- **Sterren:** ★ Letterlijk leest stage B juist · ★★ 0 misstappen (prefix en 39 bits bij de eerste verzending) ·
  ★★★ zonder hint en alle 4 lezingen in stage A.
- **Terugblik-extra:** Definitie 20 naast jouw boom; "Elk blad is een letter, geen letter heeft kinderen."

#### 0-3 "Het duiventil" (P1) — Oefening 76/77
- **Stage:** dovecote. 8 duiven (`000`…`111`), 7 korte hokken. De speler plaatst zeven duiven; de achtste kan enkel naar
  de zolder (4 bits). Dan beslist hij over het decreet van de abt: (1) "Elk bericht van 3 bits kan korter" → **Onmogelijk**
  (correct); (2) "Voor elk bericht bestaat een code die het korter maakt" → **Waar** (correct; Oef. 76, tweede deel, met
  de juiste kwantoren).
- **Terugblik-extra:** de telling van p. 81 voor n = 2: 1 + 2 + 4 = 7 < 8 = 2³. Voor bytes: (256^{n+1} − 1)/255.
  Oef. 77: "wie ≥ 100 bytes wil winnen, haalt het voor minder dan 1/(255·256^99) van de bestanden".
- **Sterren:** ★ voltooid · ★★ beide decreten juist · ★★★ zonder hint.

### 5.3 HOOFDSTUK 1 — Kerstmis: "De binderij" (Huffman, Algoritme 9)

#### 1-1 "Boosdoeer" (P0) — het notasvoorbeeld (p. 84–85)
- **Nieuw:** binderij, touw, codeboek, koker, duif.
- **Stage:** bind, tekst `boosdoeer` (n = 9), rij in de volgorde van de notas: **b:1 o:3 e:2 s:1 d:1 r:1**.
- **Verwacht (inkthand = notas):** b+s → 2 (touw 2) · d+r → 2 (touw 4) · (bs)+(dr) → 4 (touw 8) · o+e → 5 (touw 13)
  · 4+5 → 9 (touw **22**). Codes: **b 000, s 001, d 010, r 011, o 10, e 11** (= p. 85–86). Kortschrift:
  `0001010001010101111011` (**22 bits**, = p. 86). Vaste lengte (3 bits): 27; gewoon: 72.
- **Toegelaten paren:** stap 1: elk paar uit {b, s, d, r} (6); stap 2: alleen d+r (na b+s); stap 3: elk paar uit
  {(bs), e, (dr)}; … 18 geldige keuzereeksen, allemaal 22 bits en allemaal dezelfde codelengtes.
- **Intro:** "Bind de twee lichtste stapels. Herhaal tot er één boom is." Bij stap 3: "Niet uniek. Elke keuze is even
  goed."
- **Sterren:** ★ voorlezing juist · ★★ 0 misstappen (22 bits) · ★★★ zonder hint en ≤ 60 s.
- **Terugblik-extra:** de vijf stappen van p. 85 naast jouw vijf stappen; "Touw = bits: 2 + 2 + 4 + 5 + 9 = 22."
  **Notasboom-zegel** (cosmetisch) als je exact de figuur van p. 85 bouwde.

#### 1-2 "Oefening 80: bananenboom" (P0)
- **Stage:** bind, `bananenboom` (n = 11), rij **b:2 a:2 n:3 e:1 o:2 m:1** (volgorde van eerste voorkomen).
- **Verwacht (inkthand):** e+m → 2 · (em)+b → 4 · a+o → 4 · n+(b(em)) → 7 · 7+(ao) → 11. Touw **28**. Codes:
  b 000, e 0010, m 0011, n 01, a 10, o 11. Kortschrift `0001001100100100100011110011` (28 bits). Vaste lengte: 33;
  gewoon: 88.
- Stap 2 laat elk paar uit {b, a, (em), o} toe (alle gewicht 2). 12 geldige keuzereeksen met **6 verschillende
  lengteprofielen**, allemaal 28 bits. Zeno bij een ander profiel dan de inkthand: "Andere boom, zelfde touw."
- **Intro:** titelkaart "Oefening 80 — notas p. 86". Zeno: "Twee keer gewicht één. Begin daar."
- **Sterren:** ★ voorlezing juist · ★★ 0 misstappen · ★★★ zonder hint.

#### 1-3 "Oefening 81: zaken nemen geen keer" (P0)
- **Stage:** bind, `zaken_nemen_geen_keer` (n = 21, `_` is een gewoon teken), rij **z:1 a:1 k:2 e:7 n:4 _:3 m:1 g:1 r:1**.
- **Verwacht (inkthand):** z+a → 2 · m+g → 2 · r+(za) → 3 · k+(mg) → 4 · ((za)r)+_ → 6 · (k(mg))+n → 8 · 6+e → 13
  · 13+8 → 21. Touw **59**. Codes: z 00000, a 00001, r 0001, _ 001, e 01, k 100, m 1010, g 1011, n 11. Vaste lengte
  (4 bits): 84; gewoon: 168. 90 geldige keuzereeksen, 11 lengteprofielen, allemaal 59.
- **Intro:** titelkaart "Oefening 81 — notas p. 87".
- **Sterren:** ★ voorlezing juist · ★★ 0 misstappen · ★★★ zonder hint en ≤ 120 s.

#### 1-4 "De registers van de kelner" (P1) — Oefening 86 (en 83)
- **Stage:** bind zonder letters: vijf registers met **8, 3, 5, 2, 9** bladen (A–E). Samenvoegen kost de som van de
  bladen.
- **Verwacht:** D+B → 5 · (DB)+C → 10 · A+E → 17 · 17+10 → 27. Totaal **59**. De kelner deed het eerst van links naar
  rechts: 11 + 16 + 18 + 27 = **72** (dat is het voorbeeld voor het eerste deel van Oef. 86).
- **Sterren:** ★ voltooid · ★★ 59 · ★★★ zonder hint.
- **Terugblik-extra:** "Dit is Huffman: de kost is Σ gewicht × diepte (Stelling 21)."

#### 1-5 "Twee planken" (P1) — Oefening 85
- **Stage:** bind in plankmodus, tekst `de␣kok␣kookt␣koolsoep` (n = 21). Plank A (stabiel gesorteerd):
  **d:1 t:1 l:1 s:1 p:1 e:2 ␣:3 k:5 o:6**, plank B leeg.
- **Verwacht (neem telkens vooraan het lichtste; bij gelijk eerst B):** d+t → 2 · l+s → 2 · p+(dt) → 3 · (ls)+e → 4
  · (p(dt))+␣ → 6 · ((ls)e)+k → 9 · 6+o → 12 · 9+12 → 21. Touw **59**.
- **Zoekwerk:** 12 vergelijkingen tussen de twee voorkanten. In de gewone rij (zelfde 9 stapels): Σ (2m − 3) voor
  m = 9…2 = **64**.
- **Sterren:** ★ voorlezing juist · ★★ 0 misstappen · ★★★ zonder hint.
- **Terugblik-extra:** "Na het sorteren: O(n). Waarom werkt het? Nieuwe bundels worden nooit lichter (Oef. 85)."

### 5.4 HOOFDSTUK 2 — Vasten: "De levende boom" (adaptieve Huffman)

**Notatie van de verwachte verlopen:** per teken: *uit* (wat de kopiist schrijft), *groei* (automatisch), *klim* (de
beslissingen van de speler, telkens "t → t′" met **wissel**, **blijf** of **blijf (ouder)** = het speciale geval), en
de boom daarna.

#### 2-1 "Nog een e, nog een s" (P0) — Lemma 22 en Algoritme 10 (p. 89–93)
- **Nieuw:** monniken met [g, o], processie, lantaarn, wissel/blijf, klem `ancestor`.
- **Begintoestand (beide stages):** de boom van p. 90 (zonder nng):
  `[9,11]([4,9]([2,5](b[1,1] s[1,2]) [2,6](d[1,3] r[1,4])) [5,10](e[2,7] o[3,8]))`. Processie: b1 s1 d1 r1 2 2 e2 o3 4 5 9.
- **Stage A "nog een e":** adapt (één teken, zenden). uit: `10`. Klim: e[2,7] → zichzelf (de verste met gewicht 2):
  **blijf** · [5,10] → zichzelf: **blijf** · wortel +1. Boom: `[10,11]([4,9](…) [6,10](e[3,7] o[3,8]))` (= p. 91). Zeno:
  "Geluk: niemand hoefde te wisselen."
- **Stage B "nog een s":** adapt vanaf dezelfde boom. uit: `001`. Klim: s[1,2] → **r[1,4]: wissel** (s wordt [2,4]) ·
  [2,6] → **e[2,7]: wissel** ([2,6] wordt [3,7]) · [5,10] → **blijf** · wortel. Boom:
  `[10,11]([4,9]([2,5](b[1,1] r[1,2]) e[2,6]) [6,10]([3,7](d[1,3] s[2,4]) o[3,8]))` (= p. 93).
- **Gevolg zonder wissels (debriefvoorbeeld):** wie bij elke stap blijft staan, krijgt exact de boom onderaan p. 91
  (`[10,11]([5,9]([3,5](b[1,1] s[2,2]) [2,6](d[1,3] r[1,4])) [5,10](e[2,7] o[3,8]))`), die "niet voldoet aan (b)": in de
  processie daalt de trap van s (nr. 2, gewicht 2) naar d (nr. 3, gewicht 1) en van [3,5] naar [2,6]. Daar struikelen
  de monniken.
- **Intro:** "Zelfde gewicht, verste plaats in de processie. Wissel met die."
- **Sterren:** ★ beide bomen juist · ★★ 0 misstappen · ★★★ 0 klemmen en zonder hint.

#### 2-2 "Graag" (P0) — het notasvoorbeeld met nng (p. 96–98)
- **Nieuw:** nng-zaadje, schrijven vóór bijwerken, groei + hernummering, lakzegel, De Overkant met miniboom.
- **Stage:** adapt, zenden, tekst `graag`.

| teken | uit | groei | klim (beslissingen) | boom na |
|---|---|---|---|---|
| g | `"g"` (eerste teken: ruw) | nng → [1,3](nng g) | — (o is de wortel) | `[1,3](nng[0,1] g[1,2])` |
| r | `0"r"` | o′ [1,3](nng r); g → [1,4], wortel → [1,5] | — (ouder van o′ is de wortel) | `[2,5]([1,3](nng[0,1] r[1,2]) g[1,4])` |
| a | `00"a"` | o″ [1,3](nng a); +2 voor de rest | [1,5] → **g[1,6]: wissel** | `[3,7](g[1,5] [2,6]([1,3](nng[0,1] a[1,2]) r[1,4]))` |
| a | `101` | — | a[1,2] → **g[1,5]: wissel** | `[4,7](a[2,5] [2,6]([1,3](nng[0,1] g[1,2]) r[1,4]))` |
| g | `101` | — | g[1,2] → **r[1,4]: wissel** · [2,6] → **blijf** | `[5,7](a[2,5] [3,6]([1,3](nng[0,1] r[1,2]) g[2,4]))` |

  Kortschrift `"g" 0"r" 00"a" 101 101` = 8 + 9 + 10 + 3 + 3 = **33 bits** (gewoon: 40). 4 schrijfkeuzes (het eerste
  teken gaat vanzelf) + 4 klimkeuzes.
- **Gevolg (debriefvoorbeeld, nagerekend):** bij de eerste `a` blijven staan in plaats van te wisselen → jij schrijft
  `"g"0"r"00"a"001001`, Letterlijk leest **`graggga`**.
- **Intro:** "Eerst schrijven met de oude boom. Dan pas groeien."
- **Sterren:** ★ voorlezing juist · ★★ 0 misstappen (33 bits) · ★★★ zonder hint.

#### 2-3 "Eetzaal" (P0) — het speciale geval van Algoritme 11 (p. 95)
- **Nieuw:** wisselen met de ouder klemt; "blijf (ouder)".
- **Stage:** adapt, zenden, tekst `eetzaal` (het menu van de eetzaal).

| teken | uit | klim | boom na |
|---|---|---|---|
| e | `"e"` | — | `[1,3](nng[0,1] e[1,2])` |
| e | `1` | e[1,2]: de verste met gewicht 1 is de wortel [1,3] = **de ouder** → **blijf (ouder)** | `[2,3](nng[0,1] e[2,2])` |
| t | `0"t"` | — | `[3,5]([1,3](nng[0,1] t[1,2]) e[2,4])` |
| z | `00"z"` | [1,5] → zichzelf: **blijf** | `[4,7]([2,5]([1,3](nng[0,1] z[1,2]) t[1,4]) e[2,6])` |
| a | `000"a"` | [1,5] → **t[1,6]: wissel** · [2,7] → **e[2,8]: wissel** | `[5,9](e[2,7] [3,8](t[1,5] [2,6]([1,3](nng[0,1] a[1,2]) z[1,4])))` |
| a | `1101` | a[1,2] → **t[1,5]: wissel** · [3,8] → **blijf** | `[6,9](e[2,7] [4,8](a[2,5] [2,6]([1,3](nng[0,1] t[1,2]) z[1,4])))` |
| l | `1100"l"` | [1,5] → **z[1,6]: wissel** · [2,8] → **e[2,9]: wissel** | `[7,11]([3,9](z[1,5] [2,6]([1,3](nng[0,1] l[1,2]) t[1,4])) [4,10](a[2,7] e[2,8]))` |

  **55 bits** (gewoon: 56). 6 schrijfkeuzes + 8 klimkeuzes. Bij de tweede `e` is de wortel de verste monnik met
  gewicht 1; een klik op de wortel klemt (`ancestor`).
- **Gevolg (nagerekend):** bij de eerste `a` meteen blijven staan → Letterlijk leest **`eetzate…`** en daarna is de
  strook onleesbaar.
- **Intro:** "Soms is de verste monnik je eigen ouder. Dan blijf je."
- **Sterren:** ★ voorlezing juist · ★★ 0 misstappen · ★★★ 0 klemmen en zonder hint.

#### 2-4 "Oefening 90: voordeel" (P0)
- **Stage:** adapt, zenden, tekst `voordeel`. Daarna de voorlezing = het tweede deel van Oef. 90 ("Decodeer de door jou
  opgestelde code").

| teken | uit | klim | boom na |
|---|---|---|---|
| v | `"v"` | — | `[1,3](nng v[1,2])` |
| o | `0"o"` | — | `[2,5]([1,3](nng o[1,2]) v[1,4])` |
| o | `01` | o[1,2] → **v[1,4]: wissel** | `[3,5]([1,3](nng v[1,2]) o[2,4])` |
| r | `00"r"` | [1,5] → **blijf** | `[4,7]([2,5]([1,3](nng r[1,2]) v[1,4]) o[2,6])` |
| d | `000"d"` | [1,5] → **v[1,6]: wissel** · [2,7] → **o[2,8]: wissel** | `[5,9](o[2,7] [3,8](v[1,5] [2,6]([1,3](nng d[1,2]) r[1,4])))` |
| e | `1100"e"` | [1,5] → **v[1,7]: wissel** · [3,10] → **blijf** | `[6,11](o[2,9] [4,10]([2,7]([1,3](nng e[1,2]) d[1,4]) [2,8](v[1,5] r[1,6])))` |
| e | `1001` | e[1,2] → **r[1,6]: wissel** · [2,8] → **o[2,9]: wissel** | `[7,11]([3,9](v[1,5] e[2,6]) [4,10]([2,7]([1,3](nng r[1,2]) d[1,4]) o[2,8]))` |
| l | `1000"l"` | [1,5] → **v[1,7]: wissel** · [3,11] → **blijf** | `[8,13]([4,11]([2,7]([1,3](nng l[1,2]) r[1,4]) e[2,8]) [4,12]([2,9](v[1,5] d[1,6]) o[2,10]))` |

  Kortschrift `"v" 0"o" 01 00"r" 000"d" 1100"e" 1001 1000"l"` = **68 bits** (gewoon: 64; zes nieuwe letters op acht
  kosten meer dan ze opbrengen; Zeno: "Korte teksten winnen niets. Lange wel.").
  7 schrijfkeuzes + 10 klimkeuzes.
- **Gevolg (nagerekend):** bij de eerste klimstap van `d` blijven staan → Letterlijk leest **`voordvoo…`**.
- **Intro:** titelkaart "Oefening 90 — notas p. 98".
- **Sterren:** ★ voorlezing juist · ★★ 0 misstappen · ★★★ zonder hint en ≤ 240 s.

#### 2-5 "Oefening 91: de ontvanger" (P0)
- **Nieuw:** ontvangen met de levende boom (lezen → groei → klim).
- **Stage:** adapt, ontvangen, kortschrift `"n"0"o"0100"d"001100"a"100111`.

| gelezen bits | teken | klim | boom na |
|---|---|---|---|
| (ruw) | n | — | `[1,3](nng n[1,2])` |
| `0` + `"o"` | o | — | `[2,5]([1,3](nng o[1,2]) n[1,4])` |
| `01` | o | o[1,2] → **n[1,4]: wissel** | `[3,5]([1,3](nng n[1,2]) o[2,4])` |
| `00` + `"d"` | d | [1,5] → **blijf** | `[4,7]([2,5]([1,3](nng d[1,2]) n[1,4]) o[2,6])` |
| `001` | d | d[1,2] → **n[1,4]: wissel** · [2,5] → **o[2,6]: wissel** | `[5,7](o[2,5] [3,6]([1,3](nng n[1,2]) d[2,4]))` |
| `100` + `"a"` | a | [1,5] → **blijf** · [3,8] → **blijf** | `[6,9](o[2,7] [4,8]([2,5]([1,3](nng a[1,2]) n[1,4]) d[2,6]))` |
| `1001` | a | a[1,2] → **n[1,4]: wissel** · [2,5] → **o[2,7]: wissel** | `[7,9]([3,7]([1,3](nng n[1,2]) a[2,4]) [4,8](o[2,5] d[2,6]))` |
| `11` | d | d[2,6] → **blijf** · [4,8] → **blijf** | `[8,9]([3,7]([1,3](nng n[1,2]) a[2,4]) [5,8](o[2,5] d[3,6]))` |

  Kopie: **`nooddaad`** ("niet echt een woord", p. 98). 7 leeskeuzes + 10 klimkeuzes.
- **Intro:** titelkaart "Oefening 91 — notas p. 98". Zeno: "Lees met jouw boom. Werk hem bij zoals de afzender."
- **Sterren:** ★ kopie juist · ★★ 0 misstappen · ★★★ zonder hint.

#### 2-6 "Oefening 88: dieper" (P2)
- Ontdekkingspuzzel: een gegeven boom die aan (a)–(c) voldoet. Kies het blad dat Algoritme 10 in de eerste iteratie
  dieper plaatst. Data te bepalen bij de bouw (exhaustief zoeken met `ScReference`); de terugblik citeert Lemma 23.

### 5.5 HOOFDSTUK 3 — Pasen: "De meetlat" (aritmetisch coderen)

#### 3-1 "x, y en z" (P0) — het model van de notas (p. 99–101)
- **Nieuw:** meetlat, knippen, rekenboek, binaire naald, speld.
- **Model:** x 0,2 · y 0,7 · z 0,1 (in die volgorde, x onderaan).
- **Stage A (zenden):** ruler, tekst `yy`. Knippen: y → [0,2; 0,9) (links 0,2, lengte 0,7) · y → [0,34; 0,83) (links
  0,34, lengte 0,49). Naald: next 0,5: 0 + 0,5 < 0,83 → **1**, getal 0,5 ≥ 0,34 → stop. Kortschrift **`1`** (1 bit).
- **Stage B (ontvangen, drie spelden):** ruler, n = 2: speld `1` = 0,5 → **`yy`** · speld `1101` = 0,8125 → **`yy`**
  (0,8125 < 0,83) · Zeno's speld op **0,9** (een getal, geen bitstring; p. 100) → eerst het vak **z** (0,9 is de dichte
  onderrand van z, niet de open bovenrand van y), daarna **x** (0,9 is de onderrand van x in [0,9; 1)) → **`zx`**.
  Klikken op y bij 0,9 = `WRONG_EDGE`.
- **Intro:** "Knip het vak van de letter. Het interval wordt je nieuwe lat."
- **Sterren:** ★ stage A gelezen + 3 kopieën juist · ★★ 0 misstappen · ★★★ 0 klemmen en zonder hint.
- **Terugblik-extra:** de partitie van p. 100 (xx … zz) met jouw intervallen erin.

#### 3-2 "Oefening 93: cag" (P0)
- **Model:** a 0,3 · c 0,2 · g 0,4 · t 0,1.
- **Stage:** ruler, zenden, `cag`. Rekenboek: c → links 0,3, lengte 0,2 · a → links 0,3, lengte 0,06 · g → links 0,33,
  lengte 0,024 → **[0,33; 0,354)**. Naald (getal, next): 0 + 0,5 ≥ 0,354 → **0** · 0 + 0,25 < 0,354 → **1** (0,25 < 0,33,
  verder) · 0,25 + 0,125 = 0,375 ≥ 0,354 → **0** · 0,25 + 0,0625 = 0,3125 → **1** · 0,3125 + 0,03125 = 0,34375 → **1**,
  ≥ 0,33 → stop. Kortschrift **`01011`** (5 bits; Lemma 24: ≤ ⌈log₂(1/0,024)⌉ = 6).
- **Gevolg (nagerekend):** eerste bit 1 (OVERSHOOT) → strook `1` → Letterlijk leest **`gaa`**.
- **Intro:** titelkaart "Oefening 93 — notas p. 102". Zeno: "Nooit boven de bovengrens stappen."
- **Sterren:** ★ voorlezing juist · ★★ 0 misstappen (5 bits) · ★★★ zonder hint.

#### 3-3 "Oefening 95: 0010011" (P0)
- **Stage A:** ruler, ontvangen, model a c g t, bits `0010011` (= 19/128 = 0,1484375), n = 3. Vakken: a [0; 0,3) ✓ ·
  binnen a: c [0,09; 0,15) ✓ · binnen c: t [0,144; 0,15) ✓ → **`act`**.
- **Stage B "Op de grens":** ruler, ontvangen, zelfde model, bits `1` (= 0,5), n = 2. De speld staat precies op de grens
  c|g: **g** (niet c: `WRONG_EDGE`), daarna op de onderrand van a binnen g → **`ga`**.
- **Intro:** titelkaart "Oefening 95 — notas p. 102". Zeno: "Onderrand dicht, bovenrand open."
- **Sterren:** ★ beide kopieën juist · ★★ 0 misstappen · ★★★ 0 klemmen en zonder hint.

#### 3-4 "Veertig letters, één bit" (P0) — p. 101
- **Stage:** ruler, zenden, model x y z, tekst `yyyxzxxzyyyxyyyyxyyyzxyxyyyyxxyyyyyyxyyy` (n = 40: y 27, x 10, z 3).
  De speler knipt de eerste 5 letters (y y y x z: links 0,2 → 0,34 → 0,438 → 0,438 → 0,49974; lengte 0,7 → 0,49 →
  0,343 → 0,0686 → 0,00686). Daarna neemt de kopiist over (35 knippen, 0,1 s per stuk, met een zoomtunnel en een
  stijgende toon). Eindinterval (exact): **[0,4999999999999965013204725978495833741312;
  0,5000000000000032302663786237598696633344)**, lengte ≈ 6,73·10⁻¹⁵. Naald: 0 + 0,5 < up → **1**, 0,5 ≥ low → stop.
  Kortschrift **`1`**.
- **Vergelijking in de terugblik:** gewone Huffman voor deze 40 letters (y 1 bit, x en z 2 bits): **53 bits**; gewoon
  schrift 320; Lemma 24-grens 48. De notas noemen het interval "ongeveer" [0,49999999999999639178;
  0,50000000000000310862) (p. 101). Met gewone kommagetallen (doubles) krijg je ook die waarden. Het spel rekent exact
  en toont het verschil als illustratie van probleem (b) op p. 103 (§11 vraag 7).
- **Intro:** "Veertig letters. Kijk hoe klein het interval wordt."
- **Sterren:** ★ voorlezing juist · ★★ 0 misstappen · ★★★ zonder hint.

#### 3-5 "Waar de lat ophoudt" (P2) — Oef. 96, precisie
- Idee: dezelfde tekst met een lat van vaste precisie (bv. 6 decimalen); de speler moet bits uitschrijven en herschalen
  zodra het interval binnen een halve lat valt (Oef. 96). Uit te werken als de lead dat wil.

### 5.6 HOOFDSTUK 4 — Pinksteren: "Het leesraam" (LZ77, Algoritme 14)

**Notatie:** per drietal: k (positie in de tekst), het raam (de laatste G tekens), de beslissing ("begin p" of "Geen
match"), het zegel. "Alternatieven" = andere posities met dezelfde maximale lengte (ook correct).

#### 4-1 "Banaan-baan" (P0) — het notasvoorbeeld (p. 106–107), G = 6
- **Nieuw:** leesraam, draad, zegel, Geen match, overlap.
- **Stage:** window, zenden, `banaan-baan` (n = 11), G = 6.

| k | raam | beslissing | zegel |
|---|---|---|---|
| 0 | (leeg) | Geen match | (0,0,b) |
| 1 | `b` | Geen match | (0,0,a) |
| 2 | `ba` | Geen match | (0,0,n) |
| 3 | `ban` | begin 1 (`a`, dan `n`≠`a`) | (1,1,a) |
| 5 | `banaa` | begin 2 (`n`, dan `a`≠`-`) | (2,1,-) |
| 7 | `anaan-` | Geen match | (0,0,b) |
| 8 | `naan-b` | begin 1 (`aan`, dan het einde) | (1,3,EOF) |

  **7 zegels** (= p. 106–107). Gewoon: 11 tekens.
- **Intro:** "Zoek het langste stuk dat al geschreven staat. Begin in het raam."
- **Sterren:** ★ voorlezing juist · ★★ 0 misstappen (7 zegels) · ★★★ 0 klemmen en zonder hint.

#### 4-2 "Aanvaardbaar" (P0) — decoderen (p. 108), G = 6
- **Nieuw:** ontvangen met het leesraam, letter per letter kopiëren.
- **Stage:** window, ontvangen, zegels `(0,0,a) (0,1,n) (0,0,v) (0,2,r) (0,0,d) (0,0,b) (1,3,EOF)`.
  Beslissingen (enkel bij l > 0): (0,1,n): raam `a` → **0** → `aan` · (0,2,r): raam `aanv` → **0** → `aanvaar` ·
  (1,3,EOF): raam `vaardb` → **1** → `aanvaardbaar`. Ramen na elk zegel: `a`, `aan`, `aanv`, `anvaar`, `nvaard`,
  `vaardb`, `rdbaar` (= p. 108).
- **Gevolg (nagerekend):** p = 1 in plaats van 0 bij (0,2,r) → **`aanvanrdbanr`**.
- **Intro:** "Tel vanaf de linkerrand van het raam. De eerste is nul."
- **Sterren:** ★ kopie juist · ★★ 0 misstappen · ★★★ zonder hint.

#### 4-3 "Oefening 97: swiss miss" (P0), G = 8
- **Stage:** window, zenden, `swiss_miss_missing` (n = 18).

| k | raam | beslissing | zegel |
|---|---|---|---|
| 0, 1, 2 | —, `s`, `sw` | Geen match ×3 | (0,0,s) (0,0,w) (0,0,i) |
| 3 | `swi` | begin 0 | (0,1,s) |
| 5 | `swiss` | Geen match | (0,0,_) |
| 6 | `swiss_` | Geen match | (0,0,m) |
| 7 | `swiss_m` | **begin 2**: `iss_m` en dan verder over de rand: `iss_miss`, l = **8** | (2,8,i) |
| 16 | `ss_missi` | Geen match | (0,0,n) |
| 17 | `s_missin` | Geen match | (0,0,g) |

  **9 zegels**. De draad bij k = 7 loopt over de rand van het raam en kopieert letters die hij zelf net gemaakt heeft.
- **Intro:** titelkaart "Oefening 97 — notas p. 108". Zeno: "Een match mag buiten het raam eindigen."
- **Sterren:** ★ voorlezing juist · ★★ 0 misstappen · ★★★ zonder hint.

#### 4-4 "Oefening 98: eendenbende en blablabla" (P0), G = 6
- **Stage A:** window, ontvangen, `(0,0,e) (0,1,n) (0,0,d) (1,2,b) (0,4,EOF)`. Beslissingen: (0,1,n): raam `e` → **0**
  → `een` · (1,2,b): raam `eend` → **1** → `eenden` + `b` · (0,4,EOF): raam `endenb` → **0** → kopie **`eendenbende`**.
- **Stage B:** window, ontvangen, `(0,0,b) (0,0,l) (0,0,a) (0,9,EOF)`. Beslissing: raam `bla` → **0**, en de kopiist
  kopieert 9 letters uit een raam van 3: `blablabla`. Kopie **`blablablabla`** (12 letters). Zeno: "Iets raars? Dat kan."
- **Intro:** titelkaart "Oefening 98 — notas p. 108".
- **Sterren:** ★ beide kopieën juist · ★★ 0 misstappen · ★★★ zonder hint.

#### 4-5 "Oefening 97: de rest" (P1), G = 8
- **Stage A:** `een_benen_been` → (0,0,e) (0,1,n) (0,0,_) (0,0,b) (1,2,e) (2,4,e) (1,1,EOF): **7 zegels**. Laatste zegel:
  raam `enen_bee`, alternatieven p ∈ {1, 3}.
- **Stage B:** `ananas-kanaal` → (0,0,a) (0,0,n) (0,3,s) (0,0,-) (0,0,k) (0,3,a) (0,0,l): **7 zegels**. Bij k = 2 loopt
  `ana` uit het raam `an` (overlap). Bij k = 8 (raam `ananas-k`): alternatieven p ∈ {0, 2}.
- **Stage C:** `een_been_beet_hebben` → (0,0,e) (0,1,n) (0,0,_) (0,0,b) (0,7,t) (3,1,h) (3,1,b) (0,2,n): **8 zegels**. Bij
  k = 5 een overlap van 7 uit het raam `een_b`. Bij k = 15 (raam `n_beet_h`): alternatieven p ∈ {3, 4}.
- **Sterren:** ★ drie voorlezingen juist · ★★ 0 misstappen · ★★★ zonder hint.

#### 4-6 "Het register" (P1) — §4.3.1 en Oefening 100
- **Nieuw:** oneindig raam (p telt vanaf het begin van de tekst), **registerboom** (de deelstringboom van wat al
  geschreven is), teller *zoekwerk*.
- **Stage:** window met `G = ∞` en `register = true`, `abracadabra_simsalabim` (n = 22). Bij elk drietal mag de speler
  op **Register** klikken: een lantaarn wandelt door de registerboom, letter per letter (één vergelijking per letter),
  en licht de langste match op. Daarna kiest de speler zoals gewoonlijk.
  Verwacht: (0,0,a) (0,0,b) (0,0,r) (0,1,c) (0,1,d) (0,4,_) (0,0,s) (0,0,i) (0,0,m) (12,1,a) (0,0,l) (0,2,i) (14,1,EOF):
  **13 zegels** (alternatieven: k = 5 p ∈ {0, 3}; k = 18 p ∈ {0, 7}).
- **Zoekwerk:** zonder register (elke beginpositie van het raam aflopen tot de eerste ongelijke letter): **146**
  vergelijkingen; met register: **22** (= n, één per letter, p. 110).
- **P2-uitbreiding (Oef. 100, tweede deel):** de zegels daarna met twee binderijen coderen (posities/lengtes en letters).
- **Sterren:** ★ voorlezing juist · ★★ 0 misstappen · ★★★ zoekwerk ≤ 30 (dus altijd via het register).

### 5.7 HOOFDSTUK 5 — Hooimaand: "De stempelkast" (LZW)

#### 5-1 "Banaanaanval" (P0) — het notasvoorbeeld (p. 111–112)
- **Nieuw:** stempelkast, zetstok, Verleng/Stempel, nummers vanaf 256.
- **Stage:** stamps, zenden, `banaanaanval` (n = 12). De kopiist zet `b` in de zetstok. Daarna 11 beslissingen:
  `ba`? **S** (98; 256 = ba) · `an`? **S** (97; 257 = an) · `na`? **S** (110; 258 = na) · `aa`? **S** (97; 259 = aa)
  · `an` **V** · `ana`? **S** (257; 260 = ana) · `aa` **V** · `aan`? **S** (259; 261 = aan) · `nv`? **S** (110; 262 = nv)
  · `va`? **S** (118; 263 = va) · `al`? **S** (97; 264 = al) · einde: 108.
  Kortschrift **98 97 110 97 257 259 110 118 97 108** (**10 stempels**; met 12 bits: 120 bits, gewoon 96: Zeno: "Bij
  korte teksten wint de kast nog niets.").
- **Intro:** "Zit het woord met de volgende letter al in de kast? Verleng."
- **Sterren:** ★ voorlezing juist · ★★ 0 misstappen · ★★★ 0 klemmen en zonder hint.

#### 5-2 "Anananas" (P0) — decoderen en het speciale geval (p. 112–114)
- **Nieuw:** ontvangen met de kast, snijden, de lege lade.
- **Stage A:** stamps, ontvangen, codes **97 110 256 258 115**. Verloop: 97 → `a` (vanzelf) · 110 → `n`; nieuwe stempel
  256 = `a`+`n` (één letter, gaat vanzelf) · 256 → `an`; de speler snijdt 257 = `n` + **`a`** · 258 → **lade leeg**
  (speciaal geval): volgend = `an` + **`a`** = `ana`; 258 = `ana` · 115 → `s`; 259 = `anas` (vanzelf). Kopie
  **`anananas`**; woorden 256 an, 257 na, 258 ana, 259 anas (= p. 114). 2 beslissingen.
- **Stage B:** stamps, zenden, `aaaaaaaa` (p. 113): `aa`? S (97; 256 = aa) · `aa` V · `aaa`? S (256; 257 = aaa) · `aa` V
  · `aaa` V · `aaaa`? S (257; 258 = aaaa) · `aa` V · einde 256. Kortschrift **97 256 257 256**. De voorlezing toont hoe
  Letterlijk twee keer een lege lade tegenkomt.
- **Gevolg (nagerekend):** stage A met `an` + `n` bij 258 → **`anananns`**.
- **Intro:** "De lade is nog leeg? Dan begint het woord zoals het vorige."
- **Sterren:** ★ kopie en voorlezing juist · ★★ 0 misstappen · ★★★ zonder hint.

#### 5-3 "Oefening 101: swiss miss" (P0)
- **Stage:** stamps, zenden, `swiss_miss_missing` (n = 18, `_` = 95). Kortschrift **115 119 105 115 115 95 109 258 260
  262 259 105 110 103** (**14 stempels**). Nieuwe stempels: 256 sw, 257 wi, 258 is, 259 ss, 260 s_, 261 _m, 262 mi,
  263 iss, 264 s_m, 265 mis, 266 ssi, 267 in, 268 ng. 17 beslissingen: S S S S S S S V S V S V S V S S S.
- **Intro:** titelkaart "Oefening 101 — notas p. 114".
- **Sterren:** ★ voorlezing juist · ★★ 0 misstappen · ★★★ zonder hint.

#### 5-4 "Oefening 102" (P0)
- **Stage:** stamps, ontvangen, `a 256 b c a b 257 260` (letters als teken gegeven, zoals de oefening). Verloop: a ·
  256 = **lade leeg** → `a` + **`a`** = `aa`, 256 = aa · b → 257 = aab (vanzelf) · c → 258 = bc · a → 259 = ca · b →
  260 = ab · 257 → `aab`, de speler snijdt 261 = `b` + **`a`** · 260 → `ab`, de speler snijdt 262 = `aab` + **`a`**.
  Kopie **`aaabcabaabab`**; woorden ≥ 256: **aa, aab, bc, ca, ab, ba, aaba** (de oefening vraagt ze). 3 beslissingen.
- **Gevolg:** 261 verkeerd snijden (`bb`) laat de kopie juist maar de kast fout: de terugblik markeert lade 261.
- **Intro:** titelkaart "Oefening 102 — notas p. 114–115". Zeno: "Niet zinnig? Dat zegt de oefening zelf."
- **Sterren:** ★ kopie juist · ★★ 0 misstappen (kast exact) · ★★★ zonder hint.

#### 5-5 "Oefening 101: de rest" (P1)
- **Stage A:** `een_beenen_been` → **101 101 110 95 98 256 110 257 259 261** (10 stempels; 256 ee, 257 en, 258 n_,
  259 _b, 260 be, 261 een, 262 ne, 263 en_, 264 _be).
- **Stage B:** `ananas-kanaal` → **97 110 256 97 115 45 107 258 97 108** (10 stempels; 256 an, 257 na, 258 ana, 259 as,
  260 s-, 261 -k, 262 ka, 263 anaa, 264 al).
- **Sterren:** ★ beide juist · ★★ 0 misstappen · ★★★ zonder hint.

### 5.8 HOOFDSTUK 6 — Wijnmaand: "De draaitrommel" (Burrows-Wheeler, move-to-front)

#### 6-1 "Geen loon" (P0) — het notasvoorbeeld (p. 115–117, 121)
- **Nieuw:** trommel, rek (invoegen), markeren, letterplank (zenden).
- **Stage A:** drum, zenden, `geen␣loon` (n = 9). De stroken komen in de volgorde van de rotaties. De eerste valt vanzelf
  in het rek; voor de andere kiest de speler de spleet (0 = bovenaan):
  `een␣loong` → 0 · `en␣loonge` → 1 · `n␣loongee` → 3 · `␣loongeen` → 0 · `loongeen␣` → 4 · `oongeen␣l` → 6 ·
  `ongeen␣lo` → 6 · `ngeen␣loo` → 6. Rek (= p. 116): `␣loongeen`, `een␣loong`, `en␣loonge`, `geen␣loon`, `loongeen␣`,
  `n␣loongee`, `ngeen␣loo`, `ongeen␣lo`, `oongeen␣l`. Markeren: rij **1** (`een␣loong`, eindigt op g). Uitvoer
  **`1␣ngen␣eool`** (= p. 117).
- **Stage B:** shelf, zenden, invoer `1␣ngen␣eool`, beginlijst **(␣,1,a,b,e,f,g,n,o,l)**. Getallen
  **1, 1, 7, 7, 6, 2, 3, 2, 8, 0, 9** (= p. 121). Lijst op het einde: (l,o,e,␣,n,g,1,a,b,f).
- **Gevolgen (nagerekend):** rij 1 en 2 omgewisseld (c = `negn␣eool`) en daarna de strook `een␣loong` gemarkeerd (p = 2)
  → Letterlijk leest **`gen␣loong`**; met p = 1 → **`eeeeeeeee`** · juiste rek maar p = 2 → **`een␣loong`**.
- **Intro:** "Rol de tekst rond. Elke strook begint één letter verder." (stage B) "Schrijf de plaats, vanaf nul.
  Dan naar voren."
- **Sterren:** ★ voorlezing juist · ★★ 0 misstappen · ★★★ zonder hint.

#### 6-2 "Terug naar geen loon" (P0) — decoderen (p. 117–119, 121–122)
- **Nieuw:** letterplank (ontvangen), de terugweg met rangen.
- **Stage A:** shelf, ontvangen, getallen `1,1,7,7,6,2,3,2,8,0,9`, beginlijst (␣,1,a,b,e,f,g,n,o,l) → kopie
  **`1␣ngen␣eool`** (= p. 121–122).
- **Stage B:** drum, ontvangen, p = 1, c = `ngen␣eool`. De kopiist sorteert e = `␣eeglnnoo` en zet de rangen erbij
  (enkel in dit level zichtbaar). Start bij c[1] = g. Beslissingen (de rij in kolom c): e₁ → **2** · e₂ → **5** · n₁ →
  **0** · ␣ → **4** · l → **8** · o₂ → **7** · o₁ → **6** · n₂ → **3** (de weg is rond). Kopie **`geen␣loon`** (de weg
  van p. 117: "e₁ … in rij 2 … e₂ … rij 5").
- **Intro:** "De derde o bovenaan is de derde o onderaan." (stage B)
- **Sterren:** ★ kopie juist · ★★ 0 misstappen · ★★★ zonder hint.

#### 6-3 "Oefening 104: toon gaat" (P0)
- **Stage A:** drum, zenden, `toon␣gaat` (n = 9; zie §11 vraag 4). Spleten: `oon␣gaatt` → 0 · `on␣gaatto` → 0 ·
  `n␣gaattoo` → 0 · `␣gaattoon` → 0 · `gaattoon␣` → 1 · `aattoon␣g` → 1 · `attoon␣ga` → 2 · `ttoon␣gaa` → 8. Rek:
  `␣gaattoon`, `aattoon␣g`, `attoon␣ga`, `gaattoon␣`, `n␣gaattoo`, `on␣gaatto`, `oon␣gaatt`, `toon␣gaat`, `ttoon␣gaa`.
  Markeren: rij **6**. Uitvoer **`6␣nga␣ootta`**.
- **Stage B:** shelf, zenden, beginlijst **(␣,0,1,2,3,4,5,6,7,8,9,a,b,g,m,n,o,t)**. Getallen
  **7, 1, 15, 14, 13, 3, 16, 0, 17, 0, 3**. Geen positienummers onder de plank.
- **Intro:** titelkaart "Oefening 104 — notas p. 122".
- **Sterren:** ★ voorlezing juist · ★★ 0 misstappen · ★★★ zonder hint.

#### 6-4 "Figuur 26: aacaacaac" (P1) — herhalingen (p. 119–120)
- **Stage A:** drum, zenden, `aacaacaac`. Identieke stroken mogen in elke volgorde onder elkaar (elke spleet binnen de
  groep is goed). Rek: 3 × `aacaacaac`, 3 × `acaacaaca`, 3 × `caacaacaa`. Laatste kolom **`cccaaaaaa`**. Markeren: elke rij
  van het blok `acaacaaca` (3, 4 of 5) geeft dezelfde tekst; de figuur kiest **3**.
- **Stage B:** drum, ontvangen, p = 3, c = `cccaaaaaa`: de weg 3 → 6 → 0 → 3 → … loopt drie keer rond (9 stappen, niet
  "tot je terug bent", p. 119). Kopie `aacaacaac`.
- **Sterren:** ★ voorlezing en kopie juist · ★★ 0 misstappen · ★★★ zonder hint.

#### 6-5 "Oefening 105" (P2, wacht op de lead)
- De move-to-front-decodering van `(0,11,10,10,7,0,6,1,0,9,11,4,6,1)` met de lijst (7,a,e,i,o,u,b,c,n,t,w,␣) geeft
  **`7␣tnooeoobwn␣n`**, dus p = 7 en c = `tnooeoobwn␣n` (nagerekend). Die laatste kolom is onder geen enkele gangbare
  sorteervolgorde een Burrows-Wheeler-uitvoer: de terugweg loopt in kringetjes (`bonbonbon…`). Zie §11 vraag 5. Tot de
  lead beslist, bouwt het spel enkel het move-to-front-deel.

### 5.9 ALLERHEILIGEN — "De Codex" (P1) — BWT → move-to-front → Huffman (p. 122)
Het slot van het kloosterjaar: het Sanctus voor alle huizen, zo kort als het kan. Drie werktuigen na elkaar, met de
uitvoer van het ene als invoer van het volgende.
- **Stage A:** drum, zenden, `sanctus␣sanctus␣sanctus` (n = 23). De trommel sorteert nu zelf (montage, 4 s; "je hebt het
  verdiend"). De speler **markeert** enkel p: rij **2** (`anctus␣sanctus␣sanctuss`). Laatste kolom
  **`sssssnnnaaauus␣␣ucccttt`**.
- **Stage B:** shelf, zenden, invoer `2␣sssssnnnaaauus␣␣ucccttt` (25 tekens), beginlijst **(␣,2,a,c,n,s,t,u)**. Getallen
  **1,1,5,0,0,0,0,5,0,0,4,0,0,7,0,3,4,0,2,6,0,0,7,0,0** (14 nullen).
- **Stage C:** bind over de getallen (rij in volgorde van eerste voorkomen): **1:2 5:2 0:14 4:2 7:2 3:1 2:1 6:1**.
  Inkthand: 3+2 → 2 · 6+(32) → 3 · 1+5 → 4 · 4+7 → 4 · (15)+((32)6) → 7 · 7+(47) → 11 · 11+0 → 25. Touw **56**. Codes:
  0 → `1`, 4 → `010`, 7 → `011`, 1 → `0000`, 5 → `0001`, 6 → `0011`, 3 → `00100`, 2 → `00101`.
- **Vergelijking (Kelners kasboek):** gewoon schrift 184 · Huffman rechtstreeks op de tekst 63 · **Codex 56** (zonder
  de boom, zoals p. 87: "voor een gegeven alfabet constante deel … zonder veel belang").
- **Stage D (voorlezing):** Letterlijk ontrolt alles in omgekeerde volgorde (Huffman → getallen → plank → trommel), als
  montage met de vier werktuigen naast elkaar, en zingt het Sanctus.
- **Sterren:** ★ voorlezing juist · ★★ 0 misstappen (56 bits) · ★★★ zonder hint. Slot: de klokken van alle zes huizen
  luiden, aftiteling als verluchte rol.

### 5.10 NACHTWAKE (eindeloze modus, P0; slot: 1-2 ≥ 1 ★)
- **Werktuig:** de binderij, bij één kaars. Elke **ronde** is een stapelrij. Bind tot er één boom is; de kopiist schrijft
  en de duif vertrekt.
- **Ronde r (r = 0, 1, 2, …):** k = min(4 + r, 12) stapels met letters uit `eanrtoidslgkvmuhjbpwzcf` (in die volgorde),
  gewichten w = 1 + ⌊u² · (2 + 2r)⌋ met u uniform in [0, 1) (`ScTextGen`, deterministisch met de seed). Rij in willekeurige
  volgorde.
- **Kaars:** de kaars brandt (de rondetijd): T(r) = max(1,2; 2,5 − 0,08·r) s per binding × (k − 1) + 4 s. Op = de ronde
  is mislukt.
- **Levens:** 3 kaarsen op de kandelaar. Een **verkeerd paar** knapt het touw (de binding gebeurt niet, verdict
  WRONG_PAIR) en kost een kaars. Een opgebrande rondetijd kost ook een kaars (Zeno werkt de ronde af). Na elke 5 foutloze
  rondes komt er een kaars terug (max 3). Geen kaarsen meer = de dageraad: einde.
- **Leesronde** (elke 4e ronde): na het binden komt een strook van 8 letters terug (gecodeerd met jouw boom); lees ze met
  de codeboom (klik per codewoord het blad). Tijd: 1,5 s per letter.
- **Score:** §6.6. Lokale top-10 (3 letters + datum).
- (P1) variant **"Stempelwake"**: LZW-decoderen van gegenereerde codestromen met af en toe een lege lade. (P2) **"Gemengde
  wake"**: elke ronde een ander werktuig.

---

## 6. Scoring, sterren, economie & terugblik

### 6.1 Valuta en meters
- **Inkt** (druppels): de kost van het kortschrift in de eenheid van het werktuig (bits, zegels, stempels; §3.0). Altijd
  naast twee geesten: *gewoon schrift* (8 bits per teken; bij zegels en stempels: n tekens) en het *optimum*.
- **Touw** (binderij) = Σ gewichten van de bundels = bits (Stelling 21). **Zoekwerk** (twee planken, register) =
  vergelijkingen. **Nullen** (letterplank).
- **Duiven:** past de strook in de koker (inkt ≤ optimum), dan vertrekt één duif. Anders twee (gevolg, −50 punten).
  De koker heeft precies de lengte van het optimum.
- **Punten:** score per level (beste wordt bewaard) en de highscore van de Nachtwake.
- **Sterren** (0–3 per level): openen het getijdenboek verder.
- **Klemmen:** geteld, geen misstap.

### 6.2 Kostenmodel (notas-getrouw)
| werktuig | wat telt | optimum | notas |
|---|---|---|---|
| codebord | Σ a(x)·l(x) van jouw code | Huffman-kost | p. 84 |
| binderij | touw = Σ a(Z) over de bundels = Σ a(x)·l(x) | Huffman-kost (elk geldig paar geeft hetzelfde) | Stelling 21, p. 86 |
| levende boom | Σ codebits + 8 per ruwe letter (de eerste letter: enkel 8) | Algoritme 11 foutloos | p. 94–96 |
| meetlat | lengte van de bitstring | Algoritme 13 (de kortste, Oef. 92) | p. 101–102 |
| leesraam | aantal drietallen | gretig de langste match (Algoritme 14) | p. 105 |
| stempelkast | aantal codes (12 bits per code in de terugblik) | de LZW-pseudocode | p. 110–111 |
| trommel / plank | geen inkt; plank: aantal nullen | — | p. 119, 122 |
| Codex | bits na Huffman op de move-to-front-getallen (zonder boom) | 56 | p. 122 |
**Optimum** per level = de tellers na perfect spel (core: `ScLevels.optimum(spec)` speelt alle stages met
`correct_move()`).

### 6.3 Punten
| gebeurtenis | punten |
|---|---|
| correcte beslissing (paar, blad, wissel/blijf, vak, naaldstap, beginpositie, verleng/stempel, snijletter, spleet, rij, rang, getal, blokje, hok) | +10 |
| voorlezing of kopie exact gelijk aan het origineel | +200 |
| inkt bespaard t.o.v. gewoon schrift (enkel als positief) | +1 per bit; +5 per bespaard teken (zegels, stempels) |
| misstap | −20 |
| klem | −5 |
| letter die anders gelezen werd dan bedoeld | −10 per letter |
| tweede duif | −50 |

### 6.4 Sterren (algemeen patroon; exacte voorwaarden per level in §5)
- ★ = **verliesloos**: alle stages afgerond en de voorlezing (zenden) of je kopie (ontvangen) is exact het origineel.
- ★★ = **0 misstappen**. Bij perfect spel is de inkt dan exact het optimum.
- ★★★ = **meesterschap**: zonder hulp (hint, terugnemen, hernemen, hulplijnen) plus wat het level vraagt (0 klemmen,
  tijd, alle lezingen, zoekwerk).
- Hulp is altijd beschikbaar en geen misstap. Wie ze gebruikt, haalt in dat level geen ★★★.

### 6.5 Terugblik (het Kapittel)
Volgorde van de animatie:
1. **Lakzegels:** de sterren worden één voor één in rode was gedrukt, met de voorwaarde eronder (goud/grijs). Kopregel:
   "VERLIESLOOS" of "DE OVERKANT LAS ONZIN".
2. **Kelners kasboek:** balken *jouw inkt*, *optimum*, *gewoon schrift* (en *vaste lengte* bij Huffman, *Huffman* in
   3-4 en de Codex). Ernaast de punten met uitsplitsing (tabel 6.3). In de binderij ook "touw = bits".
3. **Origineel en voorlezing** onder elkaar, letter per letter: gouden stip = gelijk, inktvlek = anders gelezen. Klik op
   een inktvlek → de **oorzakenketen** ("← klim bij de eerste `a`: blijven staan, terwijl `g` [1,6] verder stond")
   springt naar dat moment.
4. **Jouw werk naast het juiste:** de boom (met [g,o]), het codeboek, het rekenboek, de zegels, de stempelkast, het rek,
   de plank. Verschillen omcirkeld.
5. **Misstappen-tijdlijn:** een stip per beslissing (groen OK, amber misstap, grijs klem). Klik op een amber stip: de
   werkbank van dat moment wordt herbouwd (`restore(entry.before)` in een tweede, alleen-lezen werktuig). Jouw zet speelt
   af in bruin-transparant, daarna de juiste zet als gouden inkthand, met één **coachzin** + **notasverwijzing**. Knop
   **"Herneem vanaf hier"**: het level gaat verder vanaf vóór die zet (telt als hulp).
6. **Notas-weergave** (knop): het level zoals de notas het tekenen: de vijf stappen van p. 85, de [g,o]-boom van p. 90,
   de reeks bomen van p. 96–98, de partitie van p. 100 met jouw intervallen, de rijen drietallen met ramen van p. 106–108,
   de LZW-stappen van p. 111–114, de gesorteerde matrix met eerste en laatste kolom van p. 116–117, de move-to-front-regels
   "lees: … schrijven, lijst nu (…)" van p. 121.
7. Knoppen Volgende / Opnieuw / Kaart.

**Coachzinnen** (`ScEventLog.coach_line(entry)`; ≤ 16 woorden + verwijzing; `{…}` = data uit het event):
| verdict | zin | verwijzing |
|---|---|---|
| NOT_PREFIX | "`{a}` is het begin van `{b}`: de lezer weet niet waar de letter stopt." | Definitie 20, p. 83 |
| LONG_CODE | "Frequente letters hoger hangen: `{x}` ({ax}×) verdient een korter woord dan `{y}`." | p. 84 |
| WRONG_PAIR | "De twee lichtste waren {w1} en {w2}, niet {v1} en {v2}." | Algoritme 9, p. 84 |
| WRONG_LEAF | "Schrijf `{x}` met de boom zoals hij nu is: {code}." | p. 92 |
| WRONG_LEAF (nieuw teken) | "`{x}` is nieuw: eerst de code van nng, dan de letter." | p. 94–95 |
| MISSED_SWAP | "Gewicht {w}: {t2} staat verder in de processie ({o2} > {o1}). Wissel." | Algoritme 11, p. 95 |
| WRONG_SWAP | "Wissel met de top met gewicht {w} en het hoogste nummer: {t2}." | Algoritme 11, p. 95 |
| BUMP `ancestor` (ouder) | "Je ouder is de verste? Dan blijf je staan." | Algoritme 11, p. 95 |
| WRONG_SEGMENT | "Het volgende teken is `{x}`: knip het vak [{lo}; {hi})." | Algoritme 12, p. 101 |
| OVERSHOOT | "{g} + {nx} ≥ {up}: die stap valt boven het interval. Schrijf 0." | Algoritme 13, p. 102 |
| LONG_BITS | "{g} + {nx} lag al in [{low}; {up}): stap en je bent klaar." | Algoritme 13, p. 102 |
| UNREACHABLE | "Zonder die stap haal je {low} nooit meer: de rest is samen maar {nx}." | Algoritme 13, p. 102 |
| WRONG_EDGE | "[a, b) bevat b niet: {r} hoort bij `{x}`." | p. 99 |
| SHORT_MATCH | "Vanaf positie {p} loopt de match {l} letters ver, niet {l2}." | Algoritme 14, p. 105 |
| WRONG_POS | "Positie {p} telt vanaf de linkerrand van het raam, de eerste is 0." | p. 106 |
| EARLY_STAMP | "`{wk}` zat al in de kast: eerst verlengen." | LZW, p. 111 |
| WRONG_CARVE | "Nieuwe stempel = `{w}` + de eerste letter van `{next}`." | LZW-decoderen, p. 113 |
| WRONG_CARVE (speciaal) | "Code {c} bestaat nog niet: `{w}` + `{w0}`." | p. 113 |
| WRONG_ORDER | "`{a}` komt vóór `{b}`: vergelijk letter per letter, de spatie is het kleinst." | p. 116 |
| WRONG_P | "p is de rij die eindigt op het eerste teken `{s0}`: rij {p}." | p. 117 |
| WRONG_RANK | "Dit is de {k}e `{x}` in e, dus de {k}e `{x}` in c: rij {i}." | p. 118 |
| WRONG_INDEX | "`{x}` staat op plaats {k} van de lijst zoals ze nu is (vanaf 0)." | p. 121 |
| GARBLED | "Hier las de overkant `{read}` in plaats van `{orig}`: zie {oorzaak}." | (verwijzing van de oorzaak) |
| TWO_PIGEONS | "{ink} druppels voor een koker van {opt}: er moest een tweede duif mee." | — |

### 6.6 Nachtwake-score
Per correct paar +10 × combo, per ronde +50 + 5 × resterende hele seconden, per goed gelezen letter in een leesronde
+10 × combo. **Combo:** correcte zetten binnen 2,5 s na elkaar → ×2 (na 3), ×3 (na 6), ×4 (na 10). De combo breekt bij
een geknapt touw, een opgebrande ronde of een hint. Bij ×4: "Volle vlam" (de kaars laait op, 0,4 s slow-mo, de broeders
zingen één noot). Highscore = punten.

---

## 7. Juice & audio

### 7.1 Juice-lijst (timing / easing; Godot-tweens)
| # | moment | effect |
|---|---|---|
| 1 | teken in de opdrachtband | inkt vloeit in het vakje (0,12 s, `TRANS_SINE`), kleine kras van de ganzenveer |
| 2 | kopiist schrijft bits | veer kriebelt per bit (40 ms per bit; snel 15 ms), inktdruppel in de pot daalt, kras-geluid per bit (0 korter dan 1) |
| 3 | lakzegel (ruwe letter) | rode was druppelt, zegel drukt (squash 1,0 → 0,85 → 1,0 in 0,2 s), "plof" |
| 4 | inktpot boven het optimum | pot wordt amber, de inkt borrelt; de strook groeit voorbij de koker en krult |
| 5 | blad kiezen / leesvinger | vinger glijdt het pad af (60 ms per tak), takken lichten goud op, de strook wordt afgeknipt (schaar, papiersnipper) |
| 6 | klem | gereedschap stuitert terug (0,25 s `TRANS_ELASTIC`), houten tok, 3 px schok 0,1 s, stofje |
| 7 | stapels binden | de twee stapels schuiven naar elkaar (0,25 s `TRANS_BACK`), touw wikkelt zich rond (0,3 s), knoop springt dicht, het getal van de bundel telt op |
| 8 | touwteller | klos draait, touw rolt af in verhouding tot het gewicht |
| 9 | codeboek ontrollen | perkament rolt open (0,5 s), elke regel inkt verschijnt met een klein streepje (stagger 60 ms) |
| 10 | duif vertrekt | duif fladdert op (sprite-animatie), strook in de koker, kort koeren; twee duiven: de tweede kijkt verwijtend |
| 11 | voorlezing | Letterlijk schraapt zijn keel; per letter 0,18 s: de letter verschijnt in zijn kopie met een gouden stip (gelijk) of bruine inktvlek (anders), elke letter een gezongen lettergreep |
| 12 | voorlezing geslaagd | kloosterklok (3 slagen), broeders zingen een akkoord, gouden stof valt over de kopie |
| 13 | voorlezing onzin | Letterlijk fronst, een broeder laat een kan vallen, de inktvlekken pulseren 1× |
| 14 | levende boom: lantaarn | de lantaarn zweeft naar t (0,2 s), zacht schijnsel |
| 15 | wissel | de twee monniken lopen met hun deelboom in een boog van plaats (0,5 s, `TRANS_CUBIC`), kaartjes wisselen in de lucht, in de processie stappen ze om elkaar heen |
| 16 | gewicht +1 | kaartje klapt om (0,12 s), getal +1, belletje dat per niveau hoger klinkt |
| 17 | groei (nng splitst) | het zaadje kiemt in twee (0,4 s), de processie schuift twee plaatsen op (stagger 30 ms) |
| 18 | processie struikelt (eigenschap (b) gebroken) | de monnik wankelt en blijft scheef staan tot het einde, zacht "oei" |
| 19 | De Overkant werkt bij | in het miniboompje herhaalt dezelfde beweging zich versneld (0,3 s) |
| 20 | meetlat knippen | schaar knipt (0,1 s), het vak licht op en groeit tot de hele lat (zoom 0,6 s `TRANS_QUART` ease-in-out), de oude grenzen glijden weg; het rekenboek schrijft de regel |
| 21 | zoomtunnel (3-4) | 35 knippen versneld met een stijgende toon, de cijfers van links/lengte rollen |
| 22 | binaire naald | 1: de naald springt naar de spookstreep (0,15 s), krasje; 0: de spookstreep krimpt naar de helft (0,15 s); in het goud: tik + gloed; overshoot: de naald schiet erover en blijft trillen |
| 23 | speld | speld daalt en prikt (0,15 s), het vak met de speld gloeit; boven open rand = stippellijn die even oplicht |
| 24 | leesraam | het raam schuift met een houten slag (0,2 s); posities glijden mee |
| 25 | draad (match) | een rode draad loopt van bron naar doel, per letter een klikje (60 ms), stijgende toon; over de raamrand: de draad buigt en de bron wordt een net geschreven letter (vonkje) |
| 26 | zegel drukken | wassen zegel met "(p,l,x)" plopt op de strook |
| 27 | kopiëren (ontvangen) | letters vliegen één voor één van de bron naar het einde (80 ms), overlap zichtbaar |
| 28 | stempelkast verlengen | de zetstok schuift één letter open, het woord licht op als het in de kast zit (lade trilt) |
| 29 | stempelen | zware stempel ploft op de strook (0,15 s), inktafdruk met het nummer; een nieuwe lade schuift uit de kast met het nummer, de kopiist snijdt (houtkrullen) |
| 30 | lege lade (speciaal geval) | lade schuift open en is leeg, stofwolkje, Zeno trekt een wenkbrauw op |
| 31 | trommel | de trommel draait één rotatie (0,3 s), een strook wordt eraf gedrukt en valt |
| 32 | invoegen in het rek | de strook zweeft mee met de muis, de spleet gaat open (0,12 s), de strook klikt erin; het rek tekent de eerste en de laatste kolom bij |
| 33 | terugweg | pijl c[i] → e[i] (0,25 s), de letter vliegt naar de kopie; bij "rond" licht de hele cyclus op |
| 34 | letterplank | blokje schuift naar voren (0,25 s), de rest schuift één plaats op (stagger 20 ms); cijferstempel ploft |
| 35 | duiventil | duif landt in het hok; de achtste fladdert rond en vindt niets (lus 1,5 s) |
| 36 | lakzegels (sterren) | was spat, zegel drukt met overshoot (0,3 s) |
| 37 | kist opent (nieuw werktuig) | deksel springt, stro dwarrelt, het werktuig glanst (shader-sweep) |
| 38 | idle | kaars flakkert, stofdeeltjes in het lichtstraaltje, een duif op de vensterbank |
| 39 | Nachtwake "Volle vlam" | hitstop 80 ms, slow-mo 0,5× 0,4 s, kaars laait op |
Instelling schermschok schaalt alle schokken (0/50/100 %). Slow-mo geldt enkel voor wereldnodes, niet voor UI.

### 7.2 Audio
**Muziek** (adaptief, CC0 of procedureel; lagen):
- *Titel/kaart:* rustig koraal (procedurele orgel-drone + gezongen klinkers), 66 BPM.
- *Werkbank:* basislaag (drone + luit-arpeggio's). Na 8 s denken komt er een zachte pad-laag bij. Tijdens de voorlezing
  zakt de muziek weg; Letterlijk "zingt" de letters (één toonhoogte per letter, procedureel).
- *Nachtwake:* sneller (88 BPM), met tikkende waterklok; bij weinig kaars een hartslagtrom.
- *Codex:* het koraal met alle stemmen.
- *Terugblik:* korte jingle (3 varianten naar sterren).

| gebeurtenis | geluid |
|---|---|
| bit schrijven | ganzenveer: kort (0) / lang (1) krasje |
| lakzegel | plof + was |
| binden | touw knarst, knoop trekt aan |
| klem | houten tok + veer |
| wissel | voetstappen op steen, kaartjes ritselen |
| gewicht +1 | belletje (toonhoogte per niveau) |
| groei | zacht "pling" + hout dat kraakt |
| knippen | schaar |
| naald | metalen tik; in het goud: helder belletje |
| draad | stijgende pizzicato per letter |
| zegel | wasplop |
| stempel | zware houten plof; nieuwe lade: schuif + mes |
| lege lade | holle schuif, stofje |
| trommel | houten ratel per rotatie |
| rek | papier glijdt, klik |
| plank | blokje schuift, tik |
| duif | gefladder + koeren |
| voorlezing juist | kloosterklok + koor-akkoord |
| voorlezing onzin | dissonant akkoord, kan valt |
| UI | boekbladzijde, houten knoppen |

---

## 8. Interface-contract core ↔ front-end

Alles in `games/scriptorium/scripts/core/` is **puur** (`RefCounted` of static, geen nodes, geen `Engine`/`Time`-calls),
deterministisch en headless testbaar. De front-end luistert naar signalen en roept methodes aan. **Alle `class_name`s
beginnen met `Sc`.** Geen nieuwe autoloads. Strings zijn `String`s van enkelvoudige tekens (de spatie is `" "`, de
front-end toont `␣`). Bits zijn `String`s van `"0"`/`"1"`. Exacte getallen (meetlat) zijn `ScDec` of hun
stringvorm `"0.34"`.

### 8.1 Bestanden
| bestand | class_name | rol |
|---|---|---|
| `sc_codes.gd` | `ScCodes` | enums en constanten (8.2) |
| `sc_dec.gd` | `ScDec` | exacte decimale getallen van willekeurige precisie in [0, 1] (8.3) |
| `sc_reference.gd` | `ScReference` | onafhankelijke referenties die de notas letterlijk volgen (8.3); bron voor orakel, geesten, Letterlijk en tests |
| `sc_tree.gd` | `ScTree` | binaire boom met ids, gewicht, ordenummer, symbool; codes, wissel, voorouder-test, render, snapshot |
| `sc_tool.gd` | `ScTool` | basisklasse van alle werktuigen (8.4) |
| `sc_prefix_reader.gd` | `ScPrefixReader` | codeboom (§3.1) |
| `sc_code_board.gd` | `ScCodeBoard` | codebord: knippen en ontwerpen (§3.2) |
| `sc_bindery.gd` | `ScBindery` | binderij: rij- en plankmodus (§3.3) |
| `sc_living_tree.gd` | `ScLivingTree` | levende boom, zenden en ontvangen (§3.4) |
| `sc_ruler.gd` | `ScRuler` | meetlat + binaire naald, zenden en ontvangen (§3.5) |
| `sc_window.gd` | `ScWindow` | leesraam, zenden en ontvangen, met optioneel register (§3.6) |
| `sc_register.gd` | `ScRegister` | deelstringboom van het al geschreven stuk (naïef opgebouwd volstaat, n ≤ 40) + wandeling |
| `sc_stamp_case.gd` | `ScStampCase` | stempelkast, zenden en ontvangen (§3.7) |
| `sc_drum.gd` | `ScDrum` | draaitrommel, zenden (invoegen, markeren) en ontvangen (terugweg) (§3.8) |
| `sc_shelf.gd` | `ScShelf` | letterplank, zenden en ontvangen (§3.9) |
| `sc_dovecote.gd` | `ScDovecote` | duiventil (§3.10, P1) |
| `sc_reader.gd` | `ScReader` | **Broeder Letterlijk**: decodeert de uitvoer van de speler met `ScReference` (8.4.1) |
| `sc_event_log.gd` | `ScEventLog` | log, coachzinnen, oorzaakketens (8.9) |
| `sc_level_spec.gd`, `sc_levels.gd` | `ScLevelSpec`, `ScLevels` | leveldata (§5) |
| `sc_director.gd` | `ScDirector` | stages, carry, voorlezing, hint, terugnemen, hernemen, Nachtwake-klok |
| `sc_scoring.gd` | `ScScoring` | punten, combo, sterren, rapport |
| `sc_save.gd` | `ScSave` | `user://scriptorium_save.json` |
| `sc_text_gen.gd` | `ScTextGen` | Nachtwake-generator |
| `sc_tree_layout.gd` | `ScTreeLayout` | posities van boomtoppen (bladeren in volgorde, diepte per rij) |
| `games/scriptorium/tests/sc_level_bot.gd` | `ScLevelBot` | **van de core**: speelt een level via `ScDirector` + orakel, met foutmodi (de front-end maakt geen tweede) |

### 8.2 `ScCodes`
```gdscript
class_name ScCodes
enum Tool { PREFIX_READ, CODE_BOARD, BINDERY, LIVING_TREE, RULER, WINDOW, STAMPCASE, DRUM, SHELF, DOVECOTE }
enum Side { SEND, RECEIVE }
enum Phase { IDLE, READ, CUTS, DESIGN, BIND, COPY, WRITE, GROW, CLIMB, CUT, NEEDLE, PICK, DECIDE, CARVE,
             INSERT, MARK, WALK, NUMBER, PICK_BLOCK, ROOST, DECREE, DONE }
enum Verdict { OK, BUMP, NOT_PREFIX, LONG_CODE, WRONG_PAIR, WRONG_LEAF, MISSED_SWAP, WRONG_SWAP, WRONG_SEGMENT,
               OVERSHOOT, LONG_BITS, UNREACHABLE, WRONG_EDGE, SHORT_MATCH, WRONG_POS, EARLY_STAMP, WRONG_CARVE,
               WRONG_ORDER, WRONG_P, WRONG_RANK, WRONG_INDEX, WRONG_DECREE, GARBLED, TWO_PIGEONS }
const NNG := "nng"          # symbool van de nng-top (kan niet botsen met een teken van lengte 1)
const EOF := "EOF"          # derde element van een drietal na het laatste teken
const RAW_BITS := 8         # kost van een ruwe letter (p. 94)
const LZW_BITS := 12        # bits per LZW-code in de terugblik (p. 110)
static func verdict_name(v: int) -> String
static func phase_name(p: int) -> String
```

### 8.3 `ScDec` en `ScReference`
```gdscript
class_name ScDec extends RefCounted      # exact: geheel getal (array van cijfergroepen) × 10^(−scale)
static func from_string(s: String) -> ScDec          # "0.2", "0.034", "1", "0"
static func dyadic(num: int, pow2: int) -> ScDec      # num / 2^pow2, exact (komt neer op ×5^pow2, scale + pow2)
func add(o: ScDec) -> ScDec; func sub(o: ScDec) -> ScDec; func mul(o: ScDec) -> ScDec; func half() -> ScDec
func cmp(o: ScDec) -> int                              # −1, 0, 1
func is_zero() -> bool
func to_string_sig(max_sig := 12) -> String           # "0,49999999999999…" voor de UI (komma, … bij afkapping)
func to_full_string() -> String                       # alle cijfers (vergrootglas, tests)
func to_float() -> float                              # enkel om te tekenen
```
```gdscript
class_name ScReference                    # static, puur; letterlijk de notas
# prefixcodes
static func is_prefix_code(code: Dictionary) -> bool                       # Definitie 20
static func decode_prefix(code: Dictionary, bits: String) -> Dictionary    # {text, cuts:Array[int], rest:String}
static func all_parses(code: Dictionary, bits: String) -> PackedStringArray
static func greedy_read(code: Dictionary, bits: String) -> String         # Letterlijk: telkens het kortste codewoord
# Huffman (Algoritme 9)
static func freqs_in_order(text: String, order := "") -> Array             # [[sym, a(sym)]] in volgorde van eerste voorkomen (of order)
static func valid_pairs(weights: Array) -> Array                           # alle ongeordende [i, j] die Algoritme 9 toelaat
static func canonical_pair(row: Array) -> Array                            # [i, j] volgens de twee-plankenregel (8.7 ScBindery)
static func huffman(row: Array) -> Dictionary                             # {tree (render-formaat), codes:Dictionary, cost:int, steps:[{row_labels, i, j, w}]}
static func huffman_cost(weights: Array) -> int
# adaptieve Huffman (Algoritme 10/11)
static func p90_tree() -> ScTree                                          # de [g,o]-boom van p. 90
static func adaptive_update(tree: ScTree, ch: String) -> Array             # voert Algoritme 11 uit; [{kind:"grow"|"swap"|"keep"|"keep_parent", t, t2}]
static func adaptive_encode(text: String) -> Dictionary                    # {tokens:Array ({"b":"0"} of {"raw":"x"}), bits:int, steps:Array, tree}
static func adaptive_decode(tokens: Array) -> Dictionary                   # {text, stuck:bool, steps, tree}
static func tokens_from_string(s: String) -> Array                         # '"n"0"o"0100…' → tokens
# aritmetisch (Algoritme 12/13)
static func get_interval(text: String, model: Array) -> Dictionary        # {low:ScDec, up:ScDec, book:[{i, sym, links, lengte}]}
static func get_bitstring(low: ScDec, up: ScDec) -> Dictionary            # {bits:String, trace:[{getal, next, bit}]}
static func arith_decode(bits_or_pin, n: int, model: Array) -> Dictionary # {text, trace}; bits_or_pin: String bits of ScDec
# LZ77 (Algoritme 14)
static func lz77_encode(text: String, G: int) -> Dictionary                # G = −1: oneindig. {triples:[[p,l,x]], info:[{k, ws, window, alts:Array[int], scan:int}]}
static func lz77_decode(triples: Array, G: int) -> String
static func lz77_scan_cost(text: String, k: int, G: int) -> int            # Σ over p in het raam: (lengte van de match vanaf p) + 1 (geen +1 als de tekst eindigde)
# LZW
static func lzw_encode(text: String) -> Dictionary                         # {codes:Array[int], adds:[[code, word]], steps:["extend"|"stamp"]}
static func lzw_decode(codes: Array) -> Dictionary                         # {text, adds, special:Array[int] (indices met lege lade)}
# Burrows-Wheeler en move-to-front
static func bwt(s: String) -> Dictionary                                   # {p, c, rows:Array[String], order:Array[int]} (stabiel; p = rij van rotatie 1)
static func insertion_gaps(s: String) -> Array                             # per rotatie r ≥ 1: [lo, hi] toegelaten spleten
static func inverse_bwt(p: int, c: String) -> Dictionary                   # {text, e:String, walk:[{ch, rank, i}]} (n stappen)
static func mtf_encode(s: String, lst: Array) -> Dictionary                # {nums, lists:Array}
static func mtf_decode(nums: Array, lst: Array) -> Dictionary              # {text, lists}
```

### 8.4 `ScTool` (basis) — signalen, staat, generieke API
```gdscript
class_name ScTool extends RefCounted
signal changed(fx: Dictionary)                          # één animatiebeschrijving (8.6), in afspeelvolgorde
signal phase_changed(phase: int, cursor: Dictionary)    # na ELKE uitgevoerde zet (ook als de fase gelijk blijft) en na elke klem
signal counters_changed(c: Dictionary)                  # {ink, twine, search, decisions, bumps, wasted, zeros}
signal output_changed(out: Dictionary)                  # het kortschrift tot nu toe (8.4.2)
signal copy_changed(copy: String)                       # ontvangen: de kopie van de speler
signal overkant_changed(state: Dictionary)              # zenden met adaptieve structuur: de toestand van Letterlijk (8.4.1)
signal event_logged(entry: Dictionary)
signal stage_done(result: Dictionary)                   # {output, copy, ink}

var tool: int                    # ScCodes.Tool
var side: int                    # ScCodes.Side
var stage: Dictionary            # de stage-spec (8.5)
var phase: int = ScCodes.Phase.IDLE
var counters: Dictionary
var log: ScEventLog

func setup(stage_spec: Dictionary, carry := {}) -> void
func begin() -> void                         # eerste fase; voert automatische beginstappen uit (eerste teken, eerste strook, …)
func cursor() -> Dictionary                  # wat de UI moet tonen/markeren (per subklasse, 8.7)
func render() -> Dictionary                  # volledige tekenstaat (cursor + structuren)
func apply(move: Dictionary) -> Dictionary   # {ok:bool, verdict:int, reason:String, done:bool}
func preview(move: Dictionary) -> Dictionary # muteert niets (hover): {ok, reason, …}; toont NOOIT de matchlengte of het verdict
func correct_move() -> Dictionary            # het orakel: juiste volgende zet (relatief aan de toestand van de speler) of {"act":"none"}
func wrong_moves() -> Array[Dictionary]      # plausibele foute zetten met ok = true (bots, QA)
func impossible_moves() -> Array[Dictionary] # zetten die ok = false geven (kliktests)
func auto_finish() -> void                   # speelt de stage verder met correct_move()
func output() -> Dictionary                  # uitvoer + carry voor de volgende stage (8.4.2)
func copy() -> String                        # ontvangen: de kopie
func overkant() -> Dictionary                # zenden: toestand van de ontvanger (leeg als niet van toepassing)
func snapshot() -> Dictionary                # volledige toestand incl. fase, cursor, tellers, log-lengte; JSON-serialiseerbaar
func restore(d: Dictionary) -> void          # snapshot → restore → snapshot is identiek
func invariants() -> PackedStringArray       # leeg = consistent (bv. (a) in elke boom, gewichten ≥ 0, uitvoer past bij de log)
func is_done() -> bool
```
**`apply()`-resultaat:** `{"ok": bool, "verdict": int, "reason": String, "done": bool}`.
- `ok = false`: onmogelijk (klem). De staat verandert niet. Er volgt `changed({"fx":"bump",…})`, een logentry `BUMP` met
  `reason` ∈ `"not_leaf" "no_path" "no_word" "need_more" "taken" "range" "incomplete" "same" "not_front" "empty"
  "ancestor" "self" "no_pin" "out_of_window" "no_match" "no_stamp" "letter" "not_shorter" "wrong_phase" "unknown_act"
  "unknown"` en `phase_changed`. Klemmen tellen in `counters.bumps`.
- `ok = true`: de zet is uitgevoerd. `verdict` = OK of een foutcode, **vóór** het uitvoeren bepaald door de zet te
  vergelijken met `correct_move()` (en de toegelaten alternatieven) in de toestand van de speler. De hint staat in de
  logentry. `done = true` als de stage hiermee af is.
- **Volgorde van signalen per zet:** alle `changed(fx)` in afspeelvolgorde (ook die van automatische vervolgstappen) →
  `counters_changed` → `output_changed` / `copy_changed` (indien) → `overkant_changed` (indien) → `event_logged` →
  `phase_changed` → eventueel `stage_done`.
- **Automatische stappen gebeuren in de core**, niet in de front-end: het eerste teken (levende boom, stempelkast), het
  schrijven van codes, groei en hernummering, gewicht +1 en het verplaatsen van de lantaarn, de wortel, het rekenwerk van
  Algoritme 12, de stop van de naald, `low = 0 → "0"`, het doorlopen van een match, l = 0-zegels bij ontvangen, het
  openen van een bestaande lade, het snijden bij een volgend woord van één letter, de slotstempel, de eerste strook, de
  eerste stap van de terugweg, het verschuiven op de plank. Ze worden gelogd met `auto: true`.
- **Oordeel relatief aan de speler:** na een afwijking rekent het orakel verder op de boom/lat/kast/plank van de speler
  (één fout = één misstap). De gevolgen voor de ontvanger rekent `ScReader` op de werkelijke uitvoer.

#### 8.4.1 `ScReader` (Broeder Letterlijk)
```gdscript
class_name ScReader                       # static, puur
static func read(kind: String, output: Dictionary, params: Dictionary) -> Dictionary
	# kind ∈ "prefix", "prefix_greedy", "huffman", "adaptive", "arith", "lz77", "lzw", "bwt", "mtf"
	# → {text:String, stuck:bool, structure:Dictionary}   (stuck = strook onleesbaar: tekst eindigt met "…")
static func read_chain(outputs: Array, kinds: Array, params: Array) -> Dictionary
	# leest een keten in omgekeerde volgorde (bv. Codex: huffman → mtf → bwt); de mtf-tekst "p␣c" wordt gesplitst in p en c
static func compare(original: String, read: String) -> Dictionary
	# {equal:bool, marks:Array[bool] (per positie van de langste van de twee), first_diff:int (−1 als gelijk)}
static func adaptive_feed(state: Dictionary, new_tokens: Array) -> Dictionary
	# incrementeel voor De Overkant: {state, text, tree (render), stuck}
```

#### 8.4.2 Uitvoer (`output()`)
| werktuig | `output()` |
|---|---|
| prefix_read | `{"kind":"copy","text":…}` |
| code_board (design) | `{"kind":"bits","bits":…,"code":{…},"ink":n}` |
| bindery | `{"kind":"bits","bits":…,"code":{…},"tree":{render},"ink":touw}` |
| living_tree (zenden) | `{"kind":"tokens","tokens":[…],"ink":n}` |
| ruler (zenden) | `{"kind":"bits","bits":…,"n":n,"model":[…],"ink":n}` |
| window (zenden) | `{"kind":"triples","triples":[[p,l,x]],"G":G,"ink":aantal}` |
| stampcase (zenden) | `{"kind":"codes","codes":[…],"ink":aantal}` |
| drum (zenden) | `{"kind":"bwt","p":p,"c":…,"text":"p␣c"}` (carry voor de plank) |
| shelf (zenden) | `{"kind":"numbers","nums":[…],"list":[…],"symbols":["1","1","7",…]}` (carry voor de binderij in de Codex) |
| ontvangen (alle) | `{"kind":"copy","text":…}` |

### 8.5 Stages en carry
Een level = 1..4 stages (`ScLevelSpec.stages`). De director maakt per stage een werktuig via
`ScLevels.make_tool(stage, carry)`. `carry` is de `output()` van de vorige stage. Stage-specs (Dictionaries):
```
{"tool":"prefix_read", "code":{"o":"00","u":"010","d":"011","f":"10","t":"11"}, "bits":"00010011", "expect":"oud"}
{"tool":"code_board", "mode":"cuts", "code":{"e":"0","n":"1","b":"10"}, "bits":"100101", "need":2, "intended":"benen"}
{"tool":"code_board", "mode":"design", "text":"een been en een benen", "max_depth":3}
{"tool":"bindery", "mode":"row"|"shelves", "text":"boosdoeer", "row":"boesdr"}           # row: optionele rijvolgorde
{"tool":"bindery", "mode":"row", "weights":[["A",8],["B",3],["C",5],["D",2],["E",9]]}   # 1-4 (geen tekst, geen voorlezing)
{"tool":"bindery", "mode":"row", "symbols":"carry"}                                       # Codex: de getallen van de plank
{"tool":"living_tree", "side":"send", "text":"graag", "start":"empty"|"p90"}
{"tool":"living_tree", "side":"receive", "tokens":"\"n\"0\"o\"0100\"d\"001100\"a\"100111", "expect":"nooddaad"}
{"tool":"ruler", "side":"send", "model":[["x","0.2"],["y","0.7"],["z","0.1"]], "text":"yy", "auto_after":-1}  # 3-4: auto_after 5
{"tool":"ruler", "side":"receive", "model":[…], "bits":"0010011", "n":3, "expect":"act"}  # of "pin":"0.9" i.p.v. "bits"
{"tool":"window", "side":"send", "text":"banaan-baan", "G":6, "register":false}            # G = −1: oneindig
{"tool":"window", "side":"receive", "triples":[[0,0,"a"],[0,1,"n"],…,[1,3,"EOF"]], "G":6, "expect":"aanvaardbaar"}
{"tool":"stampcase", "side":"send", "text":"banaanaanval"}
{"tool":"stampcase", "side":"receive", "codes":[97,110,256,258,115], "expect":"anananas"}
{"tool":"drum", "side":"send", "text":"geen loon", "auto_sort":false}
{"tool":"drum", "side":"receive", "p":1, "c":"ngen eool", "ranks":true, "expect":"geen loon"}
{"tool":"shelf", "side":"send", "input":"carry"|"1 ngen eool", "list":[" ","1","a","b","e","f","g","n","o","l"]}
{"tool":"shelf", "side":"receive", "nums":[1,1,7,7,6,2,3,2,8,0,9], "list":[…], "expect":"1 ngen eool"}
{"tool":"dovecote", "bits":3}
```
**Voorlezing (director):** een zendstage waarvan de uitvoer niet door de volgende stage gebruikt wordt, krijgt aan haar
einde een voorlezing: `ScReader.read` (of `read_chain` over de aaneengesloten zendstages van die keten, bv. trommel →
plank in 6-1, trommel → plank → binderij in de Codex). Het origineel is de tekst van de eerste stage van de keten.
`code_board` met `mode:"cuts"` krijgt een **demovoorlezing** (`prefix_greedy`; telt niet voor de sterren). Ontvangstages
vergelijken `copy()` met `expect`. `pigeons` = 1 als de inkt ≤ het optimum van die keten, anders 2.

### 8.6 Animatiebeschrijvingen (`changed(fx)`) — de front-end speelt ze af in volgorde
| `fx` | velden | betekenis |
|---|---|---|
| `"bump"` | `reason:String, at:Variant` | klem |
| `"read_path"` | `leaf:int, path:Array[int], bits:String, ch:String` | leesvinger loopt het pad af, knip, letter naar de kopie |
| `"cut"` | `at:int, ch:String` | knip in de codebord-strook |
| `"reading_done"` | `text:String, new:bool` | volledige lezing (codebord) |
| `"place"` | `sym:String, path:String, from:String` | tegel gehangen (`from` = vorige plaats of "") |
| `"bind"` | `a:int, b:int, at:int, id:int, w:int, twine:int` | twee stapels → bundel op rijpositie `at` |
| `"codebook"` | `codes:Dictionary` | codeboek ontrolt |
| `"write"` | `tokens:Array` | de kopiist schrijft (bits en/of lakzegels) |
| `"grow"` | `old_nng:int, o:int, nng:int, leaf:int, renumber:int` | zaadje splitst; alle andere nummers +`renumber` (2) |
| `"lantern"` | `node:int` | lantaarn bij t |
| `"swap"` | `a:int, b:int` | twee deelbomen wisselen van plaats en nummer |
| `"weight"` | `node:int, w:int` | gewicht +1 |
| `"stumble"` | `nodes:Array[int]` | eigenschap (b) gebroken: deze monniken struikelen |
| `"segment"` | `sym:String, lo:String, hi:String, book_row:Dictionary` | vak geknipt, lat zoomt in |
| `"needle"` | `bit:int, getal:String, next:String, inside:bool, overshoot:bool` | naaldstap |
| `"needle_reset"` | — | UNREACHABLE: de naald zakt terug |
| `"pin"` | `value:String` | speld gezet (ontvangen) |
| `"thread"` | `from:int, to:int, steps:Array, overlap_from:int` | de draad loopt (bron → doel), `overlap_from` = index vanaf waar de bron in de nieuwe tekst ligt (−1 = geen) |
| `"seal"` | `triple:Array` | zegel gedrukt |
| `"slide"` | `ws:int` | raam schuift |
| `"copy_letters"` | `src:Array[int], letters:String` | ontvangen: letters één voor één gekopieerd |
| `"register_walk"` | `steps:Array, p:int, l:int` | lantaarn door de registerboom |
| `"zetstok"` | `w:String, k:String, in_case:bool` | zetstok + volgend teken |
| `"stamp"` | `code:int, new_code:int, word:String, dup:bool` | stempel op de strook, nieuwe lade |
| `"drawer"` | `code:int, word:String, empty:bool` | lade gaat open (ontvangen) |
| `"carve"` | `code:int, word:String` | nieuwe stempel gesneden (ontvangen) |
| `"rotation"` | `r:int, text:String` | trommel drukt een strook |
| `"insert"` | `r:int, gap:int` | strook in het rek |
| `"mark"` | `row:int, out:String` | rij gemarkeerd, uitvoer geschreven |
| `"walk"` | `from_row:int, to_row:int, ch:String, rank:int, closed:bool` | terugweg-stap |
| `"shelf_move"` | `k:int, ch:String, list:Array` | blokje naar voren |
| `"number"` | `k:int` | cijferstempel |
| `"roost"` | `pigeon:int, hole:String` | duif in hok |
| `"overkant"` | `state:Dictionary` | De Overkant herhaalt (versneld) |
| `"stage"` | `index:int, tool:int` | nieuwe stage |

### 8.7 Zetten per werktuig (exacte dictionaries), cursor en orakel
**Algemeen:** `{"act": String, …}`. `correct_move()` geeft altijd een zet die `apply()` met verdict OK aanvaardt.

**`ScPrefixReader`** (`code`, `bits`, `pos`, `copy`) — fase READ.
| zet | effect / verdict |
|---|---|
| `{"act":"read","leaf":id}` | klem `not_leaf` (interne top), `no_path` (code(id) is geen prefix van bits[pos..]). Anders OK: pos += \|code\|, copy += sym. Klaar bij pos = \|bits\| |
`cursor()`: `{pos, rest:String, copy, tree:render}`. Orakel: het blad waarvan de code prefix is van de rest (uniek).

**`ScCodeBoard`** — `mode:"cuts"` (fase CUTS) en `mode:"design"` (fase DESIGN).
| zet | effect / verdict |
|---|---|
| `{"act":"cut","at":i}` | klem `no_word` (bits[start..i−1] geen codewoord), `range`. OK. Is de strook op, dan is de lezing compleet (`reading_done`, nieuw of al gevonden) en begint een nieuwe lezing |
| `{"act":"reset"}` | begin de lezing opnieuw. OK |
| `{"act":"done"}` | klem `need_more` (< `need` lezingen). OK → demovoorlezing, stage klaar |
| `{"act":"place","sym":x,"path":p}` | klem `taken`, `range` (\|p\| = 0 of > max_depth), `unknown`. OK (verplaatst x als hij al hing) |
| `{"act":"remove","sym":x}` | OK |
| `{"act":"send"}` | klem `incomplete`. Geen prefixcode → NOT_PREFIX, Letterlijk leest gulzig (onzin), de stage blijft open. Prefix en kost > optimum → LONG_CODE, stage klaar. Anders OK, stage klaar |
`cursor()`: cuts `{start, parts:Array, readings:Array, total:int}`; design `{placed:{sym:path}, ink, prefix_ok:bool}`.
Orakel cuts: de volgende knip van de eerste nog niet gevonden lezing (in de volgorde van `all_parses`); daarna `done`.
Orakel design: plaats de letters volgens de codes van `ScReference.huffman`, dan `send`.

**`ScBindery`** (`row`: Array van boom-ids, `mode`, `shelf_a`, `shelf_b`, `twine`, `search`)
| zet | effect / verdict |
|---|---|
| `{"act":"bind","a":i,"b":j}` (rij) | klem `same`, `range`. OK als {i, j} ∈ `valid_pairs`, anders WRONG_PAIR. Bundel op min(i, j), kinderen in rijvolgorde (links = 0). twine += a(Z); search += 2m − 3 (m = rijlengte vóór de binding) |
| `{"act":"bind","a":"A"\|"B","b":"A"\|"B"}` (planken) | neemt de voorkant van plank a en daarna de (nieuwe) voorkant van plank b. Klem `empty`. OK als het paar geldig is, anders WRONG_PAIR. Bundel achteraan plank B, eerste genomen = links. search += 1 per genomen stapel als beide planken niet leeg waren |
Na de laatste binding (één boom): `codebook`, COPY (de kopiist schrijft), stage klaar.
**Orakel (twee-plankenregel = Oef. 85, reproduceert p. 85):** sleutel per stapel = (gewicht, 0 voor een bundel / 1 voor
een losse stapel, ontstaansvolgorde van de bundel / rijpositie van de losse stapel); X = minimum, Y = minimum van de rest.
`cursor()`: `{row:[{id, label, w, leaf:bool}], shelf_a, shelf_b, twine, search, selected:int}`.

**`ScLivingTree`** (`tree:ScTree`, `nng`, `t`, `i`, `side`, zenden: `text`, `tokens_out`; ontvangen: `tokens`, `pos`, `copy`)
| zet | fase | effect / verdict |
|---|---|---|
| `{"act":"write","leaf":id}` | WRITE (zenden) | klem `not_leaf`. Correct: het blad van text[i] als dat bestaat, anders nng. Ander blad of nng voor een bekend teken → WRONG_LEAF. Schrijft code(id) (+ `{"raw":text[i]}` als id = nng). Daarna werkt de boom bij met het **echte** teken: GROW (nieuw) of CLIMB vanaf zijn blad |
| `{"act":"read","leaf":id}` | READ (ontvangen) | klem `not_leaf`, `no_path` (code(id) ≠ de volgende bits, of id = nng zonder lakzegel erna). OK: copy += teken (bij nng: de letter van het lakzegel). Daarna GROW/CLIMB. Bestaat er geen blad dat past (de boom van de speler week af), dan is de strook **onleesbaar**: `changed({"fx":"bump","reason":"unreadable"})`, copy += "…", stage klaar |
| `{"act":"swap","with":id}` | CLIMB | klem `self` (id = t), `ancestor` (id is voorouder of nakomeling van t; de wortel inbegrepen), `range`. Zij t* = de top met a = a(t) en het hoogste nummer. t* ∈ {t, ouder(t)} → WRONG_SWAP (je had moeten blijven). id = t* → OK. Anders WRONG_SWAP. Wissel posities en nummers; a(t) += 1; t = ouder; bij de wortel: +1 en het teken is af |
| `{"act":"keep"}` | CLIMB | OK als t* ∈ {t, ouder(t)}, anders MISSED_SWAP. a(t) += 1; t = ouder; … |
GROW (automatisch, Algoritme 11): nng → o met kinderen nng (links, nr 1) en het nieuwe blad (rechts, nr 2), o nr 3,
alle andere nummers +2, a(o) = 1; is o de wortel, dan is het teken af, anders t = ouder(o). Het eerste teken van een
tekst/kortschrift gaat volledig automatisch. Na elk afgewerkt teken (zenden): `overkant_changed` met
`ScReader.adaptive_feed`, en `stumble` als eigenschap (b) gebroken is.
`cursor()`: `{i, ch (zenden), t, tstar (enkel tutorial), same_weight:Array[int] (enkel tutorial), tree:render,
procession:[{id, num, w}], out:String, pos, copy}`.

**`ScRuler`** (`model`, `low`, `len`, `i`, `getal`, `next`, `bits`, `side`, ontvangen: `pin`)
| zet | fase | effect / verdict |
|---|---|---|
| `{"act":"cut","sym":x}` (zenden) | CUT | klem `unknown`. OK als x = text[i], anders WRONG_SEGMENT. Algoritme 12 met x. Na het laatste teken: low = 0 → bit "0" automatisch en klaar; anders NEEDLE (getal 0, next ½) |
| `{"act":"bit","b":1\|0}` | NEEDLE | b* = 1 ⇔ getal + next < up. b = b* → OK. b = 1, b* = 0 → OVERSHOOT (getal += next; getal ≥ up ≥ low → klaar). b = 0, b* = 1: getal + next > low → LONG_BITS (verder); getal + next ≤ low → UNREACHABLE (`needle_reset`, bits gewist, `counters.wasted` += lengte). Na een bit 1: getal ≥ low → klaar. next /= 2 |
| `{"act":"cut","sym":x}` (ontvangen) | CUT | [lo, hi) = vak van x in het huidige interval. Klem `no_pin` als pin < lo of pin > hi. pin = hi → WRONG_EDGE: x gaat naar de kopie, de resterende tekens worden automatisch het laatste modelteken, klaar. Anders OK, inzoomen. Klaar na n tekens |
`cursor()`: `{i, low, up, len, segs:[{sym, lo, hi, lo_f, hi_f}], book:[{i, sym, links, lengte}], getal, next, bits, pin,
copy}` (getallen als strings van `ScDec`, plus `_f`-floats om te tekenen). `auto_after = k`: na k knippen speelt de core
de rest van de knippen zelf (gelogd `auto`).

**`ScWindow`** (`G`, `k`, `written`, `triples`, `register`, `side`)
| zet | fase | effect / verdict |
|---|---|---|
| `{"act":"start","p":p}` (zenden) | PICK | klem `out_of_window` (p ∉ [0, \|raam\|)), `no_match` (raam[p] ≠ text[k]). l = lengte van de match vanaf raampositie p (de bron mag voorbij k lopen). OK als l = de maximale lengte, anders SHORT_MATCH. x = text[k+l] of EOF. Zegel (p, l, x); k += l + 1; `slide` |
| `{"act":"literal"}` (zenden) | PICK | OK als de maximale lengte 0 is, anders SHORT_MATCH. Zegel (0, 0, text[k]) |
| `{"act":"register"}` (zenden, enkel met register) | PICK | `register_walk`; markeert de beste p. search += l + 1 (l als de tekst eindigt). Zonder register telt elke beslissing `lz77_scan_cost` in search |
| `{"act":"start","p":p}` (ontvangen) | PICK | klem `out_of_window`. OK als p = de p van het zegel, anders WRONG_POS. Kopieert l letters vanaf raampositie p één voor één (de bron mag in de net geschreven letters lopen), dan x (behalve EOF). Zegels met l = 0 gaan automatisch |
`cursor()`: `{k, ws, window:String, rest:String (zenden), triple (ontvangen), triples, written, copy}`. Orakel
(zenden): de kleinste p met maximale lengte, of `literal`.

**`ScStampCase`** (`entries:[[code, word]]`, `next_code`, `w`, `i`, `side`, zenden: `out`; ontvangen: `codes`, `cpos`,
`volgend`, `copy`)
| zet | fase | effect / verdict |
|---|---|---|
| `{"act":"extend"}` | DECIDE (zenden) | klem `no_stamp` (wk niet in de kast). OK: w = wk |
| `{"act":"stamp"}` | DECIDE (zenden) | OK als wk niet in de kast zit, anders EARLY_STAMP. out += code(w) (bij dubbele woorden: de laagste code); nieuwe lade (next_code, wk) ook als wk al bestaat (`dup = true`); w = k. Is de tekst op: slotstempel code(w) automatisch, klaar |
| `{"act":"carve","i":j}` | CARVE (ontvangen) | gewoon: klem `range` (j ≥ \|volgend\|); nieuwe lade = w + volgend[j]; OK als j = 0, anders WRONG_CARVE. Speciaal geval (code = next_code, lege lade): klem `range` (j ≥ \|w\|); volgend = w + w[j]; nieuwe lade = w + volgend[0]; OK als j = 0, anders WRONG_CARVE. Daarna copy += volgend, w = volgend |
Automatisch: de eerste code, een bestaande lade openen, snijden als volgend één letter is. Een code > next_code komt in
de leveldata niet voor (`invariants` meldt het).
`cursor()`: `{w, k, i, entries_new:[{code, word, dup}], out, codes, cpos, volgend, special:bool, copy}`. Orakel zenden:
`extend` als wk in de kast zit, anders `stamp`.

**`ScDrum`** (zenden: `s`, `rack:Array[int]` (rotatie-indices), `pending`; ontvangen: `p`, `c`, `e`, `x`, `copy`, `step`)
| zet | fase | effect / verdict |
|---|---|---|
| `{"act":"insert","gap":g}` | INSERT | klem `range` (g ∉ [0, \|rek\|]). OK als lo ≤ g ≤ hi (lo/hi = aantal stroken in het rek die < resp. ≤ de nieuwe zijn), anders WRONG_ORDER. Na de laatste strook: MARK. `auto_sort = true`: het rek sorteert zichzelf (montage), meteen MARK |
| `{"act":"mark","row":r}` | MARK | klem `range`. OK als rek[r] dezelfde tekst heeft als de rotatie die bij s[1] begint, anders WRONG_P. Uitvoer p = r, c = laatste kolom van het rek van de speler |
| `{"act":"find","i":i}` | WALK | klem `letter` (c[i] ≠ de letter van x), `range`. OK als de rang van c[i] in c gelijk is aan de rang van x in e, anders WRONG_RANK. x = e[i]; na n stappen klaar (`closed` = x is terug bij het begin) |
Ontvangen begint automatisch: copy += c[p], x = e[p]. Bij elke stap gaat de letter van x eerst naar de kopie, daarna
kiest de speler. Dat geeft n − 1 keuzes.
`cursor()`: zenden `{rack:Array[String], pending:String, row_count}`; ontvangen `{p, c, e, ranks_visible, x:{ch, rank},
step, copy}`.

**`ScShelf`** (`list`, `i`, zenden: `input`, `out`, `mirror_list`; ontvangen: `nums`, `copy`)
| zet | fase | effect / verdict |
|---|---|---|
| `{"act":"number","k":k}` | NUMBER (zenden) | klem `range`. OK als list[k] = input[i], anders WRONG_INDEX. out += k. Jouw plank: input[i] naar voren. De plank van Letterlijk (`mirror_list`): list′[k] naar voren |
| `{"act":"pick","k":k}` | PICK_BLOCK (ontvangen) | klem `range`. OK als k = nums[i], anders WRONG_INDEX. copy += list[k]; list[k] naar voren |
`cursor()`: `{list, i, input|nums, out|copy, show_positions:bool}`. counters.zeros = aantal nullen in out.

**`ScDovecote`** — `{"act":"roost","pigeon":m,"hole":h}` (klem `taken`, `not_shorter`, `range`) ·
`{"act":"decree","which":1|2,"answer":"impossible"|"true"|"false"}` (OK of WRONG_DECREE).

### 8.8 Levels, director, scoring, opslag, generator
```gdscript
class_name ScLevelSpec extends RefCounted
var id: String; var chapter: int; var title: String; var intro: String; var notes_ref: String
var priority: String                          # "P0"|"P1"|"P2"
var stages: Array[Dictionary]                 # 8.5
var stars: Array[Dictionary]                  # [{"kind":"lossless"} | {"kind":"no_mistakes"} | {"kind":"no_help"} | {"kind":"no_bumps"}
                                              #  | {"kind":"time_le","s":60} | {"kind":"readings_all"} | {"kind":"search_le","v":30}
                                              #  | {"kind":"decrees_ok"} | {"kind":"done"}]
var optimum: Dictionary                       # {"ink":22, "twine":22, "search":12, …}
var ghosts: Dictionary                        # {"plain":72, "fixed":27, "huffman":53}
var hints_allowed: bool = true
var tutorial: Array[Dictionary] = []          # [{"trigger":"first_climb","ghost":{"act":"swap","with":7},"text":"…"}]
var story: Dictionary = {}                    # {"house":"Priorij Bindervoort", "zeno_intro":"…", "debrief_extra":"…", "crate":"binderij"}

class_name ScLevels
static func ids() -> PackedStringArray        # "0-1" … "6-5", "C" (Codex)
static func get_spec(id: String) -> ScLevelSpec
static func endless_spec(round_index: int, seed_: int) -> ScLevelSpec
static func make_tool(stage: Dictionary, carry: Dictionary) -> ScTool
static func optimum(spec: ScLevelSpec) -> Dictionary   # speelt alle stages met correct_move()

class_name ScDirector extends RefCounted
signal stage_started(index: int, tool: ScTool)
signal reading_started(result: Dictionary)   # {original, read, marks, pigeons, demo:bool}
signal level_finished(report: Dictionary)
signal candle_changed(lives: int, burn: float)   # Nachtwake
signal round_started(r: int, stage: Dictionary)  # Nachtwake
var spec: ScLevelSpec; var tool: ScTool; var stage_index: int; var scoring: ScScoring
var time: float; var finished: bool; var hints: int; var undos: int; var resumes: int
func start(s: ScLevelSpec) -> void
func tick(dt: float) -> void                  # tijd; Nachtwake: kaars
func apply(move: Dictionary) -> Dictionary    # naar het werktuig; volgende stage of voorlezing als de stage klaar is
func hint() -> Dictionary                     # tool.correct_move() + log HINT
func undo() -> bool                           # herstelt de snapshot van vóór de laatste beslissing; log UNDO
func resume_from(seq: int) -> bool            # "Herneem vanaf hier": restore(entry.before), de log wordt afgekapt; log RESUME
func finish() -> Dictionary                   # ScScoring.final_report

class_name ScScoring extends RefCounted
signal points_changed(total: int, delta: int, reason: String)
signal combo_changed(combo: int)
signal full_flame()                           # Nachtwake combo ×4
var points: int; var combo: int
func bind(director: ScDirector) -> void
func final_report(director: ScDirector) -> Dictionary
	# {stars:[bool,bool,bool], star_labels:[…], points, breakdown:[{label, amount}], counters, optimum, ghosts,
	#  original:String, read:String, marks:Array, pigeons:int, mistakes:Array[Dictionary], bumps, hints, undos, resumes,
	#  time_s, structures:{yours, correct}}

class_name ScSave
static func load_data() -> Dictionary         # {version:1, stars:{"1-1":3}, best:{"1-1":points}, highscores:[{name,score,date}], settings:{…}, seals:{"1-1":["notasboom"]}}
static func save_data(d: Dictionary) -> void
static func set_stars(id: String, n: int) -> void        # houdt het maximum
static func add_highscore(score: int, name: String, date: String) -> int   # rang 1..10 of 0
static func setting(k: String, default_value) -> Variant
static func set_setting(k: String, v) -> void

class_name ScTextGen extends RefCounted
func _init(seed_: int) -> void
func wake_round(r: int) -> Dictionary         # {letters:Array[String], weights:Array[int], read_text:String (elke 4e ronde)} volgens §5.10

class_name ScTreeLayout
static func layout(tree: Dictionary, width: float, height: float) -> Dictionary   # id → Vector2 (bladeren in volgorde, diepte per rij)
```
**Boom-renderformaat** (`ScTree.render()`): `{"root":id, "nng":id|−1, "nodes":[{"id":int, "w":int, "num":int (−1 als
niet gebruikt), "sym":String ("" = interne top, "nng"), "l":int, "r":int, "p":int, "code":String}]}`.

### 8.9 `ScEventLog`
```gdscript
class_name ScEventLog extends RefCounted
var entries: Array[Dictionary]
	# {seq:int, t:float, stage:int, type:String, data:Dictionary (incl. move), verdict:int, ok:bool, auto:bool,
	#  hint:Dictionary (correct_move vóór de zet), affects:Array[int] (posities in de tekst die hierdoor anders gelezen werden),
	#  before:Dictionary (snapshot; enkel bij verdict ≠ OK, bij klemmen en bij de eerste zet van elke stage)}
func add(type: String, data: Dictionary, verdict: int, ok: bool, hint: Dictionary, before: Dictionary, auto := false) -> Dictionary
func mistakes() -> Array[Dictionary]           # verdict ∉ {OK, BUMP}
func bumps() -> Array[Dictionary]
func cause_of(pos: int) -> Dictionary          # de misstap die positie pos van de voorlezing/kopie anders liet lezen, of {}
	# regel: de laatste misstap vóór de uitvoer-token waarin positie pos voor het eerst afwijkt
func coach_line(entry: Dictionary) -> String   # §6.5 (klemmen: korte regel per reason)
func notes_ref(entry: Dictionary) -> String    # bv. "Algoritme 11 · notas p. 95"
```
Types: `STAGE_START READ CUT RESET DONE PLACE REMOVE SEND BIND CODEBOOK COPY WRITE GROW SWAP KEEP SEGMENT BIT START
LITERAL REGISTER EXTEND STAMP CARVE INSERT MARK FIND NUMBER PICK ROOST DECREE READING GARBLED TWO_PIGEONS BUMP HINT UNDO
RESUME STAGE_END LEVEL_END`.

### 8.10 Gameplay-zijde (ter info, niet bindend)
`games/scriptorium/scripts/game/`: `sc_title.gd`, `sc_book_map.gd` (getijdenboek), `sc_workbench.gd` (hoofdscène: bouwt
nodes in `_ready`, één scène voor alle levels; `--level=2-2` als commandoregelargument voor QA), `sc_task_band.gd`
(opdrachtband/kopie), `sc_shorthand_strip.gd` (kortschrift, inkt, koker), `sc_overkant.gd`, `sc_tree_view.gd`
(codeboom, binderij, levende boom + processie), `sc_ruler_view.gd`, `sc_window_view.gd`, `sc_stamp_view.gd`,
`sc_drum_view.gd`, `sc_shelf_view.gd`, `sc_dovecote_view.gd`, `sc_reading.gd` (voorlezing), `sc_chapter_review.gd`
(terugblik met herbeleving via een tweede read-only werktuig), `sc_notes_view.gd` (notas-weergave), `sc_cheat_sheet.gd`,
`sc_hud.gd`, `sc_wake.gd` (Nachtwake). De bestaande autoloads `Sfx`, `Juice`, `Transition` gebruiken, niet wijzigen.
Scènes: `res://games/scriptorium/scenes/title.tscn` (minimaal), `workbench.tscn`.

---

## 9. Testgevallen die de core móét halen (`games/scriptorium/tests/run_tests.gd`)

Alle verwachte waarden komen uit de referentie-implementatie (zie inleiding) en, waar vermeld, letterlijk uit de notas.
"bot" = de stage afspelen met `correct_move()`. Elke werktuigtest controleert ook `invariants().is_empty()` na elke zet.
Spatie = `" "` in de testdata.

**ScReference tegen de notas**
- **T01 Prefixcodes (p. 83–84):** code Fig. 25: `decode_prefix(…, "00010011")` = `oud`, knippen na 2, 5, 8;
  `"100001011"` = `fout`, knippen na 2, 4, 7, 9. `is_prefix_code(Fig. 25)` = true; `is_prefix_code({e:0, n:1, b:10})` =
  false; `all_parses(dat, "100101")` = {`benen`, `bebn`, `neebn`, `neenen`}; `all_parses(dat, "10001")` = {`neeen`,
  `been`}; `greedy_read(dat, "100101")` = `neenen`.
- **T02 Huffman `boosdoeer` (p. 84–86):** rij b:1 o:3 e:2 s:1 d:1 r:1. `huffman` volgt exact de stappen b+s, d+r,
  (bs)+(dr), o+e, (bsdr)+(oe) met rijen zoals p. 85; codes b 000, s 001, d 010, r 011, o 10, e 11; bericht
  `0001010001010101111011`; kost 22. `valid_pairs([1,3,2,1,1,1])` = de 6 paren uit {0, 3, 4, 5}. Exhaustief: 18 geldige
  keuzereeksen, allemaal kost 22.
- **T03 Oef. 80/81:** `bananenboom` (rij b:2 a:2 n:3 e:1 o:2 m:1): kost 28, inkthand-codes b 000, e 0010, m 0011, n 01,
  a 10, o 11; 12 keuzereeksen, 6 lengteprofielen, alle 28. `zaken_nemen_geen_keer`: kost 59, codes z 00000, a 00001,
  r 0001, _ 001, e 01, k 100, m 1010, g 1011, n 11; 90 reeksen, 11 profielen, alle 59.
- **T04 Oef. 86/85:** gewichten 8, 3, 5, 2, 9 → 59 (links naar rechts: 72). `de kok kookt koolsoep` in plankmodus: touw
  59, zoekwerk 12; rijmodus zoekwerk 64.
- **T05 Algoritme 10 (p. 90–93):** `p90_tree()` voldoet aan (a), (b), (c). `adaptive_update(…, "e")` = geen wissels,
  boom `[10,11]([4,9](…) [6,10](e[3,7] o[3,8]))`. `adaptive_update(…, "s")` = wissels s↔r[1,4], [2,6]↔e[2,7], dan
  blijven; boom `[10,11]([4,9]([2,5](b[1,1] r[1,2]) e[2,6]) [6,10]([3,7](d[1,3] s[2,4]) o[3,8]))`. Code vooraf: e = `10`,
  s = `001`.
- **T06 `graag` (p. 96–98):** `adaptive_encode("graag")`: tokens `"g" 0"r" 00"a" 101 101`, 33 bits, bomen na elk teken
  zoals de tabel in §5.4 (2-2). Met nog een `r`: uit `101`, stappen keep_parent, keep, keep; boom
  `[6,7](a[2,5] [4,6]([2,3](nng[0,1] r[2,2]) g[2,4]))` (het speciale geval van p. 98).
- **T07 `eetzaal` en Oef. 90:** `eetzaal`: tokens `"e" 1 0"t" 00"z" 000"a" 1101 1100"l"`, 55 bits, keep_parent bij de
  tweede `e`, bomen zoals §5.4 (2-3). `voordeel`: tokens `"v" 0"o" 01 00"r" 000"d" 1100"e" 1001 1000"l"`, 68 bits, bomen
  zoals §5.4 (2-4). `adaptive_decode` van beide geeft de tekst terug.
- **T08 Oef. 91:** `adaptive_decode(tokens_from_string('"n"0"o"0100"d"001100"a"100111'))` = `nooddaad`, eindboom
  `[8,9]([3,7]([1,3](nng n[1,2]) a[2,4]) [5,8](o[2,5] d[3,6]))`.
- **T09 Aritmetisch, model x/y/z (p. 99–100):** `get_interval("yy")` = [0.34, 0.83), bits `1`; `"zx"` = [0.9, 0.92),
  bits `11101`; `"x"` = [0, 0.2), bits `0` (low = 0); `"yx"` = [0.2, 0.34), bits `01`. Grenzen voor twee tekens: 0.04, 0.18,
  0.2, 0.34, 0.83, 0.9, 0.92, 0.99. `arith_decode("1", 2)` = `yy`; `arith_decode("1101", 2)` = `yy`;
  `arith_decode(ScDec("0.9"), 2)` = `zx`.
- **T10 Veertig letters (p. 101):** interval exact [`0.4999999999999965013204725978495833741312`,
  `0.5000000000000032302663786237598696633344`), bits `1`; Huffman op dezelfde tekst 53 bits. Dezelfde berekening in
  `float` geeft ≈ [0.4999999999999964, 0.5000000000000031] (de waarden van de notas, op afronding na).
- **T11 Oef. 93/95:** `get_interval("cag")` (a 0.3, c 0.2, g 0.4, t 0.1): boekregels (c, 0.3, 0.2), (a, 0.3, 0.06),
  (g, 0.33, 0.024) → [0.33, 0.354); `get_bitstring` = `01011` met getal-waarden 0, 0.25, 0.25, 0.3125, 0.34375.
  `arith_decode("0010011", 3)` = `act` (vakken [0, 0.3), [0.09, 0.15), [0.144, 0.15)). `arith_decode("1", 2)` = `ga`.
- **T12 LZ77 (p. 106–108):** `lz77_encode("banaan-baan", 6)` = (0,0,b) (0,0,a) (0,0,n) (1,1,a) (2,1,-) (0,0,b)
  (1,3,EOF); ramen `""`, `b`, `ba`, `ban`, `banaa`, `anaan-`, `naan-b`. `lz77_decode` van (0,0,a) (0,1,n) (0,0,v) (0,2,r)
  (0,0,d) (0,0,b) (1,3,EOF) met G = 6 = `aanvaardbaar`, ramen na elk drietal `a`, `aan`, `aanv`, `anvaar`, `nvaard`,
  `vaardb`, `rdbaar`.
- **T13 Oef. 97/98 (G = 8 resp. 6):** de drietallen van §5.6 voor de vier teksten (9, 7, 7, 8 drietallen), met de
  alternatieven {1, 3} (laatste van `een_benen_been`), {0, 2} (k = 8 in `ananas-kanaal`), {3, 4} (k = 15 in
  `een_been_beet_hebben`). `lz77_decode` = `eendenbende` en `blablablabla`.
- **T14 Oef. 100 / §4.3.1:** `lz77_encode("abracadabra_simsalabim", −1)` = de 13 drietallen van §5.6; Σ `lz77_scan_cost`
  = 146; met register: 22.
- **T15 LZW (p. 111–114):** `lzw_encode("banaanaanval")` = 98 97 110 97 257 259 110 118 97 108, nieuwe woorden 256 ba …
  264 al (§5.7). `lzw_decode([97,110,256,258,115])` = `anananas`, woorden 256 an, 257 na, 258 ana, 259 anas, speciaal geval
  bij code 258. `lzw_encode("aaaaaaaa")` = 97 256 257 256; `lzw_decode` daarvan = `aaaaaaaa` met twee speciale gevallen.
- **T16 Oef. 101/102:** `swiss_miss_missing` (`_` = 95) → 115 119 105 115 115 95 109 258 260 262 259 105 110 103;
  `een_beenen_been` → 101 101 110 95 98 256 110 257 259 261; `ananas-kanaal` → 97 110 256 97 115 45 107 258 97 108.
  `lzw_decode([97,256,98,99,97,98,257,260])` = `aaabcabaabab`, woorden ≥ 256: aa, aab, bc, ca, ab, ba, aaba.
- **T17 BWT + move-to-front (p. 115–122):** `bwt("geen loon")` = p 1, c `ngen eool`, rijen zoals §5.8 (6-1).
  `inverse_bwt(1, "ngen eool")` = `geen loon`, rijen van de weg 1, 2, 5, 0, 4, 8, 7, 6, 3. `mtf_encode("1 ngen eool",
  [" ","1","a","b","e","f","g","n","o","l"])` = 1, 1, 7, 7, 6, 2, 3, 2, 8, 0, 9, eindlijst (l, o, e, " ", n, g, 1, a, b, f);
  `mtf_decode` geeft de invoer terug.
- **T18 Oef. 104 en Fig. 26:** `bwt("toon gaat")` = p 6, c `nga ootta`; move-to-front met (␣,0,…,9,a,b,g,m,n,o,t) =
  7, 1, 15, 14, 13, 3, 16, 0, 17, 0, 3. `bwt("aacaacaac")` = p 3, c `cccaaaaaa`; `inverse_bwt(p, c)` = `aacaacaac` voor
  p ∈ {3, 4, 5} en `caacaacaa` voor p ∈ {0, 1, 2}; de weg voor p = 3: 3, 6, 0, 3, 6, 0, 3, 6, 0.
- **T19 Oef. 105 (enkel move-to-front):** `mtf_decode([0,11,10,10,7,0,6,1,0,9,11,4,6,1], [7,a,e,i,o,u,b,c,n,t,w," "])` =
  `7 tnooeoobwn n`. (Gedocumenteerd, geen level: de LF-permutatie van `tnooeoobwn n` heeft meer dan één cyclus, §11.)
- **T20 Codex:** `bwt("sanctus sanctus sanctus")` = p 2, c `sssssnnnaaauus  ucccttt`; move-to-front met
  (␣,2,a,c,n,s,t,u) = 1,1,5,0,0,0,0,5,0,0,4,0,0,7,0,3,4,0,2,6,0,0,7,0,0; Huffman op die getallen kost 56; Huffman op de
  tekst kost 63. `ScReader.read_chain` → `sanctus sanctus sanctus`.
- **T21 Invoegspleten:** `insertion_gaps("geen loon")` = 0, 1, 3, 0, 4, 6, 6, 6 (rotaties 1–8); `"toon gaat"` = 0, 0, 0,
  0, 1, 1, 2, 8; `"aacaacaac"` = [1,1], [2,2], [0,1], [2,3], [4,5], [0,2], [3,5], [6,8].
- **T22 ScDec:** 0.2 + 0.7 = 0.9 exact; `dyadic(19, 7)` = 0.1484375; 0.7^27 · 0.2^10 · 0.1^3 = de lengte uit T10 (≈ 6,73·10⁻¹⁵);
  `cmp`, `half` tot 2^−60 exact.

**Werktuigen (spelregels, gevolgen)**
- **T23 codeboom:** in 0-1 stage A bij pos 0: `read` met blad u → klem `no_path`, snapshot ongewijzigd; interne top →
  klem `not_leaf`.
- **T24 codebord:** stage A: `cut at 3` vanaf start 0 (`100`) → klem `no_word`; `done` met 1 lezing → klem `need_more`.
  Stage B: code e = 0, n = 01, ␣ = 10, b = 11 → `send` = NOT_PREFIX, Letterlijk leest `eeebebeeebeeebeeeebebee e…`
  (strook onleesbaar), stage blijft open. Vaste code (2 bits) → LONG_CODE (42 bits), voorlezing juist, `pigeons` = 2.
- **T25 binderij:** 1-1: eerste zet `bind 0 1` (b+o) → WRONG_PAIR; bot verder → touw 23, voorlezing juist, 2 duiven.
  `bind 2 2` → klem `same`. Plankmodus (1-5): `bind B B` bij de start → klem `empty`.
- **T26 levende boom:** 2-2: bij de eerste `a` `keep` → MISSED_SWAP (precies één misstap); de bot speelt verder relatief
  aan de spelersboom; tokens `"g"0"r"00"a"001001`; Letterlijk leest `graggga`. 2-3: bij de tweede `e` `swap` met de
  wortel → klem `ancestor`; `keep` → OK. 2-3 met `keep` bij de eerste klimstap van de eerste `a` → Letterlijk leest
  `eetzate…`. 2-4 met `keep` bij de eerste klimstap van `d` → `voordvoo…`. 2-5 (ontvangen) met `keep` bij de derde letter
  → kopie `noonn…` (onleesbaar).
- **T27 meetlat:** 3-2: eerste `bit 1` → OVERSHOOT, strook `1`, Letterlijk leest `gaa`. 3-2 na de correcte 0: `bit 0` →
  UNREACHABLE (0 + 0,25 ≤ 0,33), `needle_reset`. 3-1 A: eerste `bit 0` → LONG_BITS, bot verder → strook `011`,
  voorlezing `yy` juist. 3-1 B speld 0,9: `cut y` → WRONG_EDGE, kopie `yz`; `cut x` → klem `no_pin`.
- **T28 leesraam:** 4-1 bij k = 3: `start 2` → klem `no_match`; `start 3` → klem `out_of_window`. Bij k = 8: `literal` →
  SHORT_MATCH; bot verder → 8 zegels (… (0,0,b) (0,0,a) (1,2,EOF)), voorlezing juist, 2 duiven. 4-2: `start 1` bij
  (0,2,r) → WRONG_POS, kopie `aanvanrdbanr`.
- **T29 stempelkast:** 5-1: `extend` bij `ba` → klem `no_stamp`. `stamp` bij de eerste `an` (wk in de kast) →
  EARLY_STAMP; bot verder → codes 98 97 110 97 97 258 257 118 97 108, lade 260 = `an` (dup), voorlezing juist.
  5-2: `carve 1` in het speciale geval (code 258) → WRONG_CARVE, kopie `anananns`.
- **T30 trommel:** 6-1: rotatie 2 in spleet 0 → WRONG_ORDER; bot verder (spleet = rang in het rek van de speler) → c =
  `negn eool`, markeren rij 2 (OK, de strook `een loong`), Letterlijk leest `gen loong`. Correct rek, `mark 2` → WRONG_P,
  Letterlijk leest `een loong`. 6-2 B: bij de stap van e₁ `find 5` → WRONG_RANK; `find 0` → klem `letter`.
- **T31 letterplank:** 6-1 B: derde getal 8 in plaats van 7 → WRONG_INDEX; bot verder → nums 1,1,8,7,6,2,3,2,8,0,9;
  Letterlijk leest `1 ogeo ennl`. 6-2 A: derde keuze 8 → WRONG_INDEX, kopie `1 ogeo ennl`. `number 10` → klem `range`.
- **T32 duiventil:** een duif naar de zolder zolang er een kort hok vrij is → klem `not_shorter`; na zeven duiven is
  de zolder de enige plaats; tweede duif in hetzelfde hok → klem `taken`.

**Algemeen**
- **T33 snapshot:** voor elk level: na elke bot-zet is `snapshot() → restore() → snapshot()` identiek (ook midden in een
  klim, een naaldreeks, een match, een speciaal geval en een half rek).
- **T34 elk level met de bot:** 3 sterren; tellers == `spec.optimum` (bv. 1-1 22 bits, 2-2 33 bits, 3-2 5 bits, 4-1 7
  zegels, 5-1 10 stempels, Codex 56 bits); voorlezing/kopie == origineel.
- **T35 orakelconsistentie:** voor elke fase van elk werktuig wordt `correct_move()` aanvaard met verdict OK; elke zet
  uit `impossible_moves()` geeft `ok=false`; elke zet uit `wrong_moves()` geeft `ok=true` en verdict ≠ OK.
- **T36 opslag:** `ScSave` roundtrip; `set_stars` houdt het maximum; highscore-rang.
- **T37 generator:** `ScTextGen.new(42).wake_round(r)` is deterministisch; k = min(4 + r, 12); gewichten ≥ 1.
- **T38 oorzaak:** in T26 (2-2) wijst `cause_of(eerste anders gelezen positie)` naar de `keep`-zet.
- **T39 eigenschappen adaptieve Huffman:** 2000 willekeurige teksten over {a, b, c, d, e} (lengte 1–20): `adaptive_decode`
  ∘ `adaptive_encode` = identiteit; na elk teken voldoet de boom aan (a), (b), (c) (Lemma 22); het aantal klimstappen is
  ≤ de diepte van het blad vóór de update (Lemma 23).
- **T40 eigenschappen Huffman:** 500 willekeurige gewichtsrijen (k ≤ 7, gewichten 1–6): elke geldige keuzereeks heeft
  kost `huffman_cost`; de twee-plankenregel geeft altijd een geldige reeks.
- **T41 roundtrips:** 2000 willekeurige teksten: LZ77 (G ∈ {1…8, −1}), LZW, BWT (met en zonder herhalingen), move-to-front
  en aritmetisch coderen (lengte ≤ 12, modellen in tienden) geven na decoderen de tekst terug.
- **T42 Algoritme 13 is minimaal (Oef. 92):** voor 500 intervallen uit `get_interval` bestaat er geen kortere bitstring
  met een waarde in [low, up) (exhaustief tot de gevonden lengte).

---

## 10. Scope & prioriteiten

**P0 (MVP: zonder dit is de game niet af):**
- Core volledig voor alle werktuigen behalve de duiventil en het register (§8), tests T01–T31 en T33–T42.
- Levels **0-1, 0-2, 1-1, 1-2, 1-3, 2-1, 2-2, 2-3, 2-4, 2-5, 3-1, 3-2, 3-3, 3-4, 4-1, 4-2, 4-3, 4-4, 5-1, 5-2, 5-3, 5-4,
  6-1, 6-2, 6-3** (25) + **Nachtwake** (binderij).
- Schermen: titel (met hub-terugweg), getijdenboek, brief, werkbank, voorlezing, Kapittel (sterren, kasboek, origineel vs.
  voorlezing met oorzakenketen, structuurvergelijking, misstappen-tijdlijn met herbeleving + coachzin + hernemen,
  notas-weergave), pauze, instellingen, Notas-spiekbriefje, opslag (sterren, beste punten, highscore, instellingen).
- Besturing muis + toetsenbord (§4.1), hint, terugnemen, tutorials (inkthand), De Overkant (miniboom, -raam, -kast,
  -plank).
- Juice 1–34, 36, 37 (minstens 30 van de 39); audio: alle cues uit §7.2 (procedureel mag), één muzieklus voor de werkbank,
  één voor de Nachtwake, titel/kaart, de gezongen voorlezing.

**P1 (sterk gewenst):**
- Levels 0-3 (duiventil), 1-4, 1-5, 4-5, 4-6 (register), 5-5, 6-4, **De Codex**.
- Nachtwake-leesronde, combo/"Volle vlam", kisten, attract-modus op de titel, kleurenblindmodus, Notasboom-zegel,
  "Stempelwake".

**P2 (polish / als er tijd is):**
- 2-6 (Oef. 88), 3-5 (precisie, Oef. 96), 6-5 (Oef. 105, na beslissing van de lead), Oef. 100 met twee Huffman-bomen,
  Oef. 106/107 als "wist je dat" in de terugblik, "Gemengde wake", verzamelbare verluchtingen.

**Bewust NIET:** hoofdstuk 5 en verder; PPM (enkel een zin in het spiekbriefje: "aritmetisch coderen met wisselende
modellen", p. 103–104); Vitter en het sliding window van Knuth (p. 89); de implementatie met vaste precisie (Amir Said,
p. 103); volle LZW-woordenboeken (p. 112, enkel vermeld); de bewijzen van Stelling 21, Lemma 22/23 en Oef. 87/89/92/109
(de terugblik verwijst ernaar); lineaire BWT via suffixbomen (Oef. 109/110); online leaderboards.

**Bouwvolgorde (voorstel voor parallel werk):**
1. core: `ScCodes`, `ScDec`, `ScReference`, `ScReader` + T01–T22 (kan meteen, zonder spelstaat) ∥ front-end: werkbank-
   skelet (opdrachtband, kortschrift, inkt, koker, De Overkant) met een **nep-werktuig** dat `ScReference`-sporen afspeelt,
   en het getijdenboek.
2. core: `ScTool`, `ScTree`, `ScPrefixReader`, `ScCodeBoard`, `ScBindery` + T23–T25 ∥ front-end: proloog en hoofdstuk 1
   (codeboom, codebord, binderij) + voorlezing.
3. core: `ScLivingTree` + T26, T39 ∥ front-end: levende boom + processie.
4. core: `ScRuler`, `ScWindow` + T27, T28 ∥ front-end: meetlat + naald, leesraam.
5. core: `ScStampCase`, `ScDrum`, `ScShelf` + T29–T31 ∥ front-end: stempelkast, trommel, plank.
6. core: `ScDirector`, `ScScoring`, `ScSave`, `ScTextGen`, `ScLevels`, `ScLevelBot` + T33–T38, T40–T42 ∥ front-end:
   Kapittel + herbeleving, Nachtwake.
7. QA-ronde (bots met foutmodi, frame-opnames), dan P1.

---

## 11. Open vragen voor de lead

1. **Titel.** Voorstel: **Kortschrift** (ondertitel *Het scriptorium van Zuinigem*); map en prefix blijven `scriptorium`/`Sc`.
   Akkoord, of blijft het "Scriptorium"?
2. **Huffman: gelijke gewichten en links/rechts.** Het spel aanvaardt **elk** paar dat Algoritme 9 toelaat ("niet uniek",
   p. 84–85). Voor de inkthand, het orakel en de verwachte codes gebruikt het de twee-plankenregel van Oef. 85 (bij gelijk
   gewicht eerst een gebonden bundel, de oudste eerst, dan losse stapels van links naar rechts). Een nieuwe bundel komt op
   de plaats van de meest linkse van de twee en de linkse is het 0-kind. Dat reproduceert p. 85 exact (codes p. 85–86).
   De rij volgt de volgorde van eerste voorkomen, behalve in 1-1 (volgorde van p. 85: b o e s d r). Akkoord?
3. **Twee figuren, twee oriëntaties.** Op p. 85 staat o links van e (o = 10), op p. 90 staat e[2,7] links van o[3,8]. Het
   spel volgt in hoofdstuk 1 p. 85 en in 2-1 (de [g,o]-boom) p. 90. Bij de levende boom ligt de oriëntatie vast door de
   regels van p. 95 (nng links, het nieuwe teken rechts, wissels ruilen plaatsen). De terugblik van 2-1 vermeldt dat de
   codes van e en o daardoor verschillen van p. 86. OK?
4. **Spatie en liggend streepje.** Oef. 81, 97 en 101 schrijven `zaken_nemen_geen_keer`, `swiss_miss_missing`, … in
   schrijfmachineletter met een echt `_`. Het spel neemt dat letterlijk (`_` = code 95 in LZW). In Oef. 104/105 staat de
   spatie als zichtbaar streepje (`toon_gaat`, lijst `(_,0,1,…)`); het spel gebruikt daar de spatie (code 32, kleiner dan
   alle letters, zoals p. 116 en 121). De tekst van Oef. 104 is dan **`toon gaat`** ("Codeer de tekst toon gaat **door**
   eerst …": "door" hoort bij de zin, want de lijst van de oefening heeft geen d en geen r). Akkoord?
5. **Oefening 105.** Move-to-front geeft `7 tnooeoobwn n`, dus p = 7 en c = `tnooeoobwn n`. Onder de ASCII-volgorde (en
   ook onder de volgorde van de lijst) valt de terugweg uiteen in kringetjes (`bon`, ` t`, `oeno`…): geen enkele tekst heeft
   die Burrows-Wheeler-uitvoer (nagerekend over alle 5040 volgordes van de 7 tekens: enkel ongewone volgordes geven één
   cyclus, en dan geen leesbare tekst). Voorstel: 6-5 blijft P2 en het spel gebruikt enkel het move-to-front-deel, tenzij
   de lead een gecorrigeerde opgave heeft. Een alternatief is 6-5 als voorbeeld voor Oef. 108 ("een string die geen BWT kan
   zijn"), maar dan zegt het spel impliciet dat de oefening fout is. Wat verkiest de lead?
6. **LZ77: meerdere langste matches.** De notas kiezen niet. Het spel aanvaardt elke positie met maximale lengte; de
   inkthand neemt de kleinste p. Bij l = 0 schrijft het spel altijd p = 0 ("neem gewoon p = 0", p. 106). Akkoord?
7. **Exacte getallen in 3-4.** De notas geven "ongeveer" [0,49999999999999639178; 0,50000000000000310862). Exact is het
   [0,4999999999999965013…; 0,5000000000000032302…). De notaswaarden zijn wat gewone doubles geven. Het spel toont de
   exacte waarden en vermeldt neutraal: "met gewone kommagetallen krijg je ongeveer de waarden van de notas; precies dat is
   probleem (b) op p. 103". OK?
8. **Broeder Letterlijk bij niet-prefixcodes** leest gulzig het kortste codewoord (0-2). Dat staat niet in de notas; het
   is een spelafspraak om de ambiguïteit van p. 82 zichtbaar te maken. De terugblik toont ook alle andere lezingen.
   Akkoord?
9. **Adaptieve Huffman: kosten en begin.** Een ruwe letter kost 8 bits ("bv. één byte", p. 94). Het eerste teken gaat
   ruw zonder nng-code (`"g"`, p. 96). EOF wordt niet gecodeerd (p. 96: "de boom moet daarvoor … niet meer gewijzigd
   worden"). Bij ontvangen is lezen gedwongen door de bits (een verkeerd blad klemt); de echte keuzes zijn de wissels.
   Akkoord?
10. **Adaptieve Huffman: "blijf" vs. wissel met de ouder.** In het speciale geval klemt een klik op de ouder (`ancestor`)
    en moet de speler "blijf" kiezen. Zo voelt hij "je kan de top niet vervangen door een boom waar die zelf inzit" (p. 95).
    Een klem telt niet als misstap, maar wel voor ★★★ in 2-3. OK?
11. **LZW: Stempel terwijl wk al in de kast zit.** Het spel voert dan de else-tak uit, inclusief "voeg wk toe" (een
    dubbele lade). Zender en ontvanger blijven zo gelijk lopen en de tekst blijft juist; het gevolg is een verloren lade en
    meestal een langer kortschrift. Alternatief: de kast weigert (klem). Wij kiezen het eerste omdat het de else-tak
    letterlijk volgt. Akkoord? Verder: bij het einde van de tekst schrijft de zender code(w) zonder iets toe te voegen.
12. **BWT-conventies.** p = de rij die eindigt op s[0] (p. 117), dus de rotatie die bij s[1] begint. Bij identieke rijen
    (Fig. 26) aanvaardt het spel elke rij van het blok (alle geven dezelfde tekst; de figuur kiest de eerste). In de
    uitvoer `p␣c` en bij move-to-front worden het getal en de spatie mee gecodeerd zoals p. 121. Akkoord?
13. **Kostenmodel en de Codex.** Inkt in bits, zegels of stempels (geen vergelijking tussen werktuigen, behalve in de
    Codex: Huffman op de move-to-front-getallen, 56 bits, tegen Huffman op de tekst, 63 bits; telkens zonder de boom,
    zoals p. 87). LZW wordt in stempels geteld, met "12 bits per code" in de terugblik. Aanvaardbaar?
14. **Aritmetisch decoderen op een grens.** Een klik op het vak onder de speld als die precies op de open bovenrand staat,
    is een misstap (WRONG_EDGE); daarna leest de speler automatisch het bovenste teken. Andere vakken zonder speld klemmen.
    OK als spelafspraak voor de halfopen intervallen van p. 99?
15. **Nachtwake = binderij (P0).** De binderij is het snelste werktuig met een duidelijke juist/fout-beslissing. LZW-
    decoderen ("Stempelwake") is P1. OK?
16. **Duiventil (0-3, P1).** Het tweede decreet ("voor elk bericht bestaat een code die het korter maakt") is de juiste
    lezing van het tweede deel van Oef. 76 (∀ bestand ∃ algoritme). Het spel geeft geen formeel bewijs; het spiekbriefje
    verwijst naar de oefening. Volstaat dat?
17. **Register (4-6).** De core mag de deelstringboom naïef opbouwen (n ≤ 40); het spel toont enkel de zoekwinst van §4.3.1,
    niet Ukkonen zelf (dat zat in Trietuin). Akkoord?

---

## Samenvatting voor het team
- **Kern:** een ambachtelijke codeerpuzzel in een middeleeuws scriptorium. Elk werktuig is een algoritme uit hoofdstuk 4:
  **codeboom** (prefixcodes), **binderij** (Huffman: bind de twee lichtste; touw = bits), **levende boom** met
  **processie** (adaptieve Huffman: nng, t′ = zelfde gewicht en hoogste nummer, niet wisselen met de ouder), **meetlat**
  en **binaire naald** (Algoritme 12/13), **leesraam** (LZ77: match begint in het raam, mag erbuiten eindigen),
  **stempelkast** (LZW, met de lege lade), **draaitrommel** (BWT: sorteren, p, de terugweg met rangen) en **letterplank**
  (move-to-front). Elke brief eindigt met **De Voorlezing**: Broeder Letterlijk leest exact wat je schreef. Fouten
  worden onzin aan de overkant of extra inkt (een tweede duif), nooit "fout".
- **Levels:** Proloog (0-1 Fig. 25 + Oef. 79 · 0-2 waarom prefix · 0-3 duiventil) | 1 Binderij (1-1 boosdoeer · 1-2 Oef. 80 ·
  1-3 Oef. 81 · 1-4 Oef. 86 · 1-5 Oef. 85) | 2 Levende boom (2-1 p. 90–93 · 2-2 graag · 2-3 eetzaal (speciaal geval) ·
  2-4 Oef. 90 · 2-5 Oef. 91 · 2-6 Oef. 88) | 3 Meetlat (3-1 x/y/z · 3-2 Oef. 93 · 3-3 Oef. 95 · 3-4 veertig letters, één bit
  · 3-5 precisie) | 4 Leesraam (4-1 banaan-baan · 4-2 aanvaardbaar · 4-3 Oef. 97 · 4-4 Oef. 98 · 4-5 Oef. 97 rest · 4-6
  register §4.3.1) | 5 Stempelkast (5-1 banaanaanval · 5-2 anananas + aaaaaaaa · 5-3 Oef. 101 · 5-4 Oef. 102 · 5-5 Oef. 101
  rest) | 6 Trommel (6-1 geen loon + MTF · 6-2 terug · 6-3 Oef. 104 · 6-4 Fig. 26 · 6-5 Oef. 105) | De Codex (sanctus:
  BWT → MTF → Huffman, 56 vs. 63 bits) | Nachtwake (binderij bij een opbrandende kaars).
- **Posities 0-gebaseerd** zoals de notas (raam, BWT-rijen, move-to-front); LZW met ASCII-codes en nieuwe codes vanaf 256;
  links = 0 in elke boom; exacte decimale getallen op de meetlat.
