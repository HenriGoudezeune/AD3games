# TELEX — QA-rapport (playtest v1)

Eigenaar: QA-playtester. Lezers: lead, core, front-end, designer. Status: **v1 af** (15/10).
Gecontroleerd op branch `claude/vibrant-turing-mfec2j` vanaf commit `d5e65d6`; alle fixes hieronder zijn gecommit
(`telex QA: …`). Screenshots: `design/screens/qa_*.png`.

**Commando's** (vanuit de projectmap, `G=/opt/godot/Godot_v4.7.2-stable_linux.x86_64`):
- core-tests: `$G --headless --path . --script res://games/telex/tests/run_tests.gd` → **956 asserts groen** (na alle fixes)
- headless sweep per level: `$G --headless --path . --fixed-fps 30 --quit-after 30000 res://games/telex/scenes/console.tscn -- level=X bot=perfect|first|every|keys speed=8 print_report autoquit nosave skip_brief`
- **muis-QA (nieuw, in de repo):** `tests/tx_mouse_qa.gd` speelt levels enkel met echte `InputEventMouseButton/Motion`
  (`Viewport.push_input`): klikt waar de spookhand (`panel.hint`) wijst, sleept het sjabloon voor verschuivingen en
  sprongen, klikt contextknoppen op hun echte plek en controleert na elke klik dat de director de verwachte zet kreeg.
  `$G --headless --path . --fixed-fps 30 --script res://games/telex/tests/tx_mouse_qa.gd -- levels=3-1,4-1,5-1,7-1 nosave unlock`
  `… -- tour tourlevel=3-1 nosave unlock` = schermroute hub → TELEX → titel → kaart → level → debrief → notas → kaart → titel → hub.
  Met `shots=<map> every=N` (onder `xvfb-run`) bewaart het een screenshot per N zetten + briefing/debrief/notas.

---

## 1. Samenvatting

| | |
|---|---|
| Tests | 956 asserts groen (≈ 25 s), ook na alle QA-fixes |
| Crashes / SCRIPT ERROR | **geen** in alle runs (19 P0-levels × perfect/first/every/keys, muis-QA, tour, opnames). Enkel de bekende `resources still in use at exit` |
| Vastlopers | geen in de campagne. Nachtdienst: zie P1-4 (niets doen levert punten op) |
| Leerstof | alle tabellen/sporen nagerekend met een eigen Python-referentie (letterlijk de pseudocode van de notas): V[] (barbados, ananas, volvoert, tata, kokos), V_H (barbara, ananas, salsa), alle hashwaarden 2-1/2-2/2-3, C_x en kolommen 5-1/5-2/6-1, d[][] 7-1/7-2, D[][] 8-1/8-2/8-3 en de lijnen van p. 76 en p. 79 → **alles klopt**. **Fouten zaten in paginanummers en coachzinnen** (P0-1 … P0-4, gefixt) |
| Muis | 19/19 P0-levels + 2-2, 7-2, 8-2 volledig met de muis uitspeelbaar (3 ★). Twee spookhand-bugs op het schakelbord gevonden en gefixt (P1-1, P1-2) |
| Opslag | `user://telex_save.json`: beste sterren/punten blijven bewaard (3-1: eerst ★★★, daarna ★ → blijft ★★★) |
| Bugs | **P0: 4 (alle gefixt) · P1: 6 (4 gefixt, 2 open) · P2: 10 (7 gefixt, 3 open)** |

Headless sweep (19 P0-levels, `speed=8`), samengevat:

| bot | resultaat |
|---|---|
| `perfect` | alle 19 levels ★★★, tellers = optimum uit GDD §5 (1-1: 27 tikken/spoelmeter 4; 2-1: 30 slagen/5 tikken; 2-2: 31/10; 2-3: 41/6; 3-1: 34; 3-2: 23; 3-3: 7+29; 4-1: 10; 4-2: 9; 4-3: 22; 5-1: 6 lampslagen; 5-2: 17; 6-1: 13; 7-1: 42 relais; 7-2: 49; 8-1: 45; 8-2: 84; 8-3: 44) |
| `keys` (echte toetsen) | alle 19 ★★★ |
| `first` / `every` | elke fout heeft een gevolg en een coachzin + notasverwijzing (zie §4). 1-1 en 1-2 hebben geen foutmodus (brute kracht heeft geen keuzes, tegenzet meet enkel) |
| muis (`tx_mouse_qa.gd`) | alle geteste levels ★★★ na de fixes P1-1/P1-2 |

---

## 2. Buglijst

### P0 — fout tegen de leerstof (allemaal gefixt)

**P0-1 · Oefening 71 staat op p. 80, niet p. 79** — *gefixt*
`TxLevels` 8-3 `notes_ref` zei "Oefening 71 · notas p. 79". In de notas eindigt p. 79 met de eerste regel van Oef. 70;
Oef. 71 staat bovenaan p. 80. → "notas p. 80".

