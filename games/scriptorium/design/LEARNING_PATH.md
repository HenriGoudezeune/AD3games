# Kortschrift — leerpad (compressie, lesnotas hoofdstuk 4, p. 81–122)

Methode: `design/LEARNING.md` (per deel **Kijk → Samen → Zelf → Check**). Verteller: **Broeder Zeno** (de mentor van
de game) in een paneel rechts, op de plaats van De Overkant, in de stijl van het scriptorium (perkament, goud).
Alle verteltekst, tips, foutuitleg, voorspel- en Check-antwoorden worden **uit de core berekend** (`ScLessons`: een
proefkopie van het werktuig + `ScReference` = orakel), dus ze kloppen altijd; de getallen hieronder zijn zo
nagerekend (`tests/suites/t_lessons.gd` controleert ze).

Code: `scripts/game/sc_lessons.gd` (delen, specs, verteltekst, toestand, tips, foutuitleg, voorspel- en
Check-vragen), `scripts/game/sc_lesson_coach.gd` (Kijk/Samen op de werkbank), `scripts/game/sc_check_quiz.gd` (Check in
de terugblik), integratie in `sc_workbench.gd` (`_on_request()` vraagt `coach.allow()`), `sc_session.gd` (wachtrij),
`sc_book_map.gd` (badges), `sc_guide.gd` (leerpadpagina's), `sc_review.gd` (knop Check).

## Lesverloop (voor elk deel)

- **Kijk**: Zeno speelt het orakel (`correct_move`) af. Vóór elke stap staat het werktuig stil en wijst Zeno's
  inkthand het element aan; na de stap zegt het paneel **wat** er gebeurde (vetgedrukt) en **waarom** (de regel, grijs,
  max. 2 zinnen), en wat het werktuig daarna **vanzelf** deed. Onderaan de **toestand zoals op het examen** (strook en
  gelezen tekst, gewichten, `[gewicht,nummer]`, `[links, links+lengte)`, `getal · next`, raam en drietallen, `w · k` en
  het woordenboek, het rek, lijst `e` en `c`, de lijst van move-to-front). Knoppen: **Volgende ›** (Spatie/Enter/→),
  **Afspelen/Pauze** (P), **Overslaan** (enkel als al gezien). Bij de codebordknippen vormen alle knippen van één
  lezing samen één stap; bij het register de zoektocht + het drietal.
- **Samen**: de speler speelt met dezelfde muis- en toetsbediening als in het spel. Tip (+ inkthand + ring) bij de
  eerste 2 zetten van elke soort, daarna "Jouw beurt" en enkel op vraag **Hint (F2)**. Een foute zet wordt **niet
  uitgevoerd**: rode uitleg *waarom* (de coachzin van de core + de regel) + "Probeer opnieuw"; na 2 fouten op
  dezelfde stap wijst de inkthand de juiste zet aan. Een zet is goed als een proefzet op een kopie geldig is en het
  oordeel OK geeft (bv. elk geldig lichtste paar, elke juiste spleet); op het codebord moet elke tegel een blad blijven.
- **Zelf**: het gewone level (eerste level van het deel = poort).
- **Check**: voorspelvragen in Kijk/Samen vóór het werktuig het toont (antwoord + uitleg meteen), en in de
  **terugblik** (knop **Check** in het Kapittel, opent vanzelf zolang een deel van dit level nog niet "begrepen" is)
  1–2 vragen op een **nieuw willekeurig voorbeeld** op een examenblad. Fout = uitleg + nieuw voorbeeld (max. 2
  herkansingen).
- **Badge** op de initiaal van de poort in het getijdenboek (rechtsboven): grijs = nog niet, blauw = demo bekeken,
  amber = samen geoefend, groen ✓ = begrepen (Samen + Check juist). Hover: "leerpad k: titel (status)".
- **Eerste keer verplicht**: vóór een level speelt de werkbank eerst Kijk en Samen van elk deel met poort ≤ dat level
  dat nog niet "samen geoefend" is. Daarna overslaanbaar en herbekijkbaar in de gids (**F1 → Doel → Leerpad · deel
  k**: "Bekijk de demo opnieuw" / "Oefen dit opnieuw"; in een level staan de delen van dat level eerst; daarna terug
  naar het level). Bot-modus (`bot=…`), de Nachtwake en `no_lessons` slaan alles over. Voortgang: `ScSave` setting
  `learning` (`nosave`: enkel in het geheugen).

## Delen (volgorde = opbouw)

| # | id | deel | Kijk (voorbeeld) | Samen | Zelf |
|---|----|------|------------------|-------|------|
| 1 | prefix_lezen | Prefixcode lezen: volg de takken tot een blad | Fig. 25: 00010011 | Fig. 25: 0110011 | 0-1 |
| 2 | prefix_def | Waarom prefix? (Definitie 20) | p. 82: e = 0, n = 1, b = 10, strook 100101 | codebord: been (diepte ≤ 2) | 0-2 |
| 3 | duiventil | Geen algoritme comprimeert alles | Oef. 76: 8 duiven van 3 bits | 4 duiven van 2 bits | 0-3 |
| 4 | huffman | Huffman: bind de twee lichtste (Alg. 9) | p. 84–85: boosdoeer | kaaskop | 1-1, 1-2, 1-3, 1-4 |
| 5 | planken | Twee planken (Oef. 85) | boosdoeer met planken A/B | kaaskop met planken | 1-5 |
| 6 | fgk_klim | Adaptieve Huffman: wisselen en klimmen (Lemma 22, Alg. 11) | p. 90–91: [g,o]-boom, nog een s | [g,o]-boom, nog een d | 2-1 |
| 7 | fgk_nieuw | Eerst schrijven, nieuw teken via nng (Alg. 10/11) | p. 96–98: graag | gaga | 2-2, 2-4 |
| 8 | fgk_ouder | Het speciale geval: t′ is de ouder (p. 95) | neen | kaak | 2-3 |
| 9 | fgk_lezen | Adaptief decoderen: de ontvanger | "g"0"r"00"a"101101 | "k"0"a"0101 | 2-5 |
| 10 | arit_interval | Aritmetisch coderen: het interval (Alg. 12) | p. 99–100: yy, model x 0,2 · y 0,7 · z 0,1 | gc, model a 0,3 · c 0,2 · g 0,4 · t 0,1 | 3-1, 3-2, 3-4 |
| 11 | arit_bits | De kortste bitstring (Alg. 13) | xy: [0,04; 0,18) | cg: [0,4; 0,48) | 3-1, 3-2, 3-4 |
| 12 | arit_lezen | Decoderen: in welk vak zit de speld? | speld 0,9, n = 2 | bits 011, n = 2 (acgt) | 3-1, 3-3 |
| 13 | lz77_zend | LZ77: de langste match in het raam (Alg. 14) | p. 106–107: banaan-baan, G = 6 | anna_ananas, G = 4 | 4-1, 4-3, 4-5 |
| 14 | lz77_lees | LZ77 decoderen | p. 108: aanvaardbaar, G = 6 | kaka_kakao, G = 4 | 4-2, 4-4 |
| 15 | lz77_register | Oneindig raam en het register (§4.3.1) | kaka_kakao, G = ∞ | nana_banaan, G = ∞ | 4-6 |
| 16 | lzw_zend | LZW coderen | p. 111–112: banaanaanval | barbara | 5-1, 5-3, 5-5 |
| 17 | lzw_lees | LZW decoderen en de lege lade (p. 112–114) | 97 110 256 258 115 | 97 98 256 258 | 5-2, 5-4 |
| 18 | bwt_zend | Burrows-Wheeler: sorteren, p en de laatste kolom | p. 115–117: geen loon | banaan | 6-1, 6-3, 6-4 |
| 19 | mtf | Move-to-front (p. 121) | p. 121: 1 ngen eool, lijst ( ,1,a,b,e,f,g,n,o,l) | 2 2 2 2 1 0, lijst (a,b,n) | 6-1, 6-2, 6-3 |
| 20 | bwt_terug | BWT terug: de k-de x in e is de k-de x in c | p. 117–119: (1, ngen eool) | (1, nbanaa) | 6-2, 6-4 |

Aanpassing van de volgorde t.o.v. de levels: level 3-1 heeft een zend- én drie ontvangstbrieven, dus de delen 10–12
hebben alle drie poort 3-1; idem 6-1 (BWT + move-to-front) en 6-2 (move-to-front terug + BWT terug). Adaptieve Huffman
krijgt vier delen (klimmen op een bestaande boom → nng en eerst schrijven → het speciale geval → ontvangen), zodat het
speciale geval pas gevraagd wordt na een eigen Kijk. De Codex (C) en de Nachtwake hebben geen eigen deel (herhaling).
Oefening 105 (6-5, P2) blijft neutraal: er wordt niets over gevraagd.

## Per deel: Kijk-verteltekst (sleutelstappen), voorspelvragen, Samen, Check

**1 · Prefixcode lezen** (Fig. 25, p. 82–84). Regel: begin bij de wortel, 0 = links, 1 = rechts; bij een blad schrijf
je de letter en begin je opnieuw bij de wortel. Kijk (o = 00, u = 010, d = 011, f = 10, t = 11; strook 00010011):
"Bits 00 → blad o: schrijf o" (waarom: "0 = links, 1 = rechts. Een letter hangt aan een blad: daar stop je.") …
"Bits 011 → blad d. Gelezen: oud". Voorspel *welke letter lees je nu (rest 010011)?* → **u**. Samen (0110011 → dot):
voorspel *rest 0011* → **o**. Foute zet (klik op een blad waar de bits niet heen gaan): "Daar leiden de bits niet
naartoe." + de regel. Check: lees een nieuwe strook met een nieuwe prefixcode (4 letters, 4–5 tekens).

**2 · Waarom prefix?** (Definitie 20, p. 82–83). Regel: in een prefixcode is geen codewoord het begin van een ander;
in de boom hangen letters enkel aan bladeren. Kijk (e = 0, n = 1, b = 10, strook 100101): één stap per lezing:
"Lezing 1|0|0|1|0|1 = neenen", "1|0|0|10|1 = neebn", "10|0|1|0|1 = benen", "10|0|10|1 = bebn" (waarom: "1 is het begin
van 10: de lezer weet niet waar de letter stopt"), dan "Klaar: 4 lezingen". Voorspel *hoeveel lezingen heeft 100101?*
→ **4**. Samen (codebord, been, diepte ≤ 2): hang b, e, n aan bladeren en verzend (optimum 6 bits, bv. e = 1, b = 00,
n = 01); voorspel *hoeveel bits wordt been met deze code?* → **6**. Fout: tegel op een knoop boven een andere tegel
→ "x = 0 is het begin van y = 01: de lezer weet niet waar de letter stopt." Check: welke van drie codes is een
prefixcode (nieuwe codes, 3–4 letters)?

**3 · Geen algoritme comprimeert alles** (Oef. 76, p. 81). Regel: er zijn 2^n berichten van n bits maar slechts
1 + 2 + … + 2^(n−1) = 2^n − 1 kortere bitstrings; wie een bericht korter maakt, maakt een ander langer. Kijk (3 bits):
"Duif 000 → hok ε", … "Duif 111: alle 7 kortere hokken zijn bezet → zolder (4 bits)", decreet 1 "Elk bericht van 3 bits
kan korter" → **onmogelijk**, decreet 2 "Voor elk bericht bestaat een code die het korter maakt" → **waar**.
Voorspel *hoeveel hokken zijn korter dan 3 bits?* → **7**. Samen (2 bits: 3 kortere hokken ε, 0, 1); voorspel decreet 2 →
**waar**. Check: hoeveel bitstrings zijn korter dan n bits (n = 2…6, het lege woord inbegrepen)? → 2^n − 1.

**4 · Huffman** (Algoritme 9, p. 84–86). Regel: bind telkens de twee bomen met de kleinste frequentie tot één boom; de
nieuwe wortel weegt de som. Touw = som van de gewichten van de bundels = Σ a(x)·l(x) bits (Stelling 21). Kijk
(boosdoeer, b 1 · o 3 · e 2 · s 1 · d 1 · r 1): "Bind b (1) en s (1) → bundel 2. Touw 2" (waarom: "de twee lichtste nu
zijn 1 en 1; bij gelijk gewicht is elke keuze even goed"), d + r, (bs) + (dr), e + o, tot slot 4 + 5: "Touw 22 = 22
bits". Voorspel *welke twee bind je nu (3e binding)?* → **twee van de drie bundels/stapels met gewicht 2**; *hoeveel bits
in totaal?* → **22**. Samen (kaaskop: k 2 · a 2 · s 1 · o 1 · p 1, totaal **16** bits); voorspel 2e binding → **p (1) met
een gewicht 2**. Fout: "De twee lichtste waren 1 en 1, niet 2 en 1." Check: Σ a(x)·l(x) van de Huffman-code voor nieuwe
gewichten (4–5 letters), met de bindingen als uitleg.

**5 · Twee planken** (Oefening 85, p. 88). Regel: plank A = de letters gesorteerd op gewicht, plank B = de bundels in
volgorde van ontstaan; neem telkens vooraan het lichtste (bij gelijk: plank B), de nieuwe bundel gaat achteraan B.
Kijk (boosdoeer): A + A (b, s), A + A (d, r), "B + B: (bs) 2 en (dr) 2 — e weegt ook 2, maar bij gelijk neem je B",
A + A (e, o), B + B. Voorspel *3e binding: welke planken?* → **B en B**. Samen (kaaskop): A + A, **A + B** (p 1, dan
(so) 2 vóór k 2), A + A, B + B; voorspel 2e binding → **A en B**. Check: welke planken bij een gegeven stand (nieuwe
gewichten).

**6 · Adaptieve Huffman: klimmen** (Lemma 22, Algoritme 11, p. 89–93). Regel: na het schrijven klim je vanaf het blad
t: t′ = de top met hetzelfde gewicht en het hoogste ordenummer; is t′ niet t (en niet de ouder), wissel t en t′; dan
a(t) + 1 en t = ouder van t. Kijk ([g,o]-boom van p. 90; nog een s): "Schrijf s met de oude boom: 001", "t = s[1,2]:
t′ = r[1,4] (gewicht 1, hoogste nummer) → wissel", "t = [2,6]: t′ = e[2,7] → wissel", "t = [5,10]: t′ is t zelf →
niet wisselen", wortel + 1. Voorspel *met wie wissel je s[1,2]?* → **r[1,4]**. Samen (nog een d): d[1,3] ↔ r[1,4],
[2,6] ↔ e[2,7], [5,10] blijft; voorspel 2e klim → **e[2,7]**. Fout: "Gewicht 1: r[1,4] staat verder in de processie
(4 > 3). Wissel." Check: met welke top wisselt het blad van x eerst (nieuwe boom, getoond als tabel nummer · gewicht
· teken · ouder)?

**7 · Eerst schrijven, nieuw teken via nng** (Algoritme 10/11, p. 92–98). Regel: schrijf het teken eerst met de boom
vóór de wijziging; een nieuw teken = code(nng) + het teken ruw (8 bits); nng wordt een ouder o met nng [0,1] en het
nieuwe blad [1,2], o krijgt nummer 3, de andere +2. Kijk (graag vanuit de lege boom): "g gaat ruw", "Nieuw teken r:
schrijf code(nng) = 0 en dan r", … uitvoer "g"0"r"00"a"101101. Voorspel *wat schrijf je voor r?* → **0 + r**. Samen
(gaga); voorspel *wat schrijf je voor de tweede g?* → het blad van g. Check: wat schrijft de afzender voor het k-de
teken (nieuwe tekst van 3–4 letters, de boom ervoor als tabel)?

**8 · Het speciale geval** (p. 95). Regel: de broer van nng heeft een ouder met hetzelfde gewicht; is die ouder t′,
dan wissel je niet: a(t) + 1 en verder met de ouder. Kijk (neen): "e[1,2] ↔ n[1,4]", dan bij de tweede n: "t =
n[1,2]: t′ = [1,3] is de ouder van t → niet wisselen (je kan een top niet vervangen door een boom waar hij zelf in
zit)". Voorspel *met wie wissel je n[1,2]?* → **niet wisselen (ouder)**. Samen (kaak): zelfde vraag bij k[1,2]. Check:
nieuwe boom waarin t′ de ouder is (of niet): wissel je, en met wie?

**9 · Adaptief decoderen** (p. 98, Oef. 91). Regel: lees bits tot een blad; is het nng, dan volgt de ruwe letter;
werk daarna de boom bij zoals de afzender. Kijk ("g"0"r"00"a"101101 → graag): lezen + dezelfde wissels. Voorspel *welk
blad lees je met 00?* (na gr) → **nng, dan a**. Samen ("k"0"a"0101 → kaak). Check: welke tekst staat er (nieuwe
stroom van 3–4 letters)?

**10 · Aritmetisch coderen: het interval** (Algoritme 12, p. 98–101). Regel: links += f(s[i])·lengte; lengte ×= p(s[i]).
Kijk (model x 0,2 · y 0,7 · z 0,1; tekst yy): "Knip y: links = 0 + 0,2·1 = 0,2; lengte = 0,7 → [0,2; 0,9)", "Knip y:
links = 0,2 + 0,2·0,7 = 0,34; lengte = 0,49 → [0,34; 0,83)" (zoals p. 100). Voorspel *interval na yy?* → **[0,34;
0,83)**. Samen (acgt-model, gc → [0,62; 0,7)); voorspel → **[0,62; 0,7)**. Check: [low, up) voor een nieuwe tekst van 2
letters.

**11 · De kortste bitstring** (Algoritme 13, p. 100–102). Regel: getal = 0, next = 0,5; als getal + next < up: 1
(getal += next, klaar zodra getal ≥ low), anders 0; next halveert. Kijk (xy: [0,04; 0,18)): "0 + 0,5 < 0,18? nee → 0",
"0 + 0,25 < 0,18? nee → 0", "0 + 0,125 < 0,18 → 1; getal 0,125 ≥ 0,04: klaar. Bits 001". Voorspel *3e bit* → **1**.
Samen (cg: [0,4; 0,48) → **0111**); voorspel 1e bit → **0**. Fout: "0 + 0,5 ≥ 0,48: die stap valt boven het interval.
Schrijf 0." Check: de bitstring voor een nieuw interval.

**12 · Decoderen: de speld** (p. 99–102, Oef. 94/95). Regel: zoek telkens het vak [lo, hi) dat de waarde r bevat;
onderrand dicht, bovenrand open. Kijk (speld 0,9, n = 2): "0,9 zit in z = [0,9; 1), niet in y = [0,2; 0,9)", "binnen
z: x = [0,9; 0,92) → zx". Voorspel *1e vak* → **z**. Samen (acgt, bits 011 = 0,375 → **cc**); voorspel 2e vak → **c**
([0,36; 0,4)). Check: welke tekst van 2 letters hoort bij een nieuwe bitstring.

**13 · LZ77: de langste match** (Algoritme 14, p. 104–107). Regel: het raam = de laatste G tekens, posities vanaf 0
links; zoek de langste match die in het raam begint (ze mag erbuiten eindigen); schrijf (p, l, x) en ga l + 1 verder.
Kijk (banaan-baan, G = 6): (0,0,b) (0,0,a) (0,0,n) "a: langste match a op positie 1, dan a → (1,1,a)", (2,1,-) (0,0,b),
"aan op positie 1 van naan-b, lengte 3, het einde → (1,3,EOF)". Voorspel *laatste drietal* → **(1,3,EOF)**. Samen
(anna_ananas, G = 4: (0,0,a)(0,0,n)(1,1,a)(0,0,_)(2,1,n)(2,3,s)); voorspel 3e match → **(2,3,s)** (de match loopt uit
het raam). Fout: "Vanaf positie 0 loopt de match 1 letter ver, niet 3." Check: de drietallen voor een nieuwe tekst
(8–10 tekens, G = 4 of 6).

**14 · LZ77 decoderen** (p. 108). Regel: bouw hetzelfde raam op; (p, l, x): kopieer l letters vanaf raampositie p,
één voor één, en schrijf x. Kijk (aanvaardbaar, G = 6): (0,1,n): "kopieer a vanaf 0, dan n", (0,2,r): "aa", (1,3,EOF):
"raam vaardb (de laatste 6 van aanvaardb): kopieer 3 letters vanaf positie 1: aar". Voorspel *welke
letters kopieer je bij het laatste zegel?* → **aar**. Samen (kaka_kakao, G = 4); voorspel 2e kopie → **ak**. Check: de
tekst bij nieuwe drietallen.

**15 · Oneindig raam en het register** (§4.3.1, p. 109–110). Regel: met G = ∞ is de hele tekst tot nu het
woordenboek; het register (deelstringboom) vindt de langste match met één blik per letter: O(n) voor de hele tekst.
Kijk (kaka_kakao): "Register: langste match ka op positie 0 → (0,2,_)", "kaka op positie 0 → (0,4,o)". Voorspel 2e
match → **(0,4,o)**. Samen (nana_banaan: … (1,3,a) (0,1,EOF)). Check: drietallen met een oneindig raam.

**16 · LZW coderen** (p. 110–112). Regel: zit wk in het woordenboek, dan w = wk; anders schrijf code(w), voeg wk toe
(volgende code vanaf 256) en w = k. Kijk (banaanaanval): "ba zit niet in de kast: stempel 98; ba = 256; w = a", …
"an zit in de kast: verleng", "ana niet: stempel 257; ana = 260". Voorspel *verleng of stempel?* (w = a, k = n, 2e keer)
→ **verleng**. Samen (barbara → 98 97 114 256 114 97); voorspel bij w = b, k = a → **verleng**. Check: de codes voor een
nieuwe tekst (6–8 tekens, letters a/b).

**17 · LZW decoderen** (p. 112–114). Regel: na elke code voeg je w + eerste letter van het volgende woord toe; is de
code nog niet gekend (lege lade), dan volgend = w + w[0]. Kijk (97 110 256 258 115 → anananas): "256 = an: nieuw 257 =
n + a", "258 is nog leeg: volgend = an + a = ana". Voorspel *258 = ?* → **ana**. Samen (97 98 256 258 → abababa);
voorspel 258 → **aba**. Check: welke tekst hoort bij nieuwe codes (met een lege lade).

**18 · Burrows-Wheeler** (p. 115–117). Regel: vorm alle rotaties, sorteer ze (spatie het kleinst); uitvoer p = de rij
die eindigt op s[0], en de laatste kolom. Kijk (geen loon): elke strook in de juiste spleet, "rij 1 eindigt op g: p =
1 → (1, ngen eool)". Voorspel *p* → **1**. Samen (banaan → (1, nbanaa)); voorspel p → **1**. Check: (p, c) voor een
nieuw woord (4–6 letters).

**19 · Move-to-front** (p. 121). Regel: schrijf de positie van x in de lijst (vanaf 0) en zet x vooraan. Kijk (1 ngen
eool, lijst ( ,1,a,b,e,f,g,n,o,l)) → **1 1 7 7 6 2 3 2 8 0 9**; voorspel 4e getal (g) → **7**. Samen (ontvangen 2 2 2 2 1 0
met lijst (a,b,n) → nbanaa); voorspel 5e letter → **a**. Check: de getallen voor een nieuwe tekst en lijst.

**20 · BWT terug** (p. 117–119). Regel: e = c gesorteerd; na c[i] komt e[i]; de k-de x in e is de k-de x in c. Kijk
((1, ngen eool) → geen loon). Voorspel bij een stap: welke rij in c → de rij met dezelfde letter en rang. Samen
((1, nbanaa) → banaan). Check: de tekst bij een nieuwe (p, c).

## CLI-opties (na `--`; scène `res://games/scriptorium/scenes/workbench.tscn` of de titel)

- `lesson=<id> [phase=kijk|samen]` — speel die les (zonder phase: Kijk en dan Samen); daarna naar `level=` of de kaart
  (met `autoquit`: afsluiten). Id's: zie de tabel (prefix_lezen, prefix_def, …, bwt_terug).
- `reset_learning` — wis de leerpadvoortgang (alles weer "eerste keer": verplicht, niet overslaanbaar).
- `no_lessons` — geen automatische lessen vóór een level (elke `bot=…` en de Nachtwake slaan ze ook over).
- `autoplay` (Kijk speelt zelf af) · `auto_answer` (voorspel- en Check-vragen juist beantwoorden) · `lesson_demo`
  (Samen: gesimuleerde speler, eerst één foute zet per soort, dan juist) · `lesson_log` (`LESSON_STEP`, en wat de speler
  leest: `LESSON_SAY #n …` + `LESSON_STATE …` op stdout) · `lesson_shots=<map>` (screenshot bij elke coachtekst; onder xvfb
  zonder `--write-movie`, veel sneller) · `guide_page=<tab>:<n>` (gids meteen open op die pagina; `guide_page=<n>` werkt
  nog voor de tutorials) · `nosave` (leerpadvoortgang enkel in het geheugen) · `save=qa`.
- Getijdenboek: `-- map=1 check=<level>` opent meteen de Check-vragen van dat level (`check_seed=<n>` voor een vast
  voorbeeld).
- Voorbeeld opname Kijk: `xvfb-run -a -s "-screen 0 1920x1080x24" $G --path . --rendering-driver opengl3
  res://games/scriptorium/scenes/workbench.tscn -- lesson=huffman phase=kijk autoplay auto_answer nosave
  reset_learning autoquit lesson_shots=<map>`.
- Tests: `$G --headless --path . --script res://games/scriptorium/tests/run_tests.gd -- t_lessons` (alle lessen headless
  uitgespeeld, voorspel- en Check-antwoorden nagerekend); muis: `tests/sc_mouse_qa.gd -- save=qa brief=0
  lessons=huffman:samen,…`.
