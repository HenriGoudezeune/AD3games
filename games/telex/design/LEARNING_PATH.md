# TELEX — leerpad (string matching, lesnotas §3.4–3.5, p. 50–80)

Methode: `design/LEARNING.md` (per deel **Kijk → Samen → Zelf → Check**). Verteller: **Chef Ponsaert** in een paneel
rechts op de console (in de stijl van het luisterstation). Alle verteltekst, tips, foutuitleg, voorspel- en
Check-antwoorden worden **uit de core berekend** (`TxLessons`, proefkopie van de machine + `TxReference`), dus ze
kloppen altijd; de getallen hieronder zijn zo nagerekend (`tests/suites/t_lessons.gd` controleert ze).

Code: `scripts/game/tx_lessons.gd` (delen, specs, verteltekst, toestand, tips, foutuitleg, voorspel- en
Check-vragen), `scripts/game/tx_lesson_coach.gd` (Kijk/Samen op de console), `scripts/game/tx_check_quiz.gd`
(Check in de terugblik), integratie in `tx_console.gd` (`move()` vraagt `coach.allow()`), `tx_session.gd`
(wachtrij), `tx_map.gd` (badges), `tx_guide.gd` (leerpadpagina's), `tx_debrief.gd` (knop Check).

## Lesverloop (voor elk deel)

- **Kijk**: de Chef speelt het orakel (`correct_move`) af. Vóór elke stap staat de machine stil, wijst de spookhand
  het element aan en zegt het paneel **wat** er gebeurt (vetgedrukt) en **waarom** (grijs). Na de stap volgt wat
  de machine **vanzelf** deed ("Daarna vanzelf: 5× mismatch al op z[0] → telkens 1 opschuiven"). Onderaan staat
  de **toestand zoals op het examen**: tabel `j / z[j] / V[j]`, `start · gelijke_tekens · eerste_mismatch`,
  `x / V_H(x)`, rijen `C_x` en de kolom `M[][j]` (`M¹[][j]`), `d[i][j] = min(↖ a + c, ↑ b + 1, ← d + 1)`,
  `q · w · h(z) · wiel`. Knoppen: **Volgende ›** (Spatie/Enter/→), **Afspelen/Pauze** (P), **Overslaan** (enkel als
  al gezien). Rabin-Karp: de wielbewerkingen van één bit/venster vormen samen één vertelde stap.
- **Samen**: de speler speelt met dezelfde muis- en toetsbediening als in het spel. Tip (+ spookhand + ring) bij
  de eerste 2 zetten van elke soort, daarna "Jouw beurt" en enkel op vraag **Hint (F2)**. Een foute zet wordt
  **niet uitgevoerd**: rode uitleg *waarom* + "Probeer opnieuw"; na 2 fouten op dezelfde stap wijst de spookhand de
  juiste zet aan. Zetten die de core pas later beoordeelt (wiel ×2/−w/+1, gaatjes, stempels, stekker) moeten met
  het orakel overeenkomen (`TxLessons.accepts`).
- **Zelf**: het gewone level (eerste level van het deel = poort).
- **Check**: voorspelvragen in Kijk/Samen vóór de machine het toont (antwoord + uitleg meteen), en in de
  **terugblik** (knop **Check** in de debrief, opent vanzelf zolang een deel nog niet "begrepen" is) 1–2 vragen op
  een **nieuw willekeurig voorbeeld** op een "examenblad". Fout = uitleg + nieuw voorbeeld (max. 2 herkansingen).
- **Badge** op het levelkaartje van de poort (missiekaart, rechtsboven): grijs = nog niet, blauw = demo bekeken,
  amber = samen geoefend, groen ✓ = begrepen (Samen + Check juist). Tooltip: "leerpad k: titel (status)".
- **Eerste keer verplicht**: vóór een level speelt de console eerst Kijk en Samen van elk deel met poort ≤ dat level
  dat nog niet "samen geoefend" is. Daarna overslaanbaar en herbekijkbaar in de gids (**F1 → Doel → Leerpad · deel
  k**: "Bekijk de demo opnieuw" / "Oefen dit opnieuw"; in een level staan de delen van dat level eerst; daarna terug
  naar het level). Bot-modus (`bot=…`) en `no_lessons` slaan alles over. Voortgang: `TxSave` setting `learning`
  (`nosave`: enkel in het geheugen).

## Delen (volgorde = opbouw)

| # | id | deel | Kijk (voorbeeld) | Samen | Zelf |
|---|----|------|------------------|-------|------|
| 1 | brute | Brute kracht: elke start, tikken tellen | z = kerk, t = de_kerker | z = nat, t = na_de_natte | 1-1, 1-2, 1-3 |
| 2 | rk_hash | Rabin-Karp: de hashwaarde h(s) | Oef. 34: z = 00101, q = 13; signalen 11011, 00101 | z = 110, q = 5; 011, 110 | 2-1 |
| 3 | rk_rollen | Rabin-Karp: rollend bijwerken | z = 1011, q = 7, t = 0101101 | z = 110, q = 5, t = 011010 | 2-2 |
| 4 | rk_vals | Rabin-Karp: alarm en valse treffer | Oef. 34: z = 00101, q = 13, t = 100100101 | z = 110, q = 5, t = 0011100 | 2-3, 2-4 |
| 5 | kmp_idee | KMP: verschuiven zonder terug te lezen | p. 58: barbados in barbaarse_barbecue_in_barbados | kakao in kaka_kakakao | 3-1 |
| 6 | kmp_def11 | KMP: de tabel V[] (Definitie 11) | p. 56: barbados | kakao | 3-2 |
| 7 | kmp_alg5 | KMP: V[] met Algoritme 5 | p. 61–62: barbados | kokos | 3-3 |
| 8 | kmp_loop | KMP: de doorloop met de strook (+ V[m]) | tata in tatata_tat (Oef. 41) | kokos in kokokos_kokos | 3-4, 3-5 |
| 9 | bmh_tabel | BMH: de tabel V_H | p. 65: barbara | nonnen | 4-1 |
| 10 | bmh_loop | BMH: van rechts en springen | p. 64: barbara in barbados_zoekt_barbara | nonnen in de_non_kent_nonnen | 4-1 … 4-4 |
| 11 | sa_cx | shift-AND: de vectoren C_x | Fig. 23: ana | kaak | 5-1 |
| 12 | sa_col | shift-AND: kolom M[][j] en de bel | Fig. 23: ana in ananas | kaak in kakaak | 5-1, 5-2, 5-3 |
| 13 | sa_k | M^k: matches met k fouten | ana in abana, k = 1 | kat in kot_kat, k = 1 | 6-1, 6-2 |
| 14 | ed_fill | Editeerafstand: d[i][j] invullen | kat → kast | roos → rots | 7-1, 7-2 |
| 15 | ed_trace | Editeerafstand: teruglopen | p. 72/76: lessen → feesten (tabel ingevuld) | kat → kast (ingevuld) | 7-1, 7-2 |
| 16 | alg8 | Algoritme 8: beste benaderende match | z = kat, t = de_kast (rij 1 ingevuld) | z = tak, t = de_tas | 8-1, 8-2, 8-3 |

Aanpassing van de volgorde t.o.v. de levels: KMP krijgt vier delen (idee met de hand in 3-1 → tabel met Definitie
11 → tabel met Algoritme 5 → doorloop met de strook en V[m]); BMH en shift-AND elk twee (eerst de tabel C/V_H, dan de
doorloop); editeerafstand twee (invullen, dan teruglopen). Zo vraagt geen level iets dat nog niet in een Kijk zat.
De finale (F) en de Nachtdienst hebben geen eigen deel (herhaling).

## Per deel: Kijk-verteltekst (sleutelstappen), voorspelvragen, Samen, Check

**1 · Brute kracht** (Alg. 2, p. 50–51). Regel: probeer elke start i = 0 … n − m; stop bij het eerste verschil; één
vergelijking = één tik; slechtste geval (n − m + 1)·m (Opmerking 9).
Kijk (kerk / de_kerker): "Start 0: z[0] = k ≠ t[0] = d: meteen verschil, 1 tik" (waarom: naald van links naar rechts)
… "Start 3: alle 4 tekens gelijk: treffer op 3, 4 tikken" (waarom: elke start, kop spoelt terug) … "Start 6 > n − m
= 5: klaar. Totaal 9 tikken voor 6 startposities (slechtste geval 24)". Voorspel: *Start 3: hoeveel tikken?* → **4**.
Samen (nat / na_de_natte): de speler klikt Naald/Volgende; voorspel *Start 0* → **3** (na_ vs nat), *Start 6* → **3**
(treffer). Check: totaal aantal tikken op een nieuw z (m = 2–3, alfabet ab) en t (n = 6–8), met uitsplitsing per start.

**2 · Rabin-Karp: h(s)** (Alg. 3, p. 52–54). Regel: h(s) = g(s) mod q, met Horner per bit ×2 (+1), mod q; gelijke h
→ strings_gelijk. Kijk (z = 00101, q = 13): per bit één stap, bv. "Bit 3 = 0: ×2: 1 → 2. Bit 3 klaar: g(0010) = 2 en
2 mod 13 = 2" … "h(z) = 5 = rode inkeping". Signaal 11011: "…12 → +1 → 0 (13 mod 13)… g(11011) = 27, 27 mod 13 = 1 ≠
5: geen treffer"; signaal 00101: "= 5 → alarm → controleer: echte treffer (5 tikken)". Voorspel: *wiel na bit 3 van
z* → **2**. Samen (z = 110, q = 5): h(z) = 1; signalen 011 (3), 110 (1, alarm, echt); voorspel *wiel na bit 1 van 011*
→ **1**. Foute zet bv. Volgend bit vóór ×2: "De stand klopt nog niet: het wiel zou 1 moeten tonen", +1 bij bit 0:
"+1 enkel als het bit 1 is". Check: h(z) voor een nieuw z (4–6 bits), q ∈ {5, 7, 11, 13}, met de Horner-reeks.

**3 · Rabin-Karp: rollen** (p. 53). Regel: h_{p+1} = (2·h_p − t_p·2^m + t_{p+m}) mod q; w = 2^m mod q vooraf.
Kijk (z = 1011, q = 7, t = 0101101; h(z) = 4 vooraf): "w: 1 → 2 → 4 → 1 → 2, w = 2 (16 mod 7)"; venster 0 = 0101 →
5; rollen: "×2: 5 → 3; t_4 = 1 komt binnen: +1 → 4. Venster 1 = 1011: h = 4 (11 mod 7) = h(z): alarm" → echte
treffer; "×2: 4 → 1; t_1 = 1 valt weg: −w: 1 → 6. Venster 2 = 0110: h = 6"; venster 3 = 1101: 6. Voorspel: *moet je
−w doen (t_1 = 1)?* → **ja**; *h van venster 2* → **6**. Samen (z = 110, q = 5, t = 011010): w = 3, h(z) = 1; vensters
3, 1 (alarm, echt), 0, 2. Check: nieuw venster na rollen (m = 3–5, q ∈ {5, 7, 11, 13}) met de formule als uitleg.

**4 · Rabin-Karp: valse treffer** (p. 53–54, Oef. 34). Kijk (z = 00101, q = 13, w = 6, h(z) = 5, t = 100100101):
venster 0 = 10010 → 18 mod 13 = 5 = h(z): alarm → "controleer: 10010 en 00101 verschillen op positie 0: valse
treffer (1 tik)"; vensters 00100 → 4, 01001 → 9, 10010 → 5 (weer vals), 00101 → 5 → echte treffer. Waarom: "gelijke
hash ≠ gelijke string: Algoritme 3 roept nog strings_gelijk op". Voorspel: *1e alarm echt?* → **nee**; *3e alarm
(00101)?* → **ja**. Samen (z = 110, q = 5, t = 0011100): 001 → 1 = h(z): vals; 110 → 1: echt; voorspel 1e alarm →
**vals**. Fout "Meld meteen": "Niet zomaar melden: gelijke hash kan een valse treffer zijn". Check: aantal valse
treffers op een nieuw t (8 bits, z = 3 bits, q = 5; er is altijd ≥ 1 alarm) met alle hashwaarden in de uitleg.

**5 · KMP: het idee** (Def. 11, Alg. 4, p. 55–59). Regel: mismatch op z[j] → kleinste s > 0 met z[0..j−1−s] =
z[s..j−1] (anders s = j) = V[j]; de leeskop gaat niet terug, gelijke_tekens = j − s. Kijk (barbados, p. 58): 4
beslissingen. "Mismatch op z[5] = d ≠ t[5] = a. Schuif V[5] = 3: start 0 → 3; gelijke_tekens = 5 − 3 = 2" — waarom:
"Gelezen barba. s = 1 ✗, s = 2 ✗, s = 3 ✓ (ba = ba) → V[5] = 3. De naald gaat verder bij z[2] onder dezelfde t[5]";
dan V[2] = 2 ("s = 1 ✗: geen 0 < s < 2 past"), "Daarna vanzelf: 5× mismatch al op z[0] → telkens 1"; V[4] = 3 (b =
b), V[1] = 1 → treffer op 22 (34 tikken, 42 bij brute kracht). Voorspel: *hoeveel schuift het sjabloon (z[5])?* →
**3**; *vanaf welke positie van z verder na V[4] = 3?* → **1**. Samen (kakao / kaka_kakakao): beslissingen V[4] = 2,
V[2] = 2, V[4] = 2, treffer op 7. Te grote sprong: "4 past wel, maar is niet de kleinste: met 4 sla je mogelijk een
voorkomen over" + de s-reeks; te kleine sprong klemt ("de tanden haken niet"). Check: kleinste verschuiving bij
mismatch op z[j] voor een nieuw z (5–7 letters, ab), met de hele V als uitleg.

**6 · V[] uit Definitie 11** (p. 56, Oef. 40). Kijk (barbados): per vakje j = 2 … 7 de s-reeks: V = 1 1 2 3 3 3 6 7
(bv. "V[6]: s = 1 … 5 ✗ → V[6] = 6"). Voorspel *V[5]* → **3**. Samen (kakao): V = 1 1 2 2 2; voorspel *V[4]* →
**2**; fout 3 bij j = 3: "3 past, maar er is een kleinere: s = 2 ✓ (k = k)". Check: V[j] voor een nieuw z.

**7 · V[] met Algoritme 5** (p. 60–62, Oef. 39). Regel: z in zichzelf vanaf start = 1; em = 0 → V[start+1] = start+1,
anders V[start+i] = start (i = gel+1 … em); start += V[em], gel = em − V[em]. Kijk (barbados, zoals p. 61–62):
"start 1: em = 0 (b ≠ a) → V[2] = 2; schuif V[0] = 1"; "start 2: em = 0 → V[3] = 3"; "start 3: em = 2 (r ≠ d) →
V[4..5] = 3; schuif V[2] = 2: start 5, gelijke_tekens = 0"; "start 5: V[6] = 6", "start 6: V[7] = 7"; "start +
gelijke_tekens = 7 ≥ m − 1: klaar". Voorspel *welke vakjes bij start 3, em = 2?* → **V[4..5] = 3**; *nieuwe start?* →
**5**. Samen (kokos): V[2] = 2, schuif 1, V[3..4] = 2, schuif 2 → V = 1 1 2 2 2. Check: welke vakjes worden ingevuld
bij een willekeurige stap van Algoritme 5 op een nieuw z.

**8 · KMP-doorloop met de strook** (Alg. 4, Stelling 12, Oef. 41). Kijk (tata, V = 1 1 2 2 2 incl. V[4], t =
tatata_tat, alle voorkomens): "Treffer op 0. Alle voorkomens: schuif V[m] = V[4] = 2 (Oef. 41); gelijke_tekens = 2"
→ treffer op 2 → mismatch z[2] → V[2] = 2 → "vanzelf 1× z[0]" (8 tikken). Voorspel *(treffer) hoeveel schuif je
op?* → **2**. Samen (kokos, V = 1 1 2 2 2 5, kokokos_kokos): V[4] = 2, treffer op 2 → V[5] = 5, treffer op 8 → V[5] =
5. Check: totaal aantal vergelijkingen van KMP (alle voorkomens) op een nieuw z/t, met het spoor per start en
brute kracht ter vergelijking.

**9 · BMH: V_H** (vul_VH, p. 63–65). Regel: eerst alles m; voor i = 0 … m − 2: V_H(z[i]) = m − 1 − i (later
overschrijft); de laatste letter telt niet. Kijk (barbara): b → 6, a → 5, r → 4, b → 3 (overschrijft 6), a → 2, r →
1; "andere letters: m = 7". Voorspel *waarde voor z[3] = b* → **3**. Samen (nonnen): n → 5, o → 4, n → 3, n → 2,
e → 1 ⇒ n = 2, o = 4, e = 1, anders 6; stempel buiten volgorde: "in volgorde van links naar rechts". Check: V_H(x)
voor een nieuw z (4–6 letters, abcd).

**10 · BMH: springen** (is_contained_BMH, p. 64–66). Regel: i = m − 1; van rechts vergelijken; dan i += V_H(t[i])
(het teken onder de laatste positie, niet het mismatchteken). Kijk (barbara in barbados_zoekt_barbara, V_H
voorgestempeld): "i = 6: a ≠ o (1 tik). Sleutel t[6] = o: V_H(o) = 7 → i = 13" ("o staat niet in z[0..5]: volle
sprong"), t[13] = t → 7 → i = 20, t[20] = r → 1 ("de laatste r vóór het einde van z staat op 5") → i = 21: treffer
op 15 (10 tikken). Voorspel *sprong bij i = 13* → **7**. Samen (nonnen in de_non_kent_nonnen): sleutels n (2),
k (6), o (4) → treffer op 12; fout sleutel: "Horspool kijkt altijd naar t[i] onder de laatste letter, niet naar het
teken waar het misging". Voorspel *sprong bij i = 7 (k)* → **6**. Check: aantal uitlijningen van BMH op een nieuw z/t
met het spoor i(sleutel → sprong).

**11 · shift-AND: C_x** (Def. 13, p. 67–68). Kijk (ana): gaten C_a[0], C_a[2], C_n[1] → C_a = 101, C_n = 010, blanco
000. Samen (kaak): C_k = 1001, C_a = 0110. Check: C_x voor een nieuw z (4–5 letters).

**12 · shift-AND: kolom M[][j]** (Alg. 6, Fig. 23). Regel: M[][j] = shift¹(M[][j−1]) & C_{t[j]}; onderste lamp =
treffer die op j eindigt. Kijk (ana / ananas): "j = 2: hendel = shift¹(010) = 101"; "t[2] = a → C_a = 101: 101 & 101 =
M[][2] = 101. Onderste lamp aan → bel: z past op t[0..2]"; … "t[5] = s → blanco: 000". Voorspel *M[][2]* → **101**;
*shift¹(M[][2]) = shift¹(101)* → **110**. Samen (kaak / kakaak): treffer op 2; voorspel *M[][4]* → **0010**; kaart
vóór hendel: "Eerst de hendel (shift¹)". Check: M[][j] uit M[][j−1] en t[j] op een nieuw voorbeeld.

**13 · M^k** (Def. 14, p. 70–71, Oef. 60). Regel: M^l[][j] = (1,0,…,0) | shift(M^(l−1)[][j−1]) | (shift(M^l[][j−1]) &
C_{t[j]}); foutkabel = "oud ↓". Kijk (ana in abana, k = 1): stekker in oud ↓; "t[1] = b → blanco: M[][1] = 000, M¹[][1]
= 100 | 110 | 000 = 110"; "t[2] = a: M¹[][2] = 100 | shift(M[][1]) 100 | (111 & 101) 101 = 101 → bel: z past met ≤ 1
fout op t[0..2] (aba)"; j = 4: beide borden bellen (ana exact). Voorspel *M¹[][2]* → **101**. Samen (kat in kot_kat,
k = 1): bel M¹ op j = 2 (kot) en M + M¹ op j = 6. Check: M¹[][j] uit M[][j−1], M¹[][j−1] en t[j].

**14 · d[i][j] invullen** (Def. 15, Alg. 7). Kijk (kat → kast, 12 cellen): "d[1][1] = min(↖ 0 + 0, ↑ 1 + 1, ← 1 + 1) =
0 (k = k)", "d[1][2] = min(2, 3, 1) = 1 via ← (voeg a toe)" … "d(t, t′) = d[3][4] = 1". Voorspel *d[2][2]* → **0**.
Samen (roos → rots, 16 cellen): d = 1; fout: "Via ↑ krijg je 2, maar het minimum is 0 (↖ 0, ↑ 2, ← 2)". De les stopt
na het vullen (teruglopen = deel 15). Check: d[i][j] uit de drie buren in een nieuwe 3×3-tabel (getoond met ?).

**15 · Teruglopen** (Lemma 17, p. 72–76). Kijk (lessen → feesten, tabel ingevuld): ↖ n = n (+0), ↖ e = e, ↖
"vervang s door t (+1)", ↖ s = s, ↖ e = e, ↖ "vervang l door e (+1)", ← "voeg f toe (+1)" ⇒ "Reeks (stijgende
volgorde): voeg f toe op 0; vervang l op 1 door e; vervang s op 4 door t" (d = 3). Voorspel *welke bewerking is de 3e
stap ↖?* → **vervangen**. Samen (kat → kast, ingevuld): pad ↖ ← ↖ ↖ (voeg s toe). Check: d(t, t′) voor nieuwe
woorden (3–4 letters) met een kortste reeks als uitleg.

