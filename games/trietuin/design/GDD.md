# Trietuin — Game Design Document (v1)

Eigenaar: game designer. Lezers: core-engineer (`games/trietuin/scripts/core/`), gameplay/front-end-engineer
(`games/trietuin/scripts/game/`, `games/trietuin/scenes/`), art & audio director (`design/ART.md`), QA.
Bron van de leerstof: lesnotas AD3 2026, hoofdstuk 3.1–3.3 (gedrukte p. 25–50; pdf-pagina = gedrukte pagina).
**Bij twijfel gaan de notas voor.** Elke boom, elke j, elke skip, elk (b,e)-label en elke Ukkonen-stap in dit document
werd nagerekend met een Python-referentiesimulator die letterlijk de regels van de notas volgt (toevoegen/verwijderen
p. 27, Algoritme 1 p. 29, Ukkonen p. 38–43). De simulator reproduceert Figuur 13→14, Figuur 15 (beide helften),
Figuur 16 (pointerboompjes), Figuur 17, Figuur 18 en alle (p̄, x̄)-pijlen uit het voorbeeld `abacabc_` (p. 44–48).
Twee plaatsen waar de figuren afwijken van de regels staan in §11 (Open vragen).

Stijl (palet, vormen, fonts) bepaalt `ART.md`. Dit document legt enkel **functionele** eisen vast: wat leesbaar moet
zijn, wat beweegt en wanneer, wat de speler beslist.

Inhoud: 1 Pitch & pijlers · 2 Wereld & kernlus · 3 Mapping leerstof (per structuur: speler/automatisch/fouten) ·
4 Bediening, schermen, HUD · 5 Campagne (alle levels) · 6 Scoring, sterren, economie, rapport · 7 Juice & audio ·
8 Interface-contract core ↔ front-end · 9 Testgevallen · 10 Scope & prioriteiten · 11 Open vragen · Samenvatting.

---

## 1. Pitch & pijlers

**Pitch.** Je bent de tuinier van de Trietuin, een betoverde boom waar elk woord een vrucht is. Zaadjes waaien aan met
een woord erop (`AAGCGA_`). Jij laat ze letter per letter langs de takken groeien en hangt de vrucht aan de juiste knop.
Elke knop drinkt sap, ook een lege. Bijen uit de korf komen vruchten proeven: ze vliegen van de kiem langs jouw takken
naar boven. Wie verkeerd plantte, ziet de bij verdwalen, de vrucht verrotten en de wesp ermee wegvliegen. Per seizoen
leert de tuin een nieuwe kunst: in de zomer **snoei en ent** je (Patricia), in de herfst groeien **rankknopen**
(ternary), in de winter span je een **slinger** van parels (de tekst) en draagt de boom al haar staartjes
(suffixboom), met inspecteur Egel die vragen komt stellen. In de finale groeit de slinger parel per parel en de hele
boom zingt mee (Ukkonen).

Wie Trietuin uitspeelt, heeft honderden keren zelf `j = min{i ≥ d | l_i ≠ s_i}` gezocht, met `skip` gelezen,
kleiner/gelijk/groter gekozen, `b − l_t` uitgerekend en de regels (ii)/(iii)/(a)/(b) en de suffix links van Ukkonen
uitgevoerd. Het spel vraagt dat niet als quiz: je doet het om je tuin te laten bloeien.

**Gevoel en referenties.** *Mini Metro* (rustig, organisch groeiend netwerk, schaarste die je voelt),
*Poly Bridge* (bouwen, dan de testrun met spanning: houdt het?), *Townscaper* (alles wat je doet voelt zacht en
mooi), *Papers, Please* (een regel toepassen; de fout merk je soms pas later).

### 1.1 Pijlers
1. **De boom ís de datastructuur.** Een top is een tak met een krans van knoppen, één per letter van het alfabet
   (array van pointers, ook de NULL-pointers). Een vrucht is een blad met zijn label. Een rankknoop is een
   pointerboompje. Een slinger is de tekst, en een (b,e)-bordje wijst naar parels op die slinger. Er bestaat geen
   spelregel naast de leerstof.
2. **Gevolgen in de tuin, geen "fout!".** Nergens verschijnt "fout". Een vrucht aan de verkeerde knop is
   onvindbaar: de bij keert met lege korf terug en de vrucht wordt grijs. Een te laat gekozen j laat dood hout en
   verspild sap achter. Een wesp die je laat plukken, steelt de vrucht, en de volgende echte bij vindt niets meer.
   Wat fysiek onmogelijk is in de datastructuur (twee vruchten aan één knop, twee vertakte takken samensnoeien), is
   ook in de wereld onmogelijk: "klonk", terugveren, zonder woorden.
3. **Geheugen is voelbaar.** Sap is het geheugen en loopt zichtbaar als vloeistof door een glazen buis. Elke nieuwe
   top kost |A| druppels (één per knop, ook de lege). Daardoor *voel* je waarom Patricia snoeit, waarom een
   ASCII-alfabet een gewone trie onbetaalbaar maakt (de knoppenkrans explodeert tot 256 knoppen) en waarom
   (b,e)-wijzers beter zijn dan strings aan de bogen.
4. **Rust om te denken, druk om te automatiseren.** De meeste levels zijn beurt-gebaseerd (de wind brengt het
   volgende zaadje pas als jij klaar bent). Tijdsdruk komt pas als een handeling gekend is (zoemavond, inspecteur in de
   mist, vrije tuin). Algoritmische beslissingen staan nooit onder een klok die korter is dan 8 s.
5. **Juice die groeit.** Takken groeien met een veerkrachtige ease, knoppen ploppen open, vruchten zwellen, bijen
   laten stuifmeel achter, de snoeischaar knipt met houtsnippers en de hele boom deint mee met de muziek. Je moet het
   willen doen, ook als je het al kunt.

### 1.2 Doelgevoel (wat de speler na afloop zegt)
- "Ik weet waarom een trie O(m) zoekt: de bij leest gewoon de letters."
- "Patricia leest niet alle letters. Daarom moet je bij het blad nog vergelijken. Die wesp heeft me te pakken gehad."
- "Ternary loont pas bij een groot alfabet. Bij DNA met 2 kinderen per top plant ik een gewone array-boom (Oef. 20)."
- "In een suffixboom staat de positie gewoon in het label: b − l_t."
- "Ukkonen: bladeren groeien vanzelf; ik stop zodra het er al in zit; na een nieuwe top volg ik de suffix link."

### 1.3 Waarom dit leuk is (en geen quiz)
- **Bouwen met schaarste.** Elke beslissing laat een zichtbaar spoor na in een boom die van jou is. Je ziet hem
  groeien, je ziet het sap zakken en je wilt een mooie, zuinige boom.
- **De testrun (Bloei).** Na elke dag vliegt de zwerm alle woorden af. Dat is het Poly Bridge-moment: je kijkt
  ademloos of elke bij thuiskomt met honing.
- **Late gevolgen en oorzaakketens.** Een slordige j uit minuut 1 laat in minuut 4 een bij verdwalen. De terugblik
  wijst de oorzaak aan. Je leert het algoritme omdat je anders je tuin verliest.
- **Aha-momenten die het spel ensceneert:** de eerste wesp (Algoritme 1 controleert pas in het blad); de ASCII-storm
  (één top wordt een krans van 256 knoppen); de winter waarin strings aan de bogen het sap opdrinken; Ukkonen waarin
  bij elke nieuwe parel álle bladeren tegelijk groeien ("eens blad, altijd blad") en de cascade van splitsingen in
  `acacacgt_` (iteratie 7: vier nieuwe toppen, keten van suffix links).
- **Meesterschap.** Toetsenbord: typen = de letters volgen; snelle spelers vliegen door de levels en halen combo's.
  Vrije tuin met highscore.

---

## 2. Wereld & kernlus

### 2.1 De wereld
- **De tuin** is een heuvel waarop één boom groeit. **De wortel (kiem) staat onderaan en de boom groeit omhoog**,
  zoals een echte boom. Motivatie: het concept "de boom groeit uit één kiem" voelt organisch, en de bijen vliegen
  vanuit de korf onderaan omhoog. De notas tekenen de wortel bovenaan. Daarom bestaat er in de terugblik altijd de
  **notas-weergave** (boom gespiegeld, getekend zoals Figuur 13–19), zodat je de examenvorm herkent.
- **Top (interne top)** = een tak die eindigt in een **knoppenkrans**: |A| knoppen naast elkaar, in alfabetvolgorde,
  elk met zijn letter (bv. `A C G T _`). Een lege knop is een dicht, grijs knopje (NULL-pointer). Een bezette knop is
  open en er groeit een tak of een vrucht uit.
- **Vrucht** = blad, met het volledige label erop (bv. `ACGT_`). In de winter draagt een vrucht ook een bordje.
- **Zaadje** = een woord dat toegevoegd moet worden. Het rijdt op een **lint** (de letters met indices
  0, 1, 2, … eronder) mee naar boven.
- **Bij** = een opzoeking (bestelling). **Wesp** (vanaf de zomer) = een opzoeking van een woord dat **niet** in de
  boom zit, vermomd als bij. Je ziet de strepen pas bij de vruchtcontrole.
- **Sap** = geheugen (§6.2). **Honing** = score.
- **De Uil** = coach. Hij spreekt hoogstens één korte zin per keer en enkel in tutorials en in de terugblik.
- **Snoeischaar** (verwijderen, Patricia-snoeien), **ent** (Patricia-toevoegen), **rankknoop** (ternary-top),
  **slinger** (tekst, één parel per teken met positienummer), **inspecteur Egel** met loep (§3.3-vragen),
  **vuurvliegje** (Ukkonen-wijzer (p̄, x̄)).

### 2.2 Kernlus per level ("een tuindag", 3–8 min)
1. **Ochtend (intro, ≤ 6 s, skipbaar):** de Uil zegt één zin. Een spookhand doet eventueel één nieuwe handeling voor.
2. **Dag (spelen):** de **windrij** bovenaan toont de komende kaarten: 🌱 zaadje (toevoegen), 🐝 bestelling
   (opzoeken), 🐝/🐝‍wesp, ✂ snoeiopdracht (verwijderen), ⚘ omvormopdracht (snoeien tot Patricia / omzetten tot
   rankknopen), 🔍 inspecteursvraag, 🪢 slingerparel (Ukkonen). In de **rustige modus** komt de volgende kaart pas als de
   vorige af is. In de **zwermmodus** (realtime) komen kaarten op een klok en hebben bijen geduld.
3. **Avond (Bloei):** automatische testrun. Voor elk woord dat in de boom hoort (en voor de afwijzers uit de spec)
   vliegt een bij volgens het **juiste** algoritme over **jouw** boom. Klopt het, dan bloeit de vrucht open en vliegt
   de bij met honing naar de korf. Klopt het niet, dan zie je het gevolg (§3) en wordt de vrucht grijs.
4. **Terugblik:** sterren, honing, sap t.o.v. optimum, bloeiresultaten en een tijdlijn met je misstappen. Klik je een
   misstap aan, dan wordt de tuin van dat moment herbouwd: eerst jouw zet (rood-transparant), dan de juiste zet als
   groene spookhand, met één coachzin die naar de notas verwijst (§6.5).

### 2.3 Microlus (per zaadje, ~5–15 s)
Gewone trie, voorbeeld `AAGCGA_` in Figuur 13: het zaadje landt op de kiem → de speler typt `A` (of klikt knop A) →
het zaadje schuift naar de top "A" → de speler typt `A` → het zaadje komt bij de vrucht `AAGTT_` → het
**vergelijkingslint** schuift open (beide woorden onder elkaar, posities 0.. erboven, posities < d grijs) → de speler
klikt kolom 3 (eerste verschil `T`≠`C`) → de vrucht wordt een tak, er groeit één tussentop (`AAG`) en de twee vruchten
springen aan hun knoppen `T` en `C` → −10 sap (2 toppen × 5 knoppen), +5 honing. Totaal: vier invoerhandelingen.

---

## 3. Mapping spel ↔ leerstof (volledig)

Per structuur: (a) tabel notas ↔ spel, (b) wat de speler doet en wat automatisch gaat, (c) fouten en hun gevolg in de
wereld. Regelnummers verwijzen naar het tekstextract van de notas; paginanummers zijn gedrukte nummers.

**Algemene conventies (functioneel bindend):**
- Posities in een woord zijn **0-gebaseerd** (`s = s0 … sk`, notas p. 27; Algoritme 1 gebruikt `s[0]…s[m]`). Het lint
  toont ze altijd onder de letters.
- Diepte d: de wortel heeft diepte 0. Een top op diepte d leest letter `s_d` en gaat naar kind `k_{s_d}`. Een blad dat
  je zo bereikt, ligt op diepte d+1 (notas p. 27: "een blad b wordt op diepte d bereikt").
- Afsluitteken `_` is een gewone letter van het alfabet en staat **achteraan** in de alfabetvolgorde (zoals de
  knoppenrijen `A C G T _` in alle figuren). Bij ternary vergelijkingen geldt dezelfde volgorde (§11 vraag 3).
- Suffixboomposities: zie §3.4.4 (welke basis het spel toont en waarom).

### 3.1 Gewone trie (§3.1, r. 1234–1412, p. 25–28) — seizoen Lente

| notas | in het spel | waarom zo |
|---|---|---|
| Definitie 1: elke interne top heeft voor elke a ∈ A een kind k_a, dat leeg kan zijn (p. 26) | top = knoppenkrans met **alle** \|A\| knoppen; lege knop = dicht grijs knopje | NULL-pointers zijn zichtbaar en kosten sap |
| wortel stelt ∅ voor; boom start met één top (p. 27) | de kiem: elk level start minstens met een wortel-krans | — |
| blad met label s; pad s′ is prefix van s (p. 26) | vrucht met het volledige woord; mag hoger hangen dan nodig (Fig. 13 heeft `TA_` onder een extra top) | figuren worden exact geladen, ook niet-minimale |
| opzoeken: op diepte d naar k_{s_d} tot NULL (niet gevonden) of blad (vergelijk) (p. 27) | bij: speler typt/klikt de letters; lege knop → bij keert terug; bij een vrucht beslist de speler "Pluk" of "Niet hier" | het vergelijken in het blad is een echte beslissing (`CATT_` komt bij `CATTAG_`) |
| toevoegen, kind NULL → blad als k_{s_d} (p. 27) | zaadje bij lege knop: klik de knop (of typ de letter) → vrucht hangt | — |
| toevoegen, blad bereikt, j = min{i ≥ d \| l_i ≠ s_i}, b wordt intern, pad langs k_{s_d}…k_{s_{j−1}}, twee bladeren k_{l_j}, k_{s_j} (p. 27) | **vergelijkingslint**: speler klikt kolom j. Daarna groeit het spel automatisch het pad (j − d + 1 nieuwe toppen) en hangt beide vruchten | j zoeken is de beslissing; het pad volgt er deterministisch uit |
| string al aanwezig → niet toevoegen (p. 27) | bij gelijke vrucht: knop "Zit er al" | — |
| verwijderen: verwijder alle toppen na de laatste top met ≥ 2 niet-lege kinderen (p. 27) | ✂-kaart: speler leidt de schaar naar het blad en knipt dan **één** tak op het pad | de beslissing is waar je knipt |
| O(m) opzoeken, onafhankelijk van het aantal woorden (p. 26) | de bij vliegt precies m+1 takjes; de HUD toont "vlucht: 4 takjes" | — |
| geheugen: veel NULL-pointers bij groot alfabet (p. 27) | sap: top = \|A\| druppels | §6.2 |

**Speler doet:** letters volgen (opzoeken/toevoegen), vrucht hangen aan een lege knop, j kiezen, "Zit er al" kiezen,
"Pluk"/"Niet hier" bij een vrucht, de knipplaats kiezen bij verwijderen.
**Automatisch:** het pad van j − d + 1 toppen groeien en de twee vruchten aan k_{l_j} en k_{s_j} hangen (deterministisch
na j); de bij keert terug bij een lege knop (dat ís het algoritme: kind NULL → niet gevonden); sap aftrekken en
teruggeven; de Bloei-testrun.

**Fouten → gevolg in de wereld**

| fout | kan het? | gevolg in de tuin | wanneer zie je het |
|---|---|---|---|
| verkeerde letter volgen (zaadje) | ja | het zaadje groeit in een verkeerde tak. De vrucht hangt op een pad dat geen prefix is van haar woord. | Bloei: de bij voor dat woord neemt de juiste knop, vindt NULL of een andere vrucht en keert met lege korf terug. De verdwaalde vrucht wordt grijs ("rot"). |
| vrucht aan verkeerde lege knop hangen | ja | idem (onvindbare vrucht) | idem |
| j te vroeg (l_j = s_j) | **nee** | beide vruchten willen aan dezelfde knop: ze botsen ("klonk"), het lint schudt, er gebeurt niets | meteen, zonder woorden |
| j < d | **nee** | de kolommen < d zijn grijs ("al gelezen") en niet klikbaar | — |
| j te laat (er bestaat i < j met l_i ≠ s_i, en l_j ≠ s_j) | ja | het pad volgt de letters van s voorbij het echte verschil. De oude vrucht hangt nu op een pad dat haar prefix niet is (onvindbaar), en er groeien extra toppen (verspild sap) | meteen: sap zakt meer dan verwacht (de sapbuis toont een amber "verlies"-streep). Bloei: de oude vrucht rot |
| "Zit er al" terwijl de woorden verschillen | ja | het zaadje waait weg; het woord ontbreekt | Bloei: de bij voor dat woord vindt niets |
| doorgroeien terwijl de woorden gelijk zijn | **nee** | geen enkele kolom verschilt; het lint toont geen klikbare kolom en enkel "Zit er al" licht op | — |
| "Pluk" bij een andere vrucht | ja | de bij brengt verkeerde honing naar de korf; de koningin fronst (−10 honing) | meteen |
| "Niet hier" bij de juiste vrucht | ja | de bij vertrekt met lege korf (bestelling mislukt, 0 honing) | meteen |
| knippen te hoog (boven de laatste top met ≥ 2 kinderen) | ja | ook andere vruchten vallen op de grond (woorden kwijt) | meteen: vruchten vallen. Bloei: die bijen falen |
| knippen te laag | ja | er blijft **dood hout** over: kale, bruine toppen zonder vruchten. Ze blijven sap drinken | meteen (bruin hout); terugblik: sapverlies |
| sap op | ja | de knoppenkrans kan niet groeien en het zaadje waait weg | meteen |

### 3.2 Patricia (§3.1.1, r. 1413–1524, p. 28–30) — seizoen Zomer

