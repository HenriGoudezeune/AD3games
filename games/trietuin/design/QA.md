# Trietuin — QA-rapport (playtest v1)

Eigenaar: QA-playtester (en fixer). Lezers: lead, front-end, core. Status: **in uitvoering**.

**Commando's** (vanuit de repo-root, `G=/opt/godot/Godot_v4.7.2-stable_linux.x86_64`):
- core-tests: `$G --headless --path . --script res://games/trietuin/tests/run_tests.gd`
- **headless level-run** (nieuw, `tests/qa_run.gd`): speelt één level in de echte tuin-scène met de front-end-bot en
  drukt `QA_RESULT` (sterren, honing, misstappen, Bloei) + elke coachzin/notasverwijzing + elke mislukte Bloei-bij af:
  `$G --headless --path . --audio-driver Dummy --script res://games/trietuin/tests/qa_run.gd -- level=2-2 bot=errors speed=8`
  (± 5 s per level). Met `shot=<pad.png>` (+ xvfb/opengl3) maakt hij een schermafdruk van het rapport; `qa_replay=1`
  opent eerst de eerste misstap.
- frames: `xvfb-run -a -s "-screen 0 1920x1080x24" $G --path . --rendering-driver opengl3 --audio-driver Dummy
  --resolution 1920x1080 res://games/trietuin/scenes/garden.tscn -- level=X bot=perfect shots=<map> shot_every=4 quit_at=60`

---

## 1. Samenvatting

| | |
|---|---|
| Core-tests | 1229 asserts groen (ook na de fixes hieronder) |
| Headless sweep | 21 levels (20 + vrije tuin) × `perfect`/`errors`/`random`: **geen SCRIPT ERROR / ERROR**, geen vastloper. Perfect = ★★★ en Bloei 100 % op elk level |
| Leerstof | figuren 13–19, Algoritme 1, ternary-volgorde, (b,e)-labels, Ukkonen-eindbomen en paginaverwijzingen nagekeken tegen de notas |

## 2. Bevindingen

### P0 — fout tegen de leerstof

**P0-1 · Coachzin "Na `t` volgt `niets`" terwijl er wél takken vertrekken** — *gefixt*
- *Repro:* `qa_run -- level=4-4 bot=errors`: vraag "Komt `ttt` voor?" → loep op de wortel/`t` → coachzin
  "Na `t` volgt `niets`, niet `t`". Ook Ukkonen (`5-2`/`5-3 bot=random`): "Na `∅` komt in de boom `niets`, niet `g`",
  terwijl de wortel takken `a`, `c` heeft.
- *Fout:* in een top volgt niet "niets": er vertrekken takken, alleen geen met dat teken (notas p. 38 geval (ii): "er
  is geen tak die met s_{i+1} begint").
- *Fix:* core geeft bij een top `at_node` + de beginletters van de takken mee (`tt_suffix_tree._do_locate`,
  `tt_ukkonen._do_rule`); coachzinnen: "Na `t` beginnen de takken met `c/g`, geen met `t`." en
  "Na `b`: takken `a/b`, geen `c`. Uitbreiden (ii)." / "Na `∅` vertrekt nog geen tak: uitbreiden (ii)."

### P1 — storend, verwarrend of ontbrekend

**P1-1 · Levelweetjes (bindende lead-beslissingen 1, 3, 10, 13) verschenen nergens** — *gefixt*
- `spec.extra` (`did_you_know` 4-2/5-3, `oef28a` 4-4, `link_order` 5-1, `rule` 3-1, `report` 1-1/1-3/2-3/3-4) werd door
  geen enkele front-end-code gelezen. De terugblik toont nu rechtsonder een papieren kader "Wist je dat? / Ontdekking /
  Volgorde / Afspraak / Uil" (`tt_report._draw_weetje`).
- Teksten gecorrigeerd: 1-1 beweerde vast "Jouw boom: 4 toppen" (fout bij elke andere boom) → nu "Figuur 13 (6
  toppen) … de figuur hangt `TA_` en `TGCGAAA_` een top dieper dan nodig"; 1-3 idem ("In deze boom vertakken 8 van de
  13 toppen niet"); 4-4 sprak van "fase/extensie" (Gusfield) → notas-termen "iteratie i, suffix j".

**P1-2 · Mislukte Bloei-bij in de suffixboom zonder oorzaak (`cause_seq=-1`)** — *gefixt*
- *Repro:* `4-1 bot=errors` (verkeerd afwijkpunt) en `4-2 bot=errors` (verkeerde b): de bij van het getroffen suffix
  faalt, maar de terugblik linkt ze aan geen misstap. Fout aanhechtpunt zette geen `affects`; een fout label van
  suffix j laat ook suffix j' falen.
- *Fix:* `ATTACH` met WRONG_POINT zet `affects`; `TtBloom` valt voor suffixbomen terug op de laatste
  boomveranderende misstap (ATTACH/LABEL).

### P2 — kleinigheden

- **P2-1** Sterlabel "level uitgespeeld, Bloei ≥ 70 %" brak af als "… ≥" / "70 %" of liet "%" alleen staan → vaste
  spaties. *gefixt*
- **P2-2** Coachzin "sla 1 letters over" → "1 letter". *gefixt*
- **P2-3** Notasverwijzing bij "vrucht bereikt ≠ gevonden" in een gewone trie verwees naar "Algoritme 1, p. 29"
  (Patricia) → "p. 27 · in het blad de hele string vergelijken (ook Alg. 1, p. 29)". *gefixt*
- **P2-4** Coachzin bij een fout afwijkpunt aan de wortel: "volgt de boom tot `∅` en wijkt daar pas af" →
  "wijkt al bij de wortel af: daar komt een nieuwe tak". *gefixt*
- **P2-5** 4-5: afsluitteken in coachzinnen als ruwe `3` i.p.v. `_₃`. *gefixt* (display_word)
- **P2-6** Notas-weergave suffixboom: (b,e)-labels van de vlakke wortelbogen (`6,8 7,8 8,8`) liepen in elkaar → labels
  dichter bij het kind. *gefixt*
- **P2-7** QA-bot `errors` maakte in 4-1 en 3-4 geen enkele fout (eerste aanhechten is de wortel = juist; bedkeuze
  had geen foutvariant) → bot markeert een zettype pas als "gezien" na een echte fout; foute bedkeuze toegevoegd. *gefixt*
