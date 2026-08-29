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
  collapsed: new Set(),       // category names whose group is collapsed
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

function setSelected(p, want) {
  if (locked(p)) return;
  const base = baseSelected(p);
  state.include.delete(p.name);
  state.exclude.delete(p.name);
  if (want !== base) (want ? state.include : state.exclude).add(p.name);
}

function toggle(p) { setSelected(p, !effectiveSelected(p)); render(); }

function setGroup(category, want) {
  for (const p of state.inv.packages) {
    if (p.category === category && p.category !== 'DROP') setSelected(p, want);
  }
  render();
}

function resetDefaults() {
  state.profiles = new Set();
  state.include.clear();
  state.exclude.clear();
  state.notes = {};
  state.imported = null;
  state.selected = null;
  for (const [key, f] of Object.entries(state.inv.features)) state.features[key] = !!f.default;
  render();
}

/* ---------- derived sets ---------- */

function effectiveSet(source) {
  if (source === 'now') {
    return new Set(state.inv.packages.filter(effectiveSelected).map((p) => p.name));
  }
  const saved = snapshot();
  applyManifest(source === 'frost' ? frostDefaultManifest() : source, { silent: true });
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
  return {
    schemaVersion: SCHEMA_VERSION, inventoryVersion: state.inv.inventoryVersion,
    profiles: ['desktop'], features: feats,
    packages: { include: [], exclude: [], aur: [] }, notes: {},
  };
}

/* ---------- import / export ---------- */

function applyManifest(m, opts = {}) {
  const silent = opts.silent;
  const problems = validateManifest(m);
  if (problems.length && !silent) alert('Manifest problems:\n\n' + problems.join('\n'));
  state.profiles = new Set((m.profiles || []).filter((k) => state.inv.profiles[k]));
  const feats = {};
  for (const [k, f] of Object.entries(state.inv.features)) {
    feats[k] = (m.features && k in m.features) ? !!m.features[k] : !!f.default;
  }
  state.features = feats;
  state.include = new Set((m.packages && m.packages.include) || []);
  state.exclude = new Set((m.packages && m.packages.exclude) || []);
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
  const inc = [], exc = [], aur = [];
  for (const p of state.inv.packages) {
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
    if (p.category === 'DROP') out.push({ level: 'bad', text: `${p.name} is DROP but selected` });
    if (p.source === 'aur' && ['BOOTSTRAP', 'CORE'].includes(p.category))
      out.push({ level: 'bad', text: `${p.name}: AUR in ${p.category}` });
  }
  for (const [key, f] of Object.entries(state.inv.features)) {
    if (!state.features[key]) continue;
    const missing = (f.packages || []).filter((n) => pkgByName(n) && !sel.has(n));
    if (missing.length) out.push({ level: 'warn', text: `“${f.label}” is on but these are deselected: ${missing.join(', ')}` });
  }
  return out;
}

/* ---------- helpers ---------- */

function fmtSize(kib) {
  if (!kib) return '—';
  if (kib < 1024) return `${kib} KiB`;
  if (kib < 1024 * 1024) return `${(kib / 1024).toFixed(1)} MiB`;
  return `${(kib / 1024 / 1024).toFixed(2)} GiB`;
}

