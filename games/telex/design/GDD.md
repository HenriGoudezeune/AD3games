# Telex — Game Design Document (v1)

Eigenaar: game designer. Lezers: core-engineer (`games/telex/scripts/core/`), gameplay/front-end-engineer
(`games/telex/scripts/game/`, `games/telex/scenes/`), art & audio director (`design/ART.md`), QA.
Bron van de leerstof: lesnotas AD3 2026, **§3.4 Exact string matching** (r. 2628–3655, gedrukte p. 50–69) en **§3.5
Benaderend string matching** (r. 3656–4185, p. 70–80). Pdf-pagina = gedrukte pagina. "r." = regel in het tekstextract
`lesnotas_layout.txt`. **Bij twijfel gaan de notas voor.**

Elke tabel, elke verschuiving, elke hashwaarde, elke lampkolom, elke cel van een editeertabel en elk aantal
vergelijkingen in dit document werd nagerekend met een Python-referentie-implementatie die de pseudocode van de notas
letterlijk volgt (Algoritme 2–8, Definitie 11/13/14/15; staat niet in de repo). Die referentie reproduceert: de tabel
V[] van `barbados` (p. 56) en elke tussenstap van Algoritme 5 (p. 61–62), de mismatchreeks 5, 2, 0, …, 4, 1, …, 8 van het
`barbados`-voorbeeld (p. 58–59), de tabel V_H van `barbara` (p. 65), de matrix M en Figuur 23 (`ana`/`ananas`, p. 67–69),
de tabel `lessen`/`feesten` (p. 76) en de tabel `examen`/`de_armen_vouwen` (p. 79), telkens cijfer voor cijfer.
Algoritme 5 werd bovendien vergeleken met Definitie 11 voor alle 1020 woorden over {a,b} van lengte 2–9 en alle woorden
over {a,b,c} van lengte 2–6: overal gelijk. Twijfels staan in §11.

Stijl (palet, vormen, fonts) bepaalt `ART.md`. Dit document legt enkel **functionele** eisen vast: wat leesbaar moet
zijn, wat beweegt en wanneer, wat de speler beslist.

Inhoud: 1 Pitch & pijlers · 2 Wereld & kernlus · 3 Mapping leerstof (per algoritme: speler/automatisch/fouten) ·
4 Bediening, schermen, HUD · 5 Campagne (alle levels) + Nachtdienst · 6 Scoring, sterren, economie, debrief ·
7 Juice & audio · 8 Interface-contract core ↔ front-end · 9 Testgevallen · 10 Scope & prioriteiten · 11 Open vragen ·
Samenvatting.

---

## 1. Pitch & pijlers

### 1.1 Titel en genre
**Definitieve titel: TELEX** (ondertitel in het spel: *Station Zoeklicht*). Kort, klinkt als het apparaat zelf
(tak-tak-tak-ding), past naast "Hash & Dash" en "Trietuin" op de hubkaart en verraadt het onderwerp: tekst die over een
lint binnenkomt.

**Genre: analoge operator-thriller.** Je bedient zware, tastbare machines in een geheime luisterpost. Elke machine
ís een algoritme uit de notas, en de knoppen, hendels, ponskaarten en schakelaars laten enkel de stappen van dat
algoritme toe. De concept-richting van de lead (inlichtingendienst, lint, één machine per algoritme) blijft. Ik heb ze
op vier punten aangescherpt:
1. **Het lint wacht niet (stroommodel).** De notas motiveren §3.4 met "geschikt voor streams" (p. 50). In het spel
   loopt het lint door een leeskop. Wat voorbij is, verdwijnt in de **versnipperaar**. Wie moet terugspoelen (brute
   kracht), heeft een **lusbak** nodig om lint vast te houden. De Doorloper (KMP) spoelt nooit terug: dat is
   Stelling 12 (p. 59) als fysieke eigenschap, niet als zin.
2. **"Tanden" in plaats van een quiz voor V[].** Een verschuiving die Definitie 11 schendt, past fysiek niet: de tanden
   van het sjabloon haken niet in het al gelezen lint. De kleinste verschuiving die past ís V[j]. Een te grote
   verschuiving past wel, maar kan een codewoord laten ontsnappen.
3. **Tegenzet-missies.** Drie oefeningen uit de notas vragen een *voorbeeld* (Oef. 32: Θ(n²) voor brute kracht; Oef.
   34b: veel hashbotsingen bij Rabin-Karp; Oef. 50: beste en slechtste geval van BMH). Daar wissel je van kant: je
   schrijft zelf het lint dat de machine van de vijand laat vastlopen. Dat is een ontwerppuzzel, geen invuloefening.
4. **Elke machine heeft een eigen ritme.** De Doorloper is een rustige precisiemachine. Het hashwiel klikt modulo q. Het
   lampenbord is een **ritmesectie**: één teken per tel, druk enkel op de letters van z. Het schakelbord is een
   **stroomnet**: de editeerafstand is de weg met de minste weerstand.

Waarom anders dan de vorige games: **Hash & Dash** is een drukke management-arcade (pakjes sorteren onder tijdsdruk).
**Trietuin** is rustig organisch bouwen met een testrun. **Telex** is een mechanische spionagethriller: je *bedient
een apparaat* met je handen, je hoort elke vergelijking tikken, en je fouten tonen zich als ontsnapte koeriers en
valse arrestaties. Referenties: *Papers, Please* (regels toepassen, gevolgen later), *Keep Talking and Nobody
Explodes* (tastbare panelen), *Opus Magnum* (machines die precies doen wat je ze laat doen), *Rhythm Doctor* (de
ritmesectie).

### 1.2 Pitch
België, 1961, retro-futuristisch. Jij bent de nieuwe **lintlezer** van *Station Zoeklicht*, een geheime luisterpost in
de duinen. Het **Ekster-netwerk** verstopt codewoorden in gewone telexberichten. Het lint ratelt binnen, letter per
letter. Jij legt er het **sjabloon** met het codewoord onder, en de naald vergelijkt: tik, tik, tik, *ding*. Elke week
komt er een kist met een nieuwe machine, met op het typeplaatje een jaartal uit de toekomst: *K-M-P 1977*,
*B-M-H 1980*, *W-M 1992*. Je leert ze bedienen, eerst traag en met de hulp van **Chef Ponsaert**, daarna live terwijl het
lint doorloopt. Mis je een codewoord, dan ziet de versnipperaar het als laatste: het woord gloeit rood op voor het
in snippers valt, en op de kustkaart vertrekt een koerier. Sla je vals alarm, dan rijdt de ploeg naar het verkeerde
adres. In het laatste deel van de campagne staat er **ruis op de lijn**: codewoorden komen verminkt aan. Met het
schakelbord herstel je berichten en met het zoeklicht vind je het best passende stuk in een lang lint.

Wie Telex uitspeelt, heeft zelf V[] gepoost (Definitie 11 en Algoritme 5), honderden verschuivingen gekozen, de
hash rollend bijgewerkt (×2, −2^m, +bit, mod q), V_H-kaarten gestempeld, C_x-kaarten geponst, een M^k-bord bedraad
en editeertabellen cel per cel ingevuld en teruggevolgd. Het spel vraagt dat nergens als quiz. Je doet het omdat het
lint anders voorbij is.

### 1.3 Pijlers
1. **De machine ís het algoritme.** Elk onderdeel komt overeen met een begrip uit de notas: sjabloon = z, lint = t,
   naald = `vergelijk_strings()`, ponsstrook = V[], kaartenbak = V_H, hashwiel = h() mod q, lampkolom = M[][j],
   ponskaart = C_x, schakelbord = d[i][j]. Er bestaat geen spelregel naast de leerstof.
2. **Gevolgen in de wereld, nooit "fout".** Een te grote verschuiving laat een codewoord ontsnappen: het gloeit rood
   in de versnipperaar en op de kaart vertrekt een koerier. Een vals alarm stuurt de ploeg naar het verkeerde adres.
   Een te hoge cel in het schakelbord kost extra inkt bij het herstel. Wat in het algoritme onmogelijk is (een
   verschuiving die Definitie 11 schendt, een sprong van 0, een terugspoeling in een stroom zonder lusbak), is ook
   fysiek onmogelijk. Je hoort dan een "klem": de machine blokkeert, veert terug, en er staat geen tekst.
3. **Elke vergelijking is hoorbaar.** De tikteller is een mechanische teller en elke tekenvergelijking is één tik. Zo
   *hoor* je het verschil tussen brute kracht (een mitrailleur) en Boyer-Moore-Horspool (een paar losse tikken en
   grote sprongen). Op het einde staat een geest-balk "brute kracht zou … tikken nodig hebben".
4. **Eerst begrijpen, dan bedienen.** Elke machine begint in **analyse** (CALM): het lint staat stil tot jij beslist.
   Pas als een handeling gekend is, komt ze **live** (LIVE): het lint loopt door en de lusbak loopt vol. Een
   algoritmische beslissing krijgt live nooit minder dan 4 s. De ritmesectie is de enige uitzondering, en daar is de
   beslissing herkenning ("staat deze letter in z?").
5. **Juice met gewicht.** Relais klakken, de naald slaat op het lint, het wiel ratelt tand voor tand (je hoort mod q),
   lampen gloeien na, de ponsmachine maakt "tsjak", de bel van een treffer klinkt als een oude telexbel. Je moet het
   willen doen, ook als je het al kunt.

### 1.4 Doelgevoel (wat de speler na afloop zegt)
- "Brute kracht is traag omdat je terugspoelt en opnieuw vergelijkt. Ik zag de tikteller ontploffen bij `aaa…ab`."
- "Rabin-Karp: gelijke vingerafdruk is nog geen gelijke string. Je moet controleren. En vergeet −2^m niet."
- "V[j] is de kleinste verschuiving waarbij wat je al gelezen hebt nog klopt. De leeskop gaat nooit terug."
- "Bij BMH kijk ik naar het teken onder de **laatste** positie, niet naar het teken waar het misging."
- "Shift-AND: schuif de lampen één omlaag, bovenste lamp aan, AND met de kaart. Onderste lamp aan = treffer."
- "Met één fout toegelaten komt M¹ uit M⁰ van één kolom **eerder**, één rij **hoger**."
- "Editeerafstand: elke cel is het goedkoopste van drie buren. Teruglopen geeft de bewerkingen."
- "Algoritme 8 is hetzelfde, maar de bovenste rij is nul (overal instappen) en ik zoek het minimum onderaan."

### 1.5 Waarom dit leuk is (en geen quiz)
- **Tastbare machines.** Je verschuift geen getallen in vakjes. Je trekt aan een hendel, ponst een kaart, draait een
  wiel en hoort het gevolg. Juist correct zijn voelt goed: de tanden klikken in, de lampen lopen synchroon door.
- **Spanning van de stroom.** Live loopt het lint door. Een snelle juiste beslissing houdt de leeskop voor de
  versnipperaar uit. Twijfel je te lang, dan scheurt het lint.
- **Oorzaak en gevolg.** Eén vergeten −2^m bij venster 1 laat het echte codewoord op venster 10 ontsnappen en geeft
  twee hashbotsingen (§9 T28). De debrief toont die keten.
- **Van kant wisselen.** In de tegenzet-missies schrijf je zelf het lint dat de vijand doet vastlopen. Daar ontdek je
  het slechtste geval in plaats van het te lezen.
- **Variatie in gevoel:** precisie (Doorloper), rekenritme (wiel), grote sprongen (Springer), muziek (lampenbord),
  bedrading (ruisbord), stroom zoeken (schakelbord).
- **Verhaal en verzamelen.** Elk dossier ontrafelt een stuk van het Ekster-netwerk. Gevonden codewoorden worden
  stempels in je dossiermap, en op het einde volgt de grote ontmaskering ("Operatie Ekster").
- **Meesterschap.** De eindeloze *Nachtdienst*: Springer-sprints met highscore en combo's.

---

## 2. Wereld & kernlus

### 2.1 De wereld
- **Station Zoeklicht:** een bunker met één groot bedieningspaneel (de **console**). Boven de console loopt het lint
  horizontaal. Onder het lint wisselt het machinepaneel per level. Links van de console hangt een **kustkaart** met
  spelden (verhaal, gevolgen). Rechts staat de **buizenpost** waarlangs gevonden codewoorden als koker vertrekken.
- **Chef Ponsaert** (coach): oud-telegrafiste, kort van stof. Ze spreekt hoogstens één zin (≤ 12 woorden) per keer,
  enkel in briefings, tutorials, hints en de debrief.
- **Het Ekster-netwerk** (tegenstander): koeriers, nooit in beeld behalve als silhouet op de kaart.
- **Machines** (één per algoritme, elk met een typeplaatje en jaartal uit de notas):

| machine (spel) | typeplaatje | algoritme (notas) |
|---|---|---|
| Sjabloon | "Model A-2" | brute kracht, Algoritme 2 (p. 50–51) |
| Vingerafdruk | "Model R-K · q" | Rabin-Karp, Algoritme 3 (p. 52–54) |
| Ponsbank + Doorloper | "Model K-M-P 1977" | Definitie 11, Algoritme 5 (V[]), Algoritme 4 (p. 55–62) |
| Springer | "Model B-M-H 1980" | Boyer-Moore-Horspool, vul_VH, is_contained_BMH (p. 63–66) |
| Lampenbord | "Model B-Y/G" | shift-AND, Definitie 13, Algoritme 6 (p. 66–69) |
| Ruisbord | "Model W-M 1992" | shift-AND met k mismatches, Definitie 14 (p. 70–71) |
| Schakelbord | "Model L" | editeerafstand, Definitie 15, Algoritme 7 (p. 72–76) |
| Zoeklicht | "Model L-8" | kleinste editeerafstand van een deelwoord, Algoritme 8 (p. 77–80) |

### 2.2 De console: gemeenschappelijke onderdelen (functioneel bindend)
| onderdeel | betekenis (notas) | gedrag |
|---|---|---|
| **lint** | tekst t[0..n−1] | papierstrook, één teken per vakje (mono), positie eronder (0-gebaseerd). Het teken `_` is een gewoon teken (de notas gebruiken het als spatie) |
| **sjabloon** | zoekstring z[0..m−1] | metalen strook onder het lint, uitgelijnd op `start` (z[0] onder t[start]), posities 0..m−1 erboven klein |
| **naald** | één tekenvergelijking | slaat op één kolom: groen lampje = gelijk, rood = verschillend. **1 vergelijking = 1 tik** |
| **leeskop** | absolute positie in t die nu vergeleken wordt | een messing kop boven het lint. Brute kracht laat hem terugspringen (de spoelmeter telt het), de Doorloper nooit |
| **tikteller** | aantal tekenvergelijkingen | mechanische teller met rolcijfers, rechtsboven. Geest-balk: brute kracht |
| **spoelmeter** | hoeveel posities de leeskop terug moest | enkel zichtbaar bij brute kracht en in de debrief |
| **inlaat** (LIVE) | wat al binnen is (front F) | rechts van het lint: tekens ≥ F zijn nog niet aangekomen (blanco strook die binnenrolt) |
| **versnipperaar** | tekens die de machine nooit meer leest | links. Alles links van `need()` (§2.5) verdwijnt erin. Een niet-gemeld echt voorkomen gloeit rood vóór het verdwijnt (= **gemist**) |
| **lusbak** (LIVE) | buffer van B tekens | een bak onder de leeskop waarin het lint hangt; zichtbaar vullend |
| **dossierkaart** | de opdracht | links onder: z (en q, k), modus "eerste" of "alle" voorkomens |
| **buizenpost** | melding van een treffer | koker met "z @ positie" vertrekt; de stempel komt in het dossier |
| **kustkaart** | gevolgen | gemist = koerier (rode speld) vertrekt; vals alarm = ploeg rijdt naar een verkeerd adres (grijze speld) |

### 2.3 Kernlus per level ("een dienst", 2–6 min)
1. **Briefing (≤ 8 s, skipbaar):** dossiermap opent. Codewoord(en), één zin van de Chef, het typeplaatje van de
   machine (nieuw: kist gaat open), notasverwijzing ("Oefening 39 · notas p. 62").
2. **Voorbereiding** (enkel bij machines met een tabel): V[] ponsen, V_H-kaarten stempelen, het hashwiel ijken
   (w = 2^m mod q, h(z)), C_x-kaarten ponsen, het ruisbord bedraden.
3. **Doorloop:** het lint gaat door de machine. De naald vergelijkt automatisch tot de eerste mismatch of tot de
   volledige treffer (dat is `vergelijk_strings()`). Daarna neemt de speler de **algoritmische beslissing**: hoe ver
   verschuiven, welke kaart, welke hashbewerking, welke cel. Een treffer belt en vertrekt automatisch via de
   buizenpost.
4. **Debrief:** sterren, tikken vs. brute kracht vs. optimum, het lintverslag (✓ gevonden, ✗ gemist, ! vals alarm), je
   tabel naast de juiste, en een tijdlijn met je misstappen. Klik op een misstap om dat moment opnieuw te zien: eerst
   jouw zet, dan de juiste zet als spookhand, met één coachzin en een notasverwijzing (§6.5).

### 2.4 Microlus (voorbeeld: Doorloper, `barbados` in `barbaarse_barbecue_in_barbados`, notas p. 58)
Het sjabloon staat op start 0. Spatie: de naald tikt b=b, a=a, r=r, b=b, a=a, `a`≠`d` (6 tikken), rood lampje op
sjabloonpositie 5, leeskop op t[5]. De speler trekt het sjabloon naar rechts: bij 1 en 2 botsen de tanden (rode vonkjes
op de al gelezen `barba`). Bij 3 klikken ze in (`ba` onder `ba`). Enter: het sjabloon schuift 3 op, de leeskop blijft
op t[5] en de naald vergelijkt meteen verder vanaf sjabloonpositie 2 (`r` vs `a`: 1 tik, mismatch op 2). De speler
schuift 2 (de enige verschuiving ≤ 2 die past). Mismatches op positie 0 schuiven vanzelf 1 op (V[0] = 1). Op t[10]
begint `barbecue`: mismatch op 4 → 3, mismatch op 1 → 1, … tot start 22: 8 tikken groen, *ding*, koker vertrekt.
Totaal 34 tikken; de geest-balk "brute kracht: 42" (§5.4, 3-1).

### 2.5 Analyse (CALM) en live (LIVE): het stroommodel (bindend voor de core)
- **CALM:** front F = n (alles is binnen), geen versnipperaar-druk. Het spel wacht op de speler. Terugzetten
  (`Ctrl+Z`) en hint (`F1`) zijn mogelijk (kosten ★★★).
- **LIVE:** F stijgt met v tekens/s (`spec.live.v`). De lusbak houdt B tekens (`spec.live.B`). De versnipperaar staat op
  S = max(0, F − B): posities < S zijn vernietigd. De naald kan enkel posities < F lezen. Moet ze verder, dan wacht ze
  (fase `WAIT_TAPE`, geen kost).
- **need()** = de kleinste positie die de machine nog nodig heeft:
  brute kracht `start`; Doorloper `start + gelijke_tekens` (de leeskop); Springer `i − m + 1`; Vingerafdruk `i`
  (vensterbegin); lampenbord `j` (huidig teken).
