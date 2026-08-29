'use strict';
/* Frost package selector. Offline, no network, no telemetry. Its only effects
 * are importing and exporting JSON. It never runs pacman or a PKGBUILD. */

const SCHEMA_VERSION = 1;
const $ = (sel) => document.querySelector(sel);

const state = {
  inv: null,
  profiles: new Set(),        // active profile keys
  features: {},               // feature key -> bool
  include: new Set(),         // explicit adds beyond the base
  exclude: new Set(),         // explicit removes from the base
  notes: {},                  // package -> text
  imported: null,             // last imported manifest (raw)
  selected: null,             // package name shown in the detail pane
  filters: { search: '', source: '', category: '', hardware: '', state: '' },
};

/* ---------- loading ---------- */

function boot(inv) {
  state.inv = inv;
  for (const [key, f] of Object.entries(inv.features)) state.features[key] = !!f.default;
  $('#version').textContent =
    `inventory ${inv.inventoryVersion} · ${inv.packages.length} packages`;
  $('#needs-inventory').classList.add('hidden');
  $('#app').classList.remove('hidden');
  buildControls();
  render();
}

async function loadInventory() {
  if (window.FROST_INVENTORY) { boot(window.FROST_INVENTORY); return; }
  try {
    const res = await fetch('./inventory.json');
    if (!res.ok) throw new Error(String(res.status));
    boot(await res.json());
  } catch (_) {
    $('#needs-inventory').classList.remove('hidden');
  }
}

function readFile(input, onJson) {
  const file = input.files && input.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = () => {
    try { onJson(JSON.parse(reader.result)); }
    catch (e) { alert('Not valid JSON: ' + e.message); }
  };
  reader.readAsText(file);
  input.value = '';
}

/* ---------- selection model ---------- */

const pkgByName = (name) => state.inv.packages.find((p) => p.name === name);

function activeProfileObjs() {
  return [...state.profiles].map((k) => state.inv.profiles[k]).filter(Boolean);
}

// The default ("base") membership before the user's explicit overrides.
function baseSelected(p) {
  if (p.category === 'DROP') return false;
  const profs = activeProfileObjs();
  for (const pr of profs) {
    if ((pr.excludePackages || []).includes(p.name)) return false;
  }
  if (p.feature && state.features[p.feature]) {
    const list = state.inv.features[p.feature].packages || [];
    if (list.includes(p.name)) return true;
  }
  for (const pr of profs) {
    if ((pr.includePackages || []).includes(p.name)) return true;
    if ((pr.includeCategories || []).includes(p.category) && p.default !== 'optional') {
      // a feature-gated package only rides its profile category when the feature is on
      if (!p.feature || state.features[p.feature]) return true;
    }
  }
  return false;
}

function locked(p) {
  return p.default === 'required' && baseSelected(p);
}

function effectiveSelected(p) {
  if (locked(p)) return true;
  if (state.exclude.has(p.name)) return false;
  if (state.include.has(p.name)) return true;
  return baseSelected(p);
}

function overridden(p) {
  return !locked(p) && (state.include.has(p.name) || state.exclude.has(p.name));
}

function toggle(p) {
  if (locked(p)) return;
  const base = baseSelected(p);
  const eff = effectiveSelected(p);
  state.include.delete(p.name);
  state.exclude.delete(p.name);
  const want = !eff;
  if (want !== base) (want ? state.include : state.exclude).add(p.name);
  render();
}

function resetDefaults() {
  state.profiles = new Set();
  state.include.clear();
  state.exclude.clear();
  state.notes = {};
  state.imported = null;
  for (const [key, f] of Object.entries(state.inv.features)) state.features[key] = !!f.default;
  render();
}

/* ---------- derived sets ---------- */

function effectiveSet(source) {
  // source: 'now' | 'frost' | manifestObject
  if (source === 'now') {
    return new Set(state.inv.packages.filter(effectiveSelected).map((p) => p.name));
  }
  if (source === 'frost') {
    const saved = snapshot();
    applyManifest(frostDefaultManifest(), { silent: true });
    const set = new Set(state.inv.packages.filter(effectiveSelected).map((p) => p.name));
    restore(saved);
    return set;
  }
  // a manifest object
  const saved = snapshot();
  applyManifest(source, { silent: true });
  const set = new Set(state.inv.packages.filter(effectiveSelected).map((p) => p.name));
  restore(saved);
  return set;
}