function escapeHtml(s) {
  return String(s == null ? '' : s).replace(/[&<>"]/g, (c) =>
    ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
}

function el(tag, cls, html) {
  const node = document.createElement(tag);
  if (cls) node.className = cls;
  if (html != null) node.innerHTML = html;
  return node;
}

/* ---------- controls ---------- */

function buildControls() {
  const pf = $('#profiles');
  pf.innerHTML = '';
  for (const [key, pr] of Object.entries(state.inv.profiles)) {
    const card = el('button', 'profile');
    card.type = 'button';
    card.dataset.key = key;
    card.innerHTML =
      `<span class="dot"></span><span><span class="p-name">${escapeHtml(pr.label)}</span>` +
      `<span class="p-desc">${escapeHtml(pr.description)}</span></span>`;
    card.addEventListener('click', () => {
      if (state.profiles.has(key)) {
        state.profiles.delete(key);
      } else {
        state.profiles.add(key);
        (pr.features || []).forEach((f) => { if (f in state.features) state.features[f] = true; });
      }
      render();
    });
    pf.appendChild(card);
  }

  const ff = $('#features');
  ff.innerHTML = '';
  for (const [key, f] of Object.entries(state.inv.features)) {
    const row = el('label', 'switch');
    row.dataset.key = key;
    row.innerHTML =
      `<input type="checkbox"><span class="track"></span>` +
      `<span class="s-text"><span class="s-name">${escapeHtml(f.label)}</span>` +
      `<span class="s-desc">${escapeHtml(f.description)}</span></span>`;
    row.querySelector('input').addEventListener('change', (e) => {
      state.features[key] = e.target.checked;
      render();
    });
    ff.appendChild(row);
  }

  const cat = $('#f-category');
  for (const c of state.inv.categories) cat.add(new Option(c, c));
  const hw = new Set();
  state.inv.packages.forEach((p) => (p.hardware || []).forEach((h) => hw.add(h)));
  [...hw].sort().forEach((h) => $('#f-hardware').add(new Option(h, h)));

  $('#search').addEventListener('input', (e) => { state.filters.search = e.target.value.toLowerCase().trim(); renderGroups(); });
  $('#search').addEventListener('keydown', (e) => { if (e.key === 'Escape') { e.target.value = ''; state.filters.search = ''; renderGroups(); } });
  for (const [id, key] of [['#f-source', 'source'], ['#f-category', 'category'], ['#f-hardware', 'hardware'], ['#f-state', 'state']]) {
    $(id).addEventListener('change', (e) => { state.filters[key] = e.target.value; renderGroups(); });
  }
  $('#clear-filters').addEventListener('click', () => {
    state.filters = { search: '', source: '', category: '', hardware: '', state: '' };
    $('#search').value = '';
    for (const id of ['#f-source', '#f-category', '#f-hardware', '#f-state']) $(id).value = '';
    renderGroups();
  });
}

function syncControls() {
  document.querySelectorAll('#profiles .profile').forEach((c) => {
    c.setAttribute('aria-pressed', String(state.profiles.has(c.dataset.key)));
  });
  document.querySelectorAll('#features .switch').forEach((r) => {
    r.querySelector('input').checked = !!state.features[r.dataset.key];
  });
}

/* ---------- filtering ---------- */

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
    const hay = [p.name, p.reason, p.category, (p.tags || []).join(' '), (p.hardware || []).join(' '), p.feature || '']
      .join(' ').toLowerCase();
    if (!hay.includes(f.search)) return false;
  }
  return true;
}

/* ---------- render ---------- */

function render() {
  syncControls();
  renderGroups();
  renderSummary();
  renderWarnings();
  renderDetail();
}

function renderGroups() {
  const host = $('#groups');
  host.innerHTML = '';
  const order = state.inv.categories;
  const shown = state.inv.packages.filter(matchesFilter)
    .sort((a, b) => order.indexOf(a.category) - order.indexOf(b.category) || a.name.localeCompare(b.name));

  if (!shown.length) {
    host.appendChild(el('p', 'empty', 'Nothing matches the filter.'));
    return;
  }

  const byCat = new Map();
  for (const p of shown) {
    if (!byCat.has(p.category)) byCat.set(p.category, []);
    byCat.get(p.category).push(p);
  }

  for (const cat of order) {
    const list = byCat.get(cat);
    if (!list) continue;
    const inCat = state.inv.packages.filter((x) => x.category === cat);
    const selCount = inCat.filter(effectiveSelected).length;
    const size = inCat.filter(effectiveSelected).reduce((s, x) => s + (x.sizeKib || 0), 0);
    const pct = inCat.length ? Math.round((selCount / inCat.length) * 100) : 0;

    const group = el('details', 'group');
    group.open = !state.collapsed.has(cat);
    group.addEventListener('toggle', () => {
      if (group.open) state.collapsed.delete(cat); else state.collapsed.add(cat);
    });

    const summary = el('summary');
    summary.innerHTML =
      `<span class="g-name">${cat}</span>` +
      `<span class="g-meta">${selCount}/${inCat.length} · ${fmtSize(size)}</span>` +
      `<span class="g-actions"></span>`;
    if (cat !== 'DROP') {
      const all = el('button', null, 'all'); all.type = 'button';
      const none = el('button', null, 'none'); none.type = 'button';
      all.addEventListener('click', (e) => { e.preventDefault(); setGroup(cat, true); });
      none.addEventListener('click', (e) => { e.preventDefault(); setGroup(cat, false); });
      summary.querySelector('.g-actions').append(all, none);
    }
    group.appendChild(summary);
    group.appendChild(el('div', 'g-bar', `<span style="width:${pct}%"></span>`));

    const rows = el('div', 'rows');
    for (const p of list) rows.appendChild(row(p));
    group.appendChild(rows);
    host.appendChild(group);
  }
}