**P0-2 · Oefening 50 staat enkel op p. 66** — *gefixt*
4-4 verwees naar "p. 66–67"; Oef. 50 staat volledig op p. 66 (p. 67 is shift-AND). → "notas p. 66".

**P0-3 · "Meld meteen" bij een hashbotsing legde niet uit dat Algoritme 3 eerst `strings_gelijk()` oproept** — *gefixt*
Lead-beslissing 5 eist dat de terugblik dat expliciet zegt. De coachzin van `FALSE_ALARM` (Rabin-Karp) was
"`0100` ≡ 4 (mod 7), maar `0100` ≠ z: een hashbotsing." met verwijzing "Opmerking 10 · p. 54" (die gaat over het
slechtste geval, niet over valse treffers). Nu: "… ≠ z: hashbotsing. Algoritme 3 controleert eerst met
strings_gelijk()." · "Algoritme 3, valse treffers · notas p. 52–54". `SKIPPED_CHECK`: "Algoritme 3 · p. 54" →
"p. 53–54" (Algoritme 3 begint op p. 53).

**P0-4 · Notasverwijzing in de verkeerde context** — *gefixt*
- 3-2 ponst volgens **Definitie 11**, maar "Klaar" met lege vakjes (`PUNCH_SHORT`) verwees naar "Algoritme 5 · p. 61".
  Nu: Def. 11 · p. 56 (Algoritme 5 blijft bij het bereik-ponsen van 3-3/3-4).
- In 8-1/8-2/8-3 (**Algoritme 8**) verwees een foute relaiswaarde (`WRONG_MIN`) naar "Algoritme 7 · p. 75". Nu
  "Algoritme 8 · notas p. 78–79" (de editeercel krijgt een `approx`-vlag in de logdata).

### P1 — speelbaarheid / onbegrijpelijk

**P1-1 · Schakelbord: spookhand bij "Klaar" wijst naar "Nog een reeks"** — *gefixt*
`TxBoardPanel.hint({"act":"finish"})` gaf `button_pos(0)`; in TRACE_DONE is knop 0 "Nog een reeks" en knop 1
"Klaar". Wie de spookhand volgde, kwam in een lus van teruglopen (muis-QA 7-1: 489 stappen, nooit klaar). Nu knop 1.

**P1-2 · Schakelbord: de spookhand wees precies op de celhoek** — *gefixt*
De hint voor ↖/↑/← lag op de rand/hoek van de cel (offset −0,5 cel). Daar besliste afronding welke cel je raakte: in
8-1 gaf een klik op de spookhand 7× `WRONG_MIN` en 3× een klem. Nu −0,33 cel: binnen de klikzone én op het getekende
draadstompje.

**P1-3 · Esc in de briefing startte de dienst** — *gefixt*
`TxBriefing.key` behandelde Esc als Enter; er was geen weg terug naar de kaart. Nu: Esc en een knop "← Missiekaart"
gaan terug (Nachtdienst vanuit de titel → titel).

**P1-4 · Nachtdienst: niets doen levert 1828 punten en 21 codewoorden op** — *open (core/designer)*
Repro: `level=N bot=idle seed=3 print_report autoquit nosave skip_brief` → `TXREPORT N stars=1 points=1828 found=21
missed=3` (pas na 3 gemiste woorden game over). Oorzaak: na een scheur zet `TxMachine.force_to` de Springer op de
scheur en `TxBmh._force` laat de naald meteen weer lopen (`_run()`). Omdat de scheur teken per teken opschuift, werkt
een stilzittende speler als brute kracht en vindt hij bijna alles, met +100 per woord. Highscore is zo te "farmen".
Voorstel: een treffer na een gedwongen uitlijning geeft geen punten (of: na een scheur wacht de naald op de speler),
en/of elke scheur kost combo + een vertrouwenslampje in de Nachtdienst.

**P1-5 · Tegenzet 1-2 begint één tegel van het antwoord** — *open (designer)*
Beginstand z = `aaaa`, t = a¹² (stage B: `aaaaaaaa`, a¹⁶). Eén klik op de laatste letter van z (→ `aaab`) geeft het
optimum 36. Oef. 32 vraagt *waarom* a…ab/a…a het slechtste geval is; zo vindt een speler het door toeval. Voorstel:
begin met een neutrale of willekeurige stand (bv. z = `abab`, t = `abba…`) en laat de debrief de familie tonen (doet
hij al).

**P1-6 · Dossierkaart: tekst buiten de kaart / lege kaart** — *gefixt*: de notasverwijzing liep buiten de dossierkaart
("Definitie 11, Algoritme 4 · notas p. 56–5", 3-1); tegenzetten hadden een lege kaart (nu m, n, alfabet).