function snapshot() {
  return {
    profiles: new Set(state.profiles),
    features: { ...state.features },
    include: new Set(state.include),
    exclude: new Set(state.exclude),
  };
}
function restore(s) {
  state.profiles = s.profiles; state.features = s.features;
  state.include = s.include; state.exclude = s.exclude;
}

function frostDefaultManifest() {
  const feats = {};
  for (const [k, f] of Object.entries(state.inv.features)) feats[k] = !!f.default;
  return { schemaVersion: SCHEMA_VERSION, inventoryVersion: state.inv.inventoryVersion,
           profiles: ['desktop'], features: feats, packages: { include: [], exclude: [], aur: [] }, notes: {} };
}

/* ---------- import / export ---------- */

function applyManifest(m, opts = {}) {
  const silent = opts.silent;
  const problems = validateManifest(m);
  if (problems.length && !silent) {
    alert('Manifest problems:\n\n' + problems.join('\n'));
  }
  state.profiles = new Set((m.profiles || []).filter((k) => state.inv.profiles[k]));
  const feats = {};
  for (const [k, f] of Object.entries(state.inv.features)) {
    feats[k] = (m.features && k in m.features) ? !!m.features[k] : !!f.default;
  }
  state.features = feats;
  state.include = new Set((m.packages && m.packages.include) || []);
  state.exclude = new Set((m.packages && m.packages.exclude) || []);
  // aur[] is advisory: it must already be reachable through include/feature.
  state.notes = { ...(m.notes || {}) };
  if (!silent) {
    state.imported = m;
    render();
  }
}

function validateManifest(m) {
  const out = [];
  const namePat = /^[a-z0-9][a-z0-9@._+-]*$/;
  if (!m || typeof m !== 'object') return ['not an object'];
  if (m.schemaVersion !== SCHEMA_VERSION) out.push(`schemaVersion must be ${SCHEMA_VERSION}`);
  if (typeof m.inventoryVersion !== 'string') out.push('inventoryVersion missing');
  else if (m.inventoryVersion !== state.inv.inventoryVersion)
    out.push(`inventoryVersion ${m.inventoryVersion} != loaded ${state.inv.inventoryVersion}`);
  for (const key of ['include', 'exclude', 'aur']) {
    const list = m.packages && m.packages[key];
    if (!Array.isArray(list)) { out.push(`packages.${key} must be an array`); continue; }
    for (const n of list) {
      if (typeof n !== 'string' || !namePat.test(n)) out.push(`packages.${key}: bad name ${JSON.stringify(n)}`);
      else if (!pkgByName(n)) out.push(`packages.${key}: ${n} is not in the inventory`);
    }
  }
  if (m.features && typeof m.features === 'object') {
    for (const [k, v] of Object.entries(m.features)) {
      if (typeof v !== 'boolean') out.push(`features.${k} must be boolean`);
      if (!state.inv.features[k]) out.push(`features.${k} is not a known feature`);
    }
  }
  return out;
}

function buildExport() {
  const packages = state.inv.packages;
  const inc = [], exc = [], aur = [];
  for (const p of packages) {
    const eff = effectiveSelected(p);
    const base = baseSelected(p);
    if (eff && !base && p.category !== 'DROP') inc.push(p.name);
    if (!eff && base) exc.push(p.name);
    if (eff && p.source === 'aur') aur.push(p.name);
  }
  const sortU = (a) => [...new Set(a)].sort();
  const features = {};
  for (const k of Object.keys(state.inv.features).sort()) features[k] = !!state.features[k];
  const notes = {};
  for (const k of Object.keys(state.notes).sort()) {
    const t = (state.notes[k] || '').trim();
    if (t) notes[k] = t;
  }
  return {
    schemaVersion: SCHEMA_VERSION,
    inventoryVersion: state.inv.inventoryVersion,
    profiles: [...state.profiles].sort(),
    features,
    packages: { include: sortU(inc), exclude: sortU(exc), aur: sortU(aur) },
    notes,
  };
}

