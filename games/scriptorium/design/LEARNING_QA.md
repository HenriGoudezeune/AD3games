# Kortschrift — leerpad-QA door een nieuwe speler (tester + fixer)

Werkwijze: per deel Kijk (`autoplay auto_answer`), Samen (`lesson_demo`: eerst één foute zet per soort, dan juist) en
de Check-vragen (`ScLessons.check_question`, enkele seeds) gespeeld met `lesson_log` + `lesson_shots`; een paar beelden
per deel bekeken. Daarna zelf een examenvraag op een NIEUW voorbeeld opgelost met enkel wat de game toonde, en
gecontroleerd tegen `ScReference` (core) en de lesnotas (p. 81–122).

Vooraf: `tests/sc_lesson_play.gd` (alle 40 lessen, vóór de fixes hieronder): **ok=120 fail=0**.

## Groep 1 — prefixcodes en Huffman (delen 1–5)

### 1. prefix_lezen (Figuur 25)
- **Geleerd:** volg de bits vanaf de wortel (0 links, 1 rechts) tot een blad, schrijf de letter, begin opnieuw.
- **Examenvraag:** code a = 0, b = 10, c = 110, d = 111; lees `1101001110`.
  Antwoord: 110|10|0|111|0 = **cbada**. Controle: `decode_prefix` → cbada ✓.
- **Probleem:** in Kijk stond de inkthand al op het juiste blad terwijl Zeno vroeg "welke letter lees je nu?"
  (het antwoord werd voorgezegd; geldt voor alle voorspelvragen in Kijk). **Fix:** geen inkthand tijdens de vraag
  (`sc_lesson_coach.gd`, `_kijk_step`).
- **Probleem:** in Samen werd na een voorspelvraag de vorige "Goed. …"-zin nog eens herhaald boven de tip.
  **Fix:** de notitie wordt na de vraag gewist (`_ask`).

### 2. prefix_def (Definitie 20)
- **Geleerd:** prefixcode = geen codewoord is het begin van een ander; anders meerdere lezingen (100101 met
  e = 0, n = 1, b = 10: 4 lezingen).
- **Examenvraag:** is {a = 0, b = 10, c = 110, d = 11} een prefixcode? Nee: 11 is het begin van 110.
  Controle: `is_prefix_code` → false ✓.
- **Probleem:** een foute zet zonder herkenbare reden gaf als uitleg enkel "Klem." (onbegrijpelijk). In de demo kwam
  dat doordat de gesimuleerde fout een onbestaande zet was. **Fix:** fallback-uitleg "Dat kan hier niet. Vraag een
  hint (F2) als je vastzit." (`ScLessons.explain_wrong`) en de demo doet nu een echte fout (tegel onder een letter
  die al hangt → "x is het begin van y …").

### 3. duiventil (Oefening 76)
- **Geleerd:** 2^n berichten van n bits, maar 2^n − 1 kortere bitstrings (ε meegeteld): niet alles kan korter.
- **Examenvraag:** kan een algoritme elk bestand van 4 bits korter maken? Nee: 16 berichten, 1+2+4+8 = 15 kortere
  strings. Klopt met Oef. 76 en met de Check-generator (`2^n − 1`).
- Geen problemen (enkel de herhaalde "Goed."-zin, zie deel 1).

### 4. huffman (Algoritme 9, boosdoeer)
- **Geleerd:** bind telkens de twee lichtste; touw = som van de bundels = Σ a(x)·l(x).
- **Examenvraag:** Huffman voor *abracadabra* (a5 b2 r2 c1 d1). c+d=2, b+r=4, (cd)+(br)=6, a+6=11;
  Σ = 2+4+6+11 = **23 bits**; l(a) = 1, de andere 3. Controle: `huffman_cost([5,2,2,1,1])` = 23 ✓.
- **Probleem (bekend punt):** Zeno zei "Bind e (2) en o (3)" maar de bundel heet (oe) (o links = 0, zoals Figuur
  p. 85). Ook "Bind p en (so)" → ((so)p). **Fix:** de verteltekst noemt de twee in de volgorde van de rij (wie eerst
  staat, wordt het linkerkind 0) — nu "Bind o (3) en e (2)" — en de waarom-zin zegt dat erbij.
- Opmerking (niet aangepast): de HUD toont "optimum 22", dus de vraag "hoeveel bits telt de code?" is af te lezen.

