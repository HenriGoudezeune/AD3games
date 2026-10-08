// Genereert tests/fixtures/js_reference.json uit de JS-referentie (ad3-quest, getest tegen de notas).
// Draaien: node tests/gen_js_fixture.js   (vanuit de projectmap)
// Per geval: starttoestand + sleutels -> per sleutel de stappen van insert() en de eindtoestand (layout).
const path = require('path');
const fs = require('fs');
globalThis.AD3 = { level(x) { globalThis.LEVEL = x; } };
require(path.resolve(__dirname, '../../ad3-quest/levels/2-1-1-extendible-hashing.js'));
const L = globalThis.LEVEL.logic;

const fb = s => parseInt(s, 2);
// starttoestand uit layout-spec [{label, hvs}] (zelfde formaat als ExtHashModel.load_layout)
function fromLayout(n, g, a, spec) {
  if (!spec.length) return L.create(n, g, a);
  const B = [], dir = new Array(2 ** a).fill(-1);
  spec.forEach((e, bi) => {
    const ab = e.label.length, span = 2 ** (a - ab), start = (e.label ? fb(e.label) : 0) * span;
    B.push({ ab, keys: e.hvs.map(fb) });
    for (let i = start; i < start + span; i++) dir[i] = bi;
  });
  return { n, g, a, B, dir };
}
function runCase(name, n, g, a, spec, keys) {
  let s = fromLayout(n, g, a, spec);
  const start = { a, layout: spec };
  const perKey = [];
  for (const k of keys) {
    const r = L.insert(s, k);
    perKey.push(r.steps.map(st => ({
      act: st.act, idx: st.idx, a: st.a, ab: st.ab,
      // st.split.stay/move zijn aliassen van de emmer-arrays (latere plaatsingen muteren ze) -> herbereken uit st.before
      stay: st.split ? st.before.filter(k => !(L.pre(k, s.n, st.ab + 1) & 1)) : [],
      move: st.split ? st.before.filter(k => (L.pre(k, s.n, st.ab + 1) & 1)) : [],
      changed: st.split ? st.split.changed.slice() : [],
    })));
    s = r.s;
    if (!r.ok) break;
  }
  const end = L.layout(s).map(x => ({ label: x.label, ab: x.ab, keys: x.keys.slice() }));
  return { name, n, g, start, keys, steps: perKey, end_a: s.a, end };
}
const b = s => s.split(' ').map(fb);
const cases = [];
cases.push(runCase('notas_fig2_5', 5, 2, 1, [], b('00100 01111 10010 11100 11111 11110')));
cases.push(runCase('dag1', 5, 3, 1, [], b('00110 10101 01011 11000 00011 10010')));
cases.push(runCase('dag2', 5, 2, 1, [], b('00100 01111 10010 11100 11111 10111')));
cases.push(runCase('dag3', 5, 2, 3, [{ label: '0', hvs: ['00100', '01111'] }, { label: '10', hvs: ['10010'] }, { label: '110', hvs: ['11000'] }, { label: '111', hvs: ['11100'] }],
  b('00110 10111 10000 01001 00010 11001 01110 11111')));
cases.push(runCase('dag4', 5, 2, 2, [{ label: '0', hvs: ['00011'] }, { label: '10', hvs: ['10100'] }, { label: '11', hvs: ['11010'] }],
  b('01101 10001 00110 11100 10110 01000 00000 11111 10011 01011 00101 11000')));
cases.push(runCase('dag5', 5, 2, 2, [{ label: '0', hvs: ['00100', '01111'] }, { label: '10', hvs: ['10010'] }, { label: '11', hvs: ['11100', '11111'] }],
  b('11110 00110 10011 01010 11010 10100 00001 01100 10111 11001')));
cases.push(runCase('oef5', 5, 2, 1, [], L.OEF5.map(x => x.h)));
cases.push(runCase('dag7_ochtend', 5, 2, 1, [], b('01001 10110 10110 10110')));
cases.push(runCase('dag7_middag_zonder_klonen', 5, 2, 1, [], b('11001 00111 11001 01100 10010 00111 11010 00000 01110')));
// willekeurige gevallen (deterministische LCG)
let seed = 12345;
const rnd = () => (seed = (seed * 1103515245 + 12345) % 2147483648) / 2147483648;
for (let c = 0; c < 40; c++) {
  const n = 4 + Math.floor(rnd() * 4), g = 1 + Math.floor(rnd() * 3), a = 1 + Math.floor(rnd() * 2);
  const keys = [];
  const m = 5 + Math.floor(rnd() * 25);
  for (let i = 0; i < m; i++) keys.push(Math.floor(rnd() * 2 ** n));
  cases.push(runCase('random_' + c, n, g, a, [], keys));
}
fs.mkdirSync(path.resolve(__dirname, 'fixtures'), { recursive: true });
fs.writeFileSync(path.resolve(__dirname, 'fixtures/js_reference.json'), JSON.stringify(cases, null, 0));
console.log('geschreven: ' + cases.length + ' gevallen');