function row(p) {
  const r = el('div', `row cat-${p.category}`);
  if (effectiveSelected(p)) r.classList.add('is-selected');
  if (locked(p)) r.classList.add('is-locked');

  const box = el('input');
  box.type = 'checkbox';
  box.checked = effectiveSelected(p);
  box.disabled = locked(p);
  box.title = locked(p) ? 'required — locked' : 'toggle selection';
  box.addEventListener('change', () => toggle(p));

  const main = el('div', 'r-main');
  const nameBtn = el('button', 'r-name');
  nameBtn.type = 'button';
  nameBtn.textContent = p.name;
  nameBtn.addEventListener('click', () => { state.selected = p.name; renderDetail(); });
  const badges =
    `<span class="badge src-${p.source}">${p.source}</span>` +
    (p.feature ? `<span class="badge">${escapeHtml(p.feature)}</span>` : '') +
    (overridden(p) ? `<span class="badge dot-changed">changed</span>` : '') +
    (locked(p) ? `<span class="badge">locked</span>` : '');
  const line1 = el('div');
  line1.appendChild(nameBtn);
  line1.insertAdjacentHTML('beforeend', badges);
  main.appendChild(line1);
  main.appendChild(el('div', 'r-reason', escapeHtml(p.reason)));

  const side = el('div', 'r-side', `${p.default}<br>${fmtSize(p.sizeKib)}`);

  r.append(box, main, side);
  return r;
}

function renderSummary() {
  const sel = state.inv.packages.filter(effectiveSelected);
  const size = sel.reduce((s, p) => s + (p.sizeKib || 0), 0);
  const by = { arch: 0, frost: 0, aur: 0 };
  sel.forEach((p) => by[p.source]++);
  const total = sel.length || 1;
  const exp = buildExport();

  const now = effectiveSet('now');
  const frost = effectiveSet('frost');
  const imported = state.imported ? effectiveSet(state.imported) : null;
  const plus = [...now].filter((n) => !frost.has(n)).length;
  const minus = [...frost].filter((n) => !now.has(n)).length;
  const impDelta = imported
    ? [...now].filter((n) => !imported.has(n)).length + [...imported].filter((n) => !now.has(n)).length
    : null;

  $('#summary').innerHTML = `
    <div class="s-top">
      <span class="s-count">${sel.length}</span>
      <span class="s-of">of ${state.inv.packages.length} packages</span>
      <span class="s-size">${fmtSize(size)}</span>
    </div>
    <div class="s-split">
      <i class="a" style="width:${(by.arch / total) * 100}%"></i>
      <i class="f" style="width:${(by.frost / total) * 100}%"></i>
      <i class="u" style="width:${(by.aur / total) * 100}%"></i>
    </div>
    <div class="s-legend">
      <span><b>${by.arch}</b> arch</span><span><b>${by.frost}</b> frost</span><span><b>${by.aur}</b> aur</span>
    </div>
    <dl class="s-rows">
      <dt>include[]</dt><dd>${exp.packages.include.length}</dd>
      <dt>exclude[]</dt><dd>${exp.packages.exclude.length}</dd>
      <dt>aur[]</dt><dd>${exp.packages.aur.length}</dd>
      <dt>notes</dt><dd>${Object.keys(exp.notes).length}</dd>
    </dl>
    <div class="compare">
      <div class="c-grid">
        <div><div class="c-num">${now.size}</div><div class="c-lab">Now</div></div>
        <div><div class="c-num">${frost.size}</div><div class="c-lab">Frost default</div>
             <div class="c-delta">+${plus} / −${minus}</div></div>
        <div><div class="c-num">${imported ? imported.size : '—'}</div><div class="c-lab">Imported</div>
             <div class="c-delta">${impDelta == null ? '' : (impDelta === 0 ? 'match' : impDelta + ' diff')}</div></div>
      </div>
    </div>`;
}