### 5. planken (Oefening 85)
- **Geleerd:** plank A gesorteerd, nieuwe bundels achteraan plank B; kies 2× het lichtste van wat vooraan staat.
- **Examenvraag:** abracadabra met twee planken: A = c1 d1 b2 r2 a5. (cd)2 → B; dan b2/(cd)2 gelijk → (cd)+b = 4;
  r2 + 4 = 6; a5 + 6 = 11; touw 23 ✓ (zelfde als deel 4, zoals Oef. 85 belooft).
- **Probleem:** "Bij gelijk gewicht is elke keuze goed (Zeno neemt dan B)" stond bij élke stap, ook zonder gelijk
  gewicht (verwarrend). **Fix:** enkel als de voorkanten van A en B echt even zwaar zijn.

### Badges op de levelkaart (bekend open punt)
- Met een QA-script (voortgang gezet, kaart geopend, muis op een poort) in beeld gebracht: grijs, blauw "1"
  (demo), amber "2" (samen), groen ✓ (begrepen) en de hover-regel "… · leerpad 2: Waarom prefix? (Definitie 20)
  (samen geoefend)" werken. **Fix:** de badges waren klein (cijfer 11 px); nu iets groter (r 11,5, cijfer 14 px).

## Groep 2 — adaptieve Huffman en het interval (delen 6–10)

### 6. fgk_klim (Algoritme 10)
- **Geleerd:** schrijf eerst met de huidige boom; dan vanaf t: t′ = top met hetzelfde gewicht en het hoogste
  nummer, wissel, a(t)+1, naar de ouder. Kijk = exact het s-na-boosdoeer-voorbeeld van p. 91–93 ✓.
- **Examenvraag:** boom na boosdoeer + s, lees nog een **b**. Schrijf 000; t = b[1,1] ↔ d[1,3]; t = [3,7] ↔ o[3,8];
  [6,10] blijft; wortel 11. Resultaat [11,11]([4,9]([2,5](d[1,1] r[1,2]) e[2,6]) [7,10](o[3,7] [4,8](b[2,3] s[2,4]))).
  Controle: `adaptive_update` geeft exact deze boom ✓.

### 7. fgk_nieuw (nng, graag p. 96–98)
- **Geleerd:** nieuw teken = code(nng) + letter ruw; nng wordt ouder o [·,3] met nng [0,1] en het nieuwe blad
  [1,2], andere nummers +2, klimmen vanaf de ouder van o. Alle bomen van graag vergeleken met p. 96–98 ✓.
- **Examenvraag:** codeer *abba*: "a" · 0"b" · 01 (b↔a wissel) · 01 (t′ = ouder: niet wisselen) =
  **"a"0"b"0101**, boom [4,5]([2,3](nng[0,1] a[2,2]) b[2,4]). Controle: `adaptive_encode("abba")` ✓.

### 8. fgk_ouder (Algoritme 11, speciaal geval)
- **Geleerd:** is t′ de ouder van t, dan niet wisselen; enkel a(t)+1 en verder.
- **Examenvraag:** zie de laatste a van *abba* hierboven: t = a[1,2], t′ = [1,3] = ouder → niet wisselen ✓.
- **Probleem:** de Check-vraag ("Wat doe je eerst?") bood als fout antwoord enkel "wissel met nummer 1" (nng) aan:
  de echte valkuil, wisselen met de ouder, stond er niet tussen. **Fix:** de ouder is nu altijd een afleider, en
  toppen met hetzelfde gewicht komen eerst (ook in fgk_klim).

### 9. fgk_lezen (p. 98, Oef. 91)
- **Geleerd:** lees tot een blad; nng → de letter erna is ruw; werk de boom bij zoals de afzender.
- **Examenvraag:** decodeer "a"0"b"0101 (mijn eigen code van deel 7) → a, nng+b, 01 = b, 01 = a: **abba** ✓.
- **Probleem:** de toestandsregel ("zoals op het examen") toonde enkel *gelezen*, niet de rest van de stroom (bij
  prefix_lezen wel). **Fix:** "· rest: 00"a"101101" erbij.