- **Scheur:** als S > need(), scheurt het lint. De core voert `force_to(S)` uit: brute kracht en Doorloper:
  `start := S, gelijke_tekens := 0`; Springer: `i := S + m − 1`; Vingerafdruk: `i := S`, het wiel wordt automatisch
  opnieuw berekend (m + #enen wielslagen); lampenbord: de kolom wordt 0 en j := S. Elk echt voorkomen dat begint vóór de
  nieuwe `start` en nog niet gemeld is, is **gemist** (oorzaak: SCHEUR).
- Gevolg (de les van p. 50 en Stelling 12): de Doorloper en het lampenbord werken met B = 1. De Springer en de
  Vingerafdruk hebben B ≥ m nodig. Brute kracht heeft na een mismatch op positie k een terugsprong van k − 1 nodig,
  dus B ≥ m.

---

## 3. Mapping spel ↔ leerstof (volledig)

Per algoritme: (a) tabel notas ↔ spel, (b) wat de speler doet en wat automatisch gaat, (c) fouten en hun gevolg.

### 3.0 Algemene conventies (functioneel bindend)
- **Posities zijn 0-gebaseerd**, letterlijk zoals de notas: z[0..m−1], t[0..n−1] (p. 50), M[i][j] met rijen en kolommen
  vanaf 0 (p. 67, 70). Editeertabellen gebruiken **lengtes** als index zoals de notas: d[i][j] = afstand tussen de
  prefix van lengte i en die van lengte j (p. 74), D[i][j] idem (p. 78). Het lint toont altijd de posities 0..n−1.
- **Tik** = één tekenvergelijking `z[..] != t[..]` in `strings_gelijk()` (Algoritme 2/3), `vergelijk_strings()`
  (Algoritme 4/5) of `strings_gelijk_invers()` (BMH). Een vergelijking met het end_of_line-teken in Algoritme 5 (p. 60)
  telt ook als tik. Hashbewerkingen tellen apart als **wielslagen**, lampkolommen als **lampslagen** en ingevulde cellen
  als **relais**.
- **Modus per level:** `FIRST` = stop bij het eerste voorkomen, letterlijk zoals de pseudocode (`return TRUE`).
  `ALL` = alle voorkomens (Oef. 41, p. 62; Figuur 23 "waarbij na de eerste match niet gestopt wordt", p. 69):
  brute kracht, Rabin-Karp en BMH gaan gewoon verder in hun lus (BMH met `i = i + V_H[t[i]]`). Shift-AND gaat altijd
  door. **KMP na een volledige treffer** (eerste_mismatch = m) verschuift met **V[m]** volgens Definitie 11 uitgebreid
  tot j = m, en `gelijke_tekens = m − V[m]`. Algoritme 5 vult V[m] soms zelf in ("één teken meer dan de lengte van z",
  p. 60). Waar het dat doet, is de waarde gelijk aan Definitie 11 (nagerekend). Zie §11 vraag 1.
- **Teksten** in kleine letters, met `_` als spatie (zoals de notas). Oef. 40 en 48 bevatten een apostrof. Het spel
  gebruikt de ASCII `'` (de pdf toont een typografisch aanhalingsteken; de lengte blijft gelijk; §11 vraag 13).
  Rabin-Karp werkt zoals in de notas met **bitstrings** over {0,1} (p. 52).
- **Gemist** = een echt voorkomen dat de machine voorbij is (`need()` voorbij het begin, of bij het lampenbord het
  einde voorbij) zonder melding. **Vals alarm** = een melding van iets wat geen voorkomen is (enkel mogelijk bij de
  Vingerafdruk via "Meld meteen", bij het lampen- en ruisbord via foute kaarten/bedrading, en bij het zoeklicht via een
  verkeerd gekozen einde). Bij brute kracht, KMP en BMH controleert de naald elk teken, dus daar bestaat geen vals
  alarm.
- **Klem** (`ok = false`) = fysiek onmogelijke zet. De staat verandert niet. Je hoort een klem, en daarna niets meer.
  Klemmen zijn geen misstap, maar ze worden geteld en ★★★ vraagt er 0 in de levels waar ze iets zeggen (§6.4).

### 3.1 Brute kracht (Algoritme 2, r. 2643–2700, p. 50–51) — machine *Sjabloon*

| notas | in het spel | waarom zo |
|---|---|---|
| `for (i=0; i<=|t|-|z|; i++) if strings_gelijk(z,t,i)` | het sjabloon staat op start i; Spatie = naald laten lopen; daarna schuift het sjabloon precies 1 op | brute kracht kent geen keuze; dat is de les |
| `strings_gelijk`: vergelijk z[0..m−1] met t[i..i+m−1], stop bij de eerste mismatch | de naald tikt van links naar rechts, stopt bij het eerste rode lampje | 1 tik per vergelijking |
| O((n−m+1)·m) slechtste geval (Opm. 9, p. 51) | tikteller + **spoelmeter**: na een mismatch op sjabloonpositie k springt de leeskop k − 1 terug | je ziet en hoort het herlezen |
| Oef. 32: Θ(n²)-voorbeeld (p. 51) | **tegenzet**: schrijf z en t zodat de vijand zoveel mogelijk tikt (§3.9) | het slechtste geval *ontdek* je |
| Oef. 33: wildcard `?` (p. 51) | (P2) jokerkaart in het sjabloon: `?` geeft altijd groen (telt als tik) | — |

**Speler doet:** Spatie (naald starten / volgende uitlijning). **Automatisch:** alles. De machine is bewust dom: ze is de
maatstaf (geest-balk) voor alle latere machines en de vijand in de tegenzet-missies.
**Fouten → gevolg:** geen (er is geen keuze). In LIVE-levels met B < m scheurt het lint bij terugspoelen (de rivaal in
3-5).

### 3.2 Rabin-Karp (Algoritme 3, r. 2716–2855, p. 52–54) — machine *Vingerafdruk*

| notas | in het spel | waarom zo |
|---|---|---|
| h(s) = (Σ s_i 2^(m−1−i)) mod q, bitstring als binair getal (p. 52) | het **hashwiel**: een tandwiel met q tanden (0..q−1). Rekenen gebeurt door te draaien, dus mod q is automatisch: het wiel loopt rond | modulo wordt een fysieke eigenschap |
| (a·b) mod q = (a·(b mod q)) mod q; Horner | **IJken**: start op 0, per bit `×2` (het wiel draait h tanden verder) en bij een 1 `+1` | h(z) en h(t_0..t_{m−1}) in O(m) |
| t_p·2^m mod q eenmaal vooraf berekenen (p. 53) | het **gewicht** w = 2^m mod q: zet het wiel op 1 en druk m keer `×2`; het resultaat wordt een tandwieltje "−w" | — |
| h(t_{p+1..p+m}) = (2h − t_p·2^m + t_{p+m}) mod q (p. 53) | **rollen**: `×2`, `−w` als het **uitgaande** bit 1 is, `+1` als het **inkomende** bit 1 is, daarna "Schuif" | elke update is een hendelreeks |
| `if (h(...)==h(z)) { if strings_gelijk(...) }` (p. 54) | op h(z) zit een **rode inkeping**. Staat de wijzer erop, dan knippert het **alarmlampje**: kies Controleer / Meld meteen / Negeer | gelijke vingerafdruk ≠ gelijke string |
| valse treffers; O(n) verwacht, O((n−m+1)m) slechtst (Opm. 10, p. 54) | een controle die faalt = **hashbotsing**: kost tikken, geen schade (geen vals alarm: er vertrekt niemand) | de notas noemen het een kost, geen fout |
| Oef. 34 (z = 00101, q = 13) | level 2-3 | — |
| Oef. 34b: tekst waarvoor strings_gelijk bijzonder vaak wordt opgeroepen | tegenzet 2-4 | — |

**Speler doet:** w ijken, h(z) en h(eerste venster) met Horner, per venster de rolbewerkingen, de alarmkeuze.
**Automatisch:** het wiel rekent mod q (draait rond), de controle (`strings_gelijk`) tikt zelf, de treffer wordt gemeld.
De machine dwingt geen volgorde af: enkel de wielstand bij "Schuif" telt. Wie −w vóór ×2 doet, trekt in feite 2w af en krijgt een foute stand (zie §11 vraag 5). Bij Horner (ijken) bevestigt
de speler elk bit met "Volgend bit".

**Fouten → gevolg**

| fout | kan het? | gevolg | wanneer zie je het |
|---|---|---|---|
| `−w` vergeten / onterecht, `+1` vergeten / onterecht, `×2` vergeten | ja | het wiel staat verkeerd en **elke volgende waarde ook** (de fout verdubbelt mee). Het echte codewoord kan ongemerkt passeren (wijzer niet op de inkeping) en het alarmlampje kan op verkeerde vensters branden (botsingen) | gemist: meteen in de versnipperaar. Debrief: tijdlijn "venster 1: −w vergeten" → oorzaak van de gemiste treffer |
| verkeerde h(z) (fout bij ijken) | ja | de rode inkeping staat op de verkeerde tand: alarmen op de verkeerde plaatsen, het echte voorkomen wordt gemist | idem |
| Negeer bij alarm, strings gelijk | ja | **gemist** | meteen |
| Negeer bij alarm, strings verschillend | ja | geen schade, wel misstap (`SKIPPED_CHECK`): "de procedure is controleren" | debrief |
| Meld meteen, strings gelijk | ja | treffer telt, misstap `UNVERIFIED` | debrief |
| Meld meteen, strings verschillend | ja | **vals alarm**: de ploeg rukt uit naar het verkeerde adres | meteen (kaart) |
| Controleer zonder alarmlampje | **nee** | de controlehendel zit vast (klem) | — |
| `−w` vóór w geijkt is | **nee** | het tandwieltje "−w" is er nog niet (klem) | — |

### 3.3 Knuth-Morris-Pratt (r. 2901–3299, p. 55–62) — machines *Ponsbank* en *Doorloper*

| notas | in het spel | waarom zo |
|---|---|---|
| Definitie 11: V[0] = 1; V[j] = min{s \| 0<s<j en z[0..j−1−s] = z[s..j−1], of s = j} (p. 56) | **tanden**: na een mismatch op sjabloonpositie j sleep je het sjabloon s plaatsen op. Het past enkel als z[0..j−1−s] precies onder de al gelezen (groene) tekens t[start+s..start+j−1] valt, of als s ≥ j. Wat niet past, botst (klem). De kleinste passende s is V[j] | de definitie wordt een fysieke beweging |
| "Observatie": de eerste j − V[j] tekens niet opnieuw vergelijken (p. 57) | na de verschuiving **blijft de leeskop staan**. De naald gaat verder vanaf sjabloonpositie j − s. Enkel bij j = 0 schuift de kop 1 op | Stelling 12: de absolute positie daalt nooit |
| Algoritme 4 (p. 57–58) | de Doorloper: naald = `vergelijk_strings(z,t,start,gelijke_tekens)`, daarna `start += s`, `gelijke_tekens = j − s` (0 als j = 0 of s ≥ j) | — |
| V[0] = 1: mismatch op positie 0 (p. 58 "speciaal geval") | schuift automatisch 1 op (instelbaar per level, `auto_zero`) | tempo; staat in elke tabel gelijk |
| bereken V vooraf; tabel op voorhand | de **ponsstrook**: een strook met m (+1) vakjes boven het sjabloon. Is ze geponst, dan kan de Doorloper bij een mismatch zelf verschuiven (`auto_strip`) | automatisering verdien je door te ponsen |
| Algoritme 5: z in zichzelf zoeken; `eerste_mismatch=0` → V[start+1] = start+1; anders V[start+i] = start voor i = gelijke_tekens+1 .. eerste_mismatch; `start += V[eerste_mismatch]` (p. 61) | **spiegelrit** op de ponsbank: z loopt als tekst onder een kopie van zichzelf. Na elke stop **pons** je het nieuw verdiende stuk van de strook (tot en met de mismatchpositie, waarde = huidige verschuiving) en verschuif je met de strook | letterlijk Algoritme 5 |
| V[0] = V[1] = 1 voor elk woord (p. 60) | voorgeponst | — |
| Oef. 39, 40 (p. 62) | levels 3-3 en 3-2 | — |
| Oef. 41: alle voorkomens (p. 62) | level 3-4: het vakje V[m] (extra vakje rechts, "na een treffer") | §11 vraag 1 |
| "geschikt voor streams" (p. 50), Stelling 12 (p. 59) | LIVE met lusbak B < m: de Doorloper overleeft, de rivaal (brute kracht) scheurt | 3-5 |

**Ponsen met de spiegel (Definitie 11, level 3-2):** voor elk vakje j (2 ≤ j ≤ m−1, en j = m in ALL-levels) toont de
ponsbank z[0..j−1] groen (al gelezen) en op positie j een vraagteken (de mismatch). De speler sleept een spookkopie van
z en ponst de verschuiving waarop de kopie inklikt. Een s die niet past, klemt. Een te grote s die wel past (bv. s = j
terwijl er een kleinere is), wordt aanvaard. Dat is de misstap `PUNCH_LONG`, en het gevolg komt later: de Doorloper
verschuift te ver.

**Spiegelrit (Algoritme 5, level 3-3), exacte procedure (core):** toestand `start = 1, gelijke_tekens = 0`, strook
V[0] = V[1] = 1, alle andere vakjes leeg. Zolang `start + gelijke_tekens < m − 1`:
1. de naald loopt automatisch: `em = vergelijk_strings(z, z, start, gelijke_tekens)` (voorbij het einde staat het
   end_of_line-teken ⏎, dat met niets overeenkomt);
2. de speler **ponst**: zet `{"act":"punch_to","to":b,"v":v}`. De ponskop begint vanzelf op het eerste open vakje
   a = start + gelijke_tekens + 1 (bij em = 0: a = start + 1). De speler kiest het laatste vakje b en de waarde v (de
   draaiknop staat standaard op `start`). Correct: b = start + em en v = start; bij em = 0: b = a = start + 1 en
   v = start + 1. Klem als een geponste waarde voor een vakje niet past (Definitie 11-voorwaarde geschonden) of als een
   vakje al gevuld is. b < correct: `PUNCH_SHORT` (de overgeslagen vakjes blijven leeg). v groter dan correct maar
   passend: `PUNCH_LONG`;
3. de speler **verschuift**: `{"act":"shift","s":s}` (of `strip` = de waarde uit het vakje V[em]). Er geldt dezelfde
   tandenregel als bij de Doorloper. `start += s; gelijke_tekens = em − s` (0 als em = 0 of s ≥ em).
Daarna mag de speler lege vakjes nog met de spiegel ponsen (zoals in 3-2), maar dat telt als `PUNCH_SHORT`-herstel en
kost ★★★.

**Speler doet:** V ponsen (spiegel of spiegelrit), bij elke mismatch verschuiven (tenzij `auto_strip`), lege of
verdachte vakjes met de hand doen. **Automatisch:** de naald (`vergelijk_strings`), de leeskop (blijft staan),
mismatch op positie 0 (als `auto_zero`), treffer melden.

**Fouten → gevolg**

| fout | kan het? | gevolg | wanneer |
|---|---|---|---|
| verschuiving s < V[j] (schendt Definitie 11) | **nee** | de tanden botsen op de groene tekens: klem, vonkjes, terugveren | meteen |
| verschuiving s > V[j] (past wel) | ja | `SHIFT_LONG`. Begint er tussen start en start+s een echt voorkomen, dan wordt het **overgeslagen** en is het **gemist** | de versnipperaar onthult het als de kop voorbij is; debrief linkt naar de verschuiving |
| verkeerd vakje in de strook (te groot) | ja | de Doorloper verschuift met `auto_strip` te ver → zoals hierboven | in de doorloop |
| leeg vakje in de strook | ja | de Doorloper stopt met een leeg-geluid ("tok"). De speler moet met de hand verschuiven (in LIVE kost dat tijd) | meteen |
| ponswaarde die niet past (te klein) | **nee** | klem | — |
| spiegelrit: te weinig vakjes geponst | ja | `PUNCH_SHORT`: gaten in de strook (gevolg: zie leeg vakje) | doorloop |
| (LIVE) te traag beslissen | ja | de lusbak loopt vol, het lint **scheurt**: de kop springt naar S, voorkomens ertussen zijn gemist | meteen |

### 3.4 Boyer-Moore-Horspool (r. 3300–3475, p. 63–67) — machine *Springer*

| notas | in het spel | waarom zo |
|---|---|---|
| `strings_gelijk_invers`: van \|z\|−1 naar 0 vergelijken (p. 63–64) | de naald begint onder de **laatste** sjabloonpositie (op t[i]) en tikt naar links | richting is zichtbaar |
| verschuiving op basis van een teken in de tekst, niet van een positie in z (p. 65) | het **sleutelteken** = t[i], het teken onder de laatste sjabloonpositie. Voor dat teken trek je de kaart | de typische fout (het mismatchteken nemen) wordt een echte keuze |
| V_H(x) = \|z\| als x niet in z of enkel op \|z\|−1; anders m−1−(laatste positie ≤ m−2) (p. 65) | de **kaartenbak**: één kaart per letter van z plus de kaart "overige" (voorgedrukt: m) | — |
| `vul_VH`: eerst alles \|z\|; `for (i=0; i<=|z|-2; i++) VH[z[i]] = |z|-i-1` (p. 65) | **stempelen**: klik sjabloonposities. Elke klik stempelt de kaart van z[i] met de afstand tot het einde (m−1−i, automatisch). Een latere stempel overschrijft. De laatste positie stempelen klemt (de lus stopt bij \|z\|−2) | "de laatste keer bepaalt de waarde" ontstaat vanzelf uit de volgorde |
| `i = i + VH[t[i]]` (p. 65–66) | **springen**: klik het sleutelteken op het lint, dan wordt de kaart getrokken en springt het sjabloon. Of sleep het sjabloon met de hand (zonder kaartenbak: tot een sjabloonletter gelijk aan het sleutelteken eronder staat, de kleinste sprong ≥ 1, anders volledig voorbij) | beide vormen uit de notas (p. 64: "kleinste aantal posities, ten minste 1") |
| barbara-voorbeeld (p. 64–65), Oef. 48, Oef. 50 (p. 66–67) | levels 4-1, 4-2, tegenzet 4-4 | — |

**Speler doet:** kaarten stempelen, per uitlijning het sleutelteken kiezen (of met de hand springen).
**Automatisch:** de naald (rechts → links), de kaartwaarde, de treffer. In 4-1 en 4-2 licht het sleutelteken op
(`key_hint`); vanaf 4-3 niet meer.

**Fouten → gevolg**

| fout | kan het? | gevolg |
|---|---|---|
| sleutelteken = het mismatchteken (of een ander teken) in plaats van t[i] | ja | `WRONG_KEY`. De sprong is die van de verkeerde kaart: te kort (verspilde tikken) of te lang (**gemist** codewoord, level 4-3 is daarop gebouwd) |
| stempels in de verkeerde volgorde / een positie vergeten | ja | `WRONG_CARDS` bij "kaarten klaar" (de kaartenbak toont niets). In de doorloop springt de Springer met de foute waarde: te ver = gemist, te kort = verspild |
| de laatste positie stempelen | **nee** | klem (waarde 0 zou nooit vooruitgaan) |
| handsprong groter dan V_H[t[i]] | ja | `JUMP_LONG`, mogelijk gemist |
| handsprong kleiner | ja | `JUMP_SHORT`, verspilde tikken |
| sprong 0 | **nee** | klem |

### 3.5 Shift-AND (Definitie 13, Algoritme 6, r. 3476–3655, p. 66–69) — machine *Lampenbord*

| notas | in het spel | waarom zo |
|---|---|---|
| M[i][j] = 1 ⇔ z[0..i] = t[j−i..j] (Definitie 13, p. 67) | een **lampkolom** van m lampen, rij i = z[i], van boven (i = 0) naar onder, net als de tabel in de notas. Elke afgewerkte kolom wordt op een papieren **matrixlog** gedrukt: de matrix M groeit kolom per kolom naar rechts | exact het beeld van p. 67/69 |
| C_x[i] = 1 ⇔ z[i] = x (p. 67) | **ponskaarten**: één verticale kaart per letter van z, met een gat op rij i als z[i] = x. De kaart "blanco" (alle andere tekens) is voorgedrukt zonder gaten | — |
| shift¹: bit i−1 naar i, nieuw bit 0 op 1 (p. 68) | de **hendel**: alle lampen schuiven één rij omlaag, de onderste valt eraf, de bovenste ("voedingslamp") gaat aan | de notas-conventie letterlijk |
| kolom = SHIFT¹(kolom) & C[t[j]] (Algoritme 6) | **kaart insteken**: enkel lampen boven een gat blijven branden | AND = licht door gaten |
| M[m−1][j] = 1 ⇔ treffer eindigt op j | onderste lamp aan → **bel**, koker "z eindigt op j" | — |
| initialisatie: kolom = 0, lus vanaf j = 0 ("kolom −1", p. 68) | het bord start donker. Het eerste teken krijgt hendel + kaart zoals elk ander | eenvormig; geeft exact de eerste kolom van de notas |
| Figuur 23 (`ana`/`ananas`), Oef. 54 | 5-1, 5-2 | — |
| "vooral een goede keuze als je alle matches zoekt en er zijn er veel" (p. 67) | 5-3 ritmesectie | — |

**Speler doet:** kaarten ponsen; per teken hendel (`S` of `↓`) en de juiste kaart (de letter typen of klikken;
`Spatie` = blanco). **Automatisch:** schuiven, de voedingslamp, de AND, de bel, het drukken van de kolom.
In de ritmesectie (`auto_lever`) trekt de metronoom de hendel; de speler steekt enkel kaarten.

**Fouten → gevolg**

| fout | kan het? | gevolg |
|---|---|---|
| gat vergeten / extra gat in een kaart | ja | `WRONG_HOLES` bij "kaarten klaar" (zonder melding in de wereld). In de doorloop: lampen doven die hadden moeten branden (gemist) of blijven branden (de bel gaat te vroeg of op de verkeerde plaats: **vals alarm**) |
| kaart insteken zonder hendel | ja | `NO_SHIFT`: de AND gebeurt op de niet-geschoven kolom. De lampen "lopen niet door", dus een treffer wordt gemist (§9 T30) |
| tweede keer hendel voor hetzelfde teken | **nee** | de hendel staat al onderaan (klem) |
| verkeerde kaart (andere letter, of blanco terwijl t[j] in z staat) | ja | `WRONG_CARD`. Lampen doven ten onrechte (gemist) of een andere letter laat licht door (mogelijk vals alarm) |
| (ritme) geen kaart vóór de volgende tel | ja | de machine steekt automatisch blanco in. Dat is correct als t[j] niet in z staat, anders `LATE` (misstap, gevolgen zoals WRONG_CARD) |

### 3.6 Shift-AND met k mismatches (Definitie 14, r. 3657–3737, p. 70–71) — machine *Ruisbord*

| notas | in het spel | waarom zo |
|---|---|---|
| M^k[i][j] = 1 ⇔ prefix z[0..i] eindigt op j met ≤ k mismatches (Definitie 14) | k+1 lampkolommen naast elkaar: M⁰, M¹ (, M²). M⁰ is het gewone lampenbord | — |
| eerste kolom voor k > 0: (1,0,…,0); M^l[0][j] = 1 (p. 70–71) | de voedingslamp van M¹/M² brandt altijd | — |
| M^l[][j] = (1,0,…,0) \| shift(M^{l−1}[][j−1]) \| (shift(M^l[][j−1]) & C[t[j]]) (p. 71) | per kolom l ≥ 1 een **OF-poort** met drie ingangen: voeding, de **foutkabel** en de eigen AND-weg. **Bedraden** (voorbereiding): de speler steekt de foutkabel in één van vier aansluitingen van kolom l−1: `oud ↓` (vorige kolom, geschoven) = correct; `oud` (vorige kolom, ongeschoven); `nieuw ↓` (huidige kolom, geschoven); `nieuw` | het inzicht van de recursie: "één fout = een willekeurig teken op j, bovenop een prefix met l−1 fouten die op j−1 eindigt" |
| Oef. 60 (`dank`, `een_dansfeest`, k = 1) | level 6-1 | — |

**Speler doet:** kaarten ponsen (zoals 3.5), de foutkabel(s) steken, per teken hendel + kaart (één hendel en één
kaart sturen alle kolommen). **Automatisch:** OF-poorten, voeding, bellen per kolom ("treffer met ≤ l fouten").
**Fouten → gevolg:** foute bedrading (`WRONG_WIRE`) geeft een ander foutmodel. In 6-1 (nagerekend): `oud` → de echte
treffer `dans` wordt **gemist** (er belt niets). `nieuw ↓` → de bel gaat een kolom te vroeg (op j = 6, "`dan` met `k`
weggelaten"), dus **vals alarm** + gemist. `nieuw` → er belt niets (gemist). Kaart- en hendelfouten zoals in 3.5.

### 3.7 Editeerafstand (Definitie 15, Algoritme 7, r. 3738–4026, p. 71–77) — machine *Schakelbord*

| notas | in het spel | waarom zo |
|---|---|---|
| bewerkingen vervangen / verwijderen / toevoegen (Definitie 15, p. 72) | de **herstelstrook**: een telexprint van t die letter per letter in t′ verandert | het doel van het bord |
| d[i][j] tussen prefixen van lengte i en j; d[i][0] = i, d[0][j] = j (p. 74) | het **schakelbord**: (\|t\|+1) × (\|t′\|+1) relais, rijen = t (links), kolommen = t′ (boven), zoals de tabel op p. 76. Rand voorgevuld | — |
| d[i][j] = min{d[i−1][j−1] + wisselkost, d[i−1][j] + 1, d[i][j−1] + 1} (Algoritme 7, p. 75) | per relais kies je de **ingang** waarlangs de stroom komt: ↖ (diagonaal, +0 bij een groen "gelijk"-lampje, anders +1), ↑ (+1, t[i−1] verwijderen), ← (+1, t′[j−1] toevoegen). De waarde volgt automatisch | de keuze van het minimum is de beslissing; de waarde rekent de machine |
| "duid aan hoe de getallen werden berekend" (Oef. 62) | gekozen ingangen blijven als draadjes zichtbaar; na het vullen lichten **alle** dragende draadjes op | de lijn uit de figuur op p. 76 |
| een kortste reeks bewerkingen; Lemma 17 (stijgende indices, p. 73) | **teruglopen** vanaf de rechteronderhoek naar (0,0) langs stroomvoerende draadjes. Elke stap is een bewerking op de herstelstrook. Op het einde print de strook de reeks in stijgende volgorde, met posities in de string van dat moment | — |

**Speler doet:** per cel de ingang kiezen (rij per rij, links → rechts, zoals de lussen van Algoritme 7), daarna
teruglopen. **Automatisch:** de waarde in de cel, het gelijk-lampje, de randen, de herstelstrook.

| fout | kan het? | gevolg |
|---|---|---|
| ingang die niet het minimum geeft | ja | `WRONG_MIN`: de cel krijgt een te hoge waarde (het relais gloeit warmer). De fout plant zich voort. Eindafstand te hoog → het herstel kost meer bewerkingen ("extra inkt") en ★★ is weg |
| een stap terug langs een draadje dat de waarde niet draagt (waarde ≠ buur + kost) | **nee** | geen stroom: klem |
| een cel invullen voor zijn buren klaar zijn | **nee** | het relais heeft geen spanning (de cursor gaat rij per rij) |

### 3.8 Kleinste editeerafstand van een deelwoord (Algoritme 8, r. 4027–4185, p. 77–80) — machine *Zoeklicht*

| notas | in het spel | waarom zo |
|---|---|---|
| D[i][j] = min over l van d(z[0..i−1], t[l..j−1]) (p. 78) | schakelbord met rijen = z, kolommen = t (het lange lint) | — |
| D[i][0] = i, **D[0][j] = 0** (p. 78) | de bovenrand is een **stroomrail op 0**: de stroom mag overal in het lint instappen | het enige verschil met Algoritme 7 (p. 79: "alleen de initialisatie … verschillen") |
| dezelfde recursie (p. 78) | zoals 3.7 | — |
| kleinste waarde in de laatste rij (p. 79) | het **zoeklicht**: klik de cel(len) met de laagste meter in de onderste rij. Kolom j = einde van de match (laatste teken t[j−1]) | — |
| de beste match terugvinden (Oef. 70–72) | teruglopen vanaf die cel tot je rij 0 raakt. De kolom l waar je de rail verlaat, is het begin. Het zoeklicht beschijnt t[l..j−1] en de herstelstrook toont de bewerkingen van z naar die match | — |

**Fouten → gevolg:** `WRONG_MIN` zoals 3.7. Een einde kiezen dat niet minimaal is (`WRONG_END`): het zoeklicht schijnt
op de verkeerde plek en de ploeg vertrekt, dus **vals spoor** (= vals alarm). Teruglopen zonder stroom: klem.

### 3.9 Tegenzet-missies (Oef. 32, 34b, 50) — de speler schrijft het lint

| oefening | opdracht in het spel | metriek | optimum (exhaustief nagerekend) |
|---|---|---|---|
| Oef. 32 (p. 51) | "Laat de Sjabloon van de vijand zoveel mogelijk tikken." Kies z (m tegels) en t (n tegels) uit {a, b} | tikken van Algoritme 2 (stop bij eerste treffer) | (n−m+1)·m, bv. z = a^(m−1)b, t = a^n (of a^(n−1)b) |
| Oef. 34b (p. 54) | "Laat de Vingerafdruk van de vijand zoveel mogelijk controleren." z = 00101, q = 13 vast; t (16 bits) | aantal oproepen van `strings_gelijk` (stop bij eerste treffer) | 12 = alle vensters, **enkel** met t = 1^16 (11111 = 31 ≡ 5 mod 13) |
| Oef. 50 (p. 66–67) | (a) "Laat de Springer vliegen": minimaal aantal tikken, z mag niet in t voorkomen. (b) "Laat de Springer kruipen": maximaal | tikken van BMH | (a) 4 = ⌈(n−m+1)/m⌉ bij n = 16, m = 4, bv. z = bbbb, t = a^16; (b) 52 = (n−m+1)·m, enkel z = baaa, t = a^16 of z = abbb, t = b^16 |

**Speler doet:** tegels zetten (klik/typ), "Verstuur" → de vijandige machine draait automatisch (versneld, met
tikgeluid) en de tikteller loopt op. Je mag zo vaak proberen als je wilt; de beste score telt.
**Automatisch:** de vijandige machine is de referentie-implementatie (`TxReference`).
**Fouten:** geen misstappen, enkel score. De debrief toont het optimum en de parametrisatie (Oef. 32: grafiek tikken
vs. n met m = n/2 → (n/2 + 1)·n/2 = Θ(n²)).

---

## 4. Bediening, schermen & HUD

### 4.1 Besturing (muis volwaardig, toetsenbord waar het sneller is)
| actie | muis | toetsenbord |
|---|---|---|
| naald laten lopen / volgende (brute kracht) | klik de naaldknop | `Spatie` (ingedrukt houden = 3× sneller) |
| verschuiven (Doorloper, spiegel, spiegelrit) | sleep het sjabloon (rastert per positie; de tanden tonen live of het past) en laat los / klik "Vastzetten" | `→`/`←` zet de voorvertoning s (start op 1), `Enter` zet vast |
| verschuiven volgens de strook | klik het vakje V[j] dat oplicht | `V` |
| ponsen (spiegel) | sleep de spookkopie, klik "Pons" | `→`/`←`, `P` |
| ponsen (spiegelrit) | sleep de ponskop over de vakjes tot b; draaiknop voor de waarde | `→`/`←` kiest b, `↑`/`↓` de waarde, `P` |
| wiel: ×2 / −w / +1 | klik de drie hendels op het wiel | `D` (dubbel) / `W` (min w) / `1` (plus één) |
| volgend bit (ijken) / Schuif (rollen) | knop | `Enter` |
| alarm: Controleer / Meld meteen / Negeer | drie knoppen naast het alarmlampje | `C` / `M` / `N` |
| kaart stempelen (Springer) | klik een sjabloonletter | `←`/`→` + `Enter` |
| sleutelteken kiezen | klik een teken op het lint (binnen het venster) | `K` = teken onder de laatste positie (pas vanaf 4-3 beschikbaar, en dan als enige snelkoppeling), of `←`/`→` + `Enter` |
| handsprong (Springer) | sleep het sjabloon | `→`/`←` + `Enter` |
| kaart ponsen (lampenbord) | klik een gatpositie op een kaart | `Tab` (kaart), `↑`/`↓` (rij), `Spatie` (gat aan/uit) |
| hendel (lampenbord) | trek de hendel omlaag | `S` of `↓` |
| kaart insteken | klik de kaart | typ de letter; `Spatie`/`0` = blanco |
| foutkabel steken (ruisbord) | sleep de kabel naar een aansluiting | `1`–`4` |
| schakelbord: ingang ↖ / ↑ / ← | klik het draadje bij de cel | `Spatie` of `Q` = ↖, `W` of `↑` = ↑, `A` of `←` = ← |
| zoeklicht: einde kiezen | klik een cel in de onderste rij | `←`/`→` + `Enter` |
| teruglopen | klik de buur waar de stroom vandaan komt | `Q`/`W`/`A` (zelfde richtingen) |
| tegenzet: tegel zetten | klik tegel (wisselt a/b of 0/1) | typ de letter, `←`/`→` |
| hint (Chef toont de juiste zet als spookhand) | Chef-icoon | `F1` (kost ★★★) |
| zet terugnemen (enkel CALM) | ⟲-knop | `Ctrl+Z` (kost ★★★) |
| pauze | knop links boven | `Esc` |
| debrief: misstap herbeleven | klik een stip | `←`/`→` + `Enter` |

Keuze: bij het lint werkt het toetsenbord het snelst (Spatie, pijltjes, Enter). In de ritmesectie typ je letters. De muis
blijft overal volwaardig, en slepen voelt het fysiekst. Alle toetsen staan op een kaartje in de pauze-notas.

### 4.2 Schermen & flow
```
Titel ──► Missiekaart ──► Briefing (≤ 8 s) ──► Console (level, 1..3 stages) ──► Debrief ──► Kaart / volgend level
  │ Esc→hub   │                                     │ Esc
  │           ├──► Nachtdienst (slot tot 4-1 ★)      └──► Pauze (Verder · Opnieuw · Notas · Instellingen · Kaart)
  └──► Instellingen
```
- **Titel** (`res://games/telex/scenes/title.tscn`): een telexmachine typt het logo **TELEX** letter per letter op een
  lint (tak-tak-tak, bel). Daaronder "Station Zoeklicht". Knoppen: **Diensten** (campagne), **Nachtdienst** (met slot),
  **Instellingen**, **Terug naar de speelhal**. `Esc` en "Terug" gaan naar `res://scenes/hub.tscn` (via `Transition`).
  Op de achtergrond (gedimd) loopt een attract-lint met de Springer die zelf springt (bot).
- **Missiekaart:** een kurkbord met de kustkaart. Acht **dossiermappen** (1 Het lint · 2 Vingerafdrukken · 3 De
  Doorloper · 4 De Springer · 5 Het lampenbord · 6 Ruis op de lijn · 7 Het schakelbord · 8 Het zoeklicht), verbonden
  met rode draad. In het midden de map **Operatie Ekster** (finale). Rechts boven het kaartje **Nachtdienst**. Een map
  opent een waaier levelkaartjes met 0–3 sterren en het pictogram van de nieuwe mechaniek. Hover toont de leerstof
  ("Oefening 39 · notas p. 62"). Het volgende level gaat open met ≥ 1 ★ op het vorige P0-level. Een dossier gaat open
  als alle P0-levels van het vorige dossier ≥ 1 ★ hebben. De finale opent als alle P0-levels ≥ 1 ★ hebben. P1/P2-levels
  sluiten nooit iets af.
- **Briefing:** de map klapt open: titel, codewoord(en) z op een kaartje, q/k indien relevant, modus ("eerste
  voorkomen" / "alle voorkomens"), notasverwijzing, één zin van de Chef. Bij een nieuwe machine gaat eerst de kist open
  (typeplaatje met jaartal, 1,5 s).
- **Console:** zie HUD (4.3). Een level kan meerdere **stages** hebben (bv. 3-2: ponsen → doorloop). Een stage-wissel
  is een korte animatie (de strook schuift van de ponsbank naar de Doorloper, 0,6 s).
- **Debrief:** §6.5.
- **Pauze:** Verder, Opnieuw, **Notas** (spiekbriefje), Instellingen, Missiekaart.
- **Instellingen:** muziek, geluid, schermschok 0/50/100 %, tekstgrootte 100/125 %, naaldsnelheid (normaal/snel),
  **live-tempo** 100 % / 80 % (toegankelijkheid; ★★★ telt dan als "met hulp"), kleurenblindmodus (groen/rood lampjes
  krijgen ook ✓/✕-vormen, lampen een rand), volledig scherm.
- **Notas (spiekbriefje):** een klembord met een tabblad per machine. Elk tabblad wordt zichtbaar zodra de machine
  binnen is. Per tab een mini-diagram en ≤ 5 regels met paginaverwijzing:
  - *Sjabloon:* "schuif telkens 1; vergelijk van links; stop bij de eerste mismatch" · "slechtst (n−m+1)·m" (p. 51).
  - *Vingerafdruk:* "h(s) = s als binair getal, mod q" · "rollen: ×2, −w als het uitgaande bit 1 is, +1 als het
    inkomende bit 1 is" · "w = 2^m mod q, één keer vooraf" · "zelfde vingerafdruk → controleren!" (p. 52–54).
  - *Doorloper:* "V[j] = kleinste s > 0 waarbij z[0..j−1−s] = z[s..j−1]; anders j; V[0] = 1" · "na het schuiven blijft de
    leeskop staan: gelijke_tekens = j − V[j]" · "spiegelrit: pons tot en met de mismatch met de huidige start; mismatch
    op 0 → V[start+1] = start+1" (p. 56–61) · (vanaf 3-4) "na een treffer: V[m]" (Oef. 41).
  - *Springer:* "vergelijk van rechts naar links" · "sleutelteken = t[i] onder de laatste positie" · "V_H(x) = afstand
    van de laatste x vóór de laatste positie tot het einde; anders m" (p. 63–66).
  - *Lampenbord:* "C_x: gat waar z[i] = x" · "hendel: alles 1 omlaag, bovenste aan" · "kaart t[j] insteken = AND" ·
    "onderste lamp = treffer eindigt op j" (p. 67–68).
  - *Ruisbord:* "M^l = voeding | (M^{l−1} oud, geschoven) | (M^l oud, geschoven & C)" (p. 71).
  - *Schakelbord:* "d[i][0] = i, d[0][j] = j" · "min(↖ + (gelijk ? 0 : 1), ↑ + 1, ← + 1)" · "↑ = verwijder t[i−1],
    ← = voeg t′[j−1] toe" (p. 74–75).
  - *Zoeklicht:* "bovenrij 0" · "kleinste waarde in de onderste rij = einde" · "terug tot rij 0 = begin" (p. 78–79).

### 4.3 HUD en layout (1920×1080)
```
y=0   ┌───────────────────────────────────────────────────────────────────────────────────────────┐
      │[II] DOSSIER 3 · 3-1 Barbados   z = barbados  (eerste)   TIKKEN 0034 ▕brute: 42▏  ◉◉◉  ★☆☆   │ 0–72
y=80  ├───────────────────────────────────────────────────────────────────────────────────────────┤
      │ versnipperaar ▓│ b a r b a a r s e _ b a r b e c u e _ i n _ b a r b a d o s │░ inlaat     │ 90–200  LINT
      │                  0 1 2 3 4 5 6 7 8 9 ...            ▲ leeskop                               │ 200–230 posities
      │                       [b a r b a d o s]  ← sjabloon (posities 0..7 erboven klein)           │ 230–320 SJABLOON
      │                       [1 1 2 3 3 3 6 7 | 8]  ← ponsstrook V (indien geponst)                │ 320–370
      ├───────────────────────────────────────────────────────────────────────────────────────────┤
      │                                                                                           │
      │          MACHINEPANEEL (wiel / kaartenbak / lampenbord / ruisbord / schakelbord)          │ 380–860
      │                                                                  ┌Chef-ballon┐            │
y=870 ├───────────────────────────────────────────────────────────────────────────────────────────┤
      │ DOSSIERKAART (z, q, k, modus) │ GEVONDEN: [barbados @22] │ contextknoppen │ kustkaartje  │ 870–1080
y=1080└───────────────────────────────────────────────────────────────────────────────────────────┘
```
- **Lint:** mono, tekens 44 px (\|t\| ≤ 40) en 32 px (langer). Positie eronder 18 px. Toont een venster van ±40 tekens
  rond de leeskop en volgt die (camera schuift mee, 0,25 s ease-out). Gelezen-gelijk = groene onderstreep; rood = de
  laatste mismatch; gemeld voorkomen = blauwe stempelband; gemist = rood (versnipperaar).
- **Sjabloon:** zelfde font en raster als het lint (een kolom = een kolom). Tanden onder elke letter.
- **Ponsstrook:** onder het sjabloon, vakje j onder sjabloonpositie j, plus een extra vakje "m" rechts (ALL-levels).
  Leeg = grijs met een gestippeld gat. Verbrand (3-5) = zwart geblakerd.
- **Tikteller:** rolcijfers, 4 posities; ernaast de geest-balk "brute kracht: N" (grijze balk die volloopt naarmate
  jouw teller stijgt; overschrijd je hem, dan kleurt hij amber).
- **◉◉◉ Vertrouwen** (3 lampjes): gaat uit bij een gemist codewoord of vals alarm (enkel zichtbaar gevolg, geen
  game-over in de campagne; in de Nachtdienst = levens).
- **Wielslagen / lampslagen / relais** vervangen de tikteller op hun machine (de tikteller blijft klein ernaast).
- **LIVE:** boven het lint een **lusbakmeter** (B vakjes, vult zich), de inlaat rolt zichtbaar binnen, de versnipperaar
  schuift mee. Bij < 1,5 s tot scheur knippert de lusbak amber en zakt de muziek naar lowpass.
- Lettergroottes: nergens < 16 px; contrast ≥ 4,5:1; lampen ook met vorm (kleurenblindmodus).

### 4.4 Machinepanelen (functionele layout)
- **Vingerafdruk:** in het midden een groot tandwiel (q tanden, cijfers 0..q−1 erop), de wijzer bovenaan. De rode
  inkeping staat op h(z). Rechts drie hendels ×2, −w, +1. Daaronder de bitvensterbalk: het venster t[i..i+m−1] als m
  lampjes met de gewichten 2^(m−1)…2^0 eronder, het uitgaande bit (links, vervagend) en het inkomende bit (rechts,
  oplichtend). Teller wielslagen. Alarmlampje met drie knoppen.
- **Ponsbank:** boven het lint z als "tekst" (met ⏎ voorbij het einde), daaronder de spookkopie. Onderaan de
  ponsstrook met de ponskop en een draaiknop voor de waarde.
- **Springer:** onder het sjabloon de **kaartenbak**: kaartjes met letter en getal, plus "overige = m". De getrokken
  kaart springt eruit en vliegt naar het sjabloon.
- **Lampenbord:** links de lampkolom (m lampen, letters z[i] ernaast, rij 0 boven), daarnaast de hendel, rechts het rek
  met ponskaarten (één per letter van z, alfabetisch, plus blanco), helemaal rechts de matrixlog (de matrix M die
  kolom per kolom gedrukt wordt, met t boven de kolommen: precies de tabel van p. 67).
- **Ruisbord:** k+1 lampkolommen (M⁰ links), tussen kolom l−1 en l de vier aansluitingen en de foutkabel. Elke kolom
  heeft een eigen bel (toonhoogte zakt per l).
- **Schakelbord / zoeklicht:** het rooster vult het hele paneel (cel 56 px bij ≤ 16 kolommen, anders 44 px). De
  letters van t′ (of t) staan boven, t (of z) links, telkens met de lege kolom/rij "0". Elke cel heeft drie korte
  ingangsdraadjes (↖ ↑ ←) en een meter met de waarde. Onder het rooster de herstelstrook.

---

## 5. Campagne

### 5.1 Algemene beslissingen
- **Acht dossiers + finale + Nachtdienst.** 27 levels, waarvan 19 P0 (§10). Per dossier één machine. Elk dossier start
  met het notasvoorbeeld (herkenbaar) en eindigt met de oefening uit de notas (examenvorm).
- **Modi:** CALM (alles behalve 3-5, 5-3, finale F-1 en de Nachtdienst) en LIVE. **Modus FIRST/ALL** per level (§3.0).
- **Tutorialstijl** (zoals Hash & Dash/Trietuin): bij de eerste keer doet een spookhand de handeling voor. Enkel het
  onderdeel dat je nu nodig hebt, gloeit. De Chef zegt ≤ 12 woorden. Een hint verschijnt pas na 6 s niets doen, en
  enkel de eerste keer.
- **Hulpafbouw:** `auto_zero` (mismatch op 0 schuift vanzelf) vanaf 3-1. `key_hint` (sleutelteken licht op) enkel in
  4-1/4-2. `auto_strip` (de Doorloper gebruikt de strook) enkel na een ponsstage. In de debrief verschijnt altijd de
  notas-weergave.
- **Sterren** zijn cumulatief (★★ vereist ★, ★★★ vereist ★★). "0 misstappen" = geen logentry met verdict ≠ OK en
  ≠ BUMP. Hints/terugnemen zijn geen misstap, maar ★★★ vraagt "zonder hulp" (§6.4).
- **Notatie in dit hoofdstuk:** (start, gelijke_tekens, eerste_mismatch) voor elke oproep van `vergelijk_strings`;
  "→ s" = de verschuiving daarna; "em 0 ×k" = k opeenvolgende mismatches op positie 0 (elk 1 tik, verschuiving 1).
  Lampkolommen als bitstring van rij 0 (boven) naar rij m−1 (onder), zoals de kolommen in de notas.
- **Stage-namen in §5 → stage-spec (§8.5):** `brute`, `rk`, `kmp_table`, `kmp`, `edit` zoals ze heten;
  `bmh_cards` = `bmh` met `"cards":"stamp"` zonder `t`; `bmh` = `bmh` met `"cards":"carry"`; `sa_cards` = `shift_and` met
  `"cards":"punch"`, `"run":false`; `wire` = `shift_and` met `"wiring":"plug"`, `"run":false`; `sa`/`sa_k` = `shift_and`
  met kaarten (en bedrading) `"carry"`; `approx` = `edit` met `"approx":true`; tegenzet = `sabotage`.

### 5.2 DOSSIER 1 — "Het lint" (Sjabloon, brute kracht)

#### 1-1 "Eerste dienst" (P0) — Algoritme 2, de console leren kennen
- **Nieuw:** lint, sjabloon, naald, tikteller, spoelmeter, buizenpost, versnipperaar, dossierkaart.
- **Stage:** brute, z = `kerk` (m = 4), t = `de_kerker_bij_de_kerk` (n = 21), ALL, CALM.
- **Verwacht verloop:** 18 uitlijningen (start 0..17). Tikken per uitlijning: 1, 1, 1, **4 (treffer @3, in `kerker`)**,
  1, 1, **4 (`ker_`: mismatch op 3)**, 1 ×10, **4 (treffer @17)** = **27 tikken**. Spoelmeter **4** (na start 3 en
  start 6 telkens 2 terug).
- **Intro (Chef):** "Schuif het sjabloon. De naald doet de rest." Na de eerste treffer: "In `kerker` zit ook een
  `kerk`." De spookhand drukt één keer Spatie.
- **Sterren:** ★ voltooid · ★★ 0 misstappen · ★★★ zonder hint en ≤ 60 s.
- **Debrief-extra:** "27 tikken voor 21 tekens. Waarom las de kop sommige letters twee keer?" (pijl naar de
  spoelmeter). Teaser: "Morgen komt er een machine die nooit terugspoelt."

#### 1-2 "Oefening 32: Stoorzender" (P0) — tegenzet, Θ(n²)
- **Nieuw:** tegenzet (tegels zetten, Verstuur, vijandige machine).
- **Stage A:** tegenzet `brute`, alfabet {a, b}, m = 4, n = 12, FIRST. Optimum **36** = (12 − 4 + 1)·4
  (bv. z = `aaab`, t = `aaaaaaaaaaaa`).
- **Stage B:** idem m = 8, n = 16. Optimum **72** = 9·8 (z = `aaaaaaab`, t = a^16).
  Exhaustief nagerekend: de enige optima zijn z = a^(m−1)b met t = a^n of a^(n−1)b, en hetzelfde met a en b omgewisseld.
- **Daarna (automatisch):** de grafiek "tikken vs. n" voor de familie z = a^(m−1)b, t = a^n met m = n/2 (n = 4, 6, …, 32).
  Jouw twee resultaten staan erop als stempels. De curve (n/2 + 1)·n/2 is een parabool: Θ(n²).
- **Intro:** "Laat hun machine stikken. Elke uitlijning moet tot het einde tikken."
- **Sterren:** ★ A ≥ 27 en B ≥ 54 · ★★ A = 36 of B = 72 · ★★★ beide optimaal.
- **Debrief-extra:** het antwoord op Oef. 32 in één zin: "z = a…ab, t = a…a: elke start kost m tikken en er is geen
  treffer, dus (n − m + 1)·m; met m = n/2 is dat Θ(n²)."

#### 1-3 "Oefening 33: Jokers" (P2) — wildcard `?`
- Stage brute met joker: z = `?uizen`, t = `de_huizen_en_buizen` (n = 19), ALL. `?` geeft altijd groen (1 tik).
  Treffers @3 (`huizen`) en @13 (`buizen`), **36 tikken**.

### 5.3 DOSSIER 2 — "Vingerafdrukken" (Rabin-Karp, bitstrings)

#### 2-1 "Het wiel" (P0) — h(s) mod q, Horner, gewicht w, gelijke vingerafdruk ≠ gelijke string
- **Nieuw:** hashwiel (q = 7), ×2, +1, rode inkeping, alarmlampje, Controleer.
- **Eén rk-stage** met `prep` = [w, hz] en daarna `signals` (de deelstappen A–C hieronder zijn fasen van die stage).
- **Stage A "Gewicht":** wiel op 1, m = 4 keer ×2: 2, 4, 1, 2 → **w = 2^4 mod 7 = 2** (4 wielslagen). Het gewicht
  verschijnt als tandwieltje "−2".
- **Stage B "Vingerafdruk van z":** z = `1011`. Horner: bit 1: ×2, +1 → 1 · bit 0: ×2 → 2 · bit 1: ×2, +1 → 5 · bit 1:
  ×2, +1 → 11 mod 7 = **4** (7 wielslagen). De rode inkeping komt op 4.
- **Stage C "Drie signalen":** reken telkens met Horner (wiel eerst op 0):
  `0100` → 0, 1, 2, **4** → alarm → Controleer: z[0] = 1 ≠ 0: **hashbotsing** (1 tik) ·
  `1011` → 1, 2, 5, **4** → alarm → Controleer: 4 tikken, **treffer** ·
  `1110` → 1, 3, 0, **0** → geen alarm.
- **Totaal:** 30 wielslagen, 5 tikken.
- **Intro:** "Het wiel kent maar zeven standen. Daar zit de modulo in." Bij het eerste alarm: "Zelfde vingerafdruk?
  Controleer het woord."
- **Sterren:** ★ voltooid · ★★ 0 misstappen · ★★★ zonder hint/terugnemen.

#### 2-2 "Rollen" (P0) — de rollende update (p. 53)
- **Nieuw:** bitvenster, −w, uitgaand/inkomend bit, Schuif, Meld meteen / Negeer.
- **Stage:** rk, z = `1011`, q = 7 (w = 2 en h(z) = 4 voorgezet uit 2-1), t = `1010010110110100` (n = 16), ALL.
- **Verwacht:** eerste venster `1010` met Horner: 1, 2, 5, **3** (6 slagen). Daarna (uit, in → h):

| i | venster | uit | in | 2h − uit·w + in (mod 7) | alarm |
|---|---|---|---|---|---|
| 1 | 0100 | 1 | 0 | 6 − 2 + 0 = **4** | botsing (1 tik) |
| 2 | 1001 | 0 | 1 | 9 → **2** | |
| 3 | 0010 | 1 | 0 | 4 − 2 = **2** | |
| 4 | 0101 | 0 | 1 | **5** | |
| 5 | 1011 | 0 | 1 | 11 → **4** | **treffer @5** (4 tikken) |
| 6 | 0110 | 1 | 0 | 8 − 2 = **6** | |
| 7 | 1101 | 0 | 1 | 13 → **6** | |
| 8 | 1011 | 1 | 1 | 12 − 2 + 1 = 11 → **4** | **treffer @8** (4 tikken) |
| 9 | 0110 | 1 | 0 | **6** | |
| 10 | 1101 | 0 | 1 | **6** | |
| 11 | 1010 | 1 | 0 | 12 − 2 = 10 → **3** | |
| 12 | 0100 | 1 | 0 | 6 − 2 = **4** | botsing (1 tik) |

  **13 vensters, 10 tikken, 31 wielslagen** (6 + 25). Brute kracht (ALL): 29 tikken.
- **Intro:** "Wat links wegvalt, moet eruit: −w als dat bit 1 was."
- **Sterren:** ★ ≥ 1 treffer · ★★ 0 misstappen (2 treffers, botsingen gecontroleerd) · ★★★ zonder hint/terugnemen.

#### 2-3 "Oefening 34" (P0) — z = 00101, q = 13 (p. 54)
- **Stage:** rk, z = `00101`, q = 13, t = `1101110010001010` (n = 16, m = 5), **FIRST**, niets voorgezet.
- **IJken:** w: 2, 4, 8, 3, **6** (5 slagen) · h(z): 0, 0, 1, 2, **5** (7 slagen) · eerste venster `11011`: 1, 3, 6, 0,
  **1** (9 slagen).
- **Rollen** (i = 1..10): hashwaarden **10, 1, 2, 12, 5, 4, 8, 4, 2, 5**. Alarm bij i = 5 (`10010` = 18 ≡ 5): **hashbotsing**,
  1 tik. Alarm bij i = 10 (`00101`): **treffer @10**, 5 tikken, stop.
- **Totaal:** 11 vensters, **6 tikken**, **41 wielslagen**. Brute kracht (FIRST): 23 tikken.
- **Intro:** titelkaart "Oefening 34 — lesnotas p. 54". Chef: "Dertien tanden, vijf bits."
- **Sterren:** ★ treffer @10 · ★★ 0 misstappen · ★★★ zonder hint/terugnemen en ≤ 150 s.
- **Debrief-extra:** tabel i | venster | h zoals een uitgewerkte oplossing. De rij i = 5 is gemarkeerd als
  "hashbotsing: 18 ≡ 5 (mod 13)".

#### 2-4 "Oefening 34b: Botsingsregen" (P1) — tegenzet
- Tegenzet `rk_calls`: z = `00101`, q = 13 vast, t = 16 bits, FIRST. Metriek: aantal oproepen van `strings_gelijk`.
- **Optimum 12** (elk venster), uniek: t = `1111111111111111` (11111 = 31 ≡ 5 mod 13).
- **Sterren:** ★ ≥ 6 · ★★ ≥ 10 · ★★★ 12.
- **Debrief:** "Elke 11111 botst: 31 = 2·13 + 5. Opmerking 10: in het slechtste geval blijft het O((n − m + 1)·m)."

### 5.4 DOSSIER 3 — "De Doorloper" (KMP)

#### 3-1 "Barbados" (P0) — Definitie 11 met de hand (notasvoorbeeld p. 58–59)
- **Nieuw:** tanden (passen/botsen), leeskop blijft staan, `auto_zero`.
- **Stage:** kmp zonder strook, z = `barbados` (m = 8), t = `barbaarse_barbecue_in_barbados` (n = 30), FIRST.
- **Verwacht:** (0,0,5) → **3** · (3,2,2) → **2** · em 0 ×5 (start 5..9) · (10,0,4) → **3** · (13,1,1) → **1** ·
  em 0 ×8 (start 14..21) · (22,0,8) **treffer @22**. Precies de mismatchreeks 5, 2, 0, …, 4, 1, …, 8 van p. 58–59.
- **Passende verschuivingen** (de tanden): na em 5: {3, 5, ≥ 5}, na em 2: {2, ≥ 2}, na em 4: {3, 4, ≥ 4}, na em 1:
  {1, …}. 1 en 2 na em 5, en 1 en 2 na em 4 klemmen.
- **Totaal:** 18 uitlijningen, **34 tikken**, spoelmeter 0. Brute kracht: 42 tikken (23 uitlijningen, spoelmeter 8).
- **Intro:** spookhand sleept bij de eerste mismatch langzaam 1 (botst), 2 (botst), 3 (klikt in). Chef: "Wat je al
  las, moet blijven kloppen. De kleinste sprong die past."
- **Sterren:** ★ treffer · ★★ 0 misstappen · ★★★ 0 klemmen en zonder hint.
- **Debrief-extra:** "Jouw sprongen 3, 2, 3, 1 staan in de tabel van p. 56: V[5] = 3, V[2] = 2, V[4] = 3, V[1] = 1."
  De notas-weergave toont de v-diagrammen van p. 58–59.

#### 3-2 "De spiegel — Oefening 40" (P0) — V[] ponsen volgens Definitie 11, dan Oef. 40
- **Nieuw:** ponsbank, spookkopie, ponsstrook, `auto_strip`.
- **Stage A:** kmp_table `def11`, z = `ananas` (m = 6). Voorgeponst V[0] = V[1] = 1. Te ponsen vakjes 2..5.
  Passende waarden: j = 2: {2}; j = 3: {2, 3}; j = 4: {2, 4}; j = 5: {2, 4, 5}. **Correct: V = 1 1 2 2 2 2.**
- **Stage B:** kmp met de strook uit A, `auto_strip`, `auto_zero`, t = `bananen_in_ra'ananas'_centrum` (n = 29), FIRST.
  (0,0,0) → 1 · (1,0,4) → **2** · (3,2,2) → **2** · em 0 ×7 (start 5..11) · (12,0,1) → 1 · (13,0,0) → 1 ·
  (14,0,6) **treffer @14**. 13 uitlijningen, **23 tikken**. Brute kracht: 27.
- **Intro:** "Pons de strook. Wat zou je doen bij elke mismatch?"
- **Sterren:** ★ treffer · ★★ 0 misstappen (strook exact) · ★★★ 0 klemmen en zonder hint.
- **Debrief-extra:** "Oefening 40: V = 1 1 2 2 2 2. Met V[4] = 4 (past ook!) had de Doorloper op start 1 te ver
  gesprongen." (spookweergave van de gevolgen van PUNCH_LONG).

#### 3-3 "Spiegelrit — Oefening 39" (P0) — Algoritme 5, dan Oef. 39
- **Nieuw:** spiegelrit (z in zichzelf zoeken), ponskop met draaiknop, end_of_line ⏎.
- **Stage A:** kmp_table `alg5`, z = `volvoert` (m = 8). Exacte stappen (naald automatisch, speler pons + schuif):

| stap | start | gel. | naald | em | pons (vakjes = waarde) | schuif V[em] |
|---|---|---|---|---|---|---|
| 1 | 1 | 0 | v≠o (1 tik) | 0 | V[2] = 2 | 1 |
| 2 | 2 | 0 | v≠l (1 tik) | 0 | V[3] = 3 | 1 |
| 3 | 3 | 0 | v=v, o=o, l≠e (3 tikken) | 2 | V[4] = V[5] = 3 | V[2] = 2 |
| 4 | 5 | 0 | v≠e (1 tik) | 0 | V[6] = 6 | 1 |
| 5 | 6 | 0 | v≠r (1 tik) | 0 | V[7] = 7 | 1 → start 7: klaar |

  **V = 1 1 2 3 3 3 6 7**, 7 tikken in de spiegelrit. Dit is exact de opbouw van `barbados` op p. 61–62 (dezelfde
  stappen, dezelfde strook).
- **Stage B:** kmp met de strook, t = `volvo_vol_vogels_volvoert_kunststukje` (n = 37), FIRST.
  (0,0,5) → **3** · (3,2,2) → **2** · (5,0,0) → 1 · (6,0,3) → **3** · (9,0,0) → 1 · (10,0,2) → **2** · em 0 ×5
  (start 12..16) · (17,0,8) **treffer @17**. 12 uitlijningen, **29 tikken**. Brute kracht: 37 tikken (18
  uitlijningen, spoelmeter 8).
- **Intro:** titelkaart "Oefening 39 — p. 62". Chef: "Zoek het woord in zichzelf. Wat je onderweg leert, pons je."
- **Sterren:** ★ treffer · ★★ 0 misstappen · ★★★ zonder hint en ≤ 180 s.
- **Debrief-extra:** "Dezelfde strook als `barbados` (p. 56): V hangt enkel af van hoe z op zichzelf past."

#### 3-4 "Oefening 41: Alle voorkomens" (P1) — V[m] en overlappende treffers
- **Nieuw:** het vakje V[m] ("na een treffer"), ALL bij de Doorloper.
- **Stage A:** kmp_table `alg5`, z = `tata` (m = 4): stap 1: start 1, t≠a, em 0 → V[2] = 2, schuif 1 · stap 2: start 2,
  t=t, a=a, t≠⏎ (3 tikken), em 2 → **V[3] = V[4] = 2** (hier vult Algoritme 5 V[m] zelf), schuif V[2] = 2 → start 4:
  klaar. **V = 1 1 2 2 | 2.**
- **Stage B:** kmp ALL, t = `tatatata_zei_de_telex_tatata` (n = 28): (0,0,4) **treffer @0** → V[4] = 2 · (2,2,4)
  **@2** → 2 · (4,2,4) **@4** → 2 · (6,2,2) → 2 · em 0 ×8 (start 8..15) · (16,0,1) → 1 · em 0 ×5 (17..21) · (22,0,4)
  **@22** → 2 · (24,2,4) **@24** → 2 (start 26 > n − m: klaar). **5 treffers, 20 uitlijningen, 30 tikken.** Brute kracht
  (ALL): 43 tikken, spoelmeter 9.
- **Intro:** "Na een treffer niet stoppen. Hoe ver mag je dan?"
- **Sterren:** ★ ≥ 3 treffers · ★★ 0 misstappen · ★★★ zonder hint.

#### 3-5 "Nachtstroom" (P1, LIVE) — geschikt voor streams
- **Nieuw:** LIVE, lusbak, scheur, verbrande vakjes, rivaal.
- **Stage:** kmp ALL met strook `1 1 2 2 ▓ | ▓` (V[4] en V[5] verbrand), `auto_strip`, `auto_zero`, z = `kokos`
  (m = 5), t = `kokokokos_in_de_kokoskokosnoot` (n = 30), **v = 0,8 teken/s, B = 4**.
- **Verwacht:** (0,0,4) → **2** (hand: verbrand vakje; passend {2, 4}) · (2,2,4) → **2** (hand) · (4,2,5) **treffer @4**
  → **5** (hand: V[5] = 5) · em 0 ×7 (start 9..15) · (16,0,5) **@16** → 5 · (21,0,5) **@21** → 5. 12 uitlijningen,
  **28 tikken**. Beslistijd per handverschuiving ≈ B / v = 5 s voor het lint scheurt.
- **Rivaal:** op een tweede spoor loopt een automatische brute-krachtmachine met dezelfde lusbak B = 4. Model:
  onmiddellijk lezen zodra een teken binnen is. Ze scheurt 5 keer (bij F = 5, 7, 9, 21, 26) en **mist alle drie**
  `kokos`. Met B ≥ 5 = m zou ze alle drie vinden (nagerekend). De Chef: "Zij moet terug. Jij niet."
- **Sterren:** ★ ≥ 2 treffers · ★★ 3 treffers en 0 misstappen · ★★★ geen scheur en zonder hint.

### 5.5 DOSSIER 4 — "De Springer" (Boyer-Moore-Horspool)

#### 4-1 "Barbara" (P0) — het notasvoorbeeld (p. 64–65)
- **Nieuw:** naald van rechts naar links, sleutelteken (oplichtend), kaartenbak, stempelen, sprong.
- **Stage A:** bmh_cards, z = `barbara` (m = 7). Stempel posities 0..5 (in die volgorde): b→6, a→5, r→4, b→3, a→2, r→1.
  Eindkaarten: **a = 2, b = 3, r = 1, overige = 7** (= tabel p. 65). Positie 6 stempelen klemt.
- **Stage B:** bmh, t = `barbados_zoekt_barbara` (n = 22), FIRST, `key_hint`. Uitlijningen (i, sleutel, sprong,
  tikken): (6, `o`, 7, 1) · (13, `t`, 7, 1) · (20, `r`, 1, 1) · (21, `a`, —, 7) **treffer @15**. 4 uitlijningen,
  **10 tikken**. Brute kracht: 29.
- **Intro:** "Kijk onder de laatste letter. Spring zo ver als het mag."
- **Sterren:** ★ treffer · ★★ 0 misstappen · ★★★ zonder hint.

#### 4-2 "Oefening 48" (P0)
- **Stage A:** bmh_cards, z = `ananas`: stempels 0..4: a→5, n→4, a→3, n→2, a→1 → **a = 1, n = 2, overige = 6**. Let op:
  `s` staat enkel op de laatste positie en krijgt dus geen kaart ("overige": 6). Positie 5 stempelen klemt.
- **Stage B:** bmh, t = `de_spa_in_ra'ananas'` (n = 20), FIRST, `key_hint`: (5, `a`, 1, 1) · (6, `_`, 6, 1) ·
  (12, `'`, 6, 1) · (18, `s`, —, 6) **treffer @13**. 4 uitlijningen, **9 tikken**. Brute kracht: 21.
- **Intro:** titelkaart "Oefening 48 — p. 66".
- **Sterren:** ★ treffer · ★★ 0 misstappen · ★★★ zonder hint.

#### 4-3 "Walsalsa" (P0) — het sleutelteken is niet het mismatchteken
- **Nieuw:** geen `key_hint`; mismatches dieper in het sjabloon.
- **Stage A:** bmh_cards, z = `salsa` (m = 5): stempels 0..3: s→4, a→3, l→2, s→1 → **a = 3, l = 2, s = 1, overige = 5**.
- **Stage B:** bmh ALL, t = `de_band_speelt_walsalsa_en_salsa` (n = 32):

| i | venster | naald (rechts→links) | tikken | sleutel t[i] | sprong | val |
|---|---|---|---|---|---|---|
| 4 | `de_ba` (start 0) | a=a, s≠b | 2 | `a` | 3 | mismatchteken `b` zou 5 geven |
| 7 | `band_` (start 3) | `_`≠a | 1 | `_` | 5 | |
| 12 | `speel` (start 8) | l≠a | 1 | `l` | 2 | |
| 14 | `eelt_` (start 10) | `_`≠a | 1 | `_` | 5 | |
| 19 | `walsa` (start 15) | a=a, s=s, l=l, a=a, **w≠s** | 5 | `a` | **3** | **mismatchteken `w` → 5: `salsa` @18 ontsnapt** |
| 22 | `salsa` (start 18) | 5 × gelijk | 5 | `a` | 3 | **treffer @18** |
| 25 | `sa_en` (start 21) | n≠a | 1 | `n` | 5 | |
| 30 | `_sals` (start 26) | s≠a | 1 | `s` | 1 | |
| 31 | `salsa` (start 27) | 5 × gelijk | 5 | `a` | 3 | **treffer @27** (i = 34: klaar) |

  **9 uitlijningen, 22 tikken.** Brute
  kracht (ALL): 39.
- **Intro:** "Het teken waar het misging? Nee: kijk onder de laatste letter."
- **Sterren:** ★ ≥ 1 treffer · ★★ 0 misstappen · ★★★ zonder hint.
- **Debrief-extra:** als de speler bij i = 19 `w` koos: herbeleving met de gemiste `salsa`; coachzin WRONG_KEY.

#### 4-4 "Oefening 50: Vliegen en kruipen" (P1) — tegenzet
- **Stage A** tegenzet `bmh_min`: n = 16, m = 4, {a, b}, z mag niet in t voorkomen. Optimum **4** (bv. z = `bbbb`,
  t = a^16; Θ(n/m)).
- **Stage B** tegenzet `bmh_max`: Optimum **52** = (16 − 4 + 1)·4, enkel z = `baaa`, t = a^16 of z = `abbb`, t = b^16
  (Θ(n·m)).
- **Sterren:** ★ A ≤ 6 en B ≥ 40 · ★★ één optimaal · ★★★ beide.

### 5.6 DOSSIER 5 — "Het lampenbord" (shift-AND)

#### 5-1 "Ana" (P0) — Figuur 23 (p. 67–69)
- **Nieuw:** ponskaarten, hendel, voedingslamp, kaart insteken, bel, matrixlog.
- **Stage A:** sa_cards, z = `ana`: **C_a = 101, C_n = 010** (blanco = 000).
- **Stage B:** sa, t = `ananas` (n = 6), ALL. Kolommen: j0 `a` 100 · j1 `n` 010 · j2 `a` **101 (bel: eindigt op 2,
  begint op 0)** · j3 `n` 010 · j4 `a` **101 (bel: eindigt op 4, begint op 2)** · j5 `s` 000. Matrixlog = de tabel van
  p. 67. 6 lampslagen (brute kracht ALL: 8 tikken).
- **Intro:** "Omlaag, bovenste aan, kaart erin. Licht onderaan? Bel!"
- **Sterren:** ★ voltooid · ★★ 0 misstappen · ★★★ zonder hint.
- **Debrief-extra:** de vijf kaders van Figuur 23 (j = 1..5: geschoven kolom & C = nieuwe kolom).

#### 5-2 "Oefening 54" (P0)
- **Stage A:** sa_cards, z = `zoeken`: **C_e = 001010, C_k = 000100, C_n = 000001, C_o = 010000, C_z = 100000.**
- **Stage B:** sa, t = `iets_zoets_zoeken` (n = 17), ALL. Kolommen: j0–j4 (`iets_`) 000000 (let op: `e` op j1 geeft
  100000 & 001010 = 000000) · j5 `z` 100000 · j6 `o` 010000 · j7 `e` 001000 · j8 `t` 000000 · j9 `s` 000000 · j10 `_`
  000000 · j11 `z` 100000 · j12 `o` 010000 · j13 `e` 001000 · j14 `k` 000100 · j15 `e` 000010 · j16 `n` **000001 (bel:
  eindigt op 16, begint op 11)**. 17 lampslagen (brute kracht: 20 tikken).
- **Intro:** titelkaart "Oefening 54 — p. 69". Chef: "Letters die niet in `zoeken` staan? Blanco."
- **Sterren:** ★ bel op 16 · ★★ 0 misstappen · ★★★ zonder hint.

#### 5-3 "Tiktak" (P1, LIVE ritme) — "veel treffers" (p. 67)
- **Nieuw:** `auto_lever` op de tel, ritme.
- **Stage:** sa ALL, z = `tik` (kaarten voorgeponst: t 100, i 010, k 001), t =
  `tiktak_tiktiktak_tik_taktik_tikkertje_tiktik` (n = 44), 100 BPM (0,6 s per teken). De hendel gaat vanzelf op elke
  tel. De speler steekt vóór de volgende tel de kaart (typ t/i/k). Bij andere tekens doet hij niets: blanco is
  automatisch en correct.
- **Verwacht:** 32 tekens vragen een kaart, 12 niet. **8 bellen**, eindes 2, 9, 12, 19, 26, 30, 40, 43 (begin 0, 7,
  10, 17, 24, 28, 38, 41).
- **Sterren:** ★ ≥ 6 bellen · ★★ 8 bellen en 0 misstappen · ★★★ ★★ en ≥ 24 van de 32 kaarten "strak" (≤ 0,2 s na de
  tel).

### 5.7 DOSSIER 6 — "Ruis op de lijn" (shift-AND met k mismatches)

#### 6-1 "Oefening 60" (P0) — Definitie 14, k = 1
- **Nieuw:** twee lampkolommen M⁰/M¹, foutkabel, vier aansluitingen, bel per kolom.
- **Stage A:** sa_cards, z = `dank`: **C_a = 0100, C_d = 1000, C_k = 0001, C_n = 0010.**
- **Stage B:** wire, k = 1: de foutkabel van M¹ correct in **`oud ↓`** (= shift(M⁰[][j−1])).
- **Stage C:** sa_k, t = `een_dansfeest` (n = 13), k = 1, ALL. Kolommen M⁰ / M¹: j0–j3 (`een_`) 0000 / 1000 · j4 `d`
  1000 / 1000 · j5 `a` 0100 / 1100 · j6 `n` 0010 / 1010 · j7 `s` 0000 / **1001 (bel M¹: `dank` met ≤ 1 fout eindigt op 7
  = `dans`, begint op 4)** · j8–j12 (`feest`) 0000 / 1000. M⁰ belt nooit.
- **Gevolg van foute kabel (nagerekend, voor de debrief):** `oud` → geen bel (gemist) · `nieuw ↓` → bel op j = 6
  (vals alarm, en `dans` gemist) · `nieuw` → geen bel (gemist).
- **Intro:** titelkaart "Oefening 60 — p. 71". Chef: "Eén fout mag. Waar komt die fout vandaan?"
- **Sterren:** ★ bel op 7 · ★★ 0 misstappen · ★★★ zonder hint.

#### 6-2 "Zender of zonder?" (P1) — vier kandidaten, één echte
- **Stage A:** sa_cards, z = `zender`: C_d 000100, C_e 010010, C_n 001000, C_r 000001, C_z 100000. **Stage B:** wire k = 1.
- **Stage C:** sa_k, t = `zonder_zender_zander_zinder` (n = 27), k = 1, ALL. **M¹ belt op 5, 12, 19, 26** (`zonder`,
  `zender`, `zander`, `zinder`), **M⁰ enkel op 12**.
- **Stage D (keuze):** "Stuur de ploeg naar de echte zender": klik één van de vier stempels. Correct: @7 (M⁰). Een
  andere = vals alarm.
- **Sterren:** ★ ploeg naar @7 · ★★ 0 misstappen · ★★★ zonder hint.

### 5.8 DOSSIER 7 — "Het schakelbord" (editeerafstand, Algoritme 7)

#### 7-1 "Lessen → feesten" (P0) — Definitie 15, Algoritme 7 (p. 72–76)
- **Nieuw:** relais, ingangen ↖ ↑ ←, gelijk-lampje, teruglopen, herstelstrook.
- **Stage:** edit, t = `lessen` (rijen), t′ = `feesten` (kolommen). 42 cellen. **Verwachte tabel (= p. 76):**
```
        f e e s t e n
      0 1 2 3 4 5 6 7
  l   1 1 2 3 4 5 6 7
  e   2 2 1 2 3 4 5 6
  s   3 3 2 2 2 3 4 5
  s   4 4 3 3 2 3 4 5
  e   5 5 4 3 3 3 3 4
  n   6 6 5 4 4 4 4 3
```
  **d = 3.** Vier kortste reeksen (teruglopen, telkens in stijgende volgorde, posities in de string van dat moment):
  1. voeg `f` toe op 0 · vervang `l` op 1 door `e` · vervang `s` op 4 door `t`
  2. vervang `l` op 0 door `f` · voeg `e` toe op 1 · vervang `s` op 4 door `t` (= de reeks van Definitie 15, p. 72, in
     stijgende volgorde)
  3. vervang `l` op 0 door `f` · voeg `e` toe op 2 · vervang `s` op 4 door `t`
  4. vervang `l` op 0 door `f` · vervang `s` op 2 door `e` · voeg `t` toe op 4 (= de lijn in de figuur op p. 76)
- **Intro:** "De stroom neemt altijd de kortste weg. Jij ook."
- **Sterren:** ★ teruggelopen (de strook print `feesten`) · ★★ 0 misstappen · ★★★ zonder hint en 2 verschillende
  kortste reeksen.

#### 7-2 "Oefening 62" (P0) — roestig → oesters
- **Stage:** edit, t = `roestig`, t′ = `oesters`. 49 cellen.
```
        o e s t e r s
      0 1 2 3 4 5 6 7
  r   1 1 2 3 4 5 5 6
  o   2 1 2 3 4 5 6 6
  e   3 2 1 2 3 4 5 6
  s   4 3 2 1 2 3 4 5
  t   5 4 3 2 1 2 3 4
  i   6 5 4 3 2 2 3 4
  g   7 6 5 4 3 3 3 4
```
  **d = 4.** Drie kortste reeksen:
  1. verwijder `r` op 0 · voeg `e` toe op 4 · vervang `i` op 5 door `r` · vervang `g` op 6 door `s`
  2. verwijder `r` op 0 · vervang `i` op 4 door `e` · voeg `r` toe op 5 · vervang `g` op 6 door `s`
  3. verwijder `r` op 0 · vervang `i` op 4 door `e` · vervang `g` op 5 door `r` · voeg `s` toe op 6
- **Intro:** titelkaart "Oefening 62 — p. 76". Chef: "Toon hoe elk getal ontstond."
- **Sterren:** ★ voltooid · ★★ 0 misstappen · ★★★ alle drie reeksen gevonden ("beschrijf de mogelijke kortste
  reeksen").

### 5.9 DOSSIER 8 — "Het zoeklicht" (Algoritme 8)

#### 8-1 "Examen" (P0) — notasvoorbeeld p. 79
- **Nieuw:** stroomrail op 0, zoeklicht (minimum onderaan), teruglopen tot rij 0.
- **Stage:** approx, z = `examen` (rijen), t = `de_armen_vouwen` (n = 15). Rijen 0..3 (ε, e, x, a) voorgevuld zoals
  p. 79. De speler vult rij m, e, n (45 cellen).
```
        d e _ a r m e n _ v o u w e n
      0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
  e   1 1 0 1 1 1 1 0 1 1 1 1 1 1 0 1
  x   2 2 1 1 2 2 2 1 1 2 2 2 2 2 1 1
  a   3 3 2 2 1 2 3 2 2 2 3 3 3 3 2 2
  m   4 4 3 3 2 2 2 3 3 3 3 4 4 4 3 3
  e   5 5 4 4 3 3 3 2 3 4 4 4 5 5 4 4
  n   6 6 5 5 4 4 4 3 2 3 4 5 5 6 5 4
```
  **Minimum 2 in kolom 8** (einde t[7]). Teruglopen (uniek): (6,8) ↖ (5,7) ↖ (4,6) ↖ (3,5) ← (3,4) ↖ (2,3) ↖ (1,2) ↖
  (0,1): rail verlaten in kolom **1** → match t[1..7] = **`e_armen`**. Bewerkingen: vervang `x` op 1 door `_` · voeg `r`
  toe op 3 (`examen` → `e_amen` → `e_armen`). Dit is de lijn van p. 79.
- **Intro:** "Nu mag de stroom overal instappen. Waar komt ze het goedkoopst uit?"
- **Sterren:** ★ match gemeld · ★★ 0 misstappen · ★★★ zonder hint.

#### 8-2 "Oefening 70" (P0) — zoeken in koekjes_kweken
- **Stage:** approx, z = `zoeken`, t = `koekjes_kweken` (n = 14), 84 cellen.
```
        k o e k j e s _ k w e k e n
      0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
  z   1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
  o   2 2 1 2 2 2 2 2 2 2 2 2 2 2 2
  e   3 3 2 1 2 3 2 3 3 3 3 2 3 2 3
  k   4 3 3 2 1 2 3 3 4 3 4 3 2 3 3
  e   5 4 4 3 2 2 2 3 4 4 4 4 3 2 3
  n   6 5 5 4 3 3 3 3 4 5 5 5 4 3 2
```
  **Minimum 2, enkel in kolom 14.** Drie beste matches (alle met afstand 2):
  `kweken` (begin 8: vervang `z` op 0 door `k`, vervang `o` op 1 door `w`) · `weken` (begin 9: verwijder `z` op 0,
  vervang `o` op 0 door `w`; of vervang `z` op 0 door `w`, verwijder `o` op 1) · `eken` (begin 10: verwijder `z` op 0,
  verwijder `o` op 0).
- **Intro:** titelkaart "Oefening 70 — p. 79".
- **Sterren:** ★ een beste match gemeld · ★★ 0 misstappen · ★★★ alle drie beginposities (8, 9, 10) gevonden.

#### 8-3 "Oefening 71" (P0) — test in beste_tekst
- **Stage:** approx, z = `test`, t = `beste_tekst` (n = 11), 44 cellen.
```
        b e s t e _ t e k s t
      0 0 0 0 0 0 0 0 0 0 0 0
  t   1 1 1 1 0 1 1 0 1 1 1 0
  e   2 2 1 2 1 0 1 1 0 1 2 1
  s   3 3 2 1 2 1 1 2 1 1 1 2
  t   4 4 3 2 1 2 2 1 2 2 2 1
```
  **Minimum 1 in kolommen 4, 7 en 11.** Matches: kolom 4: `best` (begin 0, vervang `t` op 0 door `b`) en `est` (begin 1,
  verwijder `t` op 0) · kolom 7: `te_t` (begin 3, vervang `s` op 2 door `_`) · kolom 11: `tekst` (begin 6, voeg `k` toe
  op 2).
- **Sterren:** ★ ≥ 1 beste match · ★★ alle drie eindes gemeld en 0 misstappen · ★★★ alle vier matches (ook `est`).

### 5.10 FINALE — "Operatie Ekster" (P1)
Drie linten, één nacht. Per lint kies je de machine uit het rek (alle machines die je hebt). De voorbereiding doe je
zelf (ponsen, stempelen, kaarten, bedraden). De doorloop speelt de machine daarna **zelf** met jouw tabellen
(`auto_*` overal aan; de "automaat" die je in de campagne verdiend hebt). Fouten in je tabellen hebben dus gevolgen.
Kostenmaat **machinetijd**: tik = 1, lampslag = 1 (een volledige kolom, ook bij M^k), relais = 1, wielslag = 1.

| lint | opdracht | eigenschap | gevolg per machine (nagerekend) |
|---|---|---|---|
| F-1 "Morsestroom" (LIVE, v = 2,0/s, **B = 1**) | z = `ekster`, t = `kom_naar_de_ekster_want_de_eksters_eten_ekster_brood` (n = 52), ALL; treffers @12, 27, 40 | geen buffer | **Doorloper** 51 tikken ✓ · **Lampenbord** 52 lampslagen ✓ · Springer / Sjabloon: B < m → het lint scheurt steeds → gemist (de Vingerafdruk leest enkel bits en staat in de finale niet in het rek) |
| F-2 "Ruis" (CALM) | z = `ekster`, t = `de_ekstar_zag_de_akster_op_het_dak` (n = 34): vind de verminkte codewoorden | geen exact voorkomen | **Ruisbord k = 1**: M¹ belt op eindes 8 en 22 (begin 3, 17), 34 lampslagen ✓ · **Zoeklicht**: minimum 1 in kolommen 9 en 23 ✓ (204 relais) · exacte machines: 0 treffers → 2 gemist |
| F-3 "Het dikke dossier" (CALM, budget 60 machinetijd) | z = `vuurtoren` (m = 9), t = `de_wachter_van_de_vuurtoren_ziet_om_middernacht_een_boot_zonder_licht_en_seint_naar_de_tweede_vuurtoren_aan_de_haven` (n = 116), ALL; treffers @18, 94 | lang lint, groot alfabet | **Springer** 33 tikken (17 uitlijningen; kaarten v 8, u 6, r 2, t 4, o 3, e 1, overige 9) ✓ · Doorloper 109 / Lampenbord 116 / Sjabloon 125: budget op na ±60 → rest onverwerkt → @94 gemist |

- **Sterren:** ★ ≥ 5 van de 7 codewoorden · ★★ alle 7, geen vals alarm · ★★★ totale machinetijd ≤ 120 (beste keuzes:
  51 + 34 + 33 = 118).
- **Slot:** de kustkaart licht op, alle spelden worden groen, de Ekster-koeriers worden opgepakt. Aftiteling als
  telexlint. De Chef: "Goed gelezen, lintlezer."

### 5.11 NACHTDIENST (eindeloze modus, P0; slot: 4-1 ≥ 1 ★)
- **Machine:** de Springer **zonder kaartenbak** en zonder `key_hint`. Bij elke stop klik je de sjabloonletter die
  onder het sleutelteken moet komen (de meest rechtse z[p] = t[i] met p ≤ m − 2 → sprong m − 1 − p), of `Spatie` =
  "staat niet vóór de laatste positie" → sprong m. Je kunt ook slepen. Dat is V_H(t[i]), maar uit het hoofd en snel.
- **LIVE:** lint k (k = 0, 1, 2, …): v = min(1,2 + 0,15·k; 4,0) tekens/s, B = m + 3, ALL.
- **Generator (`TxTextGen`, seed = tijd):** z uit een lijst van 30 codewoorden (`ekster kever radar morse baken kompas
  zender telex sleutel kluis schaduw nevel haven koerier sein duin golf lantaarn vuurtoren ponskaart signaal antenne
  kristal relais spoel wiel naald lint stempel dossier`), lengte max(4, min(9, 4 + ⌊k/3⌋)). t = 60–90 tekens: woorden
  uit een Nederlandse lijst (≥ 200 woorden, `_` ertussen), 1–3 keer z ingeplant (nooit overlappend), en 2–4
  **lokwoorden** die op dezelfde laatste letter als z eindigen en minstens 2 andere letters van z bevatten. Die geven
  diepe gedeeltelijke matches en niet-triviale sprongen.
- **Einde:** 3 vertrouwenslampjes. Elk gemist codewoord (te verre sprong of scheur) kost er één. Na het lint krijg je een
  lampje terug als het lint foutloos was (max 3).
- **Score:** §6.6. Lokaal top-10 (3 letters + datum).
- (P1) variant "Nachtdienst: Doorloper" (KMP-stroom met verbrande vakjes); (P2) "Gemengde dienst" (machinekeuze per lint).

---

## 6. Scoring, sterren, economie & debrief

### 6.1 Valuta en meters
- **Tikken** (tekenvergelijkingen): de kern van de efficiëntie. De geest-balk "brute kracht" staat er altijd naast
  (op hetzelfde lint, dezelfde modus).
- **Wielslagen / lampslagen / relais:** de eigen kost van de Vingerafdruk, het lampenbord en het schakelbord.
- **Vertrouwen** (3 lampjes per level): −1 per gemist codewoord of vals alarm. In de campagne enkel een gevolg (de
  Chef kijkt bezorgd, op de kaart vertrekt een koerier). In de Nachtdienst zijn het levens.
- **Punten:** score per level (beste wordt bewaard) en de highscore van de Nachtdienst.
- **Sterren** (0–3 per level): openen de missiekaart verder.
- **Klemmen:** geteld, geen misstap. ★★★ vraagt 0 klemmen waar dat in de levelvoorwaarde staat.

### 6.2 Kostenmodel (notas-getrouw)
| machine | wat telt | notas |
|---|---|---|
| Sjabloon | 1 tik per vergelijking in `strings_gelijk` | O((n−m+1)·m), p. 51 |
| Vingerafdruk | 1 wielslag per ×2/−w/+1; tikken enkel in de controle | hash O(n), controle O(m) per alarm, p. 54 |
| Doorloper | 1 tik per vergelijking in `vergelijk_strings` | ≤ 2n, Stelling 12, p. 59 |
| Ponsbank (spiegelrit) | idem, vergelijkingen met ⏎ inbegrepen | O(m), p. 61 |
| Springer | 1 tik per vergelijking in `strings_gelijk_invers` | p. 63–66 |
| Lampenbord / ruisbord | 1 lampslag per teken (een hele kolom in één keer, ook voor alle k+1 kolommen samen) | "bitvectoren … in één computerwoord", p. 69 |
| Schakel-/zoeklicht | 1 relais per ingevulde cel | O(n·m), Lemma 18/19 |
**Optimum** per level = de tellers na perfect spel (core: `TxLevels.optimum(spec)` speelt alle stages met
`correct_move()`).

### 6.3 Punten
| gebeurtenis | punten |
|---|---|
| codewoord gevonden en gemeld (echte treffer) | +100 |
| correcte beslissing (verschuiving, sprong, pons, stempel, kaart, wielstand bij Schuif/Volgend bit, alarmkeuze, cel, terugstap, bedrading) | +10 (× combo in LIVE) |
| einde level: bespaarde tikken t.o.v. brute kracht | +2 per tik (enkel als positief) |
| vals alarm | −50 |
| gemist codewoord | −100 |
| klem | −5 |
| tegenzet | 10 × metriek (beste poging) |
| ritmesectie: kaart "strak" (≤ 0,2 s na de tel) | +5 extra |
**Combo** (enkel LIVE): correcte beslissingen binnen 4 s na elkaar → ×1, ×2 (na 4), ×3 (na 8), ×4 (na 12). De combo
breekt bij een misstap, een scheur, een gemist woord of een hint. Bij ×4: "Volle stroom" (korte slow-mo 0,5×, de
lampen van de console lopen in een golf, muziekstinger).

### 6.4 Sterren (algemeen patroon; exacte voorwaarden per level in §5)
- ★ = **missie volbracht**: alle stages afgerond en de levelspecifieke ondergrens (meestal: het codewoord / ≥ x treffers
  gemeld).
- ★★ = **0 misstappen** (dus ook geen gemist woord en geen vals alarm). Bij perfect spel volgen de tellers dan exact het
  optimum.
- ★★★ = **meesterschap**: zonder hint en zonder terugnemen, plus wat het level vraagt (0 klemmen, tijd, alle
  reeksen/matches, strak ritme, beide tegenzetten optimaal).
- Hint (`F1`) en terugnemen (`Ctrl+Z`, enkel CALM) zijn altijd beschikbaar en geen misstap. Wie ze gebruikt, haalt in
  dat level geen ★★★. "Live-tempo 80 %" telt als hulp.

### 6.5 Debrief (rapportscherm)
Volgorde van de animatie:
1. **Stempel** "MISSIE GESLAAGD" (of "CODEWOORD ONTSNAPT") op de dossiermap. De sterren worden één voor één gestempeld,
   met de voorwaarde eronder (groen/grijs).
2. **Tellers:** drie balken: jouw tikken, het optimum, brute kracht (bij lampen/relais: hun eigen eenheid + "brute
   kracht zou … tikken nodig hebben"). Ernaast punten met uitsplitsing (tabel 6.3).
3. **Lintverslag:** het hele lint in miniatuur met stempels: ✓ gevonden, ✗ gemist (rood, met de koerier), ! vals alarm
   (grijs, met de ploeg). Klik op een ✗ of ! → de **oorzakenketen** ("← venster 1: −w vergeten") springt naar dat
   moment.
4. **Jouw tabel naast de juiste** (V-strook, kaartenbak, C_x-kaarten, bedrading, wielwaarden per venster, het
   schakelbord), met verschillen omcirkeld.
5. **Misstappen-tijdlijn:** een stip per beslissing (groen OK, amber misstap, grijs klem). Klik op een amber stip: de
   console van dat moment wordt herbouwd (`restore(entry.before)` in een tweede, alleen-lezen machine). Jouw zet speelt
   af in rood-transparant, daarna de juiste zet als groene spookhand, met één **coachzin** + **notasverwijzing**.
6. **Notas-weergave** (knop): het level zoals in de notas getekend: de v-diagrammen van p. 58 (KMP), de V-tabel van
   p. 56, de V_H-tabel "x = | V_H[x]" van p. 65, de matrix M van p. 67 met de kaders van Figuur 23, M⁰/M¹ naast elkaar, de
   editeertabel met de lijn van het pad (p. 76/79).
7. Knoppen Volgende / Opnieuw / Kaart.

**Coachzinnen** (`TxEventLog.coach_line(entry)`; ≤ 16 woorden + verwijzing; `{…}` = data uit het event):
| verdict | zin | verwijzing |
|---|---|---|
| SHIFT_LONG | "Na een mismatch op {j} past al {v} plaatsen: V[{j}] = {v}, niet {s}." | Definitie 11, p. 56 |
| PUNCH_LONG | "Vakje {j}: de kleinste passende verschuiving is {v}." | Definitie 11, p. 56 |
| PUNCH_SHORT | "Pons tot en met de mismatch: vakjes {a} t.e.m. {b} krijgen {v}." | Algoritme 5, p. 61 |
| BUMP `no_mesh` in de spiegelrit bij em = 0 | "Meteen mismatch: V[start+1] = start+1 = {v}." | Algoritme 5, p. 61 |
| LATE | "t[{j}] = `{x}` staat in z: kaart {x} vóór de volgende tel." | Algoritme 6, p. 68 |
| WRONG_HASH | "Venster {i}: 2·{h} {−w?} {+1?} mod {q} = {x}, niet {y}." | rollende hash, p. 53 |
| WRONG_HORNER | "Bit {k}: ×2{, +1} geeft {x} (mod {q})." | h(s), p. 52 |
| UNVERIFIED | "Zelfde vingerafdruk is geen bewijs. Eerst controleren." | Algoritme 3, p. 54 |
| SKIPPED_CHECK | "Wijzer op h(z) = {hz}: altijd strings_gelijk() oproepen." | Algoritme 3, p. 54 |
| FALSE_ALARM (RK) | "{w} ≡ {hz} (mod {q}), maar {w} ≠ z: een hashbotsing." | Opm. 10, p. 54 |
| WRONG_KEY | "Kijk naar t[i] = `{x}` onder de laatste letter, niet naar `{y}`." | is_contained_BMH, p. 65 |
| WRONG_CARDS | "V_H[`{x}`] = {v}: de laatste `{x}` vóór positie {m1} staat op {p}." | vul_VH, p. 65 |
| JUMP_LONG / JUMP_SHORT | "V_H[`{x}`] = {v}: spring {v}, niet {s}." | p. 65 |
| WRONG_HOLES | "Kaart `{x}`: gaten waar z[i] = `{x}`, dus op rij {rows}." | C_x, p. 67 |
| NO_SHIFT | "Eerst schuiven (bit i−1 → i, bovenste aan), dan AND." | Algoritme 6, p. 68 |
| WRONG_CARD | "t[{j}] = `{x}`: kaart {card}." | Algoritme 6, p. 68 |
| WRONG_WIRE | "Een fout op j bouwt verder op M^{l−1} van kolom j−1, geschoven." | Definitie 14, p. 71 |
| WRONG_MIN | "min({a}+{c}, {b}+1, {d}+1) = {v}, niet {x}." | Algoritme 7, p. 75 |
| WRONG_END | "De kleinste waarde onderaan is {v}, in kolom {cols}." | Algoritme 8, p. 79 |
| WRONG_PICK (6-2) | "Enkel M⁰ belde: daar is `{z}` exact." | Definitie 14, p. 70 |
| MISSED | "`{z}` @{p} glipte erdoor: zie {oorzaak}." | (verwijzing van de oorzaak) |
| TEAR | "Te lang gewacht: de lusbak liep vol, het lint scheurde." | p. 50 (streams) |

### 6.6 Nachtdienst-score
Per correcte sprong +10 × combo, per gevonden codewoord +100 × combo, per lint bonus 2 × (brute kracht − jouw tikken).
Combo zoals 6.3 (venster 4 s, max ×4). Highscore = punten.

---

## 7. Juice & audio

### 7.1 Juice-lijst (timing / easing; Godot-tweens)
| # | moment | effect |
|---|---|---|
| 1 | lint komt binnen (inlaat) | papier rolt van rechts in (0,12 s per teken, `TRANS_SINE`), elk teken wordt ingeslagen door een typehamer (zwart, 1 frame overshoot), tak-geluid |
| 2 | naald vergelijkt | naald slaat neer (60 ms) op de kolom, lampje: groen pulseert kort, rood blijft branden. Interval 70 ms per tik (snel: 30 ms) |
| 3 | tikteller | rolcijfers draaien met een mechanisch klikje per tik; bij elke 10 een zwaarder "klak" |
| 4 | mismatch | rode lamp + korte vonk op de kolom, naald veert terug (0,1 s `TRANS_BACK`) |
| 5 | treffer | alle m kolommen lichten groen op als golf (30 ms gestaggerd), telexbel, koker vliegt in een boog naar de buizenpost (0,5 s), "fwoop", stempel in het dossier (0,15 s squash) |
| 6 | sjabloon slepen (voorvertoning) | het sjabloon volgt de muis per raster met 40 ms ease; overlappende tanden: groen haakje bij overeenkomst, rode vonkjes bij botsing |
| 7 | tanden klikken in (vastzetten) | sjabloon zakt 4 px en klikt omhoog (squash 1,0→0,92→1,0), metalen "klak", stofje |
| 8 | klem | object botst, veert terug (0,25 s `TRANS_ELASTIC`), 6 vonkjes, shake 3 px 0,12 s, doffe metalen tok |
| 9 | leeskop blijft staan (KMP) | kop gloeit kort warm-wit ("hij gaat niet terug"); bij brute kracht: kop zoeft terug met een spoelgeluid en een bewegingsstreep, spoelmeter tikt |
| 10 | versnipperaar | snippers (12 deeltjes per teken) vallen in een bak, motorgeluid laag |
| 11 | gemist codewoord | in de versnipperaar gloeit het woord rood op (0,4 s), daarna snippers in rood; op de kustkaart vertrekt een koerier (silhouet), shake 4 px, vertrouwenslampje dooft met een "plink" |
| 12 | vals alarm | sirene kort, op de kaart rijdt een autootje naar een grijze speld, vertrouwenslampje dooft |
| 13 | hashwiel ×2 | het wiel draait h tanden verder (12 ms per tand, ratelgeluid per tand: je hoort mod q), wijzer veert na |
| 14 | −w / +1 | het tandwieltje "−w" grijpt in en draait het wiel w tanden terug; +1: één tand vooruit met een helder klikje |
| 15 | Schuif (rollen) | bitvenster schuift één plaats: uitgaand bit valt eruit (vervaagt naar beneden), inkomend bit klapt erin |
| 16 | alarmlampje | knippert 3 Hz, zoemer; Controleer = de naald loopt het venster af zoals 2 |
| 17 | ponsen | ponsmachine slaat (0,08 s), confetti van papierrondjes (6), getal verschijnt met een stempelbeweging, "tsjak" |
| 18 | spiegelrit | de spookkopie schuift over z; ⏎ voorbij het einde glinstert |
| 19 | strook schuift naar de Doorloper (stage-wissel) | strook glijdt in een boog (0,6 s), klikt vast |
| 20 | verbrand vakje | zwart geblakerd, af en toe een rookpluimpje; leeg-geluid "tok" als de Doorloper erop stuit |
| 21 | stempelen (kaartenbak) | stempel daalt op de kaart, getal verschijnt; overschrijven: oud getal wordt doorstreept (0,2 s) |
| 22 | sprong (Springer) | kaart springt uit de bak, vliegt naar het sjabloon, sjabloon springt in een boog over s posities (0,08 s per positie, max 0,5 s), landt met squash; lange sprongen laten een luchtspoor |
| 23 | sleutelteken | onder de laatste sjabloonletter licht een cirkel op (enkel met `key_hint`); bij hover over een lintteken binnen het venster: dat teken licht op |
| 24 | hendel (lampenbord) | hendel slaat omlaag, lampen glijden één rij (90 ms), de onderste valt eraf (lampje dooft en valt 6 px), de voedingslamp springt aan met een "zoem" |
| 25 | kaart insteken | kaart schuift in het rek (0,1 s), licht schijnt door de gaten, lampen zonder gat doven met naglans (0,2 s) |
| 26 | bel (lampenbord) | onderste lamp flitst, bel, kolom wordt op de matrixlog gedrukt (typehamer) |
| 27 | ritme | elke tel: hendel slaat op het ritme, de console "ademt" (schaal 1,005); strakke kaart = witte ring |
| 28 | foutkabel steken | kabel slingert (verlet-touw of bezier), plug klikt erin, vonk, de aansluiting licht op |
| 29 | relais (schakelbord) | het gekozen draadje licht op, stroom loopt (0,15 s) naar de cel, de meter slaat uit naar de waarde (naald met overshoot); gelijk-lampje groen |
| 30 | warme cel (WRONG_MIN) | de meter gloeit oranje en zoemt licht (blijft subtiel, geen tekst) |
| 31 | teruglopen | stroomspoor loopt achteruit langs het pad; bij elke stap tikt de herstelstrook een bewerking (vervang = letter klapt om, verwijder = letter valt, toevoegen = letter schuift in) |
| 32 | zoeklicht | lichtbundel zwaait over de onderste rij en blijft op het minimum hangen; daarna schijnt hij op de match in het lint |
| 33 | scheur (LIVE) | lusbak puilt uit, lint scheurt met papiergeluid, de stukken waaien weg, de kop schokt naar voren, shake 5 px |
| 34 | lusbak bijna vol | bak knippert amber, muziek lowpass, hartslagtik |
| 35 | combo ×4 "Volle stroom" | hitstop 80 ms, slow-mo 0,5× 0,4 s, golf van lampjes over de console |
| 36 | sterren | stempels met inktspat (0,3 s overshoot), papier wiebelt |
| 37 | kist opent (nieuwe machine) | deksel springt, stro dwarrelt, typeplaatje glanst (shader-sweep) |
| 38 | idle | lampjes knipperen zacht, buizenpost blaast af en toe, lint wiegt licht |
Instelling schermschok schaalt alle shakes (0/50/100 %). Slow-mo geldt enkel voor wereldnodes, niet voor UI.

### 7.2 Audio
**Muziek** (adaptief, CC0 of procedureel; 3 lagen: basis, spanning, treffer):
- *Titel/kaart:* spionage-jazz: contrabas, geborstelde drums, vibrafoon, 84 BPM.
- *CALM-levels:* basislaag (bas + vibrafoon), rustig. Bij een alarm of een moeilijke beslissing (> 6 s denken): een
  zachte pad-laag erbij.
- *LIVE-levels:* spanningslaag (staccato-strijkers, hihat), tempo volgt v. Lusbak bijna vol → lowpass + hartslag.
- *Ritmesectie (5-3):* eigen nummer op 100 BPM; de bel en de kaarten zitten in de maat (de kaartklik is een
  percussie-instrument).
- *Finale:* het thema van de titel met fanfare-koper bij elke gevonden ekster.
- *Debrief:* korte jingle (3 varianten naar sterren).

| gebeurtenis | geluid |
|---|---|
| teken binnen (inlaat) | telex-typehamer "tak" |
| tik (vergelijking) | droog naaldtikje; gelijk = hoger, verschil = lager + zoem |
| treffer | telexbel + buizenpost "fwoop" + stempel |
| klem | metalen tok + veer |
| tanden in | metalen klak |
| terugspoelen | spoelzoem met dalende toonhoogte |
| versnipperaar | motorbrom, snippers |
| gemist | dalend motief (fagot), deur slaat in de verte |
| vals alarm | korte sirene, auto start |
| wiel | ratel per tand (q tanden = q klikjes per omwenteling) |
| −w / +1 | tandwiel grijpt in / helder klikje |
| alarmlampje | zoemer |
| pons | "tsjak" + papier |
| stempel | rubberstempel |
| sprong | "swoesj" + landing |
| hendel | zware hendel + relaisklak |
| kaart insteken | kaartschuif + klik |
| lampen | zacht zoemen, gloeidraad |
| kabel | plug + vonk |
| relais | relaisklik, meter-tik |
| teruglopen | stroomzoem achteruit, typemachine per bewerking |
| zoeklicht | schijnwerper aan (klap) |
| scheur | papier scheurt |
| sterren | drie stempels, telexbel |
| UI | schakelaars en druktoetsen (bakeliet) |

---

## 8. Interface-contract core ↔ front-end

Alles in `games/telex/scripts/core/` is **puur** (`RefCounted` of static, geen nodes, geen `Engine`/`Time`-calls),
deterministisch en headless testbaar. De front-end luistert naar signalen en roept methodes aan. **Alle `class_name`s
beginnen met `Tx`.** Geen nieuwe autoloads. **Posities zijn 0-gebaseerd** (lint, sjabloon, lampenrijen). Editeertabellen
gebruiken lengtes (rij i = prefix van lengte i) zoals de notas. Strings zijn `String`s van enkelvoudige tekens. Het
end_of_line-teken van Algoritme 5 is intern `"\n"` (weergave ⏎).

### 8.1 Bestanden
| bestand | class_name | rol |
|---|---|---|
| `tx_codes.gd` | `TxCodes` | enums (8.2) |
| `tx_reference.gd` | `TxReference` | onafhankelijke referentie-implementaties van Algoritme 2–8 + Definitie 11/13/14 (8.3); bron voor orakel, waarheid, geesten en tests |
| `tx_machine.gd` | `TxMachine` | basisklasse: lint/stroom, tellers, waarheid, gevolgen, log, snapshot, apply/orakel (8.4) |
| `tx_brute.gd` | `TxBrute` | Sjabloon (Algoritme 2), ook met joker `?` |
| `tx_rabin_karp.gd` | `TxRabinKarp` | Vingerafdruk (Algoritme 3) |
| `tx_kmp_table.gd` | `TxKmpTable` | Ponsbank: Definitie 11 (spiegel) en Algoritme 5 (spiegelrit) |
| `tx_kmp.gd` | `TxKmp` | Doorloper (Algoritme 4, + V[m] bij ALL) |
| `tx_bmh.gd` | `TxBmh` | Springer: kaarten stempelen + doorloop |
| `tx_shift_and.gd` | `TxShiftAnd` | Lampenbord en ruisbord (k ≥ 0): kaarten, bedrading, doorloop, keuze |
| `tx_edit_board.gd` | `TxEditBoard` | Schakelbord (Algoritme 7) en zoeklicht (Algoritme 8) |
| `tx_sabotage.gd` | `TxSabotage` | tegenzet-missies |
| `tx_event_log.gd` | `TxEventLog` | log, coachzinnen, oorzaakketens |
| `tx_level_spec.gd`, `tx_levels.gd` | `TxLevelSpec`, `TxLevels` | leveldata (§5) |
| `tx_director.gd` | `TxDirector` | stages, LIVE-klok (front, ritme), auto-zetten, hint, terugnemen, einde |
| `tx_scoring.gd` | `TxScoring` | punten, combo, sterren, rapport |
| `tx_save.gd` | `TxSave` | `user://telex_save.json` |
| `tx_text_gen.gd` | `TxTextGen` | Nachtdienst-generator |
| `games/telex/tests/tx_bot.gd` | `TxBot` | **van de core**: speelt een level via `TxDirector` + orakel, met foutmodi (front-end maakt geen tweede) |

### 8.2 `TxCodes`
```gdscript
class_name TxCodes
enum Machine { BRUTE, RABIN_KARP, KMP_TABLE, KMP, BMH, SHIFT_AND, EDIT, SABOTAGE }
enum Mode { CALM, LIVE }
enum Find { FIRST, ALL }
enum Phase { IDLE, READY, NEEDLE, WAIT_TAPE, DECIDE,                 # naaldmachines
             W_CALC, HORNER, ROLL, ALARM,                            # Vingerafdruk
             PUNCH_CELL, MIRROR_PUNCH, MIRROR_SHIFT,                 # Ponsbank (spiegel / spiegelrit)
             CARDS, WIRE, LEVER, CARD, CHOOSE,                       # Springer-kaarten / lampenbord
             FILL, PICK_END, TRACE, TRACE_DONE,                      # schakelbord / zoeklicht
             COMPOSE, DONE }
enum Verdict { OK, BUMP, SHIFT_LONG, PUNCH_LONG, PUNCH_SHORT, WRONG_HASH, WRONG_HORNER, UNVERIFIED, SKIPPED_CHECK,
               FALSE_ALARM, WRONG_KEY, WRONG_CARDS, JUMP_LONG, JUMP_SHORT, WRONG_HOLES, NO_SHIFT, WRONG_CARD,
               WRONG_WIRE, WRONG_MIN, WRONG_END, WRONG_PICK, MISSED, TEAR, LATE }
const EOL := "\n"
const STRIP_EMPTY := -1      # leeg vakje in de ponsstrook
const STRIP_BURNT := -2      # verbrand vakje (3-5)
static func verdict_name(v: int) -> String
static func phase_name(p: int) -> String
```

### 8.3 `TxReference` (static, puur; letterlijk de pseudocode van de notas)
```gdscript
class_name TxReference
static func brute(z: String, t: String, find_all: bool, joker := "") -> Dictionary
	# {cmp:int, hits:Array[int], trace:[{start, res:int (mismatchpositie of m), cmp}], rewind:int, alignments:int}
	# rewind = Σ max(0, (laatst vergeleken absolute positie) − (volgende start)); joker: dat teken matcht alles (Oef. 33)
static func h(bits: String, q: int) -> int                       # (Σ s_i 2^(m−1−i)) mod q
static func horner_prefixes(bits: String, q: int) -> Array[int]  # waarde na elk bit
static func rk(z: String, t: String, q: int, find_all: bool) -> Dictionary
	# {hz, w (2^m mod q), hs:Array[int] (per venster, rollend), calls:[{i, equal:bool, cmp}], cmp, hits, false_hits, wheel_ops}
	# wheel_ops = m (w) + (m + #1(z)) + (m + #1(venster 0)) + Σ_i (1 + t[i−1] + t[i+m−1]) tot het laatste verwerkte venster
static func v_def(z: String, extended := true) -> Array[int]    # Definitie 11; extended voegt V[m] toe
static func mesh(z: String, em: int, s: int) -> bool             # s ≥ em of z[0..em−1−s] == z[s..em−1]  (s ≥ 1)
static func bereken_v(z: String) -> Dictionary
	# Algoritme 5 letterlijk: {v:Array[int] (lengte m+1, −1 = niet ingevuld), steps:[{start, gel, em, cmp, filled:[[pos,val]], shift}]}
static func vergelijk_strings(z: String, t: String, start: int, gel: int) -> Dictionary   # {em, cmp}; voorbij t: EOL
static func kmp(z: String, t: String, v: Array, find_all: bool) -> Dictionary
	# {cmp, hits, trace:[{start, gel, em, cmp}], alignments}; na em == m (ALL): start += v[m], gel = m − v[m]
static func vul_vh(z: String) -> Dictionary                      # letter -> waarde (enkel letters van z[0..m−2]); andere: m
static func bmh(z: String, t: String, find_all: bool) -> Dictionary
	# {cmp, hits, trace:[{i, start, ok, cmp, key, shift, mis_z}], vh, alignments}
static func c_vectors(z: String) -> Dictionary                   # letter -> Array[int] (lengte m)
static func shift1(col: Array) -> Array                          # [1] + col[0..m−2]
static func shift_and(z: String, t: String) -> Dictionary        # {c, cols:Array (per j), hits:Array[int] (begin), ends}
static func shift_and_k(z: String, t: String, k: int, plug := "old_shift") -> Dictionary
	# {c, cols:[j][l] -> Array, ends_by_level:{l: Array[int]}}; start = "kolom −1" = nullen (geeft exact M^k[][0] van p. 70)
static func mismatches_ending(z: String, t: String, j: int) -> int   # aantal mismatches van z tegen t[j−m+1..j] (∞ als j < m−1)
static func edit_table(a: String, b: String) -> Array             # Algoritme 7: d[i][j]
static func approx_table(z: String, t: String) -> Array           # Algoritme 8: D[i][j]
static func approx_best(z: String, t: String) -> Dictionary       # {best, end_cols:Array[int]}
static func arrows(tab: Array, a: String, b: String, i: int, j: int) -> PackedStringArray   # dragende ingangen "diag","up","left"
static func all_paths(tab: Array, a: String, b: String, i: int, j: int, stop_row0: bool) -> Array   # [[{dir,i,j}]]
static func ops_of_path(path: Array, a: String, b: String) -> Array
	# [{op:"vervang"|"verwijder"|"voegtoe", pos:int, from:String, to:String}] in stijgende volgorde, posities in de string van dat moment (§5.8)
```

### 8.4 `TxMachine` (basis) — signalen, staat, generieke API
```gdscript
class_name TxMachine extends RefCounted
signal changed(fx: Dictionary)                          # één animatiebeschrijving (8.6), in afspeelvolgorde
signal phase_changed(phase: int, cursor: Dictionary)    # na ELKE uitgevoerde zet (ook als de fase gelijk blijft)
signal counters_changed(c: Dictionary)                  # {ticks, wheel, lamps, relays, rewind, alignments, bumps}
signal reported(hit: Dictionary)                        # {start:int, end:int, level:int, real:bool}
signal consequence(ev: Dictionary)                      # {kind:"missed"|"false_alarm"|"tear", start, end, cause_seq:int}
signal event_logged(entry: Dictionary)
signal stage_done(result: Dictionary)                   # {ok:bool, output:Dictionary}

var kind: int                    # TxCodes.Machine
var stage: Dictionary            # de stage-spec (8.8)
var z: String; var t: String; var n: int; var m: int
var find: int                    # TxCodes.Find
var mode: int                    # TxCodes.Mode
var front: int                   # binnengekomen tekens (CALM: n)
var shred: int = 0               # posities < shred zijn vernietigd
var buffer: int = -1             # B (LIVE), −1 = onbeperkt
var phase: int = TxCodes.Phase.IDLE
var counters: Dictionary         # ticks, wheel, lamps, relays, rewind, alignments, bumps
var truth: Array[Dictionary]     # echte voorkomens [{start, end, level}] uit TxReference (level = min. aantal mismatches bij M^k, anders 0)
var hits: Array[Dictionary]      # gemelde [{start, end, level, real}]
var missed: Array[Dictionary]
var false_alarms: Array[Dictionary]
var log: TxEventLog
var now: float = 0.0             # gameplay zet dit elke frame

func setup(stage_spec: Dictionary, carry := {}) -> void
func begin() -> void                         # fase READY (naaldmachines) of de eerste voorbereidingsfase
func cursor() -> Dictionary                  # wat de UI moet tonen/markeren (per subklasse, 8.7)
func render() -> Dictionary                  # volledige tekenstaat (cursor + tabellen + kolommen)
func apply(move: Dictionary) -> Dictionary   # {ok:bool, verdict:int, reason:String, done:bool}
func preview(move: Dictionary) -> Dictionary # muteert niets: {ok:bool, reason:String, mesh:bool, s:int, …} (slepen, tanden, sprongdoel)
func correct_move() -> Dictionary            # het orakel: juiste volgende zet of {"act":"none"}
func wrong_moves() -> Array[Dictionary]      # plausibele foute zetten met ok = true (bots, QA)
func impossible_moves() -> Array[Dictionary] # zetten die ok = false geven (kliktests)
func auto_finish() -> void                   # speelt de stage verder met correct_move()
func need() -> int                           # §2.5
func set_front(f: int) -> void               # LIVE: nieuwe tekens; laat een wachtende naald verder lopen; controleert scheur
func force_to(s: int) -> void                # scheur (§2.5): logt TEAR, markeert gemiste voorkomens
func output() -> Dictionary                  # carry voor de volgende stage ({"strip":[…]}, {"cards":{…}}, {"c":{…}}, {"wiring":{…}})
func snapshot() -> Dictionary                # volledige toestand incl. fase, cursor, tellers, log-lengte; JSON-serialiseerbaar
func restore(d: Dictionary) -> void          # snapshot → restore → snapshot is identiek
func invariants() -> PackedStringArray       # leeg = consistent
func is_done() -> bool
```
**`apply()`-resultaat:** `{"ok": bool, "verdict": int, "reason": String, "done": bool}`.
- `ok = false`: fysiek onmogelijk (klem). De staat verandert niet. Er volgt `changed({"fx":"bump",…})` en een logentry
  `BUMP` met `reason` ∈ `"no_mesh" "zero" "hole" "filled" "range" "last_pos" "out_of_window" "already" "no_w" "not_now"
  "no_current" "no_card" "wrong_phase" "unknown_act" "no_alarm"`. Klemmen tellen in `counters.bumps`.
- `ok = true`: de zet is uitgevoerd. `verdict` = OK of een foutcode. Die wordt **vóór** het uitvoeren bepaald door
  `correct_move()` en de waarheid te vergelijken; de hint staat in de logentry. `done = true` als de stage hiermee af is.
- Volgorde van signalen per zet: alle `changed(fx)` in afspeelvolgorde (ook die van automatische vervolgstappen zoals de
  naald) → `counters_changed` → `reported`/`consequence` (indien) → `event_logged` → `phase_changed` → eventueel
  `stage_done`.
- **Automatische vervolgstappen gebeuren in de core**, niet in de front-end: na elke beslissing loopt de naald meteen
  (tot mismatch, treffer, front of einde). `auto_zero` (mismatch op 0 → verschuif 1) en `auto_strip` (verschuif met de
  strook als het vakje gevuld is) voert de machine zelf uit. Ze worden gelogd met `auto: true` en hun eigen verdict.
- **Gemist** wordt vastgesteld zodra `need()` voorbij het begin van een niet-gemeld echt voorkomen gaat (lampenbord:
  zodra j voorbij het einde gaat). Dan volgen `consequence({"kind":"missed"…})`, een logentry `MISSED` met
  `cause_seq` (de zet die eroverheen ging) en `changed({"fx":"missed"…})`.
- **FIRST:** de stage is klaar bij de eerste echte melding. **ALL:** bij het einde van het lint.

### 8.5 Stages en carry
Een level = 1..4 stages (`TxLevelSpec.stages`). De director maakt per stage een machine via
`TxLevels.make_machine(stage, carry)`. `carry` is de `output()` van de vorige stage (bv. de geponste strook gaat van
`TxKmpTable` naar `TxKmp`, de geponste kaarten van de kaartstage naar de doorloop). Een stage-spec is een Dictionary:
```
{"machine":"brute", "z":"kerk", "t":"de_kerker_bij_de_kerk", "find":"all", "joker":""}
{"machine":"rk", "z":"1011", "q":7, "t":"…", "find":"all", "prep":["w","hz","h0"], "prefill":{"w":2,"hz":4}}
{"machine":"rk", "z":"1011", "q":7, "signals":["0100","1011","1110"], "prep":["w","hz"]}          # 2-1 stage C
{"machine":"kmp_table", "z":"ananas", "method":"def11"|"alg5", "cells":"m-1"|"m"}
{"machine":"kmp", "z":"…", "t":"…", "find":"first", "strip":"carry"|"none"|[1,1,2,2,-2,-2],
 "auto_zero":true, "auto_strip":true}
{"machine":"bmh", "z":"…", "t":"…", "find":"first", "cards":"stamp"|"carry"|"prefilled"|"none", "key_hint":true}
{"machine":"shift_and", "z":"…", "t":"…", "k":0, "cards":"punch"|"carry"|"prefilled", "wiring":"plug"|"carry"|"prefilled",
 "run":true, "auto_lever":false, "choose":false}
{"machine":"edit", "a":"lessen", "b":"feesten", "approx":false, "prefill_rows":0}
{"machine":"sabotage", "target":"brute"|"rk_calls"|"bmh_min"|"bmh_max", "n":12, "m":4, "alphabet":"ab", "z_fixed":"", "q":0}
```
Een stage met enkel voorbereiding (bv. `kmp_table`, of `bmh` met `"cards":"stamp"` en zonder `t`) eindigt na de
voorbereiding. **Carry is cumulatief:** `output()` bevat ook de ontvangen carry (kaarten uit stage A blijven na de
bedradingsstage B beschikbaar voor de doorloop C).

### 8.6 Animatiebeschrijvingen (`changed(fx)`) — de front-end speelt ze af in volgorde
| `fx` | velden | betekenis |
|---|---|---|
| `"ready"` | `start:int` | sjabloon staat klaar |
| `"needle"` | `steps:[{zi:int, ti:int, eq:bool}], result:"mismatch"\|"match"\|"wait"\|"end", em:int, dir:"ltr"\|"rtl"` | naaldloop (één tik per stap) |
| `"head"` | `from:int, to:int, rewind:bool` | leeskop verplaatst (rewind = terugspoelen) |
| `"stencil"` | `from:int, to:int, auto:bool` | sjabloon schuift (start) |
| `"bump"` | `reason:String, at:Variant` | klem |
| `"hit"` | `start:int, end:int, level:int, real:bool` | bel + koker (real = false: vals alarm-route) |
| `"missed"` | `start:int, end:int` | versnipperaar onthult |
| `"false_alarm"` | `start:int, end:int` | ploeg vertrekt |
| `"shred"` | `upto:int` | versnipperaar schuift |
| `"front"` | `to:int` | nieuwe tekens binnen |
| `"tear"` | `from:int, to:int` | lint scheurt |
| `"wheel"` | `op:"double"\|"minus_w"\|"plus1"\|"set", from:int, to:int, q:int` | wiel draait (front-end draait (to − from) mod q tanden; bij double: from tanden) |
| `"bit"` | `which:"w"\|"z"\|"window"\|"signal", k:int, value:int, ok:bool` | ijkstap bevestigd |
| `"window"` | `i:int, out_bit:String, in_bit:String` | bitvenster schuift |
| `"notch"` | `value:int` | rode inkeping gezet |
| `"alarm"` | `i:int` | alarmlampje |
| `"verify"` | `i:int, steps:[…], equal:bool` | controle (naald op het venster) |
| `"punch"` | `cells:[{j:int, v:int}]` | ponsen |
| `"ghost"` | `s:int, mesh:bool` | (enkel uit `preview`) |
| `"strip_move"` | — | strook naar de Doorloper (stage-wissel) |
| `"stamp"` | `i:int, x:String, v:int, old:int` | kaart gestempeld (old = vorige waarde of −1) |
| `"key"` | `pos:int, ch:String, v:int` | kaart getrokken |
| `"jump"` | `from:int, to:int, s:int` | sprong (i) |
| `"hole"` | `x:String, i:int, on:bool` | gat geponst/dicht |
| `"plug"` | `l:int, src:String` | kabel gestoken |
| `"lever"` | `cols:Array` | kolommen na shift (vóór de AND) |
| `"card"` | `x:String, j:int, cols:Array` | kaart ingestoken, kolommen na AND/OF |
| `"column"` | `j:int, cols:Array` | kolom gedrukt op de matrixlog |
| `"cell"` | `i:int, j:int, v:int, dir:String, cost:int, warm:bool` | relais gevuld (warm = WRONG_MIN) |
| `"end_pick"` | `j:int, v:int` | zoeklicht |
| `"trace_step"` | `i:int, j:int, dir:String, op:Dictionary` | terugstap + bewerking op de herstelstrook |
| `"print_ops"` | `ops:Array, result:String, start:int, end:int` | herstelstrook print de reeks |
| `"compose"` | `which:String, i:int, ch:String` | tegel gezet |
| `"enemy_run"` | `metric:int, trace:Array, valid:bool` | vijandige machine draait |
| `"stage"` | `index:int, machine:int` | nieuwe stage |

### 8.7 Zetten per machine (exacte dictionaries), cursor en orakel
**Algemeen:** `{"act": String, …}`. `correct_move()` geeft altijd een zet die `apply()` met verdict OK aanvaardt.
Naaldmachines starten in READY: `{"act":"go"}` start de eerste naaldloop.

**`TxBrute`** — `{"act":"go"}` (READY) · `{"act":"next"}` (DECIDE): start += 1, de kop springt terug (`head` met
rewind), de naald loopt. Altijd OK. Joker: `stage.joker` matcht alles.
`cursor()`: `{start, k (laatste vergeleken sjabloonpositie), res, head}`.

**`TxRabinKarp`** (`q`, `w`, `hz` = rode inkeping, `wheel`, `i` = huidig venster, `bit_k`)
| zet | fase | effect / verdict |
|---|---|---|
| `{"act":"wheel","op":"double"\|"minus_w"\|"plus1"}` | W_CALC, HORNER, ROLL | wiel := (2·wiel / wiel − w / wiel + 1) mod q. `minus_w`: klem `no_w` als w nog niet geijkt is, `not_now` in W_CALC/HORNER. `plus1` in W_CALC: `not_now` |
| `{"act":"commit"}` | W_CALC | w := wiel. OK als wiel == 2^m mod q, anders WRONG_HASH (de speler werkt verder met zijn w) |
| `{"act":"next_bit"}` | HORNER | bevestigt bit k. OK als wiel == (2·wiel_vóór_dit_bit + bit_k) mod q (de stap zelf klopt, gerekend vanaf de spelerswaarde), anders WRONG_HORNER (verder met de spelerswaarde). Na het laatste bit van z: inkeping := wiel (`notch`). Na het laatste bit van venster 0 of van een signaal: alarmcheck |
| `{"act":"slide"}` | ROLL | i += 1 (`window`). OK als wiel == (2·wiel_vóór − uit·w + in) mod q met de spelers-w (de **stap** klopt), anders WRONG_HASH. Eén fout geeft dus één misstap; de verkeerde waarde zelf loopt wel door (gevolgen). Daarna alarmcheck: wiel == inkeping → ALARM, anders ROLL (of DONE na het laatste venster) |
| `{"act":"verify"}` | ALARM | naald op het venster (`verify`, tikken). Gelijk → melding (echt). Verschillend → hashbotsing (kost, geen misstap). OK |
| `{"act":"report"}` | ALARM | melding zonder controle. Strings gelijk → UNVERIFIED (melding telt). Anders FALSE_ALARM (gevolg) |
| `{"act":"ignore"}` | ALARM | strings gelijk → SKIPPED_CHECK + MISSED. Anders SKIPPED_CHECK (geen schade) |
| (klem) `verify`/`report`/`ignore` zonder alarm | ROLL | `no_alarm` |
Alarmcheck in signaalmodus (2-1 stage C): na het laatste bit van elk signaal. Daarna volgt het volgende signaal (wiel op 0).
`cursor()`: `{phase_part:"w"|"z"|"window"|"signal"|"roll", wheel, w, notch, i, bit_k, bits:String, out_bit, in_bit, signal_index}`.
Extra: `true_hash(i) -> int`, `history() -> Array` (wiel bij elke Schuif + juiste waarde, voor de debrief).

**`TxKmpTable`** (`strip: Array[int]` lengte m+1 of m, `method`)
| zet | fase | effect / verdict |
|---|---|---|
| `{"act":"punch","j":j,"v":v}` | PUNCH_CELL (def11) | klem `filled` als het vakje al gevuld is, `range` als v < 1 of v > j, `no_mesh` als !mesh(z, j, v). OK als v == V_def[j], anders PUNCH_LONG |
| `{"act":"done"}` | PUNCH_CELL | open vakjes blijven leeg: PUNCH_SHORT als er nog lege zijn, anders OK |
| `{"act":"punch_to","to":b,"v":v}` | MIRROR_PUNCH (alg5) | stempelt v in de vakjes a..b (a = start+gel+1, bij em = 0: a = start+1). b = a − 1 = niets ponsen. Klem `range` (b < a−1 of b > m), `filled`, `no_mesh` (v past niet voor een van de vakjes). Correct: b = start+em en v = start; bij em = 0: b = a en v = start+1. Kleinere b: PUNCH_SHORT; grotere passende v: PUNCH_LONG |
| `{"act":"shift","s":s}` / `{"act":"strip"}` | MIRROR_SHIFT | tandenregel tegen z zelf (klem `no_mesh`/`zero`/`hole`). OK als s == V_def[em], anders SHIFT_LONG. start += s; gel = (em == 0 or s ≥ em) ? 0 : em − s. Daarna: zolang start + gel < m − 1 loopt de spiegelnaald (MIRROR_PUNCH), anders klaar (of PUNCH_CELL voor resterende lege vakjes als `cells` = "m" en V[m] leeg is) |
`cursor()`: `{method, j (PUNCH_CELL), start, gel, em, punch_from, strip:Array}`. Extra: `preview({"act":"punch",…})` → `{mesh}`.

**`TxKmp`** (`start`, `gel`, `em`, `strip`, `auto_zero`, `auto_strip`)
| zet | fase | effect / verdict |
|---|---|---|
| `{"act":"shift","s":s}` | DECIDE | klem `zero` (s < 1), `no_mesh` (1 ≤ s < em en t[start+s..start+em−1] ≠ z[0..em−1−s]). OK als s == V_def[em] (V[m] uitgebreid bij em = m), anders SHIFT_LONG (+ MISSED-gevolgen voor overgeslagen voorkomens). start += s; gel = (em == 0 or s ≥ em) ? 0 : em − s; de leeskop komt op start + gel (blijft dus staan als 0 < s ≤ em, schuift 1 op bij em = 0, en springt vooruit als s > em); de naald loopt verder |
| `{"act":"strip"}` | DECIDE | klem `hole` (leeg of verbrand vakje). Anders zoals shift met s = strip[em] (een te kleine stripwaarde klemt) |
`cursor()`: `{start, gel, em, head, strip, v_hint:int (enkel in tutorial), window_ok:Array[bool] (welke posities groen)}`.
`preview({"act":"shift","s":s})` → `{ok, mesh, clash:Array[int] (botsende kolommen)}`.

**`TxBmh`** (`i`, `cards: Dictionary`, `key_hint`)
| zet | fase | effect / verdict |
|---|---|---|
| `{"act":"stamp","i":p}` | CARDS | klem `last_pos` (p == m−1), `range`. cards[z[p]] := m−1−p. Altijd OK (volgorde vrij; de fout blijkt bij cards_done) |
| `{"act":"cards_done"}` | CARDS | OK als cards (aangevuld met m) == V_H voor alle letters van z, anders WRONG_CARDS. Daarna READY (of klaar als de stage geen lint heeft) |
| `{"act":"key","pos":p}` | DECIDE | klem `out_of_window` (p ∉ [i−m+1, i]). s = cards.get(t[p], m). Verdict: p ≠ i → WRONG_KEY; anders s ≠ V_H[t[i]] → JUMP_LONG/JUMP_SHORT; anders OK. i += s |
| `{"act":"jump","s":s}` | DECIDE | klem `zero`. OK als s == V_H[t[i]], anders JUMP_SHORT / JUMP_LONG. i += s |
`cursor()`: `{i, start (= i−m+1), mis_z (mismatchpositie in z of −1), key_pos (= i, enkel als key_hint), cards}`.

**`TxShiftAnd`** (`k`, `cards: Dictionary` letter → Array[int], `wiring: Dictionary` l → src, `cols: Array` (k+1 kolommen), `j`)
| zet | fase | effect / verdict |
|---|---|---|
| `{"act":"hole","x":x,"i":r}` | CARDS | klem `no_card` (x geen letter van z), `range`. Gat aan/uit. OK |
| `{"act":"cards_done"}` | CARDS | OK als cards == C_x, anders WRONG_HOLES |
| `{"act":"plug","l":l,"src":"old_shift"\|"old"\|"new_shift"\|"new"}` | WIRE | OK (keuze vrij) |
| `{"act":"wire_done"}` | WIRE | OK als alle l: old_shift, anders WRONG_WIRE |
| `{"act":"lever"}` | LEVER | elke kolom := shift1(kolom) (`lever`); fase CARD. In CARD: klem `already` |
| `{"act":"card","x":x}` | LEVER of CARD | x = letter van z of `""` (blanco). Correct x* = t[j] als t[j] in z, anders `""`. Verdict: zonder hendel NO_SHIFT (dan geldt de ongeschoven kolom), anders x ≠ x* → WRONG_CARD, anders OK. Nieuwe kolommen: eigen_l = (geschoven of niet) & cards[x]; l = 0: eigen_0; l ≥ 1: (1,0,…,0) \| fout_l \| eigen_l met fout_l volgens de stekker (old_shift = shift1(oud_{l−1}), old = oud_{l−1}, new_shift = shift1(nieuw_{l−1}), new = nieuw_{l−1}). Onderste lamp van kolom l aan → melding (end = j, start = j−m+1, level = l, real = mismatches ≤ l). j += 1 |
| `{"act":"choose","start":p}` | CHOOSE | OK als p een echt exact voorkomen is (M⁰), anders WRONG_PICK + FALSE_ALARM |
`cursor()`: `{j, ch:String, lever_pulled:bool, cols, cards, wiring, expected_card (enkel tutorial)}`.

**`TxEditBoard`** (`a` = rijen, `b` = kolommen, `approx`, `tab` (spelerswaarden, −1 = leeg), `dirs`)
| zet | fase | effect / verdict |
|---|---|---|
| `{"act":"fill","dir":"diag"\|"up"\|"left"}` | FILL | cel = cursor (rij per rij, links → rechts, prefill overgeslagen). waarde = tab[pred] + kost (diag: 0 als a[i−1] == b[j−1], anders 1; up/left: 1). OK als die waarde het minimum is van de drie (met de **spelerswaarden** van de buren), anders WRONG_MIN |
| `{"act":"pick_end","j":j}` | PICK_END (approx) | klem `range`. OK als tab[m][j] minimaal is in de spelersrij, anders WRONG_END. Echtheid: kolom j is een echte minimumkolom van D |
| `{"act":"step","dir":…}` | TRACE | klem `no_current` (tab[cel] ≠ tab[pred] + kost) of `range`. OK. Bij (0,0) (Algoritme 7) of rij 0 (Algoritme 8): `print_ops`, melding (approx: start = kolom, end = j−1) → TRACE_DONE |
| `{"act":"trace_again"}` | TRACE_DONE | nieuw spoor vanaf de eindcel (Algoritme 7) of PICK_END (Algoritme 8) |
| `{"act":"finish"}` | TRACE_DONE | klaar |
`cursor()`: `{i, j (FILL-cel of spoorpositie), end_j, sequences_found:int, matches_found:Array}`.
Extra: `distinct_sequences() -> Array` (gevonden bewerkingsreeksen), `true_table() -> Array`.

**`TxSabotage`** — `{"act":"set","which":"z"|"t","i":i,"ch":c}` (COMPOSE, klem `range`/`not_now` bij een vaste z) ·
`{"act":"send"}` (`enemy_run`; bij `bmh_min` met z in t: `valid = false`, telt niet) · `{"act":"finish"}`.
`cursor()`: `{z, t, best:int, last:int, optimum:int}`. Orakel: zet de tegels naar `stage.example` (§5), dan send, finish.

### 8.8 Levels, director, scoring, opslag, generator
```gdscript
class_name TxLevelSpec extends RefCounted
var id: String; var dossier: int; var title: String; var intro: String; var notes_ref: String
var priority: String                          # "P0"|"P1"|"P2"
var mode: int                                 # TxCodes.Mode
var stages: Array[Dictionary]                 # 8.5
var live: Dictionary = {}                     # {"v":0.8, "B":4, "rival":true} | ritme: {"bpm":100, "strak":0.2}
var stars: Array[Dictionary]                  # [{"kind":"done"} | {"kind":"hits_ge","n":3} | {"kind":"no_mistakes"} | {"kind":"no_help"}
                                              #  | {"kind":"no_bumps"} | {"kind":"time_le","s":150} | {"kind":"sequences_ge","n":2}
                                              #  | {"kind":"matches_all"} | {"kind":"metric_ge","stage":0,"v":27} | {"kind":"metric_eq_opt","stage":0}
                                              #  | {"kind":"strak_ge","n":24} | {"kind":"no_tear"} | {"kind":"budget_le","v":120}]
var optimum: Dictionary                       # {ticks, wheel, lamps, relays, time_par}
var ghost: Dictionary                         # {"brute_ticks":42}
var hints_allowed: bool = true
var tutorial: Array[Dictionary] = []          # [{"trigger":"first_decide","ghost":{"act":"shift","s":3},"text":"…"}]
var story: Dictionary = {}                    # {"chef_intro":"…", "debrief_extra":"…", "crate":"K-M-P 1977"}

class_name TxLevels
static func ids() -> PackedStringArray        # campagnevolgorde "1-1" … "8-3", "F"
static func get_spec(id: String) -> TxLevelSpec
static func endless_spec(tape_index: int, seed_: int) -> TxLevelSpec
static func make_machine(stage: Dictionary, carry: Dictionary, mode: int) -> TxMachine
static func optimum(spec: TxLevelSpec) -> Dictionary   # speelt alle stages met correct_move()

class_name TxDirector extends RefCounted
signal stage_started(index: int, machine: TxMachine)
signal beat(j: int)                           # ritme
signal live_warning(seconds_to_tear: float)
signal level_finished(report: Dictionary)
var spec: TxLevelSpec; var machine: TxMachine; var stage_index: int; var scoring: TxScoring
var time: float; var finished: bool; var hints: int; var undos: int
func start(s: TxLevelSpec) -> void
func tick(dt: float) -> void                  # LIVE: front += v·dt → machine.set_front(); ritme: hendel op de tel,
                                              # blanco na de tel als er geen kaart kwam (LATE als dat fout is); rivaal
func apply(move: Dictionary) -> Dictionary    # stuurt door naar de machine; volgende stage als die klaar is
func hint() -> Dictionary                     # machine.correct_move() + log HINT
func undo() -> bool                           # CALM: herstelt de snapshot van vóór de laatste beslissing; log UNDO
func rival() -> Dictionary                    # 3-5: {start, hits, tears}
func finish() -> Dictionary                   # TxScoring.final_report

class_name TxScoring extends RefCounted
signal points_changed(total: int, delta: int, reason: String)
signal combo_changed(combo: int)
signal full_power()                           # combo ×4
var points: int; var combo: int
func bind(director: TxDirector) -> void
func tick_real(dt: float) -> void             # combo-venster 4 s
func final_report(director: TxDirector) -> Dictionary
	# {stars:[bool,bool,bool], star_labels:[String,String,String], points:int, breakdown:[{label,amount}],
	#  counters:Dictionary, optimum:Dictionary, ghost:Dictionary, hits:Array, missed:Array, false_alarms:Array,
	#  mistakes:Array[Dictionary], bumps:int, hints:int, undos:int, time_s:float, tables:{yours, correct}, sabotage:{…}}

class_name TxSave
static func load_data() -> Dictionary         # {version:1, stars:{"3-1":3}, best:{"3-1":points}, highscores:[{name,score,date}], settings:{…}}
static func save_data(d: Dictionary) -> void
static func set_stars(id: String, n: int) -> void        # houdt het maximum
static func add_highscore(score: int, name: String, date: String) -> int   # rang 1..10 of 0
static func setting(k: String, default_value) -> Variant
static func set_setting(k: String, v) -> void

class_name TxTextGen extends RefCounted
func _init(seed_: int) -> void
func tape(index: int) -> Dictionary           # {z, t, plants:Array[int], decoys:Array[int]} volgens §5.11
```

### 8.9 `TxEventLog`
```gdscript
class_name TxEventLog extends RefCounted
var entries: Array[Dictionary]
	# {seq:int, t:float, stage:int, type:String, data:Dictionary (incl. move), verdict:int, ok:bool, auto:bool,
	#  hint:Dictionary (correct_move vóór de zet), affects:Array[int] (begin van voorkomens die door dit event gemist/vals werden),
	#  before:Dictionary (snapshot; enkel bij verdict ≠ OK, bij klemmen en bij de eerste zet van elke stage)}
func add(type: String, data: Dictionary, verdict: int, ok: bool, hint: Dictionary, before: Dictionary, auto := false) -> Dictionary
func mistakes() -> Array[Dictionary]           # verdict ∉ {OK, BUMP}
func bumps() -> Array[Dictionary]
func cause_of(start: int) -> Dictionary        # het event dat voorkomen @start deed missen/vals melden, of {}
func coach_line(entry: Dictionary) -> String   # §6.5 (klemmen: korte regel per reason, bv. no_mesh → "Die tanden passen niet: …")
func notes_ref(entry: Dictionary) -> String    # bv. "Definitie 11 · notas p. 56"
```
Types: `STAGE_START GO NEEDLE SHIFT STRIP PUNCH PUNCH_TO DONE WHEEL COMMIT BIT SLIDE VERIFY REPORT IGNORE STAMP
CARDS_DONE KEY JUMP HOLE PLUG WIRE_DONE LEVER CARD CHOOSE FILL PICK_END STEP TRACE_AGAIN SET SEND HIT MISSED
FALSE_ALARM TEAR BUMP HINT UNDO STAGE_END LEVEL_END`.

### 8.10 Gameplay-zijde (ter info, niet bindend)
`games/telex/scripts/game/`: `tx_title.gd`, `tx_mission_map.gd`, `tx_console.gd` (hoofdscène: bouwt nodes in `_ready`,
één scène voor alle levels; `--level=3-1` als commandoregelargument voor QA), `tx_tape_view.gd` (lint, sjabloon, naald,
leeskop, inlaat, versnipperaar, lusbak), `tx_wheel_view.gd`, `tx_punch_view.gd` (ponsbank/strook), `tx_cards_view.gd`
(kaartenbak), `tx_lamp_view.gd` (lampen- en ruisbord + matrixlog), `tx_board_view.gd` (schakelbord/zoeklicht +
herstelstrook), `tx_sabotage_view.gd`, `tx_hud.gd`, `tx_debrief.gd` (herbeleving met een tweede read-only machine),
`tx_notes_view.gd` (notas-weergave), `tx_cheat_sheet.gd`, `tx_coast_map.gd`. De bestaande autoloads `Sfx`, `Juice`,
`Transition` gebruiken, niet wijzigen. Scènes: `res://games/telex/scenes/title.tscn` (minimaal), `console.tscn`.

---

## 9. Testgevallen die de core móét halen (`games/telex/tests/run_tests.gd`)

Alle verwachte waarden komen uit de referentie-implementatie (zie inleiding) en, waar vermeld, letterlijk uit de notas.
"bot" = de stage afspelen met `correct_move()`. Elke machinetest controleert ook `invariants().is_empty()` na elke zet.

**TxReference tegen de notas**
- **T01 V[] van `barbados` (p. 56):** `v_def("barbados", false) == [1,1,2,3,3,3,6,7]`; `v_def(…, true)[8] == 8`.
- **T02 Algoritme 5 voor `barbados` (p. 61–62):** `bereken_v("barbados").steps` =
  (start 1, gel 0, em 0, vult 2→2, schuif 1) · (2, 0, 0, 3→3, 1) · (3, 0, 2, 4→3 en 5→3, 2) · (5, 0, 0, 6→6, 1) ·
  (6, 0, 0, 7→7, 1); `v[8] == -1` (niet ingevuld).
- **T03 KMP-voorbeeld (p. 58–59):** `kmp("barbados","barbaarse_barbecue_in_barbados", v, FIRST)`: em-reeks
  5, 2, 0, 0, 0, 0, 0, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0, 8; 18 uitlijningen, 34 tikken, treffer 22.
- **T04 Alg. 5 = Def. 11:** voor alle woorden over {a,b} van lengte 2..9 en over {a,b,c} van lengte 2..6:
  `bereken_v(z).v[0..m−1] == v_def(z)[0..m−1]`, en als `bereken_v` v[m] invult, is dat gelijk aan `v_def(z, true)[m]`.
- **T05 KMP ALL = brute kracht:** 20 000 willekeurige paren (z over {a,b} van lengte 2..5, t van lengte |z|..15):
  dezelfde treffers. Idem voor BMH ALL en shift-AND.
- **T06 Oef. 39:** V(`volvoert`) = [1,1,2,3,3,3,6,7]; Algoritme 5-stappen gelijk aan T02 (zelfde vorm); KMP op
  `volvo_vol_vogels_volvoert_kunststukje`: (0,0,5)(3,2,2)(5,0,0)(6,0,3)(9,0,0)(10,0,2)(12..16 em 0)(17,0,8); 29 tikken,
  treffer 17; brute kracht 37 tikken, spoelmeter 8.
- **T07 Oef. 40:** V(`ananas`) = [1,1,2,2,2,2]; Algoritme 5: (1,0,0, 2→2, 1) · (2,0,3, 3/4/5→2, 2). KMP op
  `bananen_in_ra'ananas'_centrum`: em-reeks 0, 4, 2, 0×7, 1, 0, 6; 23 tikken, treffer 14; brute kracht 27.
- **T08 V_H van `barbara` (p. 65):** `vul_vh("barbara") == {a:2, b:3, r:1}`, andere = 7. BMH op
  `barbados_zoekt_barbara`: i = 6, 13, 20, 21; sprongen 7, 7, 1; 10 tikken; treffer 15.
- **T09 Oef. 48:** V_H(`ananas`) = {a:1, n:2}, andere (ook `s`) = 6; BMH op `de_spa_in_ra'ananas'`: i = 5, 6, 12, 18;
  9 tikken; treffer 13.
- **T10 Figuur 23 (p. 67–69):** C_a = 101, C_n = 010; kolommen voor `ananas`: 100, 010, 101, 010, 101, 000; eindes 2 en 4.
- **T11 Oef. 54:** kolommen zoals §5.6 (5-2), enige einde 16 (begin 11).
- **T12 Oef. 60 (Definitie 14):** `shift_and_k("dank","een_dansfeest",1)`: M⁰ nooit onderaan; M¹ enkel op j = 7. Kolommen
  M⁰/M¹ zoals §5.7. Eerste kolom = (0000, 1000) (p. 70: (1,0,…,0) voor k > 0). Stekkers: `old` → geen einde, `new_shift`
  → einde 6, `new` → geen einde. Elke cel van M^k klopt met Definitie 14 rechtstreeks berekend.
- **T13 `zender`:** M⁰ einde 12; M¹ eindes 5, 12, 19, 26.
- **T14 Oef. 34 (Rabin-Karp):** `rk("00101","1101110010001010",13,FIRST)`: hz 5, w 6, hs = 1, 10, 1, 2, 12, 5, 4, 8, 4, 2, 5;
  controles bij i = 5 (ongelijk, 1 tik) en i = 10 (gelijk, 5 tikken); 6 tikken; wheel_ops 41; brute kracht 23.
- **T15 2-2:** `rk("1011","1010010110110100",7,ALL)`: hz 4, w 2, hs = 3, 4, 2, 2, 5, 4, 6, 6, 4, 6, 6, 3, 4; controles 1 (ongelijk),
  5 (gelijk), 8 (gelijk), 12 (ongelijk); 10 tikken; wheel_ops 42 (31 zonder w en h(z)).
- **T16 Oef. 34b:** over alle 2^16 teksten is het maximum aantal controles (FIRST) 12, enkel voor t = 1^16.
- **T17 Oef. 32:** maximum brute-krachttikken (FIRST) over {a,b}: (n, m) = (12, 4) → 36; (16, 8) → 72; (8, 4) → 20.
- **T18 Oef. 50:** BMH, n = 16, m = 4, {a,b}: minimum tikken met z ∉ t = 4; maximum = 52, enkel (baaa, a^16) en (abbb, b^16).
- **T19 Algoritme 7 (p. 76):** `edit_table("lessen","feesten")` = de tabel van §5.8 (rij per rij); d = 3; 4 optimale paden;
  `ops_of_path` geeft de 4 reeksen van §5.8 exact (posities in de string van dat moment).
- **T20 Oef. 62:** `edit_table("roestig","oesters")` = de tabel van §5.8; d = 4; 3 reeksen zoals §5.8.
- **T21 Algoritme 8 (p. 79):** `approx_table("examen","de_armen_vouwen")` = de tabel van §5.9; best 2, eindkolom 8, uniek
  pad, begin 1, match `e_armen`, bewerkingen (vervang `x` op 1 door `_`, voeg `r` toe op 3).
- **T22 Oef. 70:** best 2, enkel kolom 14; beginposities van alle optimale paden {8, 9, 10}.
- **T23 Oef. 71:** best 1, kolommen {4, 7, 11}; matches `best`/`est` (4), `te_t` (7), `tekst` (11).
- **T24 brute kracht 1-1:** 27 tikken, 18 uitlijningen, spoelmeter 4, treffers 3 en 17. Joker (1-3): 36 tikken, treffers 3, 13.

**Machines (spelregels, gevolgen)**
- **T25 tanden (3-1):** bij (0,0,5): `shift 1` en `shift 2` → `ok=false` `no_mesh`, staat ongewijzigd (snapshot gelijk);
  `shift 3` OK; `shift 5` → SHIFT_LONG (past). `preview({"act":"shift","s":4})` → `mesh=false`. Bij (10,0,4): {3, 4} passen.
- **T26 te ver na een treffer (3-4):** na treffer @0 `shift 4` (past, s ≥ em) → SHIFT_LONG; voorkomen @2 → MISSED met
  `cause_seq` = die zet; verdere bot-zetten vinden 4, 22, 24 (30 tikken).
- **T27 spiegelrit (3-3):** bot reproduceert T02-vorm met V = [1,1,2,3,3,3,6,7]. In stap 3: `punch_to to=6 v=3` → klem
  `no_mesh` (vakje 6 met 3 past niet); `punch_to to=4 v=3` → PUNCH_SHORT en na de spiegelrit is vakje 5 leeg (`STRIP_EMPTY`);
  in stap 1: `punch_to to=2 v=1` → klem `no_mesh`.
- **T28 vergeten −w (2-3):** bij i = 1 zijn het uitgaande bit t[0] = 1 en het inkomende bit t[5] = 1. De speler doet
  `double`, `plus1`, `slide` (zonder `minus_w`) → WRONG_HASH (één keer). Met verder
  correcte stappen is de wielstand per venster 1, 3, 0, 0, 8, 10, 1, 2, 5, 4, 9, 5 (i = 0..11). Alarmen bij i = 8
  (`10001`, controle 1 tik, botsing) en i = 11 (`01010`, 2 tikken, botsing); het echte voorkomen @10 passeert (wiel 9):
  MISSED met `cause_seq` = de slide van i = 1. Er is precies één misstap WRONG_HASH.
- **T29 kaartvolgorde (4-3):** stempels in de volgorde 3, 0, 1, 2 → s = 4 (overschreven) → WRONG_CARDS. Doorloop met de
  sleutel telkens op i: sprongen 3, 5, 2, 5, 3, 3, 5, **4** → treffer 18 gevonden, @27 MISSED (i springt van 30 naar 34).
  `stamp 4` → klem `last_pos`.
- **T30 lampenbord (5-2):** `card` zonder `lever` bij j = 14 (`k`) → NO_SHIFT, geen bel op 16, MISSED @11. Blanco bij
  j = 15 (`e`) → WRONG_CARD, geen bel, MISSED @11. Tweede `lever` → klem `already`.
- **T31 schakelbord (7-1):** cel (1,1) met `up` → waarde 2, WRONG_MIN, `warm`; de bot vult de rest correct t.o.v. de
  spelerswaarden → tab[2][2] = 2 en eindwaarde nog 3. Laatste cel (6,7) met `left` → 5, WRONG_MIN. Een terugstap naar
  een buur zonder stroom → klem `no_current`.
- **T32 stroommodel:** `need()` per machine zoals §2.5. KMP (3-5, B = 4): met onmiddellijke beslissingen nooit een
  scheur. Brute-krachtrivaal (onmiddellijk lezen, B = 4) op `kokos`: scheuren bij F = 5, 7, 9, 21, 26; 0 treffers;
  met B = 5: treffers 4, 16, 21 en geen scheur. `force_to(S)` markeert elk niet-gemeld echt voorkomen met begin < S
  (KMP/brute kracht) als MISSED (oorzaak TEAR).
- **T33 Rabin-Karp-alarm:** in 2-3 bij i = 5: `report` → FALSE_ALARM (+ `consequence` false_alarm); `ignore` → SKIPPED_CHECK
  zonder MISSED; bij i = 10: `ignore` → SKIPPED_CHECK + MISSED; `report` → UNVERIFIED en de stage eindigt (FIRST).
- **T34 ruisbord-bedrading (6-1):** `plug old` → WRONG_WIRE bij `wire_done`; doorloop zonder bel; `dans` @4 MISSED.
  `plug new_shift` → bel op j = 6 met `real=false` → FALSE_ALARM, en @4 MISSED.
- **T35 tegenzet:** `send` met z = `aaab`, t = a^12 → metriek 36 (FIRST, brute kracht); `bmh_min` met z = `aaaa`,
  t = a^16 → `valid=false`.

**Algemeen**
- **T36 snapshot:** voor elk level: na elke bot-zet is `snapshot() → restore() → snapshot()` identiek (ook midden in een
  spiegelrit, een alarm, een kolom met getrokken hendel en een half spoor).
- **T37 elk level met de bot:** 3 sterren; tellers == `spec.optimum` (bv. 3-1 34 tikken, 2-3 6 tikken + 41 wielslagen,
  5-2 17 lampslagen, 7-2 49 relais); treffers == §5.
- **T38 orakelconsistentie:** voor elke fase van elke machine wordt `correct_move()` door `apply()` aanvaard met verdict
  OK; elke zet uit `impossible_moves()` geeft `ok=false`; elke zet uit `wrong_moves()` geeft `ok=true` en verdict ≠ OK.
- **T39 opslag:** `TxSave` roundtrip; `set_stars` houdt het maximum; highscore-rang.
- **T40 generator:** `TxTextGen.new(42).tape(k)` is deterministisch; de ingeplante z staan op `plants` (geen overlap);
  `TxReference.bmh(z, t, ALL).hits` ⊇ `plants`; lengtes volgens §5.11.

---

## 10. Scope & prioriteiten

**P0 (MVP: zonder dit is de game niet af):**
- Core volledig voor alle machines (§8), tests T01–T40.
- Levels **1-1, 1-2, 2-1, 2-2, 2-3, 3-1, 3-2, 3-3, 4-1, 4-2, 4-3, 5-1, 5-2, 6-1, 7-1, 7-2, 8-1, 8-2, 8-3** (19) +
  **Nachtdienst** (Springer).
- Schermen: titel (met hub-terugweg), missiekaart, briefing, console, debrief (sterren, tellers + geest, lintverslag,
  tabelvergelijking, misstappen-tijdlijn met herbeleving + coachzin, notas-weergave), pauze, instellingen,
  Notas-spiekbriefje, opslag (sterren, beste punten, highscore, instellingen).
- Besturing muis + toetsenbord (§4.1), hint, terugnemen, tutorials (spookhand).
- Juice 1–17, 21–26, 28–33, 36 (minstens 30 van de 38); audio: alle cues uit §7.2 (procedureel mag), één muzieklus voor
  CALM, één voor LIVE, titel/kaart.

**P1 (sterk gewenst):**
- Levels 2-4, 3-4, 3-5 (met rivaal), 4-4, 5-3 (ritmesectie met eigen nummer), 6-2, **Finale "Operatie Ekster"**.
- Combo/"Volle stroom", kustkaart met koeriers en ploegen, kisten met typeplaatjes, attract-lint op de titel,
  Nachtdienst-variant Doorloper, kleurenblindmodus.

**P2 (polish / als er tijd is):**
- 1-3 (Oef. 33 jokers), "Gemengde dienst" (machinekeuze in de Nachtdienst), Oef. 61 (verwijderen uit de tekst als
  stekker `old`), Oef. 51 (DNA-lint voor de Springer), Oef. 66 (verwisselen), verzamelbare "dossierfoto's".

**Bewust NIET:** hoofdstuk 4 (compressie); Boyer-Moore (volledig) en Galil; wildcards `*` (Oef. 33b/37/47/55);
Rabin-Karp over algemene alfabetten (Oef. 36); online leaderboards.

**Bouwvolgorde (voorstel voor parallel werk):**
1. core: `TxCodes`, `TxReference` + T01–T24 (dat kan meteen, zonder spelstaat) ∥ front-end: console-skelet met lint,
   sjabloon, naald, tikteller, met een **nep-machine** (speelt `TxReference.kmp`-sporen af) en de missiekaart.
2. core: `TxMachine`, `TxBrute`, `TxKmp`, `TxKmpTable` + T25–T27 ∥ front-end: dossiers 1 en 3 (tanden, strook, ponsbank).
3. core: `TxBmh`, `TxRabinKarp` + T28/T29/T33 ∥ front-end: Springer, hashwiel.
4. core: `TxShiftAnd`, `TxEditBoard` + T30/T31/T34 ∥ front-end: lampenbord/ruisbord, schakelbord/zoeklicht.
5. core: `TxDirector` (LIVE, ritme), `TxScoring`, `TxSave`, `TxTextGen`, `TxSabotage`, `TxBot` + T32/T35–T40 ∥ front-end:
   debrief + herbeleving, Nachtdienst, tegenzet-scherm.
6. QA-ronde (bots met foutmodi, frame-opnames), dan P1.

---

## 11. Open vragen voor de lead

1. **V[m] voor "alle voorkomens" (Oef. 41).** De notas definiëren V[j] voor j < \|z\| en Algoritme 4 stopt bij de eerste
   treffer. Voor ALL-levels (3-4, 3-5, finale F-1) gebruikt het spel na een volledige treffer V[m] volgens Definitie 11
   met j = m (kleinste s met 0 < s < m en z[0..m−1−s] = z[s..m−1], anders m), met `gelijke_tekens = m − V[m]`. Algoritme
   5 vult V[m] soms zelf in (`tata`, niet bij `barbados`). Waar het dat doet, is de waarde altijd gelijk aan deze
   uitbreiding (nagerekend). Akkoord als "antwoord" op Oef. 41?
2. **Wat telt als tik?** Elke tekenvergelijking in `strings_gelijk`, `vergelijk_strings` (ook tegen ⏎ in Algoritme 5) en
   `strings_gelijk_invers`. Hashbewerkingen, lampkolommen en cellen tellen apart. OK?
3. **Tanden = klem.** Een KMP-verschuiving s < V[j] zou in de pseudocode tekens als gelijk aannemen die niet gelijk
   zijn. Het spel laat dat niet toe (de tanden passen niet). Enkel te grote verschuivingen worden uitgespeeld. Reden:
   met een ongeldige `gelijke_tekens` is de rest van de doorloop onbegrijpelijk. Elke klem wordt wel geteld (★★★).
   Akkoord?
4. **Spiegelrit-procedure.** Wij laten de speler per stop het laatste vakje en de waarde kiezen (`punch_to`). De
   ponskop start op het eerste nieuwe vakje, en ponsen dat niet past klemt (§3.3). Is dat een getrouwe vertaling van
   Algoritme 5?
5. **Rabin-Karp:** (a) het wiel rekent meteen mod q, en de machine dwingt binnen een venster geen volgorde van ×2/−w/+1 af (de notas
   schrijven één formule). (b) Het oordeel per stap is relatief aan de vorige wielstand, zodat één fout één misstap is.
   (c) De knop "Meld meteen" bestaat niet in Algoritme 3. Hij laat de misvatting "gelijke hash = treffer" uitspelen.
   (d) Enkel bitstrings, zoals in de notas (geen Oef. 36). Akkoord?
6. **Shift-AND-start:** het bord start met nullen en de lus begint bij j = 0 ("kolom −1", p. 68). Voor M^k geeft dat
   exact de eerste kolom (1,0,…,0) voor k > 0 en (z[0] = t[0]) voor k = 0 (nagerekend). De voedingslamp wordt door de
   hendel gezet (shift¹). OK?
7. **Ruisbord-stekkers.** Wij bieden vier aansluitingen. `old` (ongeschoven) komt overeen met "een teken uit de tekst
   verwijderen" (Oef. 61), en `new_shift` met een teken van z overslaan. De debrief noemt dat enkel als "ander
   foutmodel", zonder een definitie te geven die de notas als oefening laten. Akkoord?
8. **Posities van bewerkingen.** De herstelstrook toont de reeks in stijgende volgorde (Lemma 17), met posities in de
   string op dat moment. Daardoor staat de reeks van Definitie 15 (p. 72) in een andere volgorde ("voeg e toe op 1"
   vóór "vervang s op 4 door t" in plaats van "vervang s op 3" eerst). Akkoord?
9. **Algoritme 8: welke "beste match"?** Bij Oef. 70 hebben `kweken`, `weken` en `eken` allemaal afstand 2 en eindigen ze
   in dezelfde kolom. Bij Oef. 71 zijn er drie eindkolommen. Het spel aanvaardt elke optimale match en beloont "alle"
   met ★★★. Klopt dat met de bedoeling van de oefeningen?
10. **Oef. 32-interpretatie.** "Geparametriseerde reeks" = z = a^(m−1)b, t = a^n met m = n/2. Het spel laat twee instanties
    bouwen en tekent de parabool. Volstaat dat (zonder formeel bewijs in het spel)?
11. **Nachtdienst = enkel de Springer (P0).** BMH geeft het snelste arcadegevoel (grote sprongen, snel beslissen). De
    Doorloper-variant is P1. OK?
12. **Machinetijd in de finale** (tik = lampslag = relais = wielslag = 1) is een spelvereenvoudiging om machines te
    vergelijken. Lampslag = 1 volgt "bitvectoren in één woord" (p. 69). Aanvaardbaar?
13. **Apostrof in Oef. 40/48:** de pdf toont `ra’ananas’`. Het spel gebruikt de ASCII-apostrof `'` (zelfde lengte en
    posities). OK?
14. **Brute-kracht-spoelmeter:** gedefinieerd als Σ max(0, laatst vergeleken positie − volgende start). Dat is geen
    begrip uit de notas, enkel een visualisatie van het herlezen. OK?
15. **Rivaal in 3-5:** de rivaal leest "onmiddellijk" zodra een teken binnen is. Dat model is het gunstigste voor brute
    kracht, en ook dan scheurt ze bij B < m. OK als demonstratie van "geschikt voor streams"?

---

## Samenvatting voor het team
- **Kern:** een analoge spionage-console. Elke machine is een algoritme. Het **lint** stroomt door een **leeskop**, en
  de **naald** doet `vergelijk_strings` (tik per vergelijking). De speler neemt de algoritmische beslissing: de
  **tanden** (Definitie 11) bij de Doorloper, de **ponsstrook** (Algoritme 5), het **hashwiel** mod q (rollend: ×2,
  −w, +1, controleren), het **sleutelteken** en de **kaartenbak** (V_H), **hendel + ponskaart** (shift¹ & C_x), de
  **foutkabel** (M^k), de **ingangen van het schakelbord** (min van drie) en het **zoeklicht** (minimum onderaan +
  teruglopen).
- **Levels:** D1 Het lint (1-1 kerk/kerker · 1-2 Oef. 32 tegenzet · 1-3 jokers) | D2 Vingerafdrukken (2-1 wiel · 2-2 rollen ·
  2-3 Oef. 34 · 2-4 Oef. 34b) | D3 De Doorloper (3-1 barbados · 3-2 spiegel + Oef. 40 · 3-3 spiegelrit + Oef. 39 ·
  3-4 Oef. 41 tata · 3-5 nachtstroom) | D4 De Springer (4-1 barbara · 4-2 Oef. 48 · 4-3 walsalsa · 4-4 Oef. 50) |
  D5 Het lampenbord (5-1 Figuur 23 · 5-2 Oef. 54 · 5-3 tiktak-ritme) | D6 Ruis op de lijn (6-1 Oef. 60 · 6-2 zender) |
  D7 Het schakelbord (7-1 lessen/feesten · 7-2 Oef. 62) | D8 Het zoeklicht (8-1 examen · 8-2 Oef. 70 · 8-3 Oef. 71) |
  Finale Operatie Ekster | Nachtdienst (Springer-sprint).
- **Fouten** hebben gevolgen in de wereld: ontsnapte koeriers (gemist), valse arrestaties (vals alarm), een gescheurd lint
  (te traag in een stroom), warme relais en extra inkt. Wat het algoritme verbiedt, is fysiek onmogelijk (klem).
- **Posities 0-gebaseerd** zoals de notas; editeertabellen met lengtes als index. FIRST stopt zoals de pseudocode, ALL
  volgt Oef. 41 (V[m]).