function renderWarnings() {
  const ul = $('#warnings');
  const ws = warnings();
  if (!ws.length) { ul.innerHTML = '<li class="empty">None</li>'; return; }
  ul.innerHTML = '';
  for (const w of ws) {
    const li = el('li', w.level === 'bad' ? 'w-bad' : 'w-warn');
    li.append(document.createTextNode(w.text));
    ul.appendChild(li);
  }
}

function renderDetail() {
  const host = $('#detail-card');
  const p = state.selected && pkgByName(state.selected);
  if (!p) {
    host.innerHTML = '<h2>Details</h2><p class="empty">Click a package name to inspect its dependencies, consumers and to leave a note.</p>';
    return;
  }
  const consumers = state.inv.packages.filter((x) => (x.dependsOn || []).includes(p.name)).map((x) => x.name);
  const inFeatures = Object.entries(state.inv.features)
    .filter(([, f]) => (f.packages || []).includes(p.name)).map(([k]) => k);
  const chips = (arr) => arr.length
    ? `<span class="chips">${arr.map((x) => `<span class="chip">${escapeHtml(x)}</span>`).join('')}</span>`
    : '<span class="empty">none</span>';

  host.innerHTML = `
    <h2>Details</h2>
    <div class="detail-badges">
      <span class="badge src-${p.source}">${p.source}</span>
      <span class="badge">${p.category}</span>
      <span class="badge">${p.default}${locked(p) ? ' · locked' : ''}</span>
      <span class="badge ${effectiveSelected(p) ? 'dot-changed' : ''}">${effectiveSelected(p) ? 'selected' : 'not selected'}</span>
    </div>
    <p style="font-family:var(--mono);font-weight:600;margin-bottom:8px">${escapeHtml(p.name)}</p>
    <dl class="kv">
      <dt>reason</dt><dd>${escapeHtml(p.reason)}</dd>
      <dt>size</dt><dd>${fmtSize(p.sizeKib)}</dd>
      ${p.feature ? `<dt>feature</dt><dd>${escapeHtml(p.feature)}</dd>` : ''}
      ${p.hardware ? `<dt>hardware</dt><dd>${chips(p.hardware)}</dd>` : ''}
      ${p.pkgbase ? `<dt>pkgbase</dt><dd>${escapeHtml(p.pkgbase)}</dd>` : ''}
      ${p.recipeUrl ? `<dt>recipe</dt><dd style="word-break:break-all">${escapeHtml(p.recipeUrl)}</dd>` : ''}
      <dt>depends on</dt><dd>${chips(p.dependsOn || [])}</dd>
      <dt>consumers</dt><dd>${chips(consumers)}</dd>
      <dt>in features</dt><dd>${chips(inFeatures)}</dd>
      <dt>conflicts</dt><dd>${chips(p.conflictsWith || [])}</dd>
    </dl>
    <div class="detail-note">
      <h2>Note</h2>
      <textarea id="note" placeholder="why this decision — saved into the manifest">${escapeHtml(state.notes[p.name] || '')}</textarea>
    </div>`;
  $('#note').addEventListener('input', (e) => { state.notes[p.name] = e.target.value; });
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