### 10. arit_interval (Algoritme 12)
- **Geleerd:** links += f(s[i])·lengte, lengte ×= p(s[i]); notatie zoals Algoritme 12.
- **Examenvraag (Oef. 93):** p(a)=0,3 p(c)=0,2 p(g)=0,4 p(t)=0,1, tekst *cag*: [0,3; 0,5) → [0,3; 0,36) →
  links = 0,3 + 0,5·0,06 = 0,33, lengte 0,024 → **[0,33; 0,354)**. Controle: `get_interval` ✓.
- Geen problemen.

## Groep 3 — bitstring, aritmetisch decoderen en LZ77 (delen 11–15)

### 11. arit_bits (Algoritme 13)
- **Geleerd:** getal = 0, next = 0,5; 1 als getal + next < up (getal += next, stop zodra getal ≥ low), anders 0;
  next halveert; low = 0 → "0".
- **Examenvraag (Oef. 93, vervolg):** [0,33; 0,354): 0 (0,5 ≥ up), 1 (0,25), 0 (0,375 ≥ up), 1 (0,3125),
  1 (0,34375 ≥ low) → **01011**. Controle: `get_bitstring` → 01011 ✓.

### 12. arit_lezen (decoderen, speld)
- **Geleerd:** r = waarde van de bits; kies telkens het vak [lo, hi) met r (onderrand dicht, bovenrand open), n tekens.
- **Examenvraag:** 01011, n = 3, model a .3 c .2 g .4 t .1: r = 0,34375 → c [0,3; 0,5) → a [0,3; 0,36) →
  g [0,33; 0,354): **cag** ✓ (`arith_decode`).
- **Probleem:** in Samen gaf de gesimuleerde fout opnieuw "Klem."/"Dat kan hier niet" (de demo koos een onbestaand
  vak "#"). **Fix:** de demo kiest nu een onmogelijke zet met een eigen uitleg ("De speld zit niet in dat vak.").

### 13. lz77_zend (Algoritme 14)
- **Geleerd:** raam = laatste G tekens, posities vanaf 0 links; langste match die in het raam begint (mag erbuiten
  eindigen); (p, l, x), verder op k + l + 1. Kijk = banaan-baan van p. 106 ✓.
- **Examenvraag (Oef. 97):** *ananas-kanaal*, G = 8: (0,0,a)(0,0,n)(0,3,s)(0,0,-)(0,0,k)(0,3,a)(0,0,l); bij "anaa"
  is p = 0 en p = 2 even lang. Controle: `lz77_encode` geeft dit (met p = 0) ✓; de werkbank aanvaardt elke even
  lange match.
- **Probleem (fout in de Check):** de Check-vraag maakte afleiders door één p met 1 te verhogen; bij twee even lange
  matches was die "foute" optie óók een juiste codering (dus twee juiste antwoorden, één fout gerekend). **Fix:**
  afleiders worden nu gecontroleerd (`_lz77_valid`: elke stap een langste match, elke positie bij gelijke lengte) en
  enkel echt foute coderingen blijven. Ook vertelt Zeno nu "(even lang vanaf positie q: mag ook)" als er meer
  langste matches zijn — de game zei nergens dat dat mag.

### 14. lz77_lees
- **Geleerd:** bouw hetzelfde raam op; kopieer l letters vanaf p letter per letter (mag in wat je net schrijft), dan x.
- **Examenvraag (Oef. 98):** G = 6: (0,0,e)(0,1,n)(0,0,d)(1,2,b)(0,4,EOF) → **eendenbende**;
  (0,0,b)(0,0,l)(0,0,a)(0,9,EOF) → **blablablabla**. Controle: `lz77_decode` ✓.
- **Probleem:** "Vanzelf: 2 zegels met l = 0" zei niet wélke zegels en letters. **Fix:** "Vanzelf (l = 0, enkel de
  letter): (0, 0, d) → d, (0, 0, b) → b."

### 15. lz77_register (§4.3.1, G = ∞)
- **Geleerd:** zonder raam is de hele tekst het woordenboek; het register (deelstringboom) geeft de langste match.
- **Examenvraag:** *abababc*, G = ∞: (0,0,a)(0,0,b)(0,4,c) (match loopt in zichzelf door). Controle ✓.
- **Probleem:** in Kijk werden register- en drietalzin samengevoegd tot 3–4 zinnen "waarom". **Fix:** max. 2 zinnen
  (registerregel + de eerste zin over het raam).

Muis-QA (`sc_mouse_qa.gd`, standaardset): **ok=202 fail=0**.