**16 · Algoritme 8** (p. 77–80). Regel: D[0][j] = 0, verder als Alg. 7; antwoord = minimum van de onderste rij; terug
tot rij 0. Kijk (z = kat, t = de_kast, rij 1 voorgevuld): rijen 2–3 ("D[2][5] = 0 via ↖ (a = a)"), "Onderste rij:
kleinste waarde = 1 in kolom 5 (ook in kolom 6, 7)", terug ↑ (verwijder t), ↖, ↖ → "pad bereikt rij 0 in kolom 3:
match t[3..4] = ka; van kat naar ka: verwijder t". Voorspel *in welke kolom staat het minimum?* → **5**. Samen (z = tak,
t = de_tas): minimum 1. Check: kleinste afstand van een nieuw z (3 letters) tot een deelwoord van t (6 letters), met de
onderste rij.

## CLI-opties (na `--`; scène `res://games/telex/scenes/console.tscn` of de titel)

- `lesson=<id> [phase=kijk|samen]` — speel die les (zonder phase: Kijk en dan Samen); daarna naar `level=` of de kaart
  (met `autoquit`: afsluiten). Id's: zie de tabel (brute, rk_hash, …, alg8).
- `reset_learning` — wis de leerpadvoortgang (alles weer "eerste keer": verplicht, niet overslaanbaar).
- `no_lessons` — geen automatische lessen vóór een level (elke `bot=…` slaat ze ook over).
- `autoplay` (Kijk speelt zelf af) · `auto_answer` (voorspel- en Check-vragen juist beantwoorden) · `lesson_demo`
  (Samen: gesimuleerde speler, eerst één foute zet per soort, dan juist) · `lesson_log` (`LESSON_STEP`, en wat de speler
  leest: `LESSON_SAY #n …` + `LESSON_STATE …` op stdout) · `lesson_shots=<map>` (screenshot bij elke coachtekst; onder xvfb
  zonder `--write-movie`, ±40× sneller) · `guide_page=<tab>:<n>` (console: gids meteen open op die pagina) ·
  `speed=<x>` · `nosave`.
- Missiekaart: `-- map check=<level>` opent meteen de Check-vragen van dat level (`check_seed=<n>` voor een vast
  voorbeeld).
- Voorbeeld opname Kijk: `xvfb-run -a -s "-screen 0 1920x1080x24" $G --path . --rendering-driver opengl3
  --write-movie <map>/f.png --fixed-fps 30 --quit-after 600 res://games/telex/scenes/console.tscn -- lesson=kmp_idee
  phase=kijk autoplay auto_answer nosave reset_learning`.
- Tests: `$G --headless --path . --script res://games/telex/tests/run_tests.gd -- t_lessons` (alle lessen headless
  uitgespeeld, voorspel- en Check-antwoorden nagerekend); muis: `tests/tx_mouse_qa.gd -- lessons=kmp_idee:samen,…`.