function download(name, text) {
  const blob = new Blob([text], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url; a.download = name;
  document.body.appendChild(a); a.click(); a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

/* ---------- warnings ---------- */

function warnings() {
  const out = [];
  const sel = effectiveSet('now');
  for (const p of state.inv.packages) {
    if (!sel.has(p.name)) continue;
    for (const c of p.conflictsWith || []) {
      if (sel.has(c) && p.name < c) out.push({ level: 'bad', text: `${p.name} conflicts with ${c}` });
    }
  }
  for (const [key, f] of Object.entries(state.inv.features)) {
    if (!state.features[key]) continue;
    const missing = (f.packages || []).filter((n) => pkgByName(n) && !sel.has(n));
    if (missing.length) out.push({ level: 'warn', text: `feature "${f.label}" is on but excludes: ${missing.join(', ')}` });
  }
  for (const p of state.inv.packages) {
    if (sel.has(p.name) && p.category === 'DROP')
      out.push({ level: 'bad', text: `${p.name} is DROP but selected` });
    if (sel.has(p.name) && p.source === 'aur' && ['BOOTSTRAP', 'CORE'].includes(p.category))
      out.push({ level: 'bad', text: `${p.name}: AUR in ${p.category}` });
  }
  return out;
}

/* ---------- rendering ---------- */

function buildControls() {
  const pf = $('#profiles');
  pf.innerHTML = '';
  for (const [key, pr] of Object.entries(state.inv.profiles)) {
    pf.appendChild(toggleRow('profile', key, pr.label, pr.description, () => state.profiles.has(key), () => {
      state.profiles.has(key) ? state.profiles.delete(key) : state.profiles.add(key);
    }));
  }
  const ff = $('#features');
  ff.innerHTML = '';
  for (const [key, f] of Object.entries(state.inv.features)) {
    ff.appendChild(toggleRow('feature', key, f.label, f.description, () => state.features[key], () => {
      state.features[key] = !state.features[key];
    }));
  }
  const cat = $('#f-category');
  for (const c of state.inv.categories) cat.add(new Option(c, c));
  const hw = new Set();
  state.inv.packages.forEach((p) => (p.hardware || []).forEach((h) => hw.add(h)));
  const hwSel = $('#f-hardware');
  [...hw].sort().forEach((h) => hwSel.add(new Option(h, h)));

  $('#search').addEventListener('input', (e) => { state.filters.search = e.target.value.toLowerCase(); render(); });
  for (const [id, key] of [['#f-source', 'source'], ['#f-category', 'category'], ['#f-hardware', 'hardware'], ['#f-state', 'state']]) {
    $(id).addEventListener('change', (e) => { state.filters[key] = e.target.value; render(); });
  }
}

function toggleRow(kind, key, label, sub, get, flip) {
  const wrap = document.createElement('label');
  wrap.className = 'toggle';
  const box = document.createElement('input');
  box.type = 'checkbox';
  box.checked = get();
  box.addEventListener('change', () => { flip(); render(); });
  const span = document.createElement('span');
  span.innerHTML = `${label}<span class="sub">${sub}</span>`;
  wrap.append(box, span);
  wrap.dataset.kind = kind; wrap.dataset.key = key;
  return wrap;
}

function matchesFilter(p) {
  const f = state.filters;
  if (f.source && p.source !== f.source) return false;
  if (f.category && p.category !== f.category) return false;
  if (f.hardware && !(p.hardware || []).includes(f.hardware)) return false;
  if (f.state) {
    const eff = effectiveSelected(p);
    if (f.state === 'selected' && !eff) return false;
    if (f.state === 'deselected' && eff) return false;
    if (f.state === 'overridden' && !overridden(p)) return false;
    if (f.state === 'locked' && !locked(p)) return false;
  }
  if (f.search) {
    const hay = [p.name, p.reason, p.description, p.category, (p.tags || []).join(' '), p.feature || '']
      .join(' ').toLowerCase();
    if (!hay.includes(f.search)) return false;
  }
  return true;
}

function fmtSize(kib) {
  if (!kib) return '';
  if (kib < 1024) return `${kib} KiB`;
  if (kib < 1024 * 1024) return `${(kib / 1024).toFixed(1)} MiB`;
  return `${(kib / 1024 / 1024).toFixed(2)} GiB`;
}

function render() {
  syncControlBoxes();
  renderGroups();
  renderTotals();
  renderWarnings();
  renderCompare();
  renderDetail();
}

function syncControlBoxes() {
  document.querySelectorAll('#profiles .toggle').forEach((row) => {
    row.querySelector('input').checked = state.profiles.has(row.dataset.key);
  });
  document.querySelectorAll('#features .toggle').forEach((row) => {
    row.querySelector('input').checked = !!state.features[row.dataset.key];
  });
}

function renderGroups() {
  const host = $('#groups');
  host.innerHTML = '';
  const order = state.inv.categories;
  const shown = state.inv.packages.filter(matchesFilter)
    .sort((a, b) => order.indexOf(a.category) - order.indexOf(b.category) || a.name.localeCompare(b.name));
  let currentCat = null, groupEl = null, body = null;
  for (const p of shown) {
    if (p.category !== currentCat) {
      currentCat = p.category;
      groupEl = document.createElement('div');
      groupEl.className = 'group';
      const inCat = state.inv.packages.filter((x) => x.category === currentCat);
      const selCount = inCat.filter(effectiveSelected).length;
      const size = inCat.filter(effectiveSelected).reduce((s, x) => s + (x.sizeKib || 0), 0);
      const h = document.createElement('h3');
      h.innerHTML = `${currentCat}<span class="count">${selCount}/${inCat.length} selected · ${fmtSize(size)}</span>`;
      groupEl.appendChild(h);
      body = document.createElement('div');
      groupEl.appendChild(body);
      host.appendChild(groupEl);
    }
    body.appendChild(pkgRow(p));
  }
  if (!shown.length) host.innerHTML = '<p class="muted">Nothing matches the filter.</p>';
}

function pkgRow(p) {
  const row = document.createElement('div');
  row.className = `pkg cat-${p.category} src-wrap`;
  if (locked(p)) row.classList.add('locked');
  if (overridden(p)) row.classList.add('overridden');

  const box = document.createElement('input');
  box.type = 'checkbox';
  box.checked = effectiveSelected(p);
  box.disabled = locked(p);
  box.title = locked(p) ? 'required — locked' : 'toggle';
  box.addEventListener('change', () => toggle(p));

  const mid = document.createElement('div');
  const variant = p.variantOf ? ` <span class="tag">${p.variantOf}</span>` : '';
  const feat = p.feature ? ` <span class="tag">${p.feature}</span>` : '';
  mid.innerHTML =
    `<div class="name src-${p.source}">${p.name}<span class="tag">${p.source}</span>${feat}${variant}</div>` +
    `<div class="reason">${escapeHtml(p.reason)}</div>`;
  mid.querySelector('.name').addEventListener('click', () => { state.selected = p.name; renderDetail(); });

  const meta = document.createElement('div');
  meta.className = 'meta';
  meta.innerHTML = `${p.default}<br>${fmtSize(p.sizeKib)}`;

  row.append(box, mid, meta);
  return row;
}

function renderTotals() {
  const sel = state.inv.packages.filter(effectiveSelected);
  const size = sel.reduce((s, p) => s + (p.sizeKib || 0), 0);
  const bySource = { arch: 0, frost: 0, aur: 0 };
  sel.forEach((p) => bySource[p.source]++);
  const exp = buildExport();
  const dl = $('#totals');
  dl.innerHTML = `
    <dt>selected</dt><dd>${sel.length}</dd>
    <dt>arch / frost / aur</dt><dd>${bySource.arch} / ${bySource.frost} / ${bySource.aur}</dd>
    <dt>est. size</dt><dd>${fmtSize(size)}</dd>
    <dt>include[]</dt><dd>${exp.packages.include.length}</dd>
    <dt>exclude[]</dt><dd>${exp.packages.exclude.length}</dd>
    <dt>aur[]</dt><dd>${exp.packages.aur.length}</dd>`;
}

function renderWarnings() {
  const ul = $('#warnings');
  const ws = warnings();
  if (!ws.length) { ul.innerHTML = '<li class="muted">none</li>'; return; }
  ul.innerHTML = '';
  for (const w of ws) {
    const li = document.createElement('li');
    li.className = w.level === 'bad' ? 'w-bad' : 'w-warn';
    li.textContent = w.text;
    ul.appendChild(li);
  }
}

function renderCompare() {
  const now = effectiveSet('now');
  const frost = effectiveSet('frost');
  const imported = state.imported ? effectiveSet(state.imported) : null;
  const rows = [
    ['total', now.size, frost.size, imported ? imported.size : '—'],
    ['+ vs Frost default', [...now].filter((n) => !frost.has(n)).length, '—', imported ? [...imported].filter((n) => !frost.has(n)).length : '—'],
    ['− vs Frost default', [...frost].filter((n) => !now.has(n)).length, '—', imported ? [...frost].filter((n) => !imported.has(n)).length : '—'],
  ];
  if (imported) {
    rows.push(['changed vs imported',
      [...now].filter((n) => !imported.has(n)).length + [...imported].filter((n) => !now.has(n)).length, '—', 0]);
  }
  $('#compare-body').innerHTML = rows.map((r) =>
    `<tr><td>${r[0]}</td><td>${r[1]}</td><td>${r[2]}</td><td>${r[3]}</td></tr>`).join('');
}

function renderDetail() {
  const host = $('#package-detail');
  const p = state.selected && pkgByName(state.selected);
  if (!p) { host.innerHTML = '<h2>Details</h2><p class="muted">Select a package.</p>'; return; }
  const consumers = state.inv.packages.filter((x) => (x.dependsOn || []).includes(p.name)).map((x) => x.name);
  const featConsumers = Object.entries(state.inv.features)
    .filter(([, f]) => (f.packages || []).includes(p.name)).map(([k]) => k);
  const chips = (arr) => arr.length ? arr.map((x) => `<span class="chip">${x}</span>`).join('') : '<span class="muted">none</span>';
  host.innerHTML = `
    <h2>${p.name}</h2>
    <dl class="kv">
      <dt>source</dt><dd class="src-${p.source}">${p.source}${p.pkgbase ? ` (pkgbase ${p.pkgbase})` : ''}</dd>
      <dt>category</dt><dd>${p.category}</dd>
      <dt>default</dt><dd>${p.default}${locked(p) ? ' · locked' : ''}</dd>
      <dt>state</dt><dd>${effectiveSelected(p) ? 'selected' : 'not selected'}${overridden(p) ? ' · changed from default' : ''}</dd>
      <dt>size</dt><dd>${fmtSize(p.sizeKib) || 'unknown'}</dd>
      <dt>reason</dt><dd>${escapeHtml(p.reason)}</dd>
      ${p.feature ? `<dt>feature</dt><dd>${p.feature}</dd>` : ''}
      ${p.hardware ? `<dt>hardware</dt><dd>${chips(p.hardware)}</dd>` : ''}
      ${p.recipeUrl ? `<dt>recipe</dt><dd>${p.recipeUrl}</dd>` : ''}
      <dt>depends on</dt><dd>${chips(p.dependsOn || [])}</dd>
      <dt>consumers</dt><dd>${chips(consumers)}</dd>
      <dt>in features</dt><dd>${chips(featConsumers)}</dd>
      <dt>conflicts</dt><dd>${chips(p.conflictsWith || [])}</dd>
    </dl>
    <h2>Note</h2>
    <textarea id="note" placeholder="why this decision">${escapeHtml(state.notes[p.name] || '')}</textarea>`;
  $('#note').addEventListener('input', (e) => { state.notes[p.name] = e.target.value; });
}

function escapeHtml(s) {
  return String(s == null ? '' : s).replace(/[&<>"]/g, (c) =>
    ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
}

/* ---------- wiring ---------- */

$('#export').addEventListener('click', () => {
  download('frost-packages.json', JSON.stringify(buildExport(), null, 2) + '\n');
});
$('#import').addEventListener('click', () => $('#file-manifest').click());
$('#file-manifest').addEventListener('change', (e) => readFile(e.target, applyManifest));
$('#reset').addEventListener('click', resetDefaults);
$('#pick-inventory').addEventListener('click', () => $('#file-inventory').click());
$('#file-inventory').addEventListener('change', (e) => readFile(e.target, boot));

loadInventory();