| notas | in het spel | waarom zo |
|---|---|---|
| lange paden zonder vertakking vermijden; elke interne top heeft `skip` = aantal overgeslagen tekens (p. 29) | gesnoeide boom; elke top draagt een **jaarring-plaatje** met het getal `skip` (en klein de leespositie `pos`) | skip is altijd zichtbaar, zoals in Fig. 15 |
| je zoekt alleen volgens tekens waar vertakt wordt (p. 29) | de bij **hopt** over het lint: op een top met skip k slaat ze k letters over en leest de volgende | de speler moet zelf de leespositie aanwijzen |
| Algoritme 1: `if next+top.skip > m → niet gevonden; next = next+skip+1; top = kind[s[next−1]]; NULL → niet gevonden; in blad: vergelijk` (p. 29) | exact zo: hoplint met cursor `next`. Is het lint te kort, dan grijpt de bij in het niets ("te kort"). Een lege knop is een dichte knop. In de vrucht beslist de speler Pluk/Niet hier | elke regel van het algoritme wordt een zichtbare situatie |
| AAAAABAAAAABC_ / BBBBBBBBBBBBB_: verschil pas in het blad gemerkt (p. 29) | de **wesp**: ziet eruit als een bij, leest enkel posities 5 en 11 (twee B's) en komt bij `AAAAABAAAAABC_`. Pas bij de vruchtcontrole zie je de strepen | level 2-2 is dit voorbeeld letterlijk |
| toevoegen is lastig: overgeslagen tekens reconstrueren via een blad (p. 29) | **enten**: daal af met Algoritme 1. Bij een lege knop of "te kort" kies je **een willekeurige vrucht onder de huidige top**. Vergelijk, kies j. De ent gebeurt op diepte j | §11 vraag 8: elke vrucht onder die top geeft dezelfde j |
| Figuur 15: trie gewoon en als Patricia (p. 30) | level 2-1: snoei de gewone boom tot Patricia | — |

**Toevoegen in Patricia, exact (core = deze procedure):**
1. *Afdalen:* `next = 0`, `top = wortel`. Zolang top geen blad: als `next + top.skip > m` → stop (te kort). Anders
   `next += top.skip + 1`; `c = top.kind[s[next−1]]`; als `c` NULL → stop; anders `top = c`.
2. *Reconstrueren:* `l` = het label van top (als top een blad is) of van **een willekeurig blad onder top**.
   Als `l = s` → "zit er al". Anders `j` = eerste i met `l_i ≠ s_i`.
3. *Enten* (automatisch na j): loop opnieuw van de wortel langs het pad van s. Een top t heeft leespositie
   `pos(t) = pos(ouder) + skip(t) + 1` (wortel: `pos = skip`); een blad heeft `pos = ∞`. Zoek de eerste top t op het pad
   met `pos(t) ≥ j`:
   - `pos(t) = j` → hang de nieuwe vrucht aan de lege knop `s_j` van t (die is gegarandeerd leeg);
   - `pos(t) > j` → nieuwe top u tussen ouder p en t, met `skip(u) = j − pos(p) − 1` (wortel als t: `pos(p) = −1`),
     `u.kind[l_j] = t`, `u.kind[s_j] = nieuwe vrucht`, en als t intern is: `skip(t) = pos(t) − j − 1`.
   Geverifieerd: dit geeft na elke invoeging dezelfde boom als "gewone trie bouwen en dan snoeien" (2000 willekeurige
   tests en de vier invoegingen van level 2-3).

**Snoeien (gewone trie → Patricia), exact:** knip-ent op een interne top met precies één niet-leeg kind:
de top verdwijnt, het kind schuift op naar de ouder. Is het kind intern: `skip(kind) += skip(top) + 1`. Is het kind een
blad: het blad schuift gewoon op. Een wortel met één kind mag ook gesnoeid worden (het kind wordt wortel, skip + 1).
Klaar als geen enkele interne top nog één kind heeft. De volgorde maakt niet uit (het eindresultaat is uniek).

**Speler doet:** leespositie aanwijzen per top (hop), "te kort" herkennen, vrucht kiezen om te reconstrueren, j
kiezen, Pluk/Niet hier, unaire toppen aanwijzen om te snoeien.
**Automatisch:** de letter op de gekozen positie bepaalt de knop; de ent na j (top invoegen, skips herrekenen); skip
optellen bij het snoeien; Bloei.

| fout | kan het? | gevolg in de tuin |
|---|---|---|
| verkeerde leespositie (skip verkeerd geteld) | ja | de bij leest een andere letter en vliegt naar die knop: een andere vrucht (bij het opzoeken: de wesp-situatie, of je plukt fout), een lege knop (bij weg) of, bij het enten, een verkeerde reconstructie |
| positie voorbij het lint lezen | **nee** | de bij grijpt in de lucht; enkel de knop "te kort" licht op |
| "te kort" terwijl het lint lang genoeg is | ja | de bij keert terug (bestelling mislukt). Bij het enten: je reconstrueert met een vrucht onder deze top, wat toch correct is (zie §11 vraag 8). Het telt wel als misstap |
| wesp laten plukken | ja | de wesp **steelt de vrucht**: het woord verdwijnt uit de boom. Een volgende echte bij voor dat woord vindt een lege knop | 
| vrucht van buiten de huidige top kiezen | **nee** | enkel de vruchten onder de top glanzen; andere zijn niet klikbaar |
| j te laat of verkeerd | ja | de ent gebeurt op de verkeerde diepte: skips kloppen niet meer. Woorden worden onvindbaar (Bloei) |
| een vertakte top snoeien | **nee** | twee takken "vergroeien niet": de schaar veert terug, houtsnipper, klonk |
| niet alle unaire toppen snoeien en "klaar" drukken | ja | de boom blijft deels gewoon: extra sap. Bloei werkt nog (Algoritme 1 met skip 0 is gewone trie-navigatie) maar ★★★ (sap = optimum) valt weg |

### 3.3 Ternary (§3.1.2, r. 1525–1629, p. 30–32) — seizoen Herfst

| notas | in het spel | waarom zo |
|---|---|---|
| elke top in de trie = klein zoekboompje (pointerboom) voor de kinderen (p. 31) | **rankknoop**: een kluwen van letterbolletjes met ranken | — |
| elke top in de pointerboom: sleutel + 3 pointers kleiner/gelijk/groter (p. 31) | letterbol met drie ranken: ← kleiner (links-onder), ↑ gelijk (recht door naar de volgende rankknoop of vrucht), → groter | de gelijk-rank is het "kind" |
| bevat enkel letters die echt gebruikt worden; niet geherbalanceerd (p. 31) | een nieuwe letter groeit waar de kleiner/groter-zoektocht eindigt (gewone BST-invoeging). Volgorde van aankomst bepaalt de vorm | — |
| Fig. 16: geen voordeel bij {A,C,G,T,_}, wel bij ASCII (p. 31–32) | level 3-1 eindigt met de **ASCII-storm** | ensceneert de zin uit de notas |
| Oef. 19: Fig. 17 als ternary (p. 32) | level 3-3 | — |
| Oef. 20: array of ternary bij \|A\| = 5 en gemiddeld 2 kinderen (p. 32) | level 3-4: kies per tuinbed de boomsoort; het sap beslist | — |

**Toevoegen in ternary (core):** zoals de gewone trie, maar "kind k_a van top t" wordt gezocht in t's pointerboom:
start bij de wortelbol; `a < bol.ch` → kleiner, `a > bol.ch` → groter, `a = bol.ch` → gelijk. Eindigt de zoektocht op
NULL (kleiner/groter), dan groeit daar een nieuwe bol `a` met de nieuwe vrucht aan zijn gelijk-rank. Gelijk naar een
vrucht → vergelijken en j kiezen zoals bij de gewone trie. Het nieuwe pad bestaat uit rankknopen met één bol
(letters `s_d … s_{j−1}`). De laatste rankknoop krijgt **eerst bol `l_j` (wortel), dan bol `s_j`** (als kleiner- of
groter-kind), in de volgorde k_{l_j}, k_{s_j} van de notas. Dit reproduceert de vorm van Figuur 16 (§11 vraag 3).

**Omzetten (gewone trie → ternary):** per top, in breedte-eerst volgorde, kiest de speler **de volgorde** waarin de
gebruikte letters in de rankknoop geplant worden. De plaats (kleiner/groter) volgt automatisch uit de BST-regel. Elke
volgorde is een geldige ternary trie. Sap is altijd gelijk (3 per bol); de **vluchtlengte** van de bijen (aantal
vergelijkingen) hangt af van je keuze. Daarom heeft deze beslissing gevolgen.

**Speler doet:** per bol kleiner/gelijk/groter kiezen (toevoegen, opzoeken), j kiezen, Pluk/Niet hier, bij omzetten de
plantvolgorde. **Automatisch:** de nieuwe bol aanmaken waar de zoektocht op NULL eindigt, het pad na j, de plaats van
bollen bij het omzetten, Bloei.

| fout | kan het? | gevolg |
|---|---|---|
| verkeerde richting (bv. groter terwijl `a < bol`) en daar is NULL | ja | de nieuwe bol groeit op een plaats die de BST-orde breekt. Een bij die die letter zoekt, gaat de andere kant op en vindt niets. De bol hangt "scheef" (subtiel: hij helt in de verkeerde richting) |
| "gelijk" terwijl `a ≠ bol` | ja | het zaadje groeit verder onder het prefix van een andere letter (zoals de verkeerde letter bij de gewone trie). Onvindbaar |
| slechte plantvolgorde bij omzetten (bv. alfabetisch: ketting) | ja | bijen maken langere vluchten (meer vergelijkingen), dus de bloei duurt zichtbaar langer en ★★★ (vergelijkingen ≤ optimum) valt weg. Geen fout in de log |
| sap op | ja | zie §3.1 |

### 3.4 Suffixbomen, §3.3-toepassingen (§3.2, r. 1630–1725, p. 32–34; §3.3, r. 2514–2627, p. 48–50) — Winter

| notas | in het spel | waarom zo |
|---|---|---|
| tekst t met uniek afsluitteken `_` (p. 32–33) | de **slinger**: één parel per teken, positienummer eronder; `_` is een sneeuwkristal | — |
| suffixboom = trie met alle suffixen, geen toppen met één kind (Patricia-achtig), strings aan de bogen met het eerste verschilteken (p. 33) | bogen dragen hun letters als kleine parels (winter 4-1) | Fig. 18 |
| ≤ 2n − 1 toppen, 2n − 2 bogen (p. 33) | HUD-teller "toppen 14 / max 17" | — |
| labels als (begin, einde)-pointers in de tekst, Θ(n) geheugen (p. 33) | bordjes `(b,e)`. Hover over een bord licht op de slinger de parels b..e op | Fig. 19 |
| Ukkonen kiest posities zodat op b − l_t een voorkomen begint; beginlabel verandert nooit, boog wordt hooguit onderverdeeld (p. 48) | bij een splitsing houdt het bovenste deel `(b, b+k−1)` en wordt het onderste `(b+k, e)`. Een nieuw blad vanuit een top met diepte l krijgt `b = j + l` | dezelfde regel als bij de naïeve opbouw (zie 3.4.3) |
| zoeken in O(m); positie = b − l_t (p. 48) | inspecteur Egel: "Waar?" De speler wijst een parel op de slinger aan. In de mist (4-4) kan dat enkel via de bordjes | de mist dwingt het datastructuurdenken af |
| Oef. 28: alle k posities in O(m + k); Oef. 29: aantal voorkomens in O(m) (p. 49) | "Wijs alle verdachten aan" (bladeren onder het punt); "Hoe vaak?" (aantal bladeren onder het punt); telbadges per top (Oef. 29-oplossing) | — |
| veralgemeende suffixboom, afsluitingstekens `_1, _2, …`; "onechte" versie via aaneengeschakelde teksten (p. 49) | drie verdachten met elk een gekleurde slinger, aan elkaar geknoopt; vruchten in de kleur van hun eigenaar | §11 vraag 9 |

#### 3.4.1 Suffix aanhechten (winter 4-1/4-2, de "voor de hand liggende" Θ(n²)-opbouw, p. 34)
Suffixen komen één voor één aan, de langste eerst (dezelfde volgorde als p. 33: `acacacgt_, cacacgt_, …, _`). Voor
suffix j wijst de speler met **één klik** het **afwijkpunt** aan: de diepste plaats in de boom tot waar het suffix al
aanwezig is. Dat is een top (dan regel "nieuwe tak") of een punt midden in een boog (dan "splitsen"). Het spel laat
het suffix van de wortel naar dat punt glijden en hecht het aan. Bij splitsen worden de labels automatisch verdeeld.
In 4-2 kiest de speler daarna de beginparel b van de nieuwe bladboog op de slinger (e = laatste positie, automatisch).

#### 3.4.2 Inspecteur (§3.3)
Een vraagkaart noemt een zoekstring z. De speler **zet de loep**: klik op de plaats in de boom waar z eindigt (een top
of een punt in een boog), of typ z (de loep loopt mee en stopt bij een mismatch). Kom je niet verder, dan druk je
"Komt niet voor". Daarna volgt de deelvraag:
- **Komt het voor?** Beantwoord door de loep te zetten of "Komt niet voor" te kiezen.
- **Waar?** Klik een parel op de slinger. Elke echte beginpositie van z is goed (notas p. 48: "een positie"). In de mist
  zie je de parels enkel via hover op een bord. Dan is `b − l_t` de snelste weg; de top toont zijn diepte l_t.
- **Hoe vaak?** Typ het getal (= aantal bladeren onder het punt).
- **Alle posities / alle verdachten.** Klik alle vruchten onder het punt aan (elke vrucht draagt haar beginpositie j).
- **Van wie?** (veralgemeend) Klik de portret(ten) van de eigenaar(s): de kleuren van de vruchten onder het punt.

#### 3.4.3 Labelconventie (bindend voor de core)
Een nieuwe bladboog vanuit punt P (stringdiepte l) voor suffix j krijgt `(j + l, n)`. Splitsen van boog `(b, e)` na k
tekens: bovenste deel `(b, b+k−1)`, onderste deel `(b+k, e)`. Dit is precies wat Ukkonen doet ("beginlabel wordt nooit
meer gewijzigd – de boog wordt ten hoogste later onderverdeeld", p. 48). De naïeve opbouw (langste suffix eerst) geeft
**dezelfde** labels als Ukkonen. Geverifieerd voor `acacacgt_` en voor alle {a,c}-teksten t.e.m. lengte 7.
Voor `acacacgt_` geeft dit (0-gebaseerd) de interne bogen `ac → ac` = **(2,3)** en `c → ac` = **(2,3)**. Figuur 19 schrijft
daar `(0,1)`. Beide wijzen naar de string `ac`, maar enkel (2,3) voldoet aan de b − l_t-eigenschap van p. 48. Het spel
gebruikt (2,3) en legt het verschil in de terugblik uit. Zie §11 vraag 1.

#### 3.4.4 Positieconventie (0- of 1-gebaseerd): welke toont het spel en waarom
De notas gebruiken beide: Figuur 19 nummert `acacacgt_` als **0..8**; Definitie 3, het Ukkonen-voorbeeld `abacabc_`
(p. 44–48, `12345678` onder de tekst, labels `1,it`) en §3.3 ("wij zijn altijd met positie 1 begonnen", p. 48)
gebruiken **1..n+1**. **Beslissing:** de core rekent intern altijd 0-gebaseerd. Elk suffix-level heeft een
weergavebasis `pos_base` (0 of 1) die het spel overal toepast (slinger, bordjes, vruchten, antwoorden). Elk
suffix-level toont linksboven op de slinger een plaatje **"telt vanaf 0"** of **"telt vanaf 1"**.
- `pos_base = 0` voor de levels rond Figuur 18/19 (4-1, 4-2, 4-3, 4-4, 4-5) en voor 5-3 (Figuur 18 herboren), zodat
  het eindbeeld letterlijk met Figuur 19 te vergelijken is.
- `pos_base = 1` voor 5-1 (`abacabc_`, het notasvoorbeeld) en 5-2 (Oef. 27), zodat elke tussenstap letter voor letter
  met de tekeningen op p. 44–48 overeenkomt (`σ_{j,it}`, labels `j,it`).
Motivatie: de student moet beide vormen op het examen herkennen. Het plaatje maakt de keuze expliciet en `b − l_t` is
in beide bases dezelfde formule. Woorden in tries (Lente–Herfst) tonen altijd 0-gebaseerde indices (Algoritme 1).

**Fouten → gevolg (winter)**

| fout | kan het? | gevolg |
|---|---|---|
| verkeerd afwijkpunt (te ondiep, te diep of op een ander pad) | ja | het suffix hangt op een plek waar het pad vanaf de wortel een andere string spelt dan de vrucht. De nieuwe tak gloeit amber, want pad en vrucht kloppen niet. Bloei: de bij voor dat suffix vindt het niet; de inspecteur krijgt later foute antwoorden |
| afwijkpunt waar het volgende teken gelijk is aan het volgende teken van het suffix (twee bogen met dezelfde eerste letter) | **nee** | Definitie 3 verbiedt het. De nieuwe boog botst tegen de bestaande ("klonk") |
| verkeerde beginparel b (4-2) | ja | de boog "zegt" iets anders: de letters op het bord veranderen in wat op de slinger staat (bv. `cgt_` i.p.v. `gt_`). Bloei: verdwaalde bij |
| inspecteur: loep op de verkeerde plaats | ja | de hond van de inspecteur snuffelt aan de verkeerde vruchten; het verkeerde aantal verdachten wordt opgepakt. Na de vraag zie je de juiste plaats knipperen |
| "Waar?" verkeerde parel | ja | de inspecteur graaft op die plek in de sneeuw en vindt niets ("leeg") |
| "Hoe vaak?" verkeerd getal | ja | te veel of te weinig arrestaties; de inspecteur kijkt boos |
| geduld van de inspecteur op (4-4) | ja | hij vertrekt (vraag mislukt) |

### 3.5 Ukkonen (§3.2.1, r. 1726–2513, p. 34–48) — Finale

| notas | in het spel |
|---|---|
| S(1, i): deelstringboom van de prefix s1..si; iteratie i+1 voegt `s_{i+1}` toe (p. 35–37) | de slinger krijgt per iteratie één nieuwe parel. De boom bevat alle deelstrings van de parels tot nu toe |
| suffixen σ_{j,i}; eerst σ_{1,i+1}, dan σ_{2,i+1}, … (p. 37) | de **σ-rij** onder de slinger: chips `σ1 … σit`. De bladen-groep is onderstreept met "blad" (zoals op p. 44–48). Een pijl staat boven de huidige σ |
| Lemma 4/5: bladeren vooraan, dan (ii)/(iii), dan "zit er al" (p. 37) | de onderstreping "blad" groeit van links naar rechts (b(i)) |
| regel (i): blad → eindpositie wordt `it`; alle bladeren tegelijk (p. 38–39) | **automatisch**: bij elke nieuwe parel zwelt `it` en groeien alle bladpunten tegelijk één parel ("eens blad, altijd blad"). De speler doet niets: dat ís de les |
| (a)/(b): zit er al in → stop de iteratie (p. 38–39) | knop **"Zit er al"** (Z). De iteratie stopt en x̄ := x + 1 |
| (ii): eindigt in een top zonder tak met `s_{i+1}` → nieuw blad `(i+1, it)` (p. 38) | knop **"Groei!"** (G) op een top → nieuwe bladtak |
| (iii): midden in een boog, volgend teken ≠ `s_{i+1}` → splits + nieuw blad (p. 38) | **"Groei!"** midden in een boog → de boog splijt, een nieuwe top en een nieuw blad |
| suffix link van top `s_i…s_j` naar `s_{i+1}…s_j`; wortel → zichzelf (p. 40) | **suffix links** = gloeiende ranken met een bolletje aan het eind (zoals de pijlen met bolletje in Fig. 22) |
| wijzer (p, x): p = laatste top op het pad, x = aantal tekens verder (p. 40–41) | het **vuurvliegje** zit op top p̄ met een badge x̄; een lichtspoor toont de x̄ tekens langs de boog. Precies de "dikke pijl met getal" van p. 44 |
| dezelfde iteratie: p = pw → x̄ = x − 1; anders p̄ = l(p), x̄ = x (p. 41) | knop **"Volg link"** (V) of **"x − 1 (wortel)"** (W): de speler kiest |
| volgende iteratie: na (a)/(b) p̄ = p, x̄ = x + 1; na het laatste blad (pw, 0) (p. 41) | automatisch |
| zoeken: als x̄ ≥ lengte van de boog → naar de top springen en x̄ −= lengte; enkel eerste teken + lengte bekijken (p. 41–42) | **"Spring"**: klik de top aan het eind van de juiste boog (H, of klik). Het lichtspoor toont de booglengte als maatlat |
| nieuwe interne top krijgt in de volgende stap zijn suffix link (p. 43) | na de volgende regelkeuze vraagt een hangende rank om vastgehecht te worden: **sleep de rank** naar de doeltop (L + pijltjes + Enter) |

**Speler doet (per extensie):** (1) springen zolang nodig (en welke boog), (2) regel kiezen: "Zit er al" of "Groei!",
(3) de hangende suffix link vasthechten, (4) na groeien kiezen tussen "Volg link" en "x − 1".
**Automatisch:** regel (i) (bladeren groeien met `it`); de vorm van "Groei!" (ii of iii volgt uit de positie); labels
`(i+1, it)` en splitsingen; na "Zit er al" x̄ := x+1 en volgende iteratie; na het laatste blad (pw, 0).

**Fouten bij Ukkonen worden geweigerd, niet uitgespeeld** (bewuste afwijking van pijler 2, zie §11 vraag 11). Een
foute Ukkonen-stap maakt een ongeldige deelstringboom. Elke volgende stap zou dan op onzin verder rekenen en de
gevolgen zijn niet meer te begrijpen. Daarom toont de wereld bij een foute keuze **lokaal waarom het niet kan**: het
vuurvliegje probeert het en stuit op de werkelijkheid.

| foute keuze | wereldreactie (≤ 1 s, geen tekst) |
|---|---|
| "Zit er al" maar het teken ontbreekt | het vuurvliegje stapt naar de volgende parel, maar daar staat een andere letter (beide parels lichten op naast elkaar) of niets → het valt terug ("plof") |
| "Groei!" maar het zit er al | een nieuwe tak schiet uit, raakt de bestaande tak met dezelfde letter en trekt zich terug ("dubbel") |
| springen terwijl x̄ < booglengte | het vuurvliegje schiet langs de boog, maar het spoor is korter dan de boog: het stopt midden in de boog en veert terug |
| niet springen terwijl x̄ ≥ booglengte (regel kiezen) | de regelknoppen trillen; het spoor steekt zichtbaar voorbij de top |
| verkeerde boog om te springen | het vuurvliegje landt op een boog waarvan de eerste parel niet klopt en veert terug |
| rank aan de verkeerde top | de rank glijdt eraf (de top stelt niet `u` zonder eerste letter voor) |
| "Volg link" bij de wortel of "x − 1" bij een andere top | het vuurvliegje schiet de verkeerde kant op en keert terug |
Elke weigering wordt gelogd als misstap (verdict ≠ OK) en telt voor de sterren (§6).

---

## 4. Bediening, schermen & HUD

### 4.1 Besturing (muis volwaardig, toetsenbord waar het sneller is)
| actie | muis | toetsenbord |
|---|---|---|
| letter volgen (zaadje, bij; gewone trie) | klik de knop in de krans van de huidige top | typ de letter (`A C G T`, `a`–`z`); `_` = `-` of `Spatie` |
| vrucht hangen aan lege knop | klik de lege knop | typ de letter (bij een lege knop hangt de vrucht er meteen) |
| j kiezen (vergelijkingslint) | klik de kolom | `←`/`→` verschuift de kolomcursor (start bij d), `Enter` bevestigt |
| "Zit er al" | knop op het lint | `Z` |
| Pluk / Niet hier (bij aan een vrucht) | knoppen naast de vrucht | `Enter`/`J` = Pluk, `N`/`Backspace` = Niet hier |
| Patricia: leespositie | klik de letter op het hoplint | `→`/`←` verschuift de leescursor (start bij `next`), `Enter` leest; `T` = "te kort" |
| Patricia: vrucht kiezen voor reconstructie | klik een glanzende vrucht | `Tab` doorloopt de vruchten, `Enter` |
| snoeien (unaire top) | klik de top (schaar verschijnt bij hover) | `Tab` doorloopt toppen, `S` knipt |
| knippen bij verwijderen | klik de tak op het pad | `↑`/`↓` kiest een tak op het pad, `S` knipt |
| ternary: kleiner / gelijk / groter | klik de rank (links / midden / rechts) | `←` / `↑` of `Enter` / `→` |
| ternary omzetten: volgende letter planten | klik een letterchip | typ de letter |
| suffix: afwijkpunt | klik een top of een opening tussen twee parels op een boog | `←`/`→` kiest een tak aan een top, `↑`/`↓` schuift de loep één parel verder/terug, `Enter` = hier aanhechten |
| suffix: beginparel b | klik een parel op de slinger | `←`/`→` + `Enter` |
| inspecteur: loep / "komt niet voor" | klik het punt / knop | typ z + `Enter` / `X` |
| inspecteur: hoe vaak | cijferpaneel | cijfers + `Enter` |
| inspecteur: alle posities / van wie | klik vruchten / portretten, dan "Klaar" | `Tab` + `Spatie` om te selecteren, `Enter` |
| Ukkonen: spring / Zit er al / Groei! / Volg link / x − 1 | klik de top / knoppen / de rank / het vuurvliegje | `H` (+`Tab` als er meerdere bogen zijn) / `Z` / `G` / `V` / `W` |
| Ukkonen: suffix link vasthechten | sleep de hangende rank naar een top | `L`, `←`/`→` doorloopt de toppen, `Enter` |
| hint (Uil toont de juiste zet als spookhand) | uil-icoon | `F1` (kost ★★★, §6) |
| terugspoelen (laatste kaart ongedaan, rustige levels) | ⟲-knop | `Ctrl+Z` (kost ★★★) |
| camera | scroll = zoom (0,6–1,6), middelste knop/rechtsklik slepen = pannen | `+`/`−`, `0` = passend |
| pauze | knop links boven | `Esc` |

Keuze: in de tries is het toetsenbord typen. Typen is de letters volgen, zodat snelle spelers het algoritme
letterlijk in de vingers krijgen. De muis blijft volwaardig: alles kan met klikken.

**Leeshulp (instelling + afbouw per level, `TtLevelSpec.letter_hint`):** `FULL` = de te lezen letter op het lint
pulseert en de bijbehorende knop gloeit; `CURSOR` = alleen de cursor staat op de juiste positie, er gloeit niets;
`NONE` = cursor start op `next`, de speler verschuift zelf (bij Patricia het hele punt: skip tellen). De
toegankelijkheidsinstelling "Leeshulp altijd aan" zet `FULL` overal, maar ★★★ telt dan als "met hulp" (§6).

### 4.2 Schermen & flow
```
Titel ──► Seizoenkaart ──► Levelintro (≤6 s) ──► Tuin (level) ──► Bloei ──► Terugblik ──► Kaart / volgend level
  │  Esc→hub     │                                  │ Esc
  │              └──► Vrije tuin (slot tot 1-4)      └──► Pauze (Verder · Opnieuw · Notas · Instellingen · Kaart)
  └──► Instellingen
```
- **Titel** (`res://games/trietuin/scenes/title.tscn`): logo "TRIETUIN". De letters groeien als vruchten aan een
  boompje dat in 3 s opgroeit. Er zoemen bijen rond. Knoppen: Spelen, Vrije tuin (met slot), Instellingen,
  Terug naar de speelhal. `Esc` en "Terug" gaan naar `res://scenes/hub.tscn`. Op de achtergrond groeit een
  attract-boom (bot plant willekeurige woorden, gedimd).
- **Seizoenkaart:** een jaarwiel (cirkel in 4 kwadranten: Lente, Zomer, Herfst, Winter). Elk level is een plantpot op
  een spiraalpad. In het midden staat de finale "De eeuwige slinger" (3 potten). De bijenkorf aan de rand is de vrije
  tuin. Een pot toont 0–3 sterren en een pictogram van zijn nieuwe mechaniek. Het volgende level gaat open met ≥ 1 ster;
  een seizoen gaat open als het vorige seizoen volledig ≥ 1 ster heeft (Finale: alle Winter-P0-levels ≥ 1 ster).
  Hover toont de leerstofreferentie ("Figuur 15 · p. 30").
- **Levelintro:** titelkaart (naam, "Figuur 15 · notas p. 30", 1 zin van de Uil), dan de spookhand indien nieuw.
- **Tuin:** zie HUD (4.3).
- **Bloei:** de camera zoomt uit, de zwerm vliegt (0,6 s per bij, parallel tot 4 tegelijk). Elke uitkomst krijgt een
  icoon in een rij onderaan. Overslaan met `Spatie` (toont meteen alle uitkomsten).
- **Terugblik:** zie §6.4.
- **Pauze:** Verder, Opnieuw, **Notas** (spiekbriefje), Instellingen, Seizoenkaart.
- **Instellingen:** muziek, geluid, schermschok 0/50/100 %, tekstgrootte 100/125 %, leeshulp altijd aan,
  volledig scherm, kleurenblind-palet (vruchtkleuren bij verdachten krijgen ook een vorm).
- **Notas (spiekbriefje):** een notitieboekje met een tab per structuur, beschikbaar zodra het seizoen open is.
  Per tab een minidiagram en ≤ 5 regels met paginaverwijzing:
  - *Trie:* "op diepte d → knop s_d" · "lege knop → niet gevonden / vrucht hangen" · "vrucht → vergelijk hele woord" ·
    "j = eerste verschil vanaf d; pad tot j; vruchten aan l_j en s_j" · "verwijderen: knip onder de laatste top met ≥ 2
    kinderen" (p. 27).
  - *Patricia:* "skip k → sla k letters over, lees positie next+k" · "next+skip > m → te kort" · "pas in de vrucht
    vergelijken!" · "enten: reconstrueer met een vrucht, j, ent op diepte j" (p. 29).
  - *Ternary:* "kleiner ←, gelijk ↑ = volgende letter, groter →" · "enkel gebruikte letters, 3 ranken per bol" ·
    "loont bij groot alfabet" (p. 31).
  - *Suffixboom:* "alle suffixen van t_" · "geen top met 1 kind" · "(b,e) = parels b..e" · "positie = b − l_t" ·
    "aantal = bladeren onder het punt" (p. 33, 48–49).
  - *Ukkonen:* "bladeren groeien vanzelf (it)" · "zit er al → stop, x+1" · "top → nieuw blad (ii); boog → splits
    (iii)" · "wortel: x−1; anders volg suffix link" · "x ≥ booglengte → spring" (p. 38–42).

### 4.3 HUD en layout (1920×1080)
```
y=0   ┌───────────────────────────────────────────────────────────────────────────────────────────┐
      │[II] LENTE 1-2 · De tuin van de professor   🌱🐝🌱✂🐝 (windrij)   SAP ▓▓▓▓▓░ 35/60  🍯 120 ★☆☆ │ 0–72
y=80  ├───────────────────────────────────────────────────────────────────────────────────────────┤
      │   (winter/finale: SLINGER  a c a c a c g t _  / 0 1 2 3 4 5 6 7 8, "telt vanaf 0")        │ 80–170
      │   (finale: σ-rij  σ1 σ2 σ3 │σ4 σ5   "blad" onderstreept, pijl op huidige σ)              │ 170–220
      │                                                                                           │
      │                       DE BOOM (tuinvlak, auto-fit, wortel onderaan)                        │
      │                                                                    ┌Uil-ballon┐           │
y=860 ├───────────────────────────────────────────────────────────────────────────────────────────┤
      │ WERKBANK: lint van het huidige zaadje / vergelijkingslint / hoplint / vraagkaart inspecteur  │ 860–1040
      │ + contextknoppen (Zit er al · Pluk · Niet hier · te kort · Groei! · Volg link · x − 1)      │
y=1080└───────────────────────────────────────────────────────────────────────────────────────────┘
```
- **Windrij:** de komende 5 kaarten als icoontjes met het woord (bij een wesp: als bij getekend, het woord zichtbaar).
  De actieve kaart staat groot links in de werkbank.
- **Sapbuis:** horizontale glazen buis met druppels "gebruikt / budget". Een grijze streep toont het optimum
  (pas zichtbaar in de terugblik en vanaf ★★-run). Bij elke uitgave een druppelanimatie (§7).
- **Lettergroottes** (mono, tabular): lint 44 px, knopletters 26 px (\|A\| ≤ 5), 18 px (\|A\| = 27); vruchtlabel 24 px;
  skip-plaatje 28 px; (b,e)-bord 22 px; slingerparels 40 px met positienummer 18 px; HUD 28 px. Nergens tekst < 16 px.
  Contrast ≥ 4,5:1.
- **Boomlayout:** tidy tree (`TtLayout`, §8.9). Wortel onderaan in het midden. Kinderen staan in alfabetvolgorde van
  links naar rechts, zoals in de figuren. Toppenafstand verticaal 110 px (schaalt omlaag tot 70 px tot de boom past),
  horizontaal minstens 1 knoppenkrans + 24 px. Een ASCII-krans (256 knoppen) wordt niet uitgetekend: dan verschijnt een
  waaier "256 knoppen" (afbeelding + teller).
- **Hover:** een knop, bol of bord toont tooltip-vrij wat erachter zit: de tak naar het kind licht op, en bij een
  (b,e)-bord lichten de parels b..e op de slinger op.

---

## 5. Campagne

### 5.1 Algemene beslissingen
- **Modi:** `CALM` (beurt-gebaseerd; terugspoelen mag) en `SWARM` (realtime; geen terugspoelen; bijen hebben geduld;
  zaadjes wachten hoogstens met 3 in de wind, een vierde blaast het oudste weg). SWARM-levels: 1-4, 4-4 (enkel het
  geduld van de inspecteur) en de vrije tuin.
- **Leeshulp-afbouw:** Lente 1-1/1-2 `FULL`, 1-3 `CURSOR`, 1-4 `NONE`; Zomer 2-1 `FULL`, 2-2 `CURSOR`, 2-3/2-4
  `NONE`; Herfst 3-1/3-2 `FULL`→`CURSOR` (eerste 3 kaarten `FULL`), 3-3/3-4 `NONE`; Winter en Finale: n.v.t. (eigen
  hulp: hover op borden).
- **Tutorialstijl:** zoals Hash & Dash: spookhand bij de eerste keer, enkel het ding dat je nu nodig hebt gloeit, en de
  Uil zegt hoogstens één zin (≤ 10 woorden). Een hint verschijnt bij de eerste keer, enkel na 5 s niets doen.
- **Sterren** zijn cumulatief (★★ vereist ★). Notatie per level: ★ / ★★ / ★★★. "0 fouten" = geen logentry met verdict
  ≠ OK (bumps tellen enkel in Ukkonen-levels, §6.3).
- **Notatie in dit hoofdstuk** (zelfde grammatica als `TtNotation`, §8.8): gewone trie `{A{…} C[ACGT_]}` (top =
  `{…}`, per niet-leeg kind: letter + subboom, vrucht = `[label]`, kinderen in alfabetvolgorde); Patricia
  `{skip|…}`; ternary `(ch kleiner gelijk groter)` met `.` = NULL; suffixboom `{(b,e){…} (b,e)#j}` met `#j` = blad van
  suffix j, posities in de weergavebasis van het level.

### 5.2 LENTE — gewone trie (alfabet {A,C,G,T,_}, top = 5 sap)

#### 1-1 "Eerste kiem" (P0) — opzoeken, vrucht hangen, j kiezen
- **Nieuw:** knoppen, letters volgen, lege knop → vrucht, vrucht → vergelijkingslint, bij → Pluk/Niet hier.
- **Start:** lege wortel `{}` (5 sap, voorbetaald). Budget 30. CALM, `FULL`.
- **Kaarten (volgorde):** 🌱`TGG_` · 🌱`ACGT_` · 🌱`TA_` · 🐝`TGG_` · 🌱`AAGTT_` · 🌱`TGCGAAA_` · 🐝`TA_` ·
  🐝`GA_` (afwezig: knop G van de wortel is leeg) · 🐝`TGA_` (afwezig: in top `TG` is knop A leeg).
- **Verloop:** `TGG_` en `ACGT_` → lege knoppen. `TA_` → komt bij vrucht `TGG_` (d = 1), j = 1 → 1 nieuwe top.
  `AAGTT_` → bij `ACGT_`, j = 1 → 1 top. `TGCGAAA_` → bij `TGG_` op d = 2, j = 2 → 1 top.
- **Eind (optimum):** `{A{A[AAGTT_] C[ACGT_]} T{A[TA_] G{C[TGCGAAA_] G[TGG_]}}}`, 4 toppen = **20 sap**.
- **Intro (Uil):** "Volg de letters. Een lege knop? Hang je vrucht." Bij het eerste lint (TA_): spookhand klikt kolom 1.
  Uil: "Waar verschillen ze het eerst?"
- **Sterren:** ★ alle kaarten afgewerkt · ★★ 0 fouten · ★★★ zonder hint/terugspoelen.
- **Terugblik-extra:** "Dezelfde vijf woorden als Figuur 13. Jouw boom: 4 toppen. Die van de notas: 6. Beide zijn
  tries volgens Definitie 1."

#### 1-2 "De tuin van de professor" (P0) — Figuur 13 → 14, Oefening 17 (toevoegen + verwijderen)
- **Nieuw:** voorgeplante figuur, langer pad bij j (meerdere toppen), snoeischaar (verwijderen).
- **Start = Figuur 13 (p. 26):** `{A{A[AAGTT_] C[ACGT_]} T{A{_[TA_]} G{C{G[TGCGAAA_]} G[TGG_]}}}` (6 toppen, 30 sap).
  Budget 60. CALM, `FULL`.
- **Kaarten:** 🐝`TA_` (vliegt T → A → _: 3 takjes, de vrucht hangt een top hoger dan nodig) · 🌱`AAGCGA_` ·
  🐝`AAGTT_` · 🌱`TGCGAAG_` · ✂`TA_` · 🐝`TGCGAAG_` · 🐝`TA_` (nu afwezig: knop A van top T is leeg).
- **Verloop:**
  - `AAGCGA_`: A, A → vrucht `AAGTT_` op d = 2; lint: `AAGTT_` / `AAGCGA_`, j = 3 → b (`AA`) wordt een top, pad k_G
    (`AAG`), vruchten aan T en C: **2 toppen (+10 sap)**. Resultaat = **Figuur 14 (p. 28)** →
    stempel "Figuur 14 ✓" vliegt over het scherm.
  - `TGCGAAG_` (Oef. 17a): T, G, C, G → vrucht `TGCGAAA_` op d = 4; j = 6 → toppen `TGCG`, `TGCGA`, `TGCGAA`:
    **3 toppen (+15 sap)**.
  - ✂`TA_` (Oef. 17b): pad wortel → T → TA → vrucht. De laatste top met ≥ 2 niet-lege kinderen is T (A en G) → knip de
    tak T–TA: top `TA` en de vrucht verdwijnen (**−5 sap**, compost-animatie).
- **Eind (optimum):** `{A{A{G{C[AAGCGA_] T[AAGTT_]}} C[ACGT_]} T{G{C{G{A{A{A[TGCGAAA_] G[TGCGAAG_]}}}} G[TGG_]}}}`,
  10 toppen = **50 sap** (piek 55).
- **Intro (Uil):** "De tuin uit de notas. Plant er netjes bij."
- **Sterren:** ★ · ★★ 0 fouten · ★★★ eindboom exact = optimum en zonder hint/terugspoelen.

#### 1-3 "Lange wortels" (P0) — lange gemeenschappelijke prefixen, sapdruk
- **Nieuw:** krap budget; j ver na d (veel toppen tegelijk). Teaser voor de zomer.
- **Start:** `{}` (5). Budget **70**. CALM, `CURSOR`.
- **Kaarten:** 🌱`GATTACA_` · 🌱`GATTAGA_` (j = 5 vanaf d = 1: **5 toppen**) · 🌱`CAT_` · 🌱`GATC_` (lege knop C in top
  `GAT` op d = 3) · 🐝`GATTACA_` · 🌱`CATTAG_` (j = 3: 3 toppen) · 🐝`GATTA_` (afwezig: in top `GATTA` is knop `_` leeg) ·
  🌱`ACGTACGT_` · 🌱`ACGTTT_` (j = 4: 4 toppen) · 🐝`CATT_` (afwezig: komt bij vrucht `CATTAG_` → Niet hier) ·
  🐝`ACGTAC_` (afwezig: vrucht `ACGTACGT_` → Niet hier) · 🐝`CAT_`.
- **Eind:** `{A{C{G{T{A[ACGTACGT_] T[ACGTTT_]}}}} C{A{T{T[CATTAG_] _[CAT_]}}} G{A{T{C[GATC_] T{A{C[GATTACA_] G[GATTAGA_]}}}}}}`,
  13 toppen = **65 sap** (budget 70: één te laat gekozen j is al te veel).
- **Terugblik-extra (teaser):** de boom licht de **8 toppen met maar één kind** op. Uil: "8 van je 13 toppen vertakken
  niet. Dat moet zuiniger kunnen…" (Patricia-versie: 5 toppen).
- **Sterren:** ★ · ★★ 0 fouten · ★★★ ≤ 65 sap en ≤ 150 s.

#### 1-4 "Zoemavond" (P1) — realtime opzoeken en planten
- **Nieuw:** SWARM-modus: zaadjes en bijen op een klok, bijen met geduld 14 s, combo.
- **Start:** `{}`. Budget 55. `NONE`.
- **Zaadjes (t in s):** 0 `TAG_` · 6 `TACT_` · 12 `GCA_` · 18 `GCGT_` · 26 `TAGA_` · 34 `AT_` · 42 `ATTC_` · 50 `CC_` ·
  58 `GCGA_` · 66 `TT_`.
- **Bijen (t, woord):** 10 `TAG_` · 22 `GCA_` · 30 `TACT_` · 38 `TAGA_` · 46 `GG_` (afwezig: knop G van top G leeg) ·
  54 `ATT_` (afwezig: vrucht `ATTC_` → Niet hier) · 62 `CC_` · 70 `TAGT_` (afwezig: knop T van top `TAG` leeg) ·
  74 `GCGA_`.
- **Eind:** `{A{T{T[ATTC_] _[AT_]}} C[CC_] G{C{A[GCA_] G{A[GCGA_] T[GCGT_]}}} T{A{C[TACT_] G{A[TAGA_] _[TAG_]}} T[TT_]}}`,
  9 toppen = **45 sap**. (Interne toppen hebben gemiddeld precies 2 kinderen; deze boom keert terug in 3-4.)
- **Sterren:** ★ ≤ 2 bijen gemist · ★★ 0 fouten en 0 bijen gemist · ★★★ combo ×5 gehaald en ≥ 250 honing.

### 5.3 ZOMER — Patricia (top = |A| + 1 sap: knoppen + skip-ring)

#### 2-1 "Snoeien" (P0) — Figuur 15, Algoritme 1
- **Nieuw:** snoeischaar op unaire toppen, skip-ringen, hoplint (Algoritme 1).
- **Start = Figuur 15 boven (gewone vorm):** `{C{G{C{C{C[CGCCCT_] T[CGCCTT_]} G[CGCGAA_]}}} G{A[GA_] G{C{C[GGCC_] G[GGCGG_]}}}}`
  (8 toppen × 6 = 48 sap). CALM, `FULL`.
- **Kaarten:** ⚘ snoeien tot Patricia · 🐝`GGCGG_` · 🐝`CGCGAA_` · 🐝`GGC_` · 🐝`CA_` · 🐝`CGCCTT_` · 🐝`GACC_`.
- **Snoeien:** de unaire toppen zijn `C`, `CG` en `GG`. Na 3 knippen:
  **`{0|C{2|C{0|C[CGCCCT_] T[CGCCTT_]} G[CGCGAA_]} G{0|A[GA_] G{1|C[GGCC_] G[GGCGG_]}}}`** = Figuur 15 onder (p. 30),
  5 toppen = **30 sap**. Bij elke knip schuift de tak omlaag en krijgt de onderste ring er één bij.
- **Bijen (verwachte Algoritme 1-sporen, leesposities):** `GGCGG_` leest 0 G, 1 G, 3 G → vrucht = ✓ ·
  `CGCGAA_` 0 C, 3 G → ✓ · `GGC_` 0, 1, 3 `_` → lege knop → niet gevonden · `CA_` 0 C → top skip 2: next + skip = 1 + 2 >
  m = 2 → **te kort** · `CGCCTT_` 0, 3 C, 4 T → ✓ · `GACC_` 0 G, 1 A → vrucht `GA_` → **Niet hier**.
- **Intro:** spookhand knipt top `C`. Uil: "Takken zonder vertakking? Knip ze. Tel de ringen."
- **Sterren:** ★ · ★★ 0 fouten · ★★★ zonder hint/terugspoelen.

#### 2-2 "Het wespenbedrog" (P0) — het AAAAABAAAAABC_-voorbeeld (p. 29)
- **Nieuw:** wespen; skip op de wortel.
- **Alfabet {A,B,C,_}** (top = 5 sap). **Start:** Patricia `{5|B{5|B[AAAAABAAAAABC_] C[AAAAABAAAAAC_]} C[AAAAACA_]}`
  (2 toppen = 10 sap). Ernaast staat een grijze geestboom: dezelfde drie woorden als gewone trie = 12 toppen (48 sap).
  CALM, `CURSOR`.
- **Kaarten:** 🐝`AAAAABAAAAABC_` (leest 5 B, 11 B → ✓) · 🐝`AAAAACA_` (5 C → ✓) · 🐝**wesp** `BBBBBBBBBBBBB_`
  (leest 5 B, 11 B → vrucht `AAAAABAAAAABC_` → Niet hier!) · 🐝`AAAAAC_` (5 C → vrucht `AAAAACA_` → Niet hier) ·
  🐝**wesp** `CCCCCBCCCCCBC_` (5 B, 11 B → zelfde vrucht → Niet hier) · 🐝`AAAAABAAAAAC_` (5 B, 11 C → ✓) ·
  🐝`AAAAABAAAAABC_` (controle: is ze nog niet gestolen?).
- **Gevolg:** plukt de speler bij de eerste wesp, dan steelt die `AAAAABAAAAABC_`. De laatste bij vindt een lege knop
  en de terugblik linkt die mislukte bestelling aan de diefstal.
- **Intro:** Uil: "Patricia kijkt niet naar overgeslagen letters…". Geen spookhand: de eerste wesp moet je zelf
  ontmaskeren.
- **Sterren:** ★ · ★★ 0 fouten (geen diefstal) · ★★★ zonder hint.

#### 2-3 "Enten" (P0) — toevoegen in een Patricia trie
- **Nieuw:** reconstructie via een vrucht, j, ent op een knop / in een skip / op een bladtak.
- **Start = Figuur 15 Patricia** (5 toppen, 30 sap). Budget 54. CALM, `NONE`.
- **Kaarten en verwacht verloop:**
  1. 🌱`GT_`: leest 0 G → top `G` (pos 1): leest 1 `T` → lege knop → kies een vrucht onder `G` (bv. `GA_`) → j = 1 =
     pos → vrucht aan knop T van top G. (+0 sap)
  2. 🌱`CGTA_`: leest 0 C → top skip 2 (pos 3): leest 3 `A` → lege knop → vrucht onder die top (bv. `CGCCCT_`) → j = 2 <
     pos 3 → **nieuwe top in de skip**: pos 2, skip 1; de oude top krijgt skip 0. (+6)
  3. 🌱`GGCGT_`: 0 G, 1 G, 3 G → vrucht `GGCGG_` → j = 4 → nieuwe top op de bladtak (pos 4, skip 0). (+6)
  4. 🌱`C_` (m = 1): 0 C → de top op pos 2 (skip 1, ontstaan bij kaart 2): next + skip = 1 + 1 > m → **te kort** →
     vrucht onder die top (bv. `CGTA_`) → j = 1 → nieuwe top pos 1 (skip 0) tussen de wortel en de pos-2-top; die
     krijgt skip 0. (+6)
  5. 🐝`CGTA_` ✓ · 🐝`C_` ✓ · 🐝`GGCGT_` ✓ · 🐝`GGCC_` ✓ · 🐝**wesp** `CGTT_` (leest 0, 1, 2 → vrucht `CGTA_` → Niet hier) ·
     🐝**wesp** `GTA_` (0 G, 1 T → vrucht `GT_` → Niet hier).
- **Eind:** `{0|C{0|G{0|C{0|C{0|C[CGCCCT_] T[CGCCTT_]} G[CGCGAA_]} T[CGTA_]} _[C_]} G{0|A[GA_] G{1|C[GGCC_] G{0|G[GGCGG_] T[GGCGT_]}} T[GT_]}}`,
  8 toppen = **48 sap**. (Alle skip-winst van de C-tak is weg: de Uil merkt op dat Patricia het meest wint in *dunne* tries.)
- **Sterren:** ★ · ★★ 0 fouten · ★★★ zonder hint/terugspoelen en ≤ 240 s.

#### 2-4 "Oefening 19a" (P0) — Figuur 17 als Patricia (examenlevel)
- **Start = Figuur 17 (p. 32):** `{C{G{A{C{C[CGACCC_] T[CGACTAA_]}} T[CGTAAT_]}} G{G{A[GGA_] C{G{A[GGCGAA_] T[GGCGTA_]}} G{G[GGGGG_] T[GGGTTT_]} T[GGTT_]}}}`
  (10 toppen × 6 = 60 sap). CALM, `NONE`, **geen hints**.
- **Kaarten:** ⚘ snoeien (unair: `C`, `CGA`, `G`, `GGC`) · 🐝`GGCGTA_` (0, 2 C, 4 T ✓) · 🐝`CGACTAA_` (0, 2 A, 4 T ✓) ·
  🐝`GGGTTT_` (0, 2 G, 3 T ✓) · 🐝**wesp** `GTGGGG_` (0, 2 G, 3 G → `GGGGG_` → Niet hier) · 🐝`CCAT_` (0, 2 A, 4 `_` →
  lege knop) · 🐝`GGTT_` ✓ · 🐝`CGTAAT_` ✓.
- **Eind (= oplossing Oef. 19a):** `{0|C{1|A{1|C[CGACCC_] T[CGACTAA_]} T[CGTAAT_]} G{1|A[GGA_] C{1|A[GGCGAA_] T[GGCGTA_]} G{0|G[GGGGG_] T[GGGTTT_]} T[GGTT_]}}`,
  6 toppen = **36 sap**.
- **Intro:** titelkaart "Oefening 19 — lesnotas p. 32". De terugblik opent standaard in de notas-weergave.
- **Sterren:** ★ · ★★ eindboom exact · ★★★ 0 fouten.

### 5.4 HERFST — ternary (bol = 3 sap; gewone top ter vergelijking = |A| sap)

#### 3-1 "Rankknopen" (P0) — Figuur 16 + ASCII-storm
- **Nieuw:** rankknoop, omzetten door plantvolgorde, vluchtlengte (vergelijkingen).
- **Start = Figuur 16 boven:** `{C{A[CA_] G[CGGA_]} G{G[GGGG_]} T{A[TAC_] C[TCCA_]}}` (4 toppen = 20 sap). CALM, `FULL`.
- **Kaart ⚘ omzetten:** breedte-eerst krijgt elke top een lege rankknoop. De speler plant de letters van die top in een
  zelfgekozen volgorde: wortel {C,G,T}, top C {A,G}, top G {G}, top T {A,C}.
- **Optimum (= Figuur 16 onder, p. 31):** `(G (C . (G (A . [CA_] .) [CGGA_] .) .) (G . [GGGG_] .) (T . (A . [TAC_] (C . [TCCA_] .)) .))`.
  Wortel G eerst (gebalanceerd); bij 2 letters is elke volgorde even goed. 8 bollen = **24 sap**. Vluchtlengte van de 5
  bloeibijen samen = **16 vergelijkingen** (optimum). Plant je de wortel als ketting (volgorde C, G, T of T, G, C), dan worden het er 17. (C, T, G is ook optimaal: de vorm telt, niet de eerste letter.)
- **Daarna 🐝-bijen:** `CA_` ✓, `TCCA_` ✓, `GGGG_` ✓, `TA_` (afwezig: in rankknoop T is gelijk-A een vrucht `TAC_` →
  Niet hier).
- **Slot: ASCII-storm.** De Uil zegt: "Wat als het alfabet alle 256 tekens telt?" De wind draait. De gewone geestboom
  ernaast blaast elke krans op tot 256 knoppen (**4 × 256 = 1024 sap**, de sapbuis barst uit beeld). De rankboom
  blijft **24**. Notas p. 31–32: "terwijl de ternary trie niet zou veranderen."
- **Sterren:** ★ · ★★ 0 fouten · ★★★ vluchtlengte = 16.

#### 3-2 "Woordenrank" (P0) — toevoegen in ternary, groot alfabet
- **Alfabet a–z + `_`** (27; gewone top = 27 sap). **Start:** lege wortel (rankknoop zonder bollen, 0 sap). Budget **70**.
  CALM, `FULL` voor de eerste 3 kaarten, daarna `CURSOR`.
- **Kaarten (zaadjes in volgorde):** `mier_ bij_ roos_ bijen_ tak_ blad_ bloem_ zaad_ sap_ tuin_ bes_ rank_`, daarna
  🐝`bloem_` ✓ · 🐝`tuin_` ✓ · 🐝`blos_` (m ← b; gelijk; i → l; gelijk; a → o; gelijk → vrucht `bloem_` → Niet hier) ·
  🐝`zon_` (vrucht `zaad_` → Niet hier) · 🐝`kip_` (m ← b → groter = NULL → niet gevonden) · 🐝`bij_` ✓.
- **Verwachte sporen (eerste zaadjes):** `bij_`: `b < m` → kleiner (NULL) → bol b. `bijen_`: m ← b, gelijk → vrucht
  `bij_` → j = 3 (`_` vs `e`) → rankknopen `i`, `j`, laatste krijgt eerst `_` (vrucht bij_), dan `e` als kleiner
  (`e < _`). `blad_`: m ←, b gelijk → rankknoop {i}: `l > i` → groter (NULL) → bol l.
- **Eind:** `(m (b . (i (e . [bes_] .) (j . (_ (e . [bijen_] .) [bij_] .) .) (l . (a . [blad_] (o . [bloem_] .)) .)) .) [mier_] (r . (o (a . [rank_] .) [roos_] .) (t (s . [sap_] .) (a . [tak_] (u . [tuin_] .)) (z . [zaad_] .))))`,
  18 bollen = **54 sap**. Een gewone trie zou 7 toppen × 27 = **189 sap** kosten (geestboom in de terugblik).
- **Sterren:** ★ · ★★ 0 fouten · ★★★ ≤ 54 sap en ≤ 240 s.

#### 3-3 "Oefening 19b" (P2) — Figuur 17 als ternary
- **Start = Figuur 17** (10 toppen = 50 sap). Kaart ⚘ omzetten (zoals 3-1). 18 bollen = 54 sap.
- **Optimale vluchtlengte** (9 bloeibijen, som vergelijkingen): **49**. Voorbeeld van een optimale keuze: wortel G
  voor C; top `CG`: A voor T; top `GG` {A,C,G,T}: C of G als wortel. Geverifieerd met een optimale-BST-berekening per top.
- **Sterren:** ★ · ★★ 0 fouten · ★★★ vluchtlengte = 49.
- Bonus (P2, Oef. 19c): de rankknopen van 2-4 (Patricia + ternary). Enkel als er tijd is.

#### 3-4 "Oefening 20: welke boom plant je?" (P1) — keuzelevel
- **Twee tuinbedden**, elk met een eigen sapbudget. Voor elk bed kiest de speler **array-boom** (gewone kransen) of
  **rankboom**. Daarna plant de tuin automatisch (versneld, 0,3 s per zaadje) en de sapbuis loopt mee.
  - **Bed A** (alfabet {a,c,g,t,_}, de 10 woorden van 1-4 in kleine letters; interne toppen hebben gemiddeld precies 2
    kinderen): array = 9 × 5 = **45 sap**, ternary = 18 × 3 = **54 sap**. Budget **48**.
  - **Bed B** (a–z_, de 12 woorden van 3-2): array = **189**, ternary = **54**. Budget **60**.
- **Gevolg van een verkeerde keuze:** het sap raakt op tijdens het planten, de resterende zaadjes waaien weg en
  de Bloei toont hongerige bijen. De speler mag het bed opnieuw planten met de andere soort (kost ★★).
- **Terugblik:** Uil: "\|A\| = 5, 2 kinderen: 5 pointers tegen 2 × 3. Oefening 20." Met verwijzing naar p. 32.
- **Sterren:** ★ beide bedden bloeien · ★★ beide keuzes meteen juist (A = array, B = ternary) · ★★★ binnen 30 s.

### 5.5 WINTER — suffixbomen (alfabet {a,c,g,t,_}, `pos_base` 0)

#### 4-1 "De slinger" (P0) — Figuur 18 opbouwen (strings aan de bogen)
- **Tekst:** `acacacgt_` (posities 0–8). Suffixen komen in de volgorde van p. 33: `acacacgt_, cacacgt_, acacgt_,
  cacgt_, acgt_, cgt_, gt_, t_, _`. CALM. Sap: elke letter op een boog of in een vrucht = 1 sap. Budget 90.
- **Verwachte afwijkpunten (speler klikt één keer per suffix):**
  | suffix j | punt | regel |
  |---|---|---|
  | 0 `acacacgt_` | wortel | nieuwe tak |
  | 1 `cacacgt_` | wortel | nieuwe tak |
  | 2 `acacgt_` | boog `acacacgt_` na 4 tekens (`acac`\|`acgt_`) | splits |
  | 3 `cacgt_` | boog `cacacgt_` na 3 tekens | splits |
  | 4 `acgt_` | boog `acac` na 2 tekens | splits |
  | 5 `cgt_` | boog `cac` na 1 teken | splits |
  | 6 `gt_`, 7 `t_`, 8 `_` | wortel | nieuwe tak |
- **Eind = Figuur 18 (p. 33):** wortel → `ac`{ `ac`{`acgt_`→acacacgt_, `gt_`→acacgt_}, `gt_`→acgt_ }, `c`{ `ac`{`acgt_`,
  `gt_`}, `gt_` }, `gt_`, `t_`, `_`. 5 interne toppen + 9 bladeren = 14 ≤ 2n − 1 = 17. Sap = 35 (bogen) + 45 (vruchten
  met volledig suffix) = **80**.
- **Intro:** Uil: "Hang elk staartje van de slinger in de boom." Spookhand bij suffix 2.
- **Sterren:** ★ · ★★ 0 fouten · ★★★ zonder hint.

#### 4-2 "Wijzers" (P0) — Figuur 19: (b,e)-labels
- **Zelfde tekst en suffixen, maar elke boog en vrucht draagt een (b,e)-bord (2 sap).** Budget **50** (strings passen
  niet meer: Uil: "Strings drinken te veel sap. Wijs gewoon naar de slinger.").
- Na elk aanhechten kiest de speler **b** van de nieuwe bladboog op de slinger (e = 8 automatisch). Juiste b =
  j + l (l = stringdiepte van het aanhechtpunt): suffix 0 → **0**, 1 → **1**, 2–6 → **6**, 7 → **7**, 8 → **8**. Bij
  splitsen verdeelt het spel het bord automatisch (`(b, b+k−1)` / `(b+k, e)`, de animatie toont de rekensom).
- **Eind (0-gebaseerd):** `{(0,1){(2,3){(4,8)#0 (6,8)#2} (6,8)#4} (1,1){(2,3){(4,8)#1 (6,8)#3} (6,8)#5} (6,8)#6 (7,8)#7 (8,8)#8}`.
  Sap = 13 bogen × 2 + 9 vruchten × 2 = **44**.
- **Wist-je-datkaart in de terugblik (geen fout):** Figuur 19 schrijft voor de twee interne `ac`-bogen `(0,1)`; jouw boom
  `(2,3)`. Beide spellen `ac`. Ukkonen kiest (2,3), want dan begint op b − l_t = 2 − 2 = 0 echt `acac` (p. 48).
- **Sterren:** ★ · ★★ 0 fouten · ★★★ ≤ 44 sap en zonder hint.

#### 4-3 "Inspecteur Egel" (P0) — §3.3, Oef. 28/29 op de boom van 4-2
- **Start:** de eindboom van 4-2 (geladen). Slinger zichtbaar. CALM. Vruchten tonen hun beginpositie.
- **Vragen (juiste antwoorden, uit de simulator):**
  | # | vraag | loep (punt) | antwoord |
  |---|---|---|---|
  | 1 | "Komt `cac` voor? Waar?" | boog (2,3) onder top `c` (l_t = 1), na 2 tekens | ja; b − l_t = 2 − 1 = **1** (ook 3 is goed) |
  | 2 | "Hoe vaak `ac`?" | einde boog (0,1) = top `ac` | **3** (bladeren 0, 2, 4) |
  | 3 | "Komt `cat` voor?" | `c` → `a` op boog (2,3) → volgende parel is `c` ≠ `t` | **komt niet voor** |
  | 4 | "Waar `acg`?" | boog (6,8) onder top `ac` (l_t = 2), 1e teken | **4** (6 − 2) |
  | 5 | "Wijs alle verdachten aan voor `a`" | boog (0,1), na 1 teken | vruchten **0, 2, 4** |
  | 6 | "Hoe vaak `c`?" | boog (1,1) = top `c` | **3** (1, 3, 5) |
  | 7 | "Waar `caca`?" | boog (4,8) onder top `cac` (l_t = 3), 1e teken | **1** (4 − 3) |
- **Intro:** Egel stapt binnen met een loep. Uil: "Vraag de boom, niet de slinger."
- **Sterren:** ★ ≥ 5 goed · ★★ 7/7 goed · ★★★ 7/7 en ≤ 120 s.

#### 4-4 "Mist over de slinger" (P0) — b − l_t afdwingen, telbadges (Oef. 29)
- **Tekst:** `gcatcgcatgcatcga_` (0–16). De boom is voorgebouwd (13 interne toppen incl. wortel):
  `{(2,2){(3,3){(4,5){(15,16)#11 (6,16)#2} (9,16)#7} (16,16)#15} (1,1){(2,3){(4,5){(15,16)#10 (6,16)#1} (9,16)#6} (5,5){(15,16)#13 (6,16)#4}} (0,0){(15,16)#14 (1,3){(4,5){(15,16)#9 (6,16)#0} (9,16)#5}} (3,3){(4,5){(15,16)#12 (6,16)#3} (9,16)#8} (16,16)#16}`
  (kinderen hier in alfabetvolgorde a, c, g, t, `_` van hun eerste letter; de grammatica sorteert zo).
- **Mist:** de slinger is bedekt; enkel de parels b..e van het bord waarover je hovert, worden zichtbaar.
  Toppen tonen hun stringdiepte l_t op een ring. De bogen tonen enkel (b,e). SWARM: de inspecteur heeft 25 s geduld per
  vraag.
- **Vragen:** "Waar `cat`?" → **1** (boog (2,3) onder top `c`, l_t = 1; ook 6, 10 goed) · "Hoe vaak `gcat`?" → **3** ·
  "Waar `atg`?" → **7** (boog (9,16) onder `at`, l_t = 2) · "Komt `ttt` voor?" → **nee** · *(telbadges ontgrendeld:
  Uil legt Oef. 29 uit: "Tel één keer alle bladeren per top. Dan weet je het meteen.")* · "Hoe vaak `tcg`?" → **2** ·
  "Waar `cga`?" → **13** (boog (15,16) onder `cg`, l_t = 2) · "Wijs alle verdachten aan voor `catc`" → **1, 10**.
- **Sterren:** ★ ≥ 5 goed · ★★ 7/7 · ★★★ 7/7 en gemiddeld ≤ 10 s per vraag.

#### 4-5 "Wiens spoor?" (P0) — veralgemeende suffixboom (p. 49)
- **Verdachten:** Mol `gatcga_₁`, Merel `tcgatt_₂`, Muis `atcgg_₃`. Aaneengeschakeld (onechte veralgemeende
  suffixboom): `gatcga_₁tcgatt_₂atcgg_₃`, posities 0–19 (Mol 0–6, Merel 7–13, Muis 14–19). Elke slinger heeft de kleur
  van zijn eigenaar. Een bladboog die over een afsluitteken loopt, wordt getekend tot en met dat teken, gevolgd door
  "⋯" (Oef. 30a: alles vanaf het afsluitteken ligt op één bladboog). Start = boom gebouwd uit de aaneengeschakelde
  tekst (`TtUkkonen.run_all()`, of naïef: zelfde boom), 12 interne toppen, alfabet `dna_lower_multi(3)`.
- **Sporen (vragen "Van wie?"):** `gatt` → **Merel** (9) · `tcgg` → **Muis** (15) · `cga` → **Mol en Merel** (3, 8) ·
  `atc` → **Mol en Muis** (1, 14) · `ggg` → **niemand** · `cgat` → **Merel** (8).
- **Sterren:** ★ ≥ 4 goed · ★★ 6/6 · ★★★ 6/6 en ≤ 90 s.

### 5.6 FINALE — Ukkonen: "De eeuwige slinger"
Notatie verloop: `it=k 'c'` = iteratie k met nieuw teken c. (p̄,x̄) zoals de dikke pijl in de notas. `[u]` = top die
string u voorstelt, w = wortel. Spelerbeslissingen in **vet**.

#### 5-1 "Ukkonen aan het werk" (P0) — `abacabc_`, notas p. 43–48 (`pos_base` 1)
- **Iteraties 1–4 met spookhand** (de speler kijkt en drukt enkel "Verder"), daarna 5–8 zelf. Elke iteratie toont
  rechts een miniatuur van de tekening uit de notas ter vergelijking (enkel in dit level).
- **Verwachte stappen:**
  - it=1 'a': (w,0) **Groei** (ii) → blad 1 `(1,it)`. Iteratie af → (w,0).
  - it=2 'b': (w,0) **Groei** (ii) → blad 2 `(2,it)` → (w,0).
  - it=3 'a': (w,0) **Zit er al** (a) → (w,1).
  - it=4 'c': (w,1), boog `a…` lang genoeg → **Groei** (iii): top [a] `(1,1)`, rest `(2,it)`, blad 3 `(4,it)` →
    **x − 1** → (w,0) → **Groei** (ii) blad 4 `(4,it)` → **rank [a] → w** → iteratie af → (w,0).
  - it=5 'a': (w,0) **Zit er al** (a) → (w,1).
  - it=6 'b': (w,1): boog `(1,1)` heeft lengte 1 ≤ x̄ → **Spring** naar [a] → ([a],0) → **Zit er al** (a) → ([a],1).
    (notas p. 46: "eerst 1, zoeken, dan 0, achteraf 1")
  - it=7 'c': ([a],1) → **Groei** (iii): top [ab] `(2,2)`, blad 5 `(7,it)` → **Volg link** (p = [a] ≠ w) → (w,1) →
    **Groei** (iii): top [b] `(2,2)`, blad 6 `(7,it)` → **rank [ab] → [b]** → **x − 1** → (w,0) → **Zit er al** (a)
    (`c` bestaat) → **rank [b] → w** → (w,1).
  - it=8 '_': (w,1) → **Groei** (iii): top [c] `(4,4)`, blad 7 `(8,it)` → **x − 1** → (w,0) → **Groei** (ii) blad 8
    `(8,8)` → **rank [c] → w** → klaar.
- **Eind (1-gebaseerd):** `{(1,1){(2,2){(3,8)#1 (7,8)#5} (4,8)#3} (2,2){(3,8)#2 (7,8)#6} (4,4){(5,8)#4 (8,8)#7} (8,8)#8}`;
  suffix links [a]→w, [ab]→[b], [b]→w, [c]→w.
- **Intro:** Uil: "Eén parel per keer. Bladeren groeien vanzelf." **Sterren:** ★ · ★★ ≤ 2 misstappen · ★★★ 0 misstappen.

#### 5-2 "Oefening 27" (P0) — `aabbabc_` (`pos_base` 1, geen spookhand)
- **Verwachte stappen:**
  - it=1 'a': (w,0) **Groei** (ii) blad 1 → (w,0).
  - it=2 'a': (w,0) **Zit er al** → (w,1).
  - it=3 'b': (w,1) **Groei** (iii): top [a] `(1,1)`, blad 2 `(3,it)` → **x − 1** → (w,0) **Groei** (ii) blad 3 → **rank [a] → w** → (w,0).
  - it=4 'b': (w,0) **Zit er al** → (w,1).
  - it=5 'a': (w,1) **Groei** (iii): top [b] `(3,3)`, blad 4 `(5,it)` → **x − 1** → (w,0) **Zit er al** (`a` bestaat) →
    **rank [b] → w** → (w,1).
  - it=6 'b': (w,1): boog `(1,1)` → **Spring** naar [a] → ([a],0) **Zit er al** → ([a],1).
  - it=7 'c': ([a],1) **Groei** (iii): top [ab] `(3,3)`, blad 5 `(7,it)` → **Volg link** → (w,1): boog `(3,3)` →
    **Spring** naar [b] → ([b],0) **Groei** (ii) blad 6 `(7,it)` → **rank [ab] → [b]** → **Volg link** (p = [b]) → (w,0)
    → **Groei** (ii) blad 7 `(7,it)` → (w,0).
  - it=8 '_': (w,0) **Groei** (ii) blad 8 `(8,8)` → klaar.
- **Eind (1-gebaseerd):** `{(1,1){(2,8)#1 (3,3){(4,8)#2 (7,8)#5}} (3,3){(5,8)#4 (4,8)#3 (7,8)#6} (7,8)#7 (8,8)#8}`
  (de grammatica sorteert de kinderen van [b] op eerste letter: `a`=(5,8), `b`=(4,8), `c`=(7,8)). Links [a]→w,
  [ab]→[b], [b]→w.
- **Sterren:** zoals 5-1.

#### 5-3 "Figuur 18 herboren" (P1) — `acacacgt_` met Ukkonen (`pos_base` 0)
- **Verloop (het cascade-moment):** it 1–2 **Groei** (ii); it 3 **Zit er al** (x̄ = 1); it 4, 5, 6 **Zit er al** (b) midden
  in de boog: x̄ wordt 2, 3, 4 (het vuurvliegje kruipt langs de boog). it 7 'g': (w,4) **Groei** (iii) → x − 1 → (w,3)
  **Groei** (iii) + rank → x − 1 → (w,2) **Groei** (iii) + rank → x − 1 → (w,1) **Groei** (iii) + rank → x − 1 → (w,0)
  **Groei** (ii) + rank → w. Vier nieuwe toppen in één iteratie, suffix links [acac]→[cac]→[ac]→[c]→w. it 8, 9 **Groei** (ii).
- **Eind:** identiek aan 4-2 (0-gebaseerd) → het spel legt jouw boom over Figuur 18/19; de twee `ac`-borden tonen
  `(2,3)` naast `(0,1)` van de notas (zie 4-2).
- **Sterren:** zoals 5-1.

### 5.7 Vrije tuin "Bijenkoorts" (P0; ontgrendeld na 1-4 ≥ 1 ster, of na 1-3 als 1-4 niet gebouwd is)
- **Gewone trie, alfabet {A,C,G,T,_}, SWARM.** Start: lege wortel, sap 60 (cap 120), +1 sap per 3 s.
- **Generator (`TtWordGen`, seed = tijd):** woorden van 2–7 letters + `_`. Met 50 % kans start een nieuw woord met
  een prefix (lengte 1–4) van een woord dat al in de boom zit, zodat er lange gedeelde prefixen ontstaan. Duplicaten
  zijn toegelaten (5 %: juiste reactie "Zit er al").
- **Tempo (niveau k = ⌊t / 30 s⌋):** zaadje elke max(3,0; 8,0 − 0,5k) s; bij elke max(2,5; 7,0 − 0,4k) s, geduld
  max(8; 16 − 0,6k) s; 25 % van de bijen vraagt een afwezig woord; vanaf 120 s elke 45 s een ✂-kaart ("dit woord is
  verwelkt") die sap teruggeeft.
- **Einde:** na 3 **missers** (bij boos weg / verkeerde honing / zaadje weggewaaid / sap op bij planten).
  Highscore = honing; lokaal top-10 met 3 letters en datum.
- (P2) Variant "Zomerkoorts" met Patricia na Zomer.

---

## 6. Scoring, sterren, economie & terugblik

### 6.1 Valuta en meters
- **Sap** (geheugen): het budget van het level. Je ziet het als vloeistof die zakt. Lopen de knoppen droog, dan kan er
  niets meer groeien (§3). Snoeien en knippen geven sap terug.
- **Honing** (score): verdien je met correct afgewerkte kaarten. Dit is de highscore in de vrije tuin.
- **Sterren** (0–3 per level): openen de kaart verder.
- **Misstappen:** logentries met verdict ≠ OK. Bumps (fysieke weigeringen) tellen enkel in Ukkonen-levels
  (`TtLevelSpec.count_bumps = true`), elders kosten ze enkel tijd (zoals "klonk" in Hash & Dash).

### 6.2 Sapmodel (notas-getrouw: geheugen = pointers; vereenvoudigingen staan in §11 vraag 5)
| structuur | kost | motivatie (notas) |
|---|---|---|
| gewone trie: interne top | \|A\| druppels (5 bij DNA, 4 bij {A,B,C,_}, 27 bij a–z_, 256 bij ASCII) | "array van pointers van lengte \|A\|", NULL-pointers kosten ook (p. 27–28) |
| Patricia: interne top | \|A\| + 1 (knoppen + skip) | extra variabele `skip` (p. 29) |
| ternary: letterbol | 3 (kleiner, gelijk, groter) | "naast een sleutel … nog drie pointers" (p. 31); de sleutel (1 teken) rekenen we niet (§11) |
| ternary: rankknoop-container | 0 | enkel een tekenhulp; in de notas is de pointerboom de top |
| vrucht (blad) in tries | 0 | elke voorstelling bewaart dezelfde strings; vergelijken gaat over de pointers |
| suffixboom, labels als strings (4-1) | 1 per letter op een boog + \|suffix\| per vrucht | "alleen het opslaan van alle prefixen in de bladeren Θ(n²)" (p. 33) |
| suffixboom, labels als (b,e) (4-2 e.v.) | 2 per boog + 2 per vrucht | "pointers naar het begin en het einde" (p. 33) |
| suffixboom: top | 0 | — |
Optimum per level = sap na perfect spel (core: `TtLevels.optimum(spec)` speelt de kaarten met `correct_move()`).

### 6.3 Honing
| gebeurtenis | honing |
|---|---|
| zaadje correct geplant (alle stappen OK) | +10 × combo |
| bestelling correct (pluk of terecht "Niet hier") | +15 × combo |
| wesp ontmaskerd | +20 × combo |
| snoei/knip correct | +10 |
| omzetten (ternary) afgerond | +5 per bol, +20 als vluchtlengte = optimum |
| suffix correct aangehecht / bord correct | +10 / +5 |
| inspecteursvraag correct | +20 (+10 bij "Waar?" als het antwoord gelijk is aan b − l_t; + resterend geduld × 1 in 4-4) |
| Ukkonen-beslissing correct | +5 per beslissing; iteratie zonder misstap +10 |
| verkeerde honing (pluk bij andere vrucht) | −10 |
| wesp steelt | −20 |
| einde level: overgebleven sap | +1 per 2 druppels |
| Bloei: elke geslaagde bij | +5 |
**Combo** (enkel in SWARM): kaarten correct afgewerkt binnen 6 s na elkaar → ×1 … ×5. De combo breekt bij een
misstap, een gemiste bij of een gebruikte hint. Bij ×5 krijg je "Bijendans": korte slow-mo 0,5×, bijen vliegen een
achtje, muziekstinger.

### 6.4 Sterren (algemeen patroon; exacte voorwaarden per level in §5)
★ = level uitgespeeld (alle kaarten afgewerkt) **en** de Bloei is ≥ 70 % geslaagd (of de levelspecifieke ★-eis).
★★ = 0 misstappen (en dus 100 % Bloei).
★★★ = efficiëntie of meesterschap: sap = optimum, vluchtlengte = optimum, tijdslimiet, of "zonder hint en zonder
terugspoelen".
Hint (`F1`) en terugspoelen (`Ctrl+Z`) zijn altijd beschikbaar in CALM-levels. Wie ze gebruikt, kan in dat level
geen ★★★ halen (★★ blijft mogelijk: een hint is geen misstap). Uitzondering: examenlevels 2-4 (geen hints).

### 6.5 Terugblik (rapportscherm)
Volgorde van de animatie: (1) sterren vliegen één voor één in, met de voorwaarde eronder (groen/grijs); (2) honing
telt op met een uitsplitsing (tabel 6.3); (3) **sapbalk**: gebruikt vs. optimum vs. budget, met de geestvergelijking
van het level (bv. "gewone trie: 48 · jouw Patricia: 30" of "ASCII: 1024 · rank: 24"); (4) **Bloeirij**: één icoon per
bij (✓ honing / ✗ lege korf / wesp), klikbaar: toont het pad van de bij in de boom; (5) **misstappen-tijdlijn**: een stip per
event (groen OK, amber misstap). Klik op een amber stip: de tuin van dat moment wordt herbouwd (`restore(entry.before)`
in een tweede, alleen-lezen model). Jouw zet speelt af in rood-transparant, daarna de juiste zet als groene
spookhand, met één **coachzin** + **notasverwijzing**. (6) **Oorzaakketens**: een mislukte Bloei-bij linkt naar het event
waar haar vrucht verkeerd geplant, gestolen of weggeknipt werd ("← kaart 4: j = 5 i.p.v. 3"). (7) Knop
**Notas-weergave**: de eindboom getekend zoals in de figuren (wortel boven, knoppenrijen `A C G T _` als kaders,
Patricia met skip-kolom, ternary met cirkels, suffixboom met (b,e) in de weergavebasis). (8) Knoppen Volgende /
Opnieuw / Kaart.

**Coachzinnen** (`TtEventLog.coach_line(entry)`; ≤ 16 woorden + verwijzing; `{…}` = data uit het event):
| verdict | zin | verwijzing |
|---|---|---|
| WRONG_LETTER | "Op diepte {d} lees je letter {d}: `{c}`. Knop {c}, niet {x}." | notas p. 27, opzoeken |
| WRONG_KNOP | "Lege knop? De vrucht hoort aan knop `{c}` = s_{d}." | p. 27, toevoegen |
| J_LATE | "`{l}` en `{s}` verschillen al op positie {j}, niet pas op {x}." | p. 27: j = min{i ≥ d \| l_i ≠ s_i} |
| WRONG_SAME | "`{l}` ≠ `{s}`: vergelijk het hele woord." | p. 27 |
| WRONG_ANSWER (pluk) | "Een vrucht bereiken is niet vinden: `{l}` ≠ `{s}`." | p. 27; Algoritme 1, p. 29 |
| WRONG_ANSWER (niet hier) | "`{s}` hing hier wel: label = gezochte string." | p. 27 |
| CUT_TOO_HIGH | "Knip net onder `{u}`: de laatste top met twee kinderen." | p. 27, verwijderen |
| CUT_TOO_LOW | "Alles na `{u}` mag weg; er bleef dood hout." | p. 27, verwijderen |
| WRONG_POS | "skip = {k}: sla {k} letters over en lees positie {p}." | Algoritme 1, p. 29 |
| WRONG_SHORT | "next + skip = {a} ≤ m = {m}: het lint is lang genoeg." | Algoritme 1, p. 29 |
| UNPRUNED | "Top `{u}` had maar één kind: die mocht weg." | p. 28–29 |
| WRONG_DIR | "`{c}` {<,=,>} `{k}` → {kleiner/gelijk/groter}." | p. 31 |
| WRONG_POINT | "`{σ}` volgt de boom tot `{u}` en wijkt daar pas af." | p. 33 |
| WRONG_B | "Nieuwe boog vanuit diepte {l}: b = {j} + {l} = {b}." | p. 48 (b − l_t) |
| WRONG_WHERE | "Boog ({b},{e}) vanuit diepte {l}: positie = {b} − {l} = {p}." | p. 48 |
| WRONG_COUNT / WRONG_PICK | "Onder het punt hangen {n} vruchten: zoveel voorkomens." | Oef. 28–29, p. 49 |
| WRONG_ABSENT | "`{z}` loopt tot het einde door: het komt voor." / "Na `{u}` volgt `{x}`, niet `{c}`." | p. 48 |
| WRONG_OWNER | "De kleuren onder het punt: {namen}." | p. 49, veralgemeende suffixboom |
| WRONG_BED | "\|A\| = {a}, {k} kinderen gemiddeld: {pa} pointers vs. {pt}." | Oef. 20, p. 32 |
| WRONG_RULE (stop) | "Na `{σ}` komt in de boom `{x}`, niet `{c}`: uitbreiden ({r})." | p. 38 |
| WRONG_RULE (groei) | "`{σ}{c}` zit er al in: stop de iteratie, x + 1." | p. 39 |
| WRONG_HOP | "x̄ = {x} {≥,<} lengte {L}: {spring / blijf}." | p. 41–42 |
| WRONG_LINK | "`{u}` linkt naar `{u′}`: zonder de eerste letter." | p. 40, 43 |
| WRONG_FOLLOW | "p = wortel → x − 1; anders volg je de link en blijft x." | p. 41 |

---

## 7. Juice & audio

### 7.1 Juice-lijst (timing / easing; Godot-tweens)
| # | moment | effect |
|---|---|---|
| 1 | zaadje komt aan | waait uit de windrij in een boog (0,45 s `TRANS_SINE`), landt op de kiem met squash (1,25; 0,8) → (1,1) 0,15 s `TRANS_BACK`, stofje (4 pollen) |
| 2 | letter gevolgd | zaadje schuift langs de tak (0,18 s `EASE_OUT`), tak licht op van onder naar boven, knop maakt een klein knikje; getypte letter springt uit het lint (pop 0,1 s) |
| 3 | lege knop → vrucht | knop gaat open (0,12 s), vrucht groeit van 0 → 1,1 → 1 (0,3 s `TRANS_ELASTIC`), 6 blaadjes, "plop" |
| 4 | nieuwe top(pen) groeien | tak groeit als lijn (0,25 s per top, gestaggerd), knoppenkrans ontvouwt van midden naar buiten (30 ms per knop), lege knoppen dimmen tot grijs |
| 5 | sap uitgeven | druppels vliegen van de buis naar de nieuwe knoppen (1 druppel per 5 sap), buisniveau zakt met slosh (0,4 s `TRANS_SPRING`-achtig) |
| 6 | vergelijkingslint open | lint rolt open (0,2 s), kolommen < d grijs; hover op kolom: beide letters lichten op (gelijk = groen, verschil = oranje) |
| 7 | j gekozen | het lint knipt op kolom j (schaar-snip), de vrucht "splijt" in een tak; oude vrucht schuift naar knop l_j, nieuwe naar s_j (0,35 s, gestaggerd 80 ms) |
| 8 | klonk (fysiek onmogelijk) | object botst, veert terug 0,25 s `TRANS_ELASTIC`, 6 vonkjes, shake 2 px 0,1 s, dof "tok" |
| 9 | bij vliegt | bij met vleugelflap-sprite, volgt de takken (Bezier per tak, 0,12 s per tak, versnelt in combo), stuifmeelspoor |
| 10 | pluk correct | vrucht gloeit, bij pakt een honingdruppel, vliegt in een boog naar de korf, +honing floater, korf pulst |
| 11 | niet hier correct | bij schudt het hoofd, draait om, vliegt kalm terug; klein "zzz" |
| 12 | lege knop bereikt (bij) | bij botst zacht tegen het gesloten knopje, keert terug |
| 13 | verkeerde honing | koningin bij de korf fronst, honingpot morst (5 druppels), −10 floater rood |
| 14 | wesp ontmaskerd | bij de vruchtcontrole schuift een vergrootglas over de bij: strepen verschijnen (0,2 s), wesp sist en vlucht; +20 floater; schermflits geel 6 % |
| 15 | wesp steelt | wesp grijpt de vrucht, vliegt zigzaggend weg met de vrucht, de knop blijft leeg en zwaait na; shake 4 px |
| 16 | onvindbare vrucht (Bloei) | vrucht verkleurt in 0,8 s naar grijs, krimpt 10 %, 3 rotte vliegjes |
| 17 | snoeischaar (Patricia) | schaar opent bij hover, knip: houtsnippers (10), de top klapt weg, de tak erboven zakt in 0,35 s `TRANS_BACK` naar beneden, de skip-ring van het kind telt op (ring rolt in) |
| 18 | knip bij verwijderen | knip + de afgeknipte tak valt met rotatie, landt in de composthoop, sap stroomt terug (druppels omgekeerd) |
| 19 | dood hout | tak verkleurt bruin (0,6 s), af en toe valt er een blaadje af |
| 20 | Patricia: bij hopt | de bij springt over k letters op het lint (k kleine boogjes, 60 ms elk), leest de doelletter (letter licht op) |
| 21 | te kort | de bij springt van het lint af en grijpt in de lucht ("whoosh") |
| 22 | ent | de nieuwe top wordt met bastband in de tak gebonden (wikkel-animatie 0,3 s), ringen herverdeeld (oude ring krimpt, nieuwe ring groeit) |
| 23 | rankknoop groeit | nieuwe bol rolt uit de rank (kleiner = links-onder, groter = rechts), rank krult (spiraalshader of polyline) 0,3 s |
| 24 | ternary kiezen | de rank in de gekozen richting licht op en trekt het zaadje mee (0,2 s) |
| 25 | ASCII-storm | wind blaast; elke knoppenkrans van de geestboom groeit tot een waaier van 256 knoppen (1,2 s), de sapbuis loopt over en barst uit beeld; rankboom blijft stil en glinstert |
| 26 | slinger | parels hangen aan een draad die zacht deint; nieuwe parel rijgt zich aan (Ukkonen) met een tik en een noot (§7.2) |
| 27 | (b,e)-bord hover | parels b..e op de slinger lichten op en een lichtdraad loopt van het bord naar de slinger |
| 28 | boog splijt (suffix) | de boog knikt, een nieuwe top bolt op (0,25 s), het bord breekt in twee borden (getallen tellen naar hun nieuwe waarde) |
| 29 | mist | volumetrische nevel (shader) over de slinger; hover blaast een gat (0,15 s) |
| 30 | inspecteur | Egel stapt in (0,4 s), loep zoomt in op het punt; goed antwoord: hond kwispelt, stempel "OPGELOST"; fout: hond blaft naar de verkeerde boom |
| 31 | Ukkonen: nieuwe parel | `it`-teller tikt op, **alle bladpunten groeien tegelijk** één parel (0,3 s, synchroon, akkoord) |
| 32 | Ukkonen: vuurvliegje | vliegt naar p̄ (0,25 s), lichtspoor van x̄ parels langs de boog; spring = boogsprong |
| 33 | Ukkonen: suffix link | rank schiet uit de nieuwe top, krult naar het doel, bolletje klikt vast (0,3 s) |
| 34 | Ukkonen: regel stop | de σ-rij krijgt een zachte "stop"-gloed, het vuurvliegje knikt, x̄ + 1 pop |
| 35 | Bloei | camera zoomt uit (0,6 s), bloesems openen in een golf van wortel naar kruin, zwerm vertrekt; elke ✓ is een kort belletje met stijgende toonhoogte |
| 36 | sterren | elke ster groeit als een bloem (knop → bloem, 0,35 s, overshoot), blaadjesregen |
| 37 | idle | boom deint met de muziek (0,5° op de maat), bijen vliegen af en toe langs, lichtvlekjes |
| 38 | combo ×5 "Bijendans" | hitstop 80 ms, slow-mo 0,5× 0,4 s, bijen vliegen een achtje rond de kroon |
Instelling schermschok schaalt alle shakes (0/50/100 %). Slow-mo geldt enkel voor wereldnodes, niet voor UI.

### 7.2 Audio
**Muziek** (adaptief, 2 lagen per seizoen: basis + bloei; bij Bloei en sterren komt de bloei-laag erbij):
- *Lente*: lichte marimba + houtfluit, 92 BPM, majeur, vogels in de verte.
- *Zomer*: warme akoestische gitaar + zachte shaker, krekels, 100 BPM.
- *Herfst*: pizzicato-strijkers + celesta, ritselende bladeren, 84 BPM, dorisch.
- *Winter*: speeldoos + zachte pads + sneeuwkraak, 76 BPM.
- *Finale*: een thema dat per iteratie groeit. **Elke parel van de slinger is een noot** (a = C, c = E, g = G, t = A,
  b = D, `_` = hoge C). Bij elke nieuwe parel speelt de hele slinger als melodie. Het lied van `abacabc_` is het
  eindthema. Elk afgerond level voegt een instrument uit één seizoen toe.
- *Titel/kaart*: rustige versie van het lentethema. *Rapport*: korte jingle (3 varianten naar sterren).
Alles CC0 of procedureel (zie ART.md / `assets/CREDITS.md`).

| gebeurtenis | geluid |
|---|---|
| zaadje landt | zacht "pfft" + houtje |
| letter volgen / typen | houten tik, toonhoogte = letterpositie in het alfabet |
| knop opent / vrucht groeit | "plop" + glas-tingel |
| top groeit | krakend hout dat rekt (kort), per knop een mini-plop |
| sap | druppelgeluid (pitch zakt met het niveau) |
| lint open / j geknipt | papier-rol / snip |
| klonk | doffe houtklop + boing |
| bij vliegt / pluk / niet hier / lege knop | zoem (stereo volgt de bij) / "ding" + honing-slurp / kort neuriënd "hmm" / zachte bonk |
| verkeerde honing | koningin-zoem omlaag + morsend |
| wesp ontmaskerd / steelt | sissen + triomfstinger / ritsend vleugelgeluid + dalend motief |
| rot | zacht kreunend hout + vliegjes |
| snoeischaar / knip / compost | metalen snip / takval op aarde / omgekeerd druppelen |
| ent | bast-wikkel (stof) + klik |
| rank groeit | krullend strijkje (glissando) |
| ASCII-storm | windvlaag + krakend hout + glas dat barst |
| slinger / parel | zachte kristaltik + noot (finale) |
| mist | wind laag |
| inspecteur | voetstapjes, loep-"tsjing", stempel; hond kwispelt/blaft |
| Ukkonen: it | akkoord (alle bladeren) |
| suffix link | elastiek-"twang" + klik |
| Bloei | crescendo, belletjes per bij |
| sterren | drie stijgende klokjes |

---

## 8. Interface-contract core ↔ front-end

Alles in `games/trietuin/scripts/core/` is **puur** (`RefCounted` of static, geen nodes, geen `Engine`/`Time`-calls),
deterministisch en headless testbaar. Gameplay luistert naar signalen en roept methodes aan. Alle `class_name`s
beginnen met `Tt`. Geen nieuwe autoloads. **Posities zijn intern altijd 0-gebaseerd.** `pos_base` is enkel weergave.
Ids van toppen worden nooit hergebruikt. Woorden en teksten zijn `String`s van enkelvoudige tekens. Afsluittekens van een
veralgemeende suffixboom zijn intern de tekens `"1"`, `"2"`, `"3"` (weergave `_₁ _₂ _₃`).

### 8.1 Bestanden
| bestand | class_name | rol |
|---|---|---|
| `tt_codes.gd` | `TtCodes` | enums (8.2) |
| `tt_alphabet.gd` | `TtAlphabet` | alfabet, volgorde, sapgrootte |
| `tt_node.gd` | `TtNode` | één top/blad/bol/rankknoop |
| `tt_tree_model.gd` | `TtTreeModel` | basisklasse: log, sap, kaart-operatie, snapshot, apply/oracle |
| `tt_trie.gd` | `TtTrie` | gewone trie |
| `tt_patricia.gd` | `TtPatricia` | Patricia |
| `tt_ternary.gd` | `TtTernary` | ternary (rankknopen) |
| `tt_suffix_tree.gd` | `TtSuffixTree` | suffixboom: aanhechten, labels, inspecteur, veralgemeend |
| `tt_ukkonen.gd` | `TtUkkonen` (extends `TtSuffixTree`) | stapsgewijze Ukkonen |
| `tt_notation.gd` | `TtNotation` | parse/serialize van de boomnotaties (§5.1, 8.8) |
| `tt_card.gd` | `TtCard` | kaart |
| `tt_event_log.gd` | `TtEventLog` | log, coachzinnen, oorzaakketens |
| `tt_level_spec.gd`, `tt_levels.gd` | `TtLevelSpec`, `TtLevels` | leveldata (§5) |
| `tt_director.gd` | `TtDirector` | kaartenstroom, klok, geduld, Bloei, einde |
| `tt_bloom.gd` | `TtBloom` | automatische testrun |
| `tt_scoring.gd` | `TtScoring` | honing, combo, sterren, rapport |
| `tt_save.gd` | `TtSave` | `user://trietuin_save.json` |
| `tt_layout.gd` | `TtLayout` | pure tidy-tree layout |
| `tt_word_gen.gd` | `TtWordGen` | vrije tuin |
| `tt_reference.gd` | `TtReference` | onafhankelijke referentie-implementaties voor tests (naïef, zonder spelstaat) |

### 8.2 `TtCodes`
```gdscript
class_name TtCodes
enum Kind { TRIE, PATRICIA, TERNARY, SUFFIX, UKKONEN }
enum Mode { CALM, SWARM }
enum Hint { FULL, CURSOR, NONE }
enum CardKind { SEED, BEE, PRUNE, PATRICIFY, TERNARIFY, BEDS, SUFFIX, ASK, UKKONEN }   # wesp = BEE met card.wasp = true
enum Phase { IDLE, WALK, COMPARE, AT_LEAF, PICK_LEAF, CUT, PRUNING, PLACING, ATTACH, LABEL, LOCATE, ANSWER,
             U_CANON, U_RULE, U_LINK, U_FOLLOW, DONE }
enum Verdict { OK, BUMP, WRONG_LETTER, WRONG_KNOP, J_LATE, WRONG_SAME, WRONG_ANSWER, CUT_TOO_HIGH, CUT_TOO_LOW,
               WRONG_POS, WRONG_SHORT, UNPRUNED, WRONG_DIR, WRONG_POINT, WRONG_B, WRONG_ABSENT, WRONG_WHERE,
               WRONG_COUNT, WRONG_PICK, WRONG_OWNER, WRONG_BED, WRONG_RULE, WRONG_HOP, WRONG_LINK, WRONG_FOLLOW,
               LOST, TIMEOUT }
const OPEN := -2   # eindlabel "it" van een open Ukkonen-bladboog
```

### 8.3 `TtAlphabet`
```gdscript
class_name TtAlphabet extends RefCounted
var name: String                      # "dna", "dna_lower", "abc", "az", "dna_lower_multi"
var letters: PackedStringArray        # weergave- én vergelijkingsvolgorde; "_" en "1","2","3" achteraan
var cost_size: int                    # |A| voor sap (meestal letters.size(); ASCII-storm: 256)
static func dna() -> TtAlphabet           # A C G T _
static func dna_lower() -> TtAlphabet     # a c g t _
static func abc() -> TtAlphabet           # A B C _
static func az() -> TtAlphabet            # a … z _
static func dna_lower_multi(k: int) -> TtAlphabet   # a c g t 1 … k  (veralgemeend)
static func by_name(n: String) -> TtAlphabet
func size() -> int
func has(ch: String) -> bool
func index_of(ch: String) -> int          # -1 als onbekend
func compare(a: String, b: String) -> int # -1 / 0 / 1 volgens index_of
func display(ch: String) -> String        # "1" -> "_₁", anders ch
```

### 8.4 `TtNode` (één klasse voor alle structuren; ongebruikte velden houden hun default)
```gdscript
class_name TtNode extends RefCounted
enum Type { INNER, LEAF, BALL, PACK }   # BALL = ternary letterbol, PACK = rankknoop (container van bollen)
var id: int
var type: int
var parent: int = -1        # trie/Patricia/suffix: ouder-top; BALL: ouder-bol of -1 (wortelbol van zijn PACK); PACK: de BALL waarvan hij de gelijk-tak is (-1 = wortel); LEAF bij ternary: de BALL
var via: String = ""        # letter van de inkomende tak (trie, Patricia); suffix: eerste teken van de inkomende boog
var depth: int = 0          # trie/ternary: letterdiepte (wortel 0, blad = diepte waarop bereikt); suffix: stringdiepte l_t
var kids: Dictionary = {}   # INNER: letter -> kind-id (enkel niet-lege kinderen)
var label: String = ""      # LEAF (tries): opgeslagen woord
var skip: int = 0           # Patricia
var pos: int = 0            # Patricia: leespositie = pos(ouder) + skip + 1; wortel: skip
var ch: String = ""         # BALL
var lo: int = -1            # BALL: kleiner-bol
var eq: int = -1            # BALL: PACK (volgende rankknoop) of LEAF
var hi: int = -1            # BALL: groter-bol
var pack: int = -1          # BALL: id van zijn PACK
var ball_root: int = -1     # PACK: wortelbol (-1 = leeg)
var b: int = -1             # suffix: label van de boog NAAR deze top, 0-gebaseerd, inclusief
var e: int = -1             # suffix: idem; TtCodes.OPEN = "it"
var start: int = -1         # suffix-LEAF: beginpositie j van het suffix
var link: int = -1          # suffix link (Ukkonen); wortel.link == wortel.id
var owner: int = 0          # veralgemeend: index van de tekst (1..k) van een suffix-LEAF
func to_dict() -> Dictionary   # alle velden + afgeleiden: {"dead":bool, "misplaced":bool} (ingevuld door het model)
```

### 8.5 `TtTreeModel` (basis) — signalen, staat, generieke API
```gdscript
class_name TtTreeModel extends RefCounted
signal changed(fx: Dictionary)                       # één animatiebeschrijving (tabel 8.6), in volgorde
signal phase_changed(phase: int, cursor: Dictionary)
signal card_started(card: TtCard)
signal card_finished(card: TtCard, outcome: Dictionary)  # {all_ok: bool, verdicts: Array[int], result: String}
signal sap_changed(used: int, delta: int)
signal event_logged(entry: Dictionary)

var kind: int                       # TtCodes.Kind
var alphabet: TtAlphabet
var nodes: Dictionary = {}          # id -> TtNode
var root: int
var next_id: int
var sap_budget: int
var card: TtCard = null             # actieve kaart of null
var phase: int = TtCodes.Phase.IDLE
var log: TtEventLog
var now: float = 0.0                # gameplay zet dit elke frame (tijdstempel voor de log)
var count_bumps := false            # uit de levelspec (Ukkonen: true)

func sap_used() -> int                         # berekend uit de structuur volgens §6.2
func can_afford(cost: int) -> bool             # sap_used() + cost <= sap_budget
func node(id: int) -> TtNode
func render_nodes() -> Array[Dictionary]       # to_dict() van alle toppen, met dead/misplaced ingevuld
func begin(c: TtCard) -> void                  # start een kaart-operatie; zet phase en cursor
func cursor() -> Dictionary                    # wat de UI moet tonen/markeren (per subklasse, 8.7)
func apply(move: Dictionary) -> Dictionary     # generieke dispatcher -> {ok, verdict, reason, done}
func correct_move() -> Dictionary              # het orakel: de juiste volgende zet voor de actieve kaart, of {"act":"none"}
func auto_finish_card() -> void                # speelt de rest van de kaart met correct_move() (bots, "doorspoelen")
func lookup_auto(word: String) -> Dictionary   # juiste algoritme, muteert niets: {found, path: Array[int], end: int, reason}
func insert_auto(word: String) -> void         # juiste invoeging zonder log (3-4-bedden, opbouw)
func serialize() -> String                     # TtNotation-vorm van de boom
func load_notation(s: String) -> void
func snapshot() -> Dictionary                  # volledige toestand incl. actieve kaart, phase, cursor, Ukkonen-staat; JSON-serialiseerbaar
func restore(d: Dictionary) -> void            # snapshot -> restore -> snapshot is identiek
func invariants() -> PackedStringArray         # leeg = consistent (ouder/kind-links, ids, skips, BST-orde enkel als waarschuwing)
```
**`apply()`-resultaat:** `{"ok": bool, "verdict": int, "reason": String, "done": bool}`.
- `ok = false`: fysiek onmogelijk ("klonk"). De staat verandert niet, er wordt een `changed({"fx":"bump",…})` geëmit en
  een logentry `BUMP` geschreven (verdict BUMP; telt enkel als misstap als `count_bumps`). `reason` ∈ `"occupied"`,
  `"same_letter"`, `"before_d"`, `"no_diff"`, `"past_end"`, `"not_in_subtree"`, `"branching"`, `"not_on_path"`,
  `"duplicate_first"`, `"not_canonical"`, `"short_edge"`, `"wrong_edge"`, `"bad_target"`, `"no_letter_left"`, `"no_sap"`.
- `ok = true`: de zet is uitgevoerd. `verdict` = OK of een foutcode (bepaald **vóór** het uitvoeren, door
  `correct_move()` te vergelijken; de hint staat in de logentry). `done = true` als de kaart hiermee af is (dan volgt
  `card_finished`).
- Elke uitgevoerde zet emit eerst alle `changed(fx)` in afspeelvolgorde, dan `sap_changed` (als sap wijzigde), dan
  `event_logged`, en eventueel `phase_changed` / `card_finished`.

### 8.6 Animatiebeschrijvingen (`changed(fx)`) — de front-end speelt ze af in volgorde
| `fx` | velden | betekenis |
|---|---|---|
| `"move"` | `from:int, to:int, letter:String, who:"seed"\|"bee"` | zaadje/bij gaat een tak op (to kan een LEAF zijn) |
| `"bee_null"` | `at:int, letter:String` | bij botst op lege knop → keert terug (kaart klaar) |
| `"hang"` | `leaf:int, node:int, letter:String` | nieuwe vrucht aan knop |
| `"grow"` | `nodes:Array[int]` | nieuwe interne toppen (pad), van onder naar boven |
| `"rehang"` | `leaf:int, from:int, to:int, letter:String` | bestaande vrucht verhuist (split) |
| `"compare"` | `a:String, b:String, d:int` | vergelijkingslint openen (a = vruchtlabel, b = woord) |
| `"answer"` | `found:bool, correct:bool, wasp:bool, stolen:bool` | uitkomst van een bestelling |
| `"same"` | `leaf:int, correct:bool` | "zit er al" |
| `"cut"` | `node:int, removed:Array[int], fallen:Array[int]` | knip; fallen = vruchten die meevallen |
| `"dead_wood"` | `nodes:Array[int]` | toppen die dood hout werden |
| `"prune"` | `node:int, child:int, new_skip:int` | snoei (Patricia) |
| `"read"` | `node:int, pos:int, letter:String` | Patricia-bij hopt naar pos en leest |
| `"short"` | `node:int` | te kort |
| `"pick"` | `leaf:int` | gekozen vrucht voor reconstructie |
| `"graft"` | `node:int, new:bool, skips:Dictionary` | ent (nieuwe top of bestaande), skips: id -> nieuwe skip |
| `"ball"` | `ball:int, parent:int, dir:"lo"\|"hi"\|"root", pack:int` | nieuwe letterbol |
| `"go"` | `from:int, to:int, dir:String` | zaadje volgt rank |
| `"split_edge"` | `upper:int, new_node:int, lower:int, k:int` | suffix-boog splijt na k tekens |
| `"attach"` | `leaf:int, at:int, off:int` | suffix-blad hangt |
| `"label"` | `node:int, b:int, e:int` | bord gezet/gewijzigd |
| `"loupe"` | `node:int, off:int, found:bool` | inspecteursloep |
| `"leaf_grow"` | `it:int` | Ukkonen regel (i): alle open bladeren groeien |
| `"firefly"` | `p:int, x:int` | vuurvliegje (p̄, x̄) |
| `"hop"` | `from:int, to:int, x:int` | spring |
| `"link"` | `from:int, to:int` | suffix link vastgehecht |
| `"iteration"` | `i:int, ch:String` | nieuwe parel |
| `"bump"` | `at:int, reason:String` | fysieke weigering |
| `"sap"` | `delta:int` | (ook als signaal sap_changed) |

### 8.7 Zetten per model (exacte dictionaries) en orakel
**Algemeen:** `{"act": String, …}`. `correct_move()` geeft altijd een zet die `apply()` met verdict OK aanvaardt.

**`TtTrie`** (`setup(alpha: TtAlphabet, notation := "{}")`)
| zet | fase | effect / verdict |
|---|---|---|
| `{"act":"move","letter":c}` | WALK | SEED: niet-leeg kind → schuift (naar COMPARE bij een vrucht); leeg → vrucht hangt (kaart klaar). BEE/PRUNE: leeg → `bee_null` (kaart klaar, "niet gevonden"); vrucht → AT_LEAF (BEE) of CUT (PRUNE). Verdict OK als `c == woord[d]`, anders WRONG_LETTER (leeg + SEED: WRONG_KNOP). `ok=false` (`"no_sap"`) kan niet bij move |
| `{"act":"split","j":j}` | COMPARE | `ok=false` als j < d (`before_d`), j ≥ min(\|l\|,\|s\|) (`past_end`), `l_j == s_j` (`same_letter`) of te weinig sap (`no_sap`). OK als j = eerste verschil ≥ d, anders J_LATE. Groeit j − d + 1 toppen |
| `{"act":"same"}` | COMPARE | OK als l = s (niets verandert), anders WRONG_SAME (zaadje weg). Als l = s is "split" onmogelijk (`no_diff`) |
| `{"act":"answer","found":bool}` | AT_LEAF | OK als found == (label == woord), anders WRONG_ANSWER |
| `{"act":"cut","node":id}` | CUT | id moet een top of vrucht op het pad zijn, niet de wortel (`not_on_path`). Correct = het kind (op het pad) van de laatste top met ≥ 2 niet-lege kinderen (of het kind van de wortel). Hoger → CUT_TOO_HIGH (alles eronder valt), lager → CUT_TOO_LOW (dood hout) |
`cursor()`: `{node:int, depth:int, word:String, leaf:int, j_min:int, letter_hint:String}` (letter_hint = `woord[d]`).
Extra: `words() -> PackedStringArray`, `misplaced() -> Array[int]` (vruchten waarvan het pad geen prefix van hun label
is), `dead_wood() -> Array[int]` (interne toppen ≠ wortel zonder vrucht eronder), `delete_auto(word)`.

**`TtPatricia`** (`setup(alpha, notation := "{0|}")`, `load_trie(notation)` laadt een gewone trie als Patricia met
skip 0 voor snoeilevels)
| zet | fase | effect / verdict |
|---|---|---|
| `{"act":"read","pos":p}` | WALK | `ok=false` als p > m (`past_end`). Correct p = next + skip(top). Verkeerd → WRONG_POS (de letter op p bepaalt de knop). Leeg kind: BEE → kaart klaar (niet gevonden); SEED → PICK_LEAF. Vrucht: BEE → AT_LEAF, SEED → COMPARE |
| `{"act":"short"}` | WALK | OK als next + skip > m, anders WRONG_SHORT. BEE → kaart klaar (niet gevonden); SEED → PICK_LEAF |
| `{"act":"pick_leaf","leaf":id}` | PICK_LEAF | `ok=false` als het blad niet onder de huidige top hangt (`not_in_subtree`). Altijd OK → COMPARE |
| `{"act":"split","j":j}` / `{"act":"same"}` | COMPARE | zoals TtTrie (zonder `before_d`: j mag 0 zijn). Na split: ent volgens §3.2 (automatisch) |
| `{"act":"answer","found":bool}` | AT_LEAF | zoals TtTrie; wesp + pluk → de vrucht wordt verwijderd (`stolen`) |
| `{"act":"prune","node":id}` | PRUNING | `ok=false` als de top geen INNER met precies 1 kind is (`branching`). Altijd OK |
| `{"act":"prune_done"}` | PRUNING | OK als er geen unaire toppen meer zijn, anders UNPRUNED. Kaart klaar |
`cursor()`: `{node, next:int, skip:int, read_pos:int, m:int, word, leaf, candidates:Array[int]}`.
Extra: `unary_nodes() -> Array[int]`, `zoek(word) -> Dictionary` (Algoritme 1-spoor:
`{found, steps:[{node, pos, letter}], end:"leaf"|"null"|"short"}`).

**`TtTernary`** (`setup(alpha, notation := "")`; `""` = lege wortel-PACK; `load_trie(notation)` voor omzetlevels)
| zet | fase | effect / verdict |
|---|---|---|
| `{"act":"go","dir":"lo"\|"eq"\|"hi"}` | WALK | correct dir = compare(woord[d], bol.ch). lo/hi naar NULL: SEED → nieuwe bol + vrucht (kaart klaar); BEE → kaart klaar (niet gevonden). eq: naar PACK (d + 1) of vrucht (COMPARE/AT_LEAF). Verkeerd → WRONG_DIR. Een lege PACK krijgt automatisch de eerste bol |
| `split`/`same`/`answer` | COMPARE/AT_LEAF | zoals TtTrie; nieuwe PACKs met één bol; laatste PACK: eerst bol l_j, dan s_j |
| `{"act":"place","letter":c}` | PLACING | `ok=false` als c geen resterende letter van de huidige top is (`no_letter_left`). Altijd OK; de bol wordt via BST-regel geplaatst. Na de laatste letter van de laatste top: kaart klaar |
`cursor()`: `{pack:int, ball:int, depth:int, word, letter_hint, placing_node:int, remaining:PackedStringArray}`.
Extra: `comparisons(words: PackedStringArray) -> int` (som van bezochte bollen bij opzoeken), `balls() -> int`.

**`TtSuffixTree`** (`setup(alpha, text: String, pos_base: int, labels: String = "pointers"|"strings", owners := PackedInt32Array())`)
Een **punt** is `{"node":id, "off":k}`: k = 0 → precies op top `id`; k ≥ 1 → in de boog naar `id`, na k tekens
(1 ≤ k < booglengte).
| zet | fase | effect / verdict |
|---|---|---|
| `{"act":"attach","node":id,"off":k}` | ATTACH | u = string van het punt (lengte l). `ok=false` als l ≥ \|σ_j\| of als het volgende teken op het punt gelijk is aan σ_j[l] (`duplicate_first`). Hecht een blad met label (j + l, n) aan (splits bij k ≥ 1). OK als het punt het echte afwijkpunt is, anders WRONG_POINT. In 4-2 volgt LABEL |
| `{"act":"label","b":b}` | LABEL | OK als b = j + l, anders WRONG_B (het bord wordt (b, n)). `ok=false` als b > n (`past_end`) |
| `{"act":"locate","node":id,"off":k}` / `{"act":"absent"}` | LOCATE | OK als het punt het eindpunt van z is / z niet voorkomt; anders WRONG_POINT / WRONG_ABSENT. Daarna ANSWER (voor where/count/all/owner) of klaar |
| `{"act":"where","pos":p}` | ANSWER | OK als z op p begint, anders WRONG_WHERE. Log bevat `formula: bool` (p == b − l_t) |
| `{"act":"count","n":n}` | ANSWER | OK als n = aantal bladeren onder het punt, anders WRONG_COUNT |
| `{"act":"pick","leaves":Array}` | ANSWER | OK als de set gelijk is aan de bladeren onder het punt, anders WRONG_PICK |
| `{"act":"owner","texts":Array}` | ANSWER | OK als de set gelijk is aan de eigenaars onder het punt, anders WRONG_OWNER |
`cursor()`: `{j:int, suffix:String, point:Dictionary, z:String, q:String}`.
Extra: `point_string(pt) -> String`, `leaves_under(pt) -> Array[int]`, `locate_auto(z) -> Dictionary`
(`{found, node, off, b, e, l_t, pos:int (= b − l_t), leaves:Array[int]}`), `edge_string(id) -> String`,
`path_ok(leaf) -> bool` (padstring == suffix vanaf start), `display_pos(p) -> int` (= p + pos_base).

**`TtUkkonen`** (`setup_text(alpha, text, pos_base)`; bouwt S(1,1) … S(1,n+1) stap voor stap)
| zet | fase | effect / verdict |
|---|---|---|
| `{"act":"hop","node":id}` | U_CANON | `ok=false` + (indien count_bumps) misstap WRONG_HOP als x̄ < booglengte (`short_edge`) of id niet het eind van de boog met eerste teken s[i − x̄ + 1] is (`wrong_edge`) |
| `{"act":"rule","grow":bool}` | U_RULE (of U_CANON als canoniek) | `ok=false` + WRONG_HOP als nog gesprongen moet worden (`not_canonical`); `ok=false` + WRONG_RULE als grow ≠ (teken ontbreekt). Groei: (ii) of (iii) volgens de positie |
| `{"act":"link","node":id}` | U_LINK | `ok=false` + WRONG_LINK als id ≠ doel (`bad_target`) |
| `{"act":"follow","mode":"link"\|"minus"}` | U_FOLLOW | `ok=false` + WRONG_FOLLOW als mode ≠ (p == wortel ? "minus" : "link") |
Fasevolgorde per extensie: U_CANON (zolang x̄ ≥ booglengte) → U_RULE → [U_LINK als een top uit de vorige stap op zijn link
wacht; doel = nieuwe top bij (iii), anders p] → [U_FOLLOW als er gegroeid werd en j ≤ i + 1] → volgende extensie.
Na "zit er al": x̄ := x + 1, volgende iteratie. Na het blad voor σ_{i+1,i+1}: (w, 0), volgende iteratie. Een nieuwe
iteratie emit `iteration` en `leaf_grow` en zet `it`.
`active() -> Dictionary`: `{p:int, x:int, j:int, i:int, it:int, ch:String, pending:int, b_i:int}` (j en i 1-gebaseerd
zoals de notas, plus `j0`, `i0` 0-gebaseerd). `sigmas() -> Array[Dictionary]`: `[{j, leaf:bool, current:bool}]`.
`run_all()` speelt alles met `correct_move()`. `trace() -> Array[Dictionary]`: één record per extensie
`{it, j, rule:"ii"|"iii"|"a"|"b", hops:int, p_before, x_before, link_from, link_to}` (voor tests en de notas-miniatuur).

### 8.8 `TtNotation` (grammatica, bindend voor levels en tests; spaties optioneel)
```
trie      := "{" (LETTER trie_child)* "}"           trie_child := trie | "[" LABEL "]"
patricia  := "{" INT "|" (LETTER pat_child)* "}"    pat_child  := patricia | "[" LABEL "]"
ternary   := "(" LETTER t_side t_eq t_side ")"      t_side := "." | ternary      t_eq := ternary | "[" LABEL "]"
suffix    := "{" (edge)* "}"                        edge := "(" INT "," (INT|"it") ")" ( suffix | "#" INT )
```
Kinderen staan in alfabetvolgorde (bij suffixbomen: op eerste teken van de boog). Getallen in een suffixnotatie
staan in de weergavebasis van de spec (`pos_base`); `TtNotation.parse_suffix(s, pos_base)` zet ze om naar 0-gebaseerd.
```gdscript
class_name TtNotation
static func normalize(s: String) -> String                 # spaties weg
static func parse_trie(s: String) -> Dictionary            # {"kids": {letter: sub}} of {"leaf": label}
static func parse_patricia(s: String) -> Dictionary        # + "skip"
static func parse_ternary(s: String) -> Dictionary         # {"ch","lo","eq","hi"} of {"leaf"}
static func parse_suffix(s: String, pos_base: int) -> Dictionary  # {"edges":[{b,e,child|leaf_start}]}
```

### 8.9 Kaarten, levels, director, Bloei, scoring, opslag, layout
```gdscript
class_name TtCard extends RefCounted
var id: int; var kind: int                  # TtCodes.CardKind
var word: String = ""                       # SEED/BEE/PRUNE; ASK: de zoekstring z
var wasp: bool = false                      # BEE: afwezig woord in een Patricia-level (wesp)
var q: String = ""                          # ASK: "exists"|"where"|"count"|"all"|"owner"
var j: int = -1                             # SUFFIX: suffix-start (0-gebaseerd)
var t: float = 0.0; var patience: float = 0.0   # SWARM
var state: String = "waiting"               # waiting|active|done|expired
var outcome: Dictionary = {}

class_name TtLevelSpec extends RefCounted
var id: String; var season: String; var title: String; var intro: String; var notes_ref: String
var priority: String                        # "P0"|"P1"|"P2"
var kind: int; var alphabet: String; var start: String     # notatie (of tekst bij SUFFIX/UKKONEN)
var text: String = ""; var pos_base: int = 0; var labels: String = "pointers"; var owners_spec: Array = []   # [{name, from, to}]
var mode: int; var letter_hint: int; var sap_budget: int; var count_bumps: bool = false
var cards: Array[Dictionary]                # [{"kind":"seed","word":"TGG_"}, {"kind":"bee","word":"GA_"}, {"kind":"bee","word":"BBBBBBBBBBBBB_","wasp":true},
                                            #  {"kind":"prune","word":"TA_"}, {"kind":"patricify"}, {"kind":"ternarify"}, {"kind":"beds","beds":[…]},
                                            #  {"kind":"suffix","j":2}, {"kind":"ask","q":"where","z":"cac"}, {"kind":"ukkonen"}]  (+ "t","patience" in SWARM)
var bloom_present: PackedStringArray; var bloom_absent: PackedStringArray
var stars: Array[Dictionary]                # [{"kind":"done"}, {"kind":"no_mistakes"}, {"kind":"no_help"} | {"kind":"sap_le","max":65} | {"kind":"time_le","s":150}
                                            #  | {"kind":"exact_end"} | {"kind":"cmp_le","max":16} | {"kind":"correct_ge","n":5} | {"kind":"max_mistakes","n":2}
                                            #  | {"kind":"combo","n":5,"honey":250} | {"kind":"first_choice"} | {"kind":"missed_le","n":2} | {"kind":"avg_time_le","s":10}]
var expect_end: String                      # notatie van de optimale eindboom
var optimum: Dictionary                     # {sap, comparisons, time_par}
var ghost: Dictionary = {}                  # vergelijkingsgeest: {"label":"gewone trie","sap":48}
var hints_allowed: bool = true; var tutorial: Array[Dictionary] = []   # [{"trigger":"first_compare","ghost":{"act":"split","j":1},"text":"…"}]
var timeline: Array[Dictionary] = []        # 4-4: [{"after_card":3,"event":"badges"}]
var generator: Dictionary = {}              # vrije tuin (§5.7)

class_name TtLevels
static func ids() -> PackedStringArray                      # campagnevolgorde: "1-1" … "5-3"
static func get_spec(id: String) -> TtLevelSpec
static func endless() -> TtLevelSpec
static func make_model(spec: TtLevelSpec) -> TtTreeModel    # juiste subklasse, start geladen
static func optimum(spec: TtLevelSpec) -> Dictionary        # speelt alle kaarten met correct_move(): {sap, comparisons, end}

class_name TtDirector extends RefCounted
signal card_queued(card: TtCard)            # verschijnt in de windrij
signal card_started(card: TtCard)
signal card_expired(card: TtCard, reason: String)   # "patience" | "blown" (4e zaadje) | "no_sap"
signal bloom_started(results: Array)
signal level_finished(report: Dictionary)
var spec: TtLevelSpec; var model: TtTreeModel; var scoring: TtScoring
var time: float; var finished: bool
func start(s: TtLevelSpec) -> void
func tick(dt: float) -> void                # SWARM: klok, geduld; CALM: no-op behalve tijd
func queue() -> Array[TtCard]               # komende kaarten (windrij)
func waiting() -> Array[TtCard]             # SWARM: aangekomen, nog niet gestart
func next_card() -> TtCard                  # CALM: start de volgende; SWARM: start de oudste wachtende
func take(card_id: int) -> void             # SWARM: kies welke wachtende kaart
func hint() -> Dictionary                   # model.correct_move() + log HINT
func rewind() -> bool                       # CALM: herstelt de snapshot van vóór de laatste kaart; log REWIND
func run_bloom() -> Array[Dictionary]       # TtBloom.run(...) en emit bloom_started
func finish() -> Dictionary                 # rapport (TtScoring.final_report)

class_name TtBloom
static func run(model: TtTreeModel, present: PackedStringArray, absent: PackedStringArray) -> Array[Dictionary]
	# [{word, expected:bool, found:bool, ok:bool, path:Array[int], end:int, reason:String, cause_seq:int}]
	# Suffix/Ukkonen: voor elk suffix j: ok = locate(σ_j) eindigt exact in een blad met start j.

class_name TtScoring extends RefCounted
signal honey_changed(total: int, delta: int, reason: String)
signal combo_changed(combo: int)
signal bee_dance()
var honey: int; var combo: int
func bind(director: TtDirector) -> void     # luistert naar model.event_logged en director-signalen
func tick_real(dt: float) -> void           # combo-timeout (6 s)
func final_report(director: TtDirector) -> Dictionary
	# {stars:[bool,bool,bool], star_labels:[String,String,String], honey:int, breakdown:[{label,amount}],
	#  sap_used, sap_optimum, sap_budget, ghost, comparisons, comparisons_opt, bloom:Array, mistakes:Array[Dictionary],
	#  time_s, hints:int, rewinds:int, end_exact:bool}

class_name TtSave
static func load_data() -> Dictionary       # {version:1, stars:{"1-1":3}, best:{"1-1":honey}, highscores:[{name,score,date}], settings:{…}}
static func save_data(d: Dictionary) -> void
static func set_stars(id: String, n: int) -> void           # houdt het maximum
static func add_highscore(score: int, name: String, date: String) -> int   # rang (1..10) of 0
static func setting(k: String, default_value) -> Variant
static func set_setting(k: String, v) -> void

class_name TtLayout
static func compute(render_nodes: Array[Dictionary], kind: int, rect: Rect2, root_bottom := true) -> Dictionary
	# id -> Vector2 (centrum van top/vrucht/bol). Tidy tree (Reingold–Tilford), kinderen in alfabetvolgorde
	# links→rechts; PACK-bollen als lokaal BST-cluster; vruchten op hun eigen diepte. Deterministisch.

class_name TtWordGen extends RefCounted
func _init(seed_: int, alpha: TtAlphabet) -> void
func next_word(existing: PackedStringArray) -> String
```

### 8.10 `TtEventLog`
```gdscript
class_name TtEventLog extends RefCounted
var entries: Array[Dictionary]
	# {seq:int, t:float, card:int, type:String, data:Dictionary, verdict:int, hint:Dictionary (correct_move vóór de zet),
	#  before:Dictionary (snapshot; enkel bij verdict != OK en bij de eerste zet van elke kaart)}
func add(type: String, data: Dictionary, verdict: int, hint: Dictionary, before: Dictionary) -> Dictionary
func mistakes(count_bumps := false) -> Array[Dictionary]
func cause_of_word(word: String) -> Dictionary    # het event waar de vrucht van dit woord misplaatst/gestolen/weggeknipt werd, of {}
func coach_line(entry: Dictionary) -> String      # §6.5
func notes_ref(entry: Dictionary) -> String       # bv. "notas p. 27 · toevoegen"
```
Types: `CARD_START MOVE SPLIT SAME ANSWER CUT READ SHORT PICK PRUNE PRUNE_DONE GO PLACE ATTACH LABEL LOCATE ABSENT
WHERE COUNT PICKSET OWNER BED ITERATION HOP RULE LINK FOLLOW BUMP HINT REWIND CARD_END EXPIRE BLOOM LEVEL_END`.

### 8.11 Gameplay-zijde (ter info, niet bindend)
`games/trietuin/scripts/game/`: `tt_title.gd`, `tt_season_map.gd`, `tt_garden.gd` (hoofdscène: bouwt nodes in `_ready`,
één scène voor alle levels, `--level=1-2` als commandoregelargument voor QA), `tt_tree_view.gd` (tekent uit
`render_nodes()` + `TtLayout`, speelt `changed(fx)`-wachtrij af), `tt_workbench.gd` (lint, vergelijkingslint, hoplint,
vraagkaart), `tt_string_view.gd` (slinger + σ-rij + mist), `tt_hud.gd`, `tt_report.gd` (herbeleving met een tweede
read-only model), `tt_notes_view.gd` (notas-weergave), `tt_cheat_sheet.gd`, `tt_bot.gd` (speelt via `correct_move()`,
optioneel met foutmodi voor QA). Bestaande autoloads `Sfx`, `Juice`, `Transition` gebruiken, niet wijzigen.

---

## 9. Testgevallen die de core móét halen (`games/trietuin/tests/run_tests.gd`)

Alle verwachte waarden komen uit de referentiesimulator (zie de inleiding). Notaties volgens §8.8. "bot" = kaart afspelen met
`correct_move()`. Elke test controleert ook `invariants().is_empty()` na elke zet.

**Gewone trie**
- **T01 Figuur 13 laden/serialiseren:** `load_notation(F13)` met
  `F13 = {A{A[AAGTT_] C[ACGT_]} T{A{_[TA_]} G{C{G[TGCGAAA_]} G[TGG_]}}}` → `serialize() == F13`, 6 interne toppen,
  `sap_used() == 30`.
- **T02 Figuur 14 = Figuur 13 + `AAGCGA_`:** bot-invoeging geeft
  `{A{A{G{C[AAGCGA_] T[AAGTT_]}} C[ACGT_]} T{A{_[TA_]} G{C{G[TGCGAAA_]} G[TGG_]}}}` (8 toppen). De correcte `split`-zet
  heeft j = 3 bij d = 2 en er groeien precies 2 toppen.
- **T03 Oef. 17a:** + `TGCGAAG_` → j = 6, d = 4, 3 nieuwe toppen →
  `{A{A{G{C[AAGCGA_] T[AAGTT_]}} C[ACGT_]} T{A{_[TA_]} G{C{G{A{A{A[TGCGAAA_] G[TGCGAAG_]}}}} G[TGG_]}}}` (11 toppen).
- **T04 Oef. 17b:** verwijder `TA_` → correcte `cut` = top `TA` (kind van T op het pad) →
  `{A{A{G{C[AAGCGA_] T[AAGTT_]}} C[ACGT_]} T{G{C{G{A{A{A[TGCGAAA_] G[TGCGAAG_]}}}} G[TGG_]}}}` (10 toppen, 50 sap).
  `cut` op T → CUT_TOO_HIGH en `TGG_`, `TGCGAAA_`, `TGCGAAG_` vallen mee. `cut` op de vrucht → CUT_TOO_LOW,
  `dead_wood() == [id van TA]`.
- **T05 opzoeken in T04-boom:** `ACGT_`, `TGCGAAG_`, `TGCGAAA_`, `TGG_`, `AAGCGA_` gevonden; `TA_`, `AAGC_`, `GA_`
  niet (`GA_` en `TA_` eindigen op een lege knop, `AAGC_` op vrucht `AAGCGA_` ≠).
- **T06 level 1-1 bot:** eindboom `{A{A[AAGTT_] C[ACGT_]} T{A[TA_] G{C[TGCGAAA_] G[TGG_]}}}`, 4 toppen; j-waarden 1, 1, 2.
- **T07 level 1-3 bot:** eindboom zoals §5.2 (13 toppen, 65 sap); `GATTAGA_` groeit 5 toppen; `GATC_` hangt aan een lege
  knop op d = 3.
- **T08 foutpaden trie:** `split` met `l_j == s_j` → `ok=false` (`same_letter`), staat ongewijzigd. `split` met j te
  laat (in 1-3: `ACGTTT_` bij vrucht `ACGTACGT_` met j = 5 i.p.v. 4; `l_5 = C ≠ s_5 = T`) → J_LATE, `misplaced()` bevat `ACGTACGT_`, 1 top (5 sap) extra.
  `same` bij verschillende woorden → WRONG_SAME, woord ontbreekt in `words()`.
- **T09 Figuur 15/16/17 vanaf leeg bouwen:** de woorden van Fig. 15 en Fig. 17 (in eender welke volgorde) geven exact
  de gewone figuren (§5.3); de woorden van Fig. 16 geven `{C{A[CA_] G[CGGA_]} G[GGGG_] T{A[TAC_] C[TCCA_]}}` (één top
  minder dan de figuur, zie §11 vraag 4).

**Patricia**
- **T10 Figuur 15 snoeien:** gewone Fig. 15 → `unary_nodes()` = {C, CG, GG}; na snoeien (elke volgorde)
  `{0|C{2|C{0|C[CGCCCT_] T[CGCCTT_]} G[CGCGAA_]} G{0|A[GA_] G{1|C[GGCC_] G[GGCGG_]}}}`, 5 toppen, 30 sap.
- **T11 Algoritme 1-sporen (Fig. 15P):** `zoek` geeft exact de leesposities uit §5.3 level 2-1, incl. `CA_` → `short`
  (next 1 + skip 2 > m 2) en `GGC_` → `null` op pos 3.
- **T12 BBBB (p. 29):** in `{5|B{5|B[AAAAABAAAAABC_] C[AAAAABAAAAAC_]} C[AAAAACA_]}` leest `BBBBBBBBBBBBB_` posities 5 en
  11 en eindigt in vrucht `AAAAABAAAAABC_` → niet gevonden. Gewone vorm van dezelfde 3 woorden: 12 toppen.
- **T13 Patricia-invoegen (level 2-3):** vanuit Fig. 15P: `GT_` (j 1, ent op knop), `CGTA_` (j 2, nieuwe top skip 1, oude
  top skip 0), `GGCGT_` (j 4, nieuwe top skip 0 op bladtak), `C_` (short, j 1) → eindboom zoals §5.3, 8 toppen.
- **T14 Patricia-invoegen = snoeien(gewone trie):** 500 willekeurige woordensets over {A,C,G,T} (lengte 1–6 + `_`):
  start met de eerste 2 woorden, voeg de rest toe met de bot; na elke invoeging is `serialize()` gelijk aan
  `TtReference.patricia_of(trie_of(woorden tot nu))`.
- **T15 Figuur 17 snoeien (Oef. 19a):** → `{0|C{1|A{1|C[CGACCC_] T[CGACTAA_]} T[CGTAAT_]} G{1|A[GGA_] C{1|A[GGCGAA_] T[GGCGTA_]} G{0|G[GGGGG_] T[GGGTTT_]} T[GGTT_]}}`.
- **T16 wesp:** 2-2, `answer(found=true)` bij de wesp → verdict WRONG_ANSWER, de vrucht `AAAAABAAAAABC_` is weg, en de
  laatste bestelling van dat woord eindigt op een lege knop; `cause_of_word("AAAAABAAAAABC_")` wijst naar de diefstal.

**Ternary**
- **T17 Figuur 16 via invoegen** (volgorde `GGGG_ CGGA_ CA_ TAC_ TCCA_`):
  `(G (C . (G (A . [CA_] .) [CGGA_] .) .) [GGGG_] (T . (A . [TAC_] (C . [TCCA_] .)) .))`, 7 bollen.
- **T18 Figuur 16 via omzetten** (plantvolgorde wortel G, C, T; C: G, A; G: G; T: A, C) =
  `(G (C . (G (A . [CA_] .) [CGGA_] .) .) (G . [GGGG_] .) (T . (A . [TAC_] (C . [TCCA_] .)) .))`, 8 bollen, 24 sap,
  `comparisons([CA_, CGGA_, GGGG_, TAC_, TCCA_]) == 16`. Met wortelvolgorde C, G, T: 17; met C, T, G: 16.
- **T19 level 3-2 bot:** eindboom zoals §5.4 (18 bollen, 54 sap); `bijen_` splitst op j = 3 met bol `_` als wortel en `e`
  als kleiner-kind. Gewone trie van dezelfde woorden: 7 toppen (× 27 = 189).
- **T20 Figuur 17 omzetten:** minimale `comparisons` (9 woorden) = 49 met een optimale volgorde; 18 bollen.
- **T21 ASCII:** `TtAlphabet.cost_size = 256` → gewone Fig. 16 kost 1024; ternary blijft 24.

**Suffixbomen**
- **T22 Figuur 18/19 (naïef, 0-gebaseerd):** de bot hecht de suffixen van `acacacgt_` aan met de afwijkpunten uit §5.5 →
  `{(0,1){(2,3){(4,8)#0 (6,8)#2} (6,8)#4} (1,1){(2,3){(4,8)#1 (6,8)#3} (6,8)#5} (6,8)#6 (7,8)#7 (8,8)#8}`;
  5 interne toppen (incl. wortel), 9 bladeren, ≤ 2n − 1. Juiste b per suffix: 0, 1, 6, 6, 6, 6, 6, 7, 8.
- **T23 Figuur 19 zoals getekend is ook laadbaar:** `{(0,1){(0,1){(4,8)#0 (6,8)#2} (6,8)#4} (1,1){(0,1){(4,8)#1 (6,8)#3} (6,8)#5} (6,8)#6 (7,8)#7 (8,8)#8}`
  laadt zonder invariantfout (elke boog spelt de juiste string), maar `locate_auto("cac").pos` geeft daar −1
  (b − l_t = 0 − 1). In de boom van T22 is het 1. Dit legt §11 vraag 1 vast.
- **T24 §3.3-vragen (T22-boom):** `locate_auto`: `cac` → b 2, l_t 1, pos 1, leaves {1,3}; `ac` → pos 0, leaves
  {0,2,4}; `acg` → (6,8), l_t 2, pos 4; `caca` → (4,8), l_t 3, pos 1; `cat`, `ccc` → niet gevonden; `a` → leaves {0,2,4};
  `c` → {1,3,5}.
- **T25 Mist-tekst `gcatcgcatgcatcga_`:** naïef = Ukkonen = de notatie van §5.5 (4-4), 13 interne toppen; `cat` pos 1
  (leaves {1,6,10}), `gcat` 3 bladeren, `atg` pos 7, `tcg` 2 bladeren {3,12}, `cga` pos 13, `catc` {1,10}, `ttt`
  niet gevonden.
- **T26 Veralgemeend `gatcga1tcgatt2atcgg3`:** 12 interne toppen; eigenaars: `gatt` {2}, `tcgg` {3}, `cga` {1,2},
  `atc` {1,3}, `cgat` {2}, `ggg` niet gevonden.

**Ukkonen** (sporen = `trace()`; regels en (p, x) zoals de notas, j/i 1-gebaseerd)
- **T27 `abacabc_` (p. 43–48)**, extensies in volgorde (it, j, regel, sprongen, p vóór de regel, x):
  (1,1,ii,0,w,0) (2,2,ii,0,w,0) (3,3,a,0,w,0) (4,3,iii,0,w,1) (4,4,ii,0,w,0) (5,5,a,0,w,0) (6,5,a,1,[a],0)
  (7,5,iii,0,[a],1) (7,6,iii,0,w,1) (7,7,a,0,w,0) (8,7,iii,0,w,1) (8,8,ii,0,w,0).
  De dikke pijl (x̄ na de laatste stap van elke iteratie) is: it1 0, it2 0, it3 1, it4 0, it5 1, it6 1 (na sprong 0),
  it7 1, it8 0, zoals de tekeningen. Suffix links: [a]→w (gezet in it 4), [ab]→[b] (it 7), [b]→w (it 7), [c]→w (it 8).
  Eindboom (1-gebaseerd): `{(1,1){(2,2){(3,8)#1 (7,8)#5} (4,8)#3} (2,2){(3,8)#2 (7,8)#6} (4,4){(5,8)#4 (8,8)#7} (8,8)#8}`.
  Tussenboom na it 4 (labels met `it`): `{(1,1){(2,it)#1 (4,it)#3} (2,it)#2 (4,it)#4}`.
- **T28 Oef. 27 `aabbabc_`:** (1,1,ii,0,w,0) (2,2,a,0,w,0) (3,2,iii,0,w,1) (3,3,ii,0,w,0) (4,4,a,0,w,0) (5,4,iii,0,w,1)
  (5,5,a,0,w,0) (6,5,a,1,[a],0) (7,5,iii,0,[a],1) (7,6,ii,1,[b],0) (7,7,ii,0,w,0) (8,8,ii,0,w,0).
  Eindboom `{(1,1){(2,8)#1 (3,3){(4,8)#2 (7,8)#5}} (3,3){(5,8)#4 (4,8)#3 (7,8)#6} (7,8)#7 (8,8)#8}`; links [a]→w, [b]→w,
  [ab]→[b].
- **T29 `acacacgt_`:** it 3 (a), it 4–6 (b) met x 1, 2, 3; it 7: iii met x 4, 3, 2, 1, daarna ii; it 8, 9 ii. Links
  [acac]→[cac]→[ac]→[c]→w. Eindboom (0-gebaseerd) == T22.
- **T30 Ukkonen = naïef:** voor alle teksten over {a,c} van lengte 1..7 + `_` (254 teksten) geeft `run_all()` dezelfde
  `serialize()` als de naïeve opbouw van T22.
- **T31 Ukkonen-weigeringen:** in 5-1, it 6 vóór de sprong: `rule` → `ok=false` (`not_canonical`), WRONG_HOP gelogd.
  In it 7 na de eerste groei: `follow mode=minus` → `ok=false`, WRONG_FOLLOW. In it 7 bij de link: `link` naar de wortel
  → `ok=false`, WRONG_LINK. Staat telkens ongewijzigd (snapshot gelijk).

**Algemeen**
- **T32 snapshot:** voor elk level: na elke bot-zet is `snapshot() → restore() → snapshot()` identiek (ook midden in
  een kaart en midden in een Ukkonen-iteratie).
- **T33 elke level met de bot:** 3 sterren, `sap_used() == optimum.sap`, eindboom == `expect_end`, Bloei 100 %.
- **T34 orakel-consistentie:** voor elke fase van elk model wordt `correct_move()` door `apply()` aanvaard met verdict OK.
- **T35 sap:** level 1-2: piek 55, eind 50; 2-1: 48 → 30; 4-1: 80; 4-2: 44; 3-4 bed A: array 45 / ternary 54; bed B:
  array 189 / ternary 54.
- **T36 layout:** `TtLayout.compute` is deterministisch, geen overlappende vruchten in alle `expect_end`-bomen op
  1920×(860−220) px.

---

## 10. Scope & prioriteiten

**P0 (MVP: zonder dit is de game niet af):**
- Core volledig voor trie, Patricia, ternary, suffixboom (aanhechten + inspecteur + veralgemeend) en Ukkonen (§8),
  tests T01–T36.
- Levels **1-1, 1-2, 1-3, 2-1, 2-2, 2-3, 2-4, 3-1, 3-2, 4-1, 4-2, 4-3, 4-4, 4-5, 5-1, 5-2** + vrije tuin.
- Schermen: titel (met hub-terugweg), seizoenkaart, tuin, Bloei, terugblik (sterren, honing, sap, Bloeirij,
  misstappen-tijdlijn met herbeleving + coachzin), pauze, instellingen, Notas-spiekbriefje, opslag (sterren, highscore,
  instellingen).
- Besturing muis + toetsenbord (§4.1), hint, terugspoelen, leeshulp-niveaus.
- Juice 1–12, 14–18, 20, 22–24, 26–28, 31–36 (minstens 30 van de 38); audio: alle cues uit §7.2 (procedureel mag),
  één muzieklus per seizoen + finale.
- Notas-weergave voor trie/Patricia/suffixboom.

**P1 (sterk gewenst):**
- Levels 1-4 (zoemavond), 3-4 (Oef. 20), 5-3 (Figuur 18 herboren).
- Combo/Bijendans, ASCII-storm in volle glorie (juice 25), mist-shader (29), Ukkonen-melodie, notas-miniaturen in 5-1,
  notas-weergave voor ternary, attract-boom op het titelscherm.

**P2 (polish / als er tijd is):**
- Level 3-3 (Oef. 19b) en de Oef. 19c-bonus; "Zomerkoorts" (Patricia-vrije tuin); Oef. 18-bonus (bitboom {0,1} vs.
  ASCII); kleurenblind-palet; dag/nacht in de tuin; verzamelbare "notasbladzijden".

**Bewust NIET:** §3.4 exact string matching en §3.5 editeerafstand (aparte game), suffix arrays (Oef. 31), de "echte"
veralgemeende suffixboom (Oef. 30b), verwijderen uit Patricia/ternary, online leaderboards.

**Bouwvolgorde (voorstel voor parallel werk):** (1) core: `TtAlphabet/TtNode/TtNotation/TtTrie` + T01–T09 ∥ front-end:
tuin-scène met `TtTrie` en levels 1-1/1-2 (boom tekenen, lint, vergelijkingslint, bijen). (2) Patricia + 2-x ∥ terugblik +
seizoenkaart. (3) Ternary + suffixboom ∥ rankknopen, slinger, inspecteur. (4) Ukkonen ∥ vuurvliegje, σ-rij. (5) QA-ronde.

---

## 11. Open vragen voor de lead

1. **Figuur 19 vs. Ukkonen-labels.** Figuur 19 labelt de interne bogen `ac`→`ac` en `c`→`ac` met `(0,1)`. Volgens de
   regel van p. 48 ("beginlabel b zodat op positie b − l_t een deelstring begint die met s_t begint en met de nieuwe
   boog doorgaat; beginlabel wordt nooit gewijzigd, boog hooguit onderverdeeld") en volgens onze simulatie van
   Ukkonen (en van de naïeve opbouw) is dat **(2,3)**. Met (0,1) geeft b − l_t voor `cac` de positie −1. Het spel
   gebruikt (2,3), accepteert Figuur 19 als geldige boom (T23) en toont het verschil als "wist je dat" in 4-2 en 5-3.
   Akkoord?
2. **0- vs. 1-gebaseerd.** Beslissing in §3.4.4: per level `pos_base`, met een zichtbaar plaatje op de slinger (0 voor
   Fig. 18/19 en de winterlevels, 1 voor het Ukkonen-voorbeeld en Oef. 27). Liever overal 1 (Definitie 3, §3.3)?
3. **Ternary-details die de notas niet vastleggen:** (a) de volgorde van `_` t.o.v. de letters (wij: achteraan, zoals de
   knoppenrijen `A C G T _`; in ASCII komt `_` vóór `a`–`z`); (b) bij een split in een ternary trie wordt eerst `l_j`
   en dan `s_j` geplant (volgorde k_{l_j}, k_{s_j} uit p. 27). Dit reproduceert Figuur 16, maar de notas zeggen het
   niet expliciet.
4. **Niet-minimale figuren.** Figuur 13 (`TA_` onder een extra top `TA`, en de top `TGC` met één kind) en Figuur 16 (top
   `G` met enkel `GGGG_`) zijn geldige tries volgens Definitie 1, maar ontstaan niet door de toevoegregel vanuit een lege
   boom (wel bv. na verwijderen). Het spel laadt ze exact. Level 1-1 bouwt dezelfde 5 woorden als Fig. 13 vanaf leeg
   (4 toppen) en zegt dat expliciet. OK?
5. **Sapmodel.** We tellen pointers: gewone top \|A\|, Patricia \|A\| + 1 (skip), ternary-bol 3 (de sleutel van 1 teken
   telt niet), vruchten 0, suffixlabels 1/teken of 2 per (b,e). Dat is een didactische vereenvoudiging (pointers 64
   bit, tekens 8 bit, notas p. 28). Volstaat dat?
6. **Verwijderen tot een lege wortel** ("vervang je die door een blad dat de lege string voorstelt", p. 27) komt in
   geen enkel level voor. De core implementeert het niet (een lege wortel blijft een lege top). OK?
7. **Oef. 20-antwoord.** In 3-4 is "array" goed bij \|A\| = 5 en gemiddeld 2 kinderen (5 tegen 2 × 3 pointers). Met de
   sleutel erbij (2 × 3 pointers + 2 tekens) blijft het antwoord hetzelfde. Klopt dit met de bedoeling van de oefening?
8. **Patricia-invoegen** volgt het idee van p. 29 ("eerst een string vinden om de tekens die je hebt overgeslaan te
   reconstrueren"). Onze precieze procedure (§3.2) laat bij een lege knop of "te kort" **eender welk blad onder de
   huidige top** kiezen: alle bladeren daaronder geven dezelfde j. Dit is geverifieerd tegen "gewone trie bouwen en
   snoeien". Mag "te kort" bij invoegen zo behandeld worden?
9. **Veralgemeende suffixboom:** wij gebruiken de "onechte" variant (teksten aan elkaar met `_1 _2 _3`, p. 49), met
   eigenaar = tekst waarin het suffix begint. Bladbogen worden visueel afgekapt na het eerste afsluitteken (Oef. 30a). De
   echte variant (Oef. 30b) zit niet in het spel.
10. **Oef. 28a** ("Is b − l_t altijd de eerste positie?"). In al onze simulaties (alle {a,c}-teksten t.e.m. lengte 7 en
    de leveltekst) gaf b − l_t met Ukkonen-labels **altijd** het eerste voorkomen. De reden: bladeren worden in stijgende j
    aangemaakt en een boog behoudt de b van zijn eerste blad. Het spel beweert dit nergens als feit en aanvaardt bij
    "Waar?" elk voorkomen. Wil de lead het als ontdekking in 4-3/4-4 (inspecteur: "Waar komt het **eerst** voor?")?
11. **Ukkonen-fouten worden geweigerd** in plaats van uitgespeeld (§3.5). Dat wijkt af van pijler 2, omdat een ongeldige
    deelstringboom onbegrijpelijke vervolgstappen geeft. De wereld toont wel lokaal waarom de keuze niet kan, en elke
    weigering telt als misstap. Akkoord?
12. **Patricia-wortel met skip > 0** (level 2-2, nodig voor het letterlijke AAAAABAAAAABC_-voorbeeld). Algoritme 1
    behandelt de wortel als elke andere top (`top.skip`). De figuren tonen enkel wortels met skip 0. OK?
13. **Volgorde link/blad bij Ukkonen.** De notas leggen in it = 4 eerst de suffix link en maken dan het blad voor σ4,4
    (p. 45). In het spel kiest de speler eerst de regel en hecht dan de link. Het resultaat is identiek; enkel de
    volgorde van de handelingen verschilt. Akkoord?

---

## Samenvatting voor het team
- **Kern:** een boom die je zelf laat groeien. Elke knop is een pointer (sap!) en elke vrucht een blad. Bijen zijn
  opzoekingen, wespen zijn afwezige woorden die tot een blad geraken (Patricia). Snoeien/enten = Patricia,
  rankknopen = ternary, slinger + (b,e)-borden + inspecteur = suffixboom en §3.3, vuurvliegje + suffix-linkranken =
  Ukkonen.
- **Levels:** Lente 1-1 Eerste kiem · 1-2 Fig. 13→14 + Oef. 17 · 1-3 Lange wortels · 1-4 Zoemavond | Zomer 2-1 Fig. 15
  snoeien · 2-2 Wespenbedrog (AAAAABAAAAABC_) · 2-3 Enten · 2-4 Oef. 19a | Herfst 3-1 Fig. 16 + ASCII-storm ·
  3-2 Woordenrank · 3-3 Oef. 19b · 3-4 Oef. 20 | Winter 4-1 Fig. 18 · 4-2 Fig. 19 (b,e) · 4-3 Inspecteur (Oef. 28/29) ·
  4-4 Mist (b − l_t) · 4-5 Wiens spoor (veralgemeend) | Finale 5-1 Ukkonen aan het werk (`abacabc_`) · 5-2 Oef. 27 ·
  5-3 Fig. 18 herboren | Vrije tuin "Bijenkoorts".
- **Speler beslist** telkens de algoritmische stap (letter/knop, j, leespositie, kleiner/gelijk/groter, afwijkpunt, b,
  loep, regel, sprong, link, volg). **Automatisch:** wat daar deterministisch uit volgt (pad groeien, ent, skips,
  splitsingslabels, regel (i)).
- **Fouten** hebben gevolgen in de tuin (rotte vruchten, dood hout, gestolen vruchten, verkeerde arrestaties). Wat in
  de datastructuur onmogelijk is, is fysiek onmogelijk ("klonk"). Bij Ukkonen worden fouten lokaal geweigerd.
- **Posities:** intern 0; weergave per level 0 (Fig. 18/19, winter) of 1 (Ukkonen-voorbeeld, Oef. 27), met een
  plaatje op de slinger.