### P2 — afwerking

| # | wat | status |
|---|---|---|
| P2-1 | Debrief toonde interne stekkernamen ("foutkabel: [new_shift] (juist: old_shift = oud ↓)"); nu "foutkabel jij: nieuw ↓ · juist: oud ↓ = shift(M⁰[][j−1])", amber bij fout | gefixt |
| P2-2 | Sterrenvoorwaarden liepen onder de stempel "MISSIE GESLAAGD" (1-2: "Tegenzet 1 optimaal of Tegenzet 2 optimaal") | gefixt (lettergrootte past zich aan) |
| P2-3 | Springer-uitleg "vul_VH: klik de sjabloonletters 0..m−2 (van links naar rechts)." liep in de kaartenbak | gefixt (2 regels) |
| P2-4 | HUD toonde "z = lessen" bij Algoritme 7; de notas kennen daar geen z maar t en t′ | gefixt ("t =") |
| P2-5 | Coachzin "Er bleven vakjes leeg: [2, 3, 4, 5]." (GDScript-array) | gefixt ("2, 3, 4, 5. Elk vakje j krijgt V[j].") |
| P2-6 | Godot-waarschuwing "Nodes with non-equal opposite anchors…" bij elke titel-/kaartstart (`size =` na `PRESET_FULL_RECT`) | gefixt |
| P2-7 | Punten kunnen negatief worden (5-1 met `bot=every`: −146; gemist = −100). Klopt met GDD §6.3, maar "PUNTEN −146" leest raar | open (designer) |
| P2-8 | De debrief-extra van 3-1 is vaste tekst ("Jouw sprongen 3, 2, 3, 1 …"), ook als je andere sprongen maakte | gefixt ("De juiste sprongen …") |
| P2-9 | Chef-ballon van de intro blijft hangen in een volgende stage (3-2 stage B toont nog "Pons de strook…") | open |
| P2-10 | `bot=keys` in de Nachtdienst: één keer `KEYBOT-STUCK N {jump s=9}` (timing in LIVE, de zet kwam daarna wel door) | open (QA-tool, geen spelbug) |

---

## 3. Leerstof-controle (tegen `lesnotas` r. 2628–4185)

Paginagrenzen bepaald uit de voetregels van de tekstextractie (p. 50 = r. ≤ 2649, p. 51 = r. 2650–2701, …,
p. 80 = r. 4147–4178). Gecontroleerd: alle `notes_ref` in `TxLevels`, alle verwijzingen in `TxEventLog.notes_ref`,
het spiekbriefje (`tx_cheat_sheet.gd`), de koppen van de notas-weergave (`tx_notes_view.gd`), titelkaarten en
debrief-extra's.

| onderwerp | notas | game | |
|---|---|---|---|
| Algoritme 2, Opm. 9, Oef. 32/33 | p. 50–51 | p. 50–51 / 51 | ✓ |
| hashing, h(s), rollende update | p. 52–53 | p. 52 / 53 | ✓ |
| Algoritme 3, Opm. 10, Oef. 34 | p. 53–54 | p. 52–54 / 54 (+ fix P0-3) | ✓ |
| Def. 11 + tabel barbados 1 1 2 3 3 3 6 7 | p. 56 | p. 56 | ✓ |
| Algoritme 4 + spoor barbados (5, 2, 0…, 4, 1, …, 8) | p. 57–59 | p. 58–59; game-spoor = notas | ✓ |
| Stelling 12, streams | p. 59, p. 50 | idem | ✓ |
| Algoritme 5 + opbouw barbados | p. 61–62 | p. 61, 61–62 | ✓ |
| Oef. 39/40/41 | p. 62 | p. 62 | ✓ |
| BMH, voorbeeld barbara, V_H, vul_VH, is_contained_BMH | p. 63–66 | p. 63–65 | ✓ |
| Oef. 48 / Oef. 50 | p. 66 / p. 66 | 66 / ~~66–67~~ → 66 | gefixt |
| Def. 13, C_x, Algoritme 6, Figuur 23, Oef. 54 | p. 67, 67, 68, 69, 69 | 67–69, 67, 68, 69 | ✓ |
| Def. 14, recursie M^l, Oef. 60 | p. 70–71 | 70, 71 | ✓ |
| Def. 15 + lessen→feesten | p. 72 | p. 72 (volgorde notas in debrief 7-1) | ✓ |
| Algoritme 7 / tabel + lijn / Oef. 62 | p. 75 / 76 / 76 | 75 / 76 / 76; pad notas-weergave = lijn p. 76 | ✓ |
| Algoritme 8 / tabel examen + lijn / Oef. 70 / Oef. 71 | p. 78–79 / 79 / 79 / **80** | 77–79 / 79 / 79 / ~~79~~ → 80 | gefixt |

Getoonde getallen (eigen Python-referentie ↔ game ↔ notas): V(ananas) = 1 1 2 2 2 2; V(volvoert) = 1 1 2 3 3 3 6 7
(+V[8] = 8); V(tata) = 1 1 2 2 | 2; V(kokos)[5] = 5; V_H barbara a2 b3 r1/7, ananas a1 n2/6, salsa a3 l2 s1/5;
hashreeks 2-2 = 3,4,2,2,5,4,6,6,4,6,6,3,4 en 2-3 = 1,10,1,2,12,5,4,8,4,2,5; kolommen 5-1/5-2/6-1 bit voor bit;
d/D-tabellen 7-1, 7-2, 8-1, 8-2, 8-3 cel voor cel — **geen afwijking**. De coachzinnen van alle foutmodi (§4) zijn
inhoudelijk juist (bv. "V_H[`s`] = 1: de laatste `s` vóór positie 4 staat op 3", "min(0+1, 1+1, 1+1) = 1, niet 2").

---

## 4. Foutmodi: gevolg in de wereld + debrief

| level | fout (bot) | gevolg in de wereld | debrief (coachzin · verwijzing) |
|---|---|---|---|
| 2-1/2-3 | verkeerd gewicht w | wiel blijft verkeerd rollen; 2-3: `00101` @10 glipt erdoor (koerier op de kaart) | "Gewicht: zet het wiel op 1 en verdubbel 5 keer: w = 6." · rollende hash p. 53; MISSED wijst naar "het ijken" |
| 2-2 | foute Horner-stap | beide `1011` gemist, ★ 0 | "Bit 1: ×2, +1 geeft 1 (mod 7)." · h(s) p. 52 |
| 3-1 | te grote sprong | ★★ weg; spoor in de notas-weergave | "Na een mismatch op 5 past al 3 plaatsen: V[5] = 3, niet 5." · Def. 11 p. 56 |
| 3-2/3-3 | strook te vroeg klaar / te kort geponst | Doorloper moet met de hand verder | "Er bleven vakjes leeg: 2, 3, 4, 5. …" · Def. 11 p. 56 (gefixt) / "Pons tot en met de mismatch…" · Alg. 5 p. 61 |
| 4-x | stempel vergeten | kaarten leeg (= overige m); herbeleving toont "jouw kaarten a=5 l=5 s=5 / volgens vul_VH a=3 l=2 s=1" | "V_H[`s`] = 1: de laatste `s` vóór positie 4 staat op 3." · vul_VH p. 65 |
| 5-1/5-2 | gat verkeerd geponst | lampen doven, `ana`/`zoeken` gemist, koerier | "Kaart `a`: gaten waar z[i] = `a`, dus op rij 0, 2." · C_x p. 67 |
| 6-1 | foutkabel verkeerd | `dank` gemist | "Een fout op j bouwt verder op M^0 van kolom j−1, geschoven." · Def. 14 p. 71 |
| 7-x/8-x | verkeerde ingang | relais warm, ★★ weg | "min(0+1, 1+1, 1+1) = 1, niet 2." · Alg. 7 p. 75 / Alg. 8 p. 78–79 (gefixt) |

Herbeleving (`debrief=auto`, opname 4-3 `bot=first`): de tijdlijn toont de amber stip, "JOUW ZET" en daarna
"JUISTE ZET" met de kaartenbak naast vul_VH en de coachzin + verwijzing. Duidelijk.

---

## 5. Schermroute, opslag en muis

- `tx_mouse_qa.gd -- tour`: hub → klik TELEX-kaart → titel → klik "Diensten" → kaart → klik kaartje 3-1 → briefing
  → klik "Start dienst" → level met de muis → debrief → "Notas-weergave" → "Sluiten" → "Missiekaart" → Esc → titel →
  "← Alle games" → hub: **12/12 controles OK**.
- Opslag: na 3-1 ★★★ (156 p.) en daarna 3-1 ★ (136 p.) blijft `{"stars": {"3-1": 3}, "best": {"3-1": 156}}`.
- Muis per machine (enkel muis, 3 ★): Sjabloon 1-1, tegenzet 1-2, wiel 2-1/2-2 (hendels, wielklik, alarmknoppen),
  ponsbank 3-2 (kopie slepen + vakje klikken) en 3-3 (vakje + Waarde ± + Pons), Doorloper 3-1/3-2/3-3 (sjabloon slepen),
  Springer 4-1/4-2/4-3 (stempelen op het sjabloon, sleutelteken op het lint), lampenbord 5-1/5-2 (gaten, hendel,
  kaarten), ruisbord 6-1 (stekker), schakelbord 7-1/7-2 en zoeklicht 8-1/8-2/8-3 (ingangen, zoeklicht, teruglopen,
  Klaar).
