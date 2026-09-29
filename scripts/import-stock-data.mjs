// One-shot import of the FY24-25 physical stock CSV into cloud Supabase.
// Usage: node scripts/import-stock-data.mjs "<path-to-csv>"
// Reads keys from ../../config.local.js (gitignored).
// Rerunnable: deletes prior rows where source='CSV-FY24-25' before inserting.
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const CONFIG = path.join(ROOT, 'config.local.js');
const SOURCE = 'CSV-FY24-25';

if (!fs.existsSync(CONFIG)) { console.error('Missing config.local.js'); process.exit(1); }
const cfgSrc = fs.readFileSync(CONFIG, 'utf8');
const KEY = (cfgSrc.match(/secretKey:\s*'([^']+)'/) || [])[1];
const ANON = (cfgSrc.match(/anonKey:\s*'([^']+)'/) || [])[1];
if (!KEY) { console.error('secretKey not found'); process.exit(1); }
const HOST = 'rfvevmckrjvcvlldtlaq.supabase.co';

const csvPath = process.argv[2];
if (!csvPath || !fs.existsSync(csvPath)) { console.error('usage: import-stock-data.mjs <csv>'); process.exit(1); }

/* ---------------- tiny REST helper (service_role) ---------------- */
let seq = 0;
async function pg(method, pathname, body) {
  seq++;
  const opts = {
    host: HOST,
    path: pathname,
    method,
    headers: { apikey: KEY, Authorization: 'Bearer ' + KEY, 'Content-Type': 'application/json' }
  };
  if (body !== undefined) opts.headers.Prefer = 'return=representation';
  return new Promise((res, rej) => {
    const r = httpsReq(opts, res, rej);
    if (body !== undefined) r.write(JSON.stringify(body));
    r.end();
  });
}
import https from 'https';
function httpsReq(opts, ok, fail) {
  const req = https.request(opts, (x) => {
    let d = '';
    x.on('data', (c) => d += c);
    x.on('end', () => {
      let json = null;
      try { json = JSON.parse(d); } catch (e) {}
      ok({ status: x.statusCode, body: json, raw: d });
    });
  });
  req.on('error', fail);
  return req;
}

/* ---------------- CSV parse ----------------
   Robust for hand-edited files: a `"` only opens/quotes when it is the FIRST character
   of a field, and only closes when it is the LAST character (followed by , \r \n or EOF).
   Stray quotes inside a field (e.g. item names with inch marks like 10"X18") are literal.
*/
function parseCsv(text) {
  const rows = [];
  let cur = [], f = '', inQ = false, qstart = false;
  const pushField = () => { cur.push(f); f = ''; qstart = false; inQ = false; };
  const pushRow = () => { cur.push(f); f = ''; qstart = false; inQ = false; rows.push(cur); cur = []; };
  for (let i = 0; i <= text.length; i++) {
    const ch = i === text.length ? '\n' : text[i];
    const nx = i + 1 < text.length ? text[i + 1] : '\n';
    if (inQ) {
      if (ch === '"') {
        if (nx === '"') { f += '"'; i++; }            // escaped ""
        else if (nx === ',' || nx === '\r' || nx === '\n') { inQ = false; qstart = false; } // closing quote; separator pushes field
        else f += ch;                                  // stray quote inside quoted field
      } else f += ch;
      continue;
    }
    if (ch === '"' && f === '') { inQ = true; qstart = true; continue; }
    if (ch === ',' ) { pushField(); continue; }
    if (ch === '\r') continue;
    if (ch === '\n') { pushRow(); continue; }
    f += ch;
  }
  return rows;
}

/* ---------------- centre mapping ---------------- */
// file name -> { name: existing DB name OR newName, create: bool, parent: parent DB name or newName }
const CENTRE_MAP = {
  'ABHEYPUR': { name: 'ABHEYPUR' },
  'ANKHEER': { name: 'ANKHEER' },
  'BADHA SIKANDERPUR': { name: 'BADHA SIKENDERPUR' },
  'BAHIN': { name: 'BAHIN' },
  'BAROLI': { name: 'BAROLI' },
  'BILASPUR': { name: 'BILASPUR' },
  'BILASPUR (Loan)': { create: true, name: 'BILASPUR (Loan)', parent: 'BILASPUR' },
  'BUDHERA': { name: 'BUDHERA' },
  'DHATIR': { name: 'DHATIR' },
  'DLF CITY': { name: 'DLF CITY GURGAON' },
  'DUNDAHERA': { name: 'DUNDAHERA' },
  'DUNDAHERA (BS)': { create: true, name: 'DUNDAHERA (BS)', parent: 'DUNDAHERA' },
  'DUNDAHERA (Loan)': { create: true, name: 'DUNDAHERA (Loan)', parent: 'DUNDAHERA' },
  'FARUKHNAGAR': { name: 'FARUKH NAGAR' },
  'FARUKHNAGAR (BS)': { create: true, name: 'FARUKHNAGAR (BS)', parent: 'FARUKH NAGAR' },
  'FARUKHNAGAR (Loan)': { create: true, name: 'FARUKHNAGAR (Loan)', parent: 'FARUKH NAGAR' },
  'GURGAON': { name: 'GURGAON' },
  'GURGAON (BS)': { create: true, name: 'GURGAON (BS)', parent: 'GURGAON' },
  'GURGAON (ES)': { create: true, name: 'GURGAON (ES)', parent: 'GURGAON' },
  'GURGAON (Loan)': { create: true, name: 'GURGAON (Loan)', parent: 'GURGAON' },
  'HASANPUR': { name: 'HASANPUR' },
  'HATHIN': { name: 'HATHIN' },
  'JATAULA': { name: 'JATAULA' },
  'KASAN': { name: 'KASAN' },
  'MANDKOLA': { name: 'MANDKOLA' },
  'NACHULI': { name: 'NACHAULI' },
  'NANGLA GUJRAN': { name: 'NANGLA GUJRAN' },
  'NAYAGAON': { name: 'NAYAGAON' },
  'NIT-2': { name: 'NIT - 2' },
  'NUH': { name: 'NUH' },
  'PALWAL': { name: 'PALWAL' },
  'PALWAL BAAL SATSANG': { create: true, name: 'PALWAL BAAL SATSANG', parent: 'PALWAL' },
  'PATAUDI': { name: 'PATAUDI' },
  'PATAUDI (BS)': { create: true, name: 'PATAUDI (BS)', parent: 'PATAUDI' },
  'PATAUDI (Loan)': { create: true, name: 'PATAUDI (Loan)', parent: 'PATAUDI' },
  'PRITHLA': { name: 'PRITHLA' },
  'RAJENDRA PARK': { name: 'RAJENDRA PARK' },
  'SECTOR 15A': { name: 'SECTOR-15-A' },
  'SECTOR 81': { create: true, name: 'SECTOR 81', parent: 'GURGAON' },
  'SIHA': { name: 'SIHA' },
  'SOHNA': { name: 'SOHNA' },
  'Surajkund': { name: 'SURAJ KUND' },
  'TAORU': { name: 'TAORU' },
  'TIGAON': { name: 'TIGAON' }
};

/* ---------------- quantity parsing ---------------- */
const UNIT_ALIAS = {
  'mtr': 'mtr', 'mtrs': 'mtr', 'metre': 'mtr', 'metres': 'mtr', 'meter': 'mtr', 'meters': 'mtr',
  'nos': 'nos', 'no': 'nos', 'pcs': 'nos', 'pc': 'nos', 'qty': 'nos',
  'set': 'SET', 'sets': 'SET',
  'roll': 'Roll', 'rolls': 'Roll',
  'kg': 'KG', 'kgs': 'KG', 'kgm': 'KG',
  'sqm': 'SQM', 'sq.m': 'SQM', 'sqmtr': 'SQM', 'sqmtrs': 'SQM',
  'sq.ft': 'SQF', 'sqft': 'SQF', 'ft': 'ft', 'feet': 'ft', 'foot': 'ft',
  'inch': 'inch', 'inches': 'inch',
  'tl': 'TL', 'thali': 'TL', 'ton': 'ton', 'tonne': 'ton'
};

// Returns { num: number|null, unit: string, raw: string }
function parseQty(raw) {
  const orig = String(raw || '').replace(/\s+/g, ' ').trim();
  if (!orig) return { num: null, unit: '', raw: orig };

  // 1) pure numeric
  if (/^[+-]?(\d+(\.\d+)?)$/.test(orig)) return { num: Number(orig), unit: '', raw: orig };

  // 2) "N + M + ..." with optional trailing unit word
  const plusMatch = orig.match(/^([0-9.\s+]+)\s*([a-zA-Z.\/\(\)\s]*)$/);
  if (plusMatch && plusMatch[1] && /\+/.test(plusMatch[1])) {
    const terms = plusMatch[1].split('+').map((s) => Number(s.trim()));
    if (terms.every((t) => !isNaN(t))) {
      const num = terms.reduce((a, b) => a + b, 0);
      return { num, unit: extractUnit(plusMatch[2]), raw: orig };
    }
  }

  // 3) "14 10 6 20 10 15 15" (space-separated numbers -> sum)
  const spaceMatch = orig.match(/^([0-9.\s]+)\s*([a-zA-Z.\/\(\)\s]*)$/);
  if (spaceMatch && /\s/.test(spaceMatch[1])) {
    const terms = spaceMatch[1].trim().split(/\s+/).map((s) => Number(s));
    if (terms.length > 1 && terms.every((t) => !isNaN(t))) {
      const num = terms.reduce((a, b) => a + b, 0);
      return { num, unit: extractUnit(spaceMatch[2]), raw: orig };
    }
  }

  // 4) "18 (54 KG)" or "2 ( 40 mtrs)" or "3 (12ft)" -> outer number, unit from parens
  const paren = orig.match(/^([0-9.\s+]+)\s*\(([^)]*)\)\s*$/);
  if (paren) {
    const lead = paren[1].replace(/\+/g, '').trim();
    if (lead && !isNaN(Number(lead))) {
      const num = lead.split(/\s+/).reduce((a, s) => a + (Number(s) || 0), 0);
      return { num, unit: extractUnit(paren[2]), raw: orig };
    }
  }

  // 5) "N mtr" / "1 nos" / "100 SQM" style
  const numUnit = orig.match(/^([0-9]+(?:\.[0-9]+)?)\s*(.+)$/);
  if (numUnit) {
    const n = Number(numUnit[1]);
    if (!isNaN(n)) return { num: n, unit: extractUnit(numUnit[2]), raw: orig };
  }

  return { num: null, unit: extractUnit(orig), raw: orig };
}

function extractUnit(s) {
  const clean = String(s || '').replace(/[()]/g, ' ').trim().toLowerCase();
  if (!clean) return '';
  const known = Object.keys(UNIT_ALIAS).sort((a, b) => b.length - a.length).find((k) => new RegExp('(^|\\s)' + k.replace(/\./g, '\\.') + '(\\s|$)').test(clean) || clean === k);
  if (known) return UNIT_ALIAS[known];
  const letters = clean.replace(/[^a-zA-Z.]/g, '').trim();
  return letters ? letters : '';
}

/* ---------------- date parsing ---------------- */
function parseDate(s) {
  const v = String(s || '').trim();
  if (!v) return null;
  const ddmmrrrr = v.match(/^(\d{1,2})[.\-\/](\d{1,2})[.\-\/](\d{4})$/);
  if (ddmmrrrr) {
    const [_, d, m, y] = ddmmrrrr;
    const dt = new Date(Date.UTC(Number(y), Number(m) - 1, Number(d)));
    return isNaN(dt) ? null : dt.toISOString().slice(0, 10);
  }
  const named = v.match(/^(\d{1,2})\s+(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{4})$/i);
  if (named) {
    const months = ['january', 'february', 'march', 'april', 'may', 'june', 'july', 'august', 'september', 'october', 'november', 'december'];
    const dt = new Date(Date.UTC(Number(named[3]), months.indexOf(named[2].toLowerCase()), Number(named[1])));
    return isNaN(dt) ? null : dt.toISOString().slice(0, 10);
  }
  return null;
}

/* ---------------- main ---------------- */
(async () => {
  const text = fs.readFileSync(csvPath, 'utf8');
  const rows = parseCsv(text);
  const data = rows.filter((r) => /^\s*\d+\s*$/.test((r[0] || '').trim()) || /^#NAME/.test((r[0] || '').trim()));
  console.log('parsed rows:', rows.length, '| data rows:', data.length);

  // normalize records
  const records = [];
  const skipped = [];
  const noUnit = [];
  const warnings = [];
  data.forEach((r, i) => {
    const centreFile = (r[1] || '').trim();
    let item = (r[2] || '').trim().replace(/\s+/g, ' ');
    const pageNo = (r[3] || '').trim();
    const approvalNo = (r[4] || '').replace(/[\r\n]+/g, '; ').replace(/\s{2,}/g, ' ').trim();
    const approvalDate = (r[5] || '').replace(/[\r\n]+/g, '; ').trim();
    const qtyAraw = (r[6] || '').trim();
    const qtyBraw = (r[7] || '').trim();
    const reason = (r[9] || '').trim();
    const remarks = (r[10] || '').trim();

    const qA = parseQty(qtyAraw);
    const qB = parseQty(qtyBraw);

    if (!centreFile) { skipped.push(`row#${i + 2} empty centre`); return; }
    if (!CENTRE_MAP[centreFile]) { skipped.push(`row#${i + 2} unknown centre "${centreFile}"`); return; }
    if (!item) { item = '(no item name)'; }

    const unit = qB.unit || qA.unit;
    const numA = qA.num;
    const numB = qB.num;

    const dateISO = parseDate(approvalDate);
    let extraRemark = '';
    if (approvalDate && !dateISO) extraRemark = 'Approval date text: ' + approvalDate;
    if (qA.num === null) noUnit.push(`row#${i + 2} ${centreFile} / ${item} qtyA="${qtyAraw}" (parse failed)`);
    if (qB.num === null) noUnit.push(`row#${i + 2} ${centreFile} / ${item} qtyB="${qtyBraw}" (parse failed)`);
    if (numA !== null && numB !== null && numA !== numB) warnings.push(`${centreFile} / ${item}: A=${qtyAraw} B=${qtyBraw}`);

    records.push({
      centreFile,
      item,
      pageNo: pageNo || '',
      approvalNo,
      approvalDate: dateISO,
      qtyA: numA === null ? 0 : Math.round(numA),
      qtyB: numB === null ? 0 : Math.round(numB),
      qtyRaw: [qtyAraw, qtyBraw].filter(Boolean).join(' | '),
      unit,
      reason,
      remarks: [remarks, extraRemark, (numA !== null && numA % 1 !== 0) || (numB !== null && numB % 1 !== 0) ? 'Decimal quantity rounded' : ''].filter(Boolean).join(' ').trim(),
      verifiedBy: 'CSV IMPORT'
    });
  });
  console.log('records kept:', records.length, '| skipped:', skipped.length, '| A!=B rows:', warnings.length);

  if (skipped.length) {
    console.log('\n--- skipped ---');
    skipped.slice(0, 30).forEach((s) => console.log('  ' + s));
  }
  if (noUnit.length) {
    console.log('\n--- qty with no clean parse (kept raw) count:', noUnit.length, ' sample ---');
    noUnit.slice(0, 25).forEach((s) => console.log('  ' + s));
  }

  // ---- centres ----
  const centersRes = await pg('GET', '/rest/v1/centres?select=id,name&order=id&limit=2000');
  const dbByName = {};
  (centersRes.body || []).forEach((c) => { dbByName[c.name] = c.id; });
  const toCreate = [];
  for (const rec of records) {
    const cfg = CENTRE_MAP[rec.centreFile];
    if (cfg.create) {
      if (!dbByName[cfg.name] && !toCreate.some((t) => t.name === cfg.name)) {
        const parentId = cfg.parent ? (dbByName[cfg.parent] || toCreate.find((t) => t.name === cfg.parent)?.row?.id) : null;
        toCreate.push({ name: cfg.name, type: 'SUB CENTRE', parentId: parentId || null });
        console.log('  queue new centre:', cfg.name, 'parent:', cfg.parent, '(', parentId, ')');
      }
    }
  }
  // resolve parents that are also being created (dedupe by order)
  const created = [];
  for (const t of toCreate) {
    if (dbByName[t.name]) { created.push(dbByName[t.name]); continue; }
    let parentId = t.parentId;
    if (!parentId && t.name !== 'SECTOR 81') {
      const cfg = Object.values(CENTRE_MAP).find((c) => c.name === t.name);
      if (cfg && cfg.parent) parentId = dbByName[cfg.parent] || null;
    }
    const ins = await pg('POST', '/rest/v1/centres?on_conflict=name', { name: t.name, type: 'SUB CENTRE', parentId });
    if (ins.status >= 200 && ins.status < 300 && Array.isArray(ins.body) && ins.body.length) {
      dbByName[ins.body[0].name] = ins.body[0].id;
      created.push(ins.body[0].id);
      console.log('  created centre:', t.name, '->', ins.body[0].id);
    } else if (ins.status === 409) {
      const got = await pg('GET', '/rest/v1/centres?select=id,name&name=eq.' + encodeURIComponent(t.name));
      if (got.body && got.body[0]) { dbByName[got.body[0].name] = got.body[0].id; created.push(got.body[0].id); }
    } else {
      console.error('  FAILED centre create', t.name, ins.status, ins.raw.slice(0, 300));
    }
  }

  // ---- stock_items: aggregate per (centreId, item) summed qty + unit ----
  const agg = new Map();
  for (const rec of records) {
    const cid = dbByName[CENTRE_MAP[rec.centreFile].name] ?? dbByName[rec.centreFile];
    const key = cid + '|' + rec.item;
    if (!agg.has(key)) agg.set(key, { centreId: cid, item: rec.item, qty: 0, unit: rec.unit });
    const a = agg.get(key);
    a.qty += rec.qtyB;
    if (rec.unit && !a.unit) a.unit = rec.unit;
  }
  const aggArr = [...agg.values()];
  console.log('\nstock_items aggregate rows:', aggArr.length);

  // pre-flight: every record must resolve to a centre before any writes
  const unresolved = records.filter((rec) => !(dbByName[CENTRE_MAP[rec.centreFile].name] ?? dbByName[rec.centreFile]));
  if (unresolved.length) {
    console.error('FATAL: ' + unresolved.length + ' records unresolved to a centre:');
    [...new Set(unresolved.map((r) => r.centreFile + ' => ' + (CENTRE_MAP[r.centreFile] ? CENTRE_MAP[r.centreFile].name : '???')))].slice(0, 40).forEach((s) => console.error('  ' + s));
    process.exit(1);
  }

  // ---- item master (upsert all distinct names) ----
  const itemNames = [...new Set(records.map((r) => r.item))];
  console.log('\ndistinct items:', itemNames.length);
  const ITEM_BATCH = 400;
  for (let i = 0; i < itemNames.length; i += ITEM_BATCH) {
    const chunk = itemNames.slice(i, i + ITEM_BATCH).map((name) => ({ name }));
    const r = await pg('POST', '/rest/v1/items?on_conflict=name', chunk);
    if (r.status >= 300 && r.status !== 409) console.error('  items insert failed', r.status, r.raw.slice(0, 200));
  }
  console.log('items upserted (batches of', ITEM_BATCH + ')');

  // ---- register: delete by source then insert ----
  await pg('DELETE', '/rest/v1/stock_register?source=eq.' + encodeURIComponent(SOURCE));
  console.log('cleared old source rows');

  const NOW = new Date().toISOString();
  const REG_BATCH = 300;
  let ins = 0;
  for (let i = 0; i < records.length; i += REG_BATCH) {
    const chunk = records.slice(i, i + REG_BATCH).map((rec) => ({
      centreId: dbByName[CENTRE_MAP[rec.centreFile].name] ?? dbByName[rec.centreFile],
      item: rec.item,
      pageNo: rec.pageNo,
      approvalNo: rec.approvalNo,
      approvalDate: rec.approvalDate,
      qtyA: Math.max(0, rec.qtyA),
      qtyB: Math.max(0, rec.qtyB),
      reason: rec.reason,
      remarks: rec.remarks,
      unit: rec.unit,
      qtyRaw: rec.qtyRaw.slice(0, 500),
      source: SOURCE,
      verifiedAt: NOW,
      verifiedBy: rec.verifiedBy
    }));
    const missing = chunk.filter((c) => !c.centreId);
    if (missing.length) { console.error('  rows without centreId:', missing.length); process.exit(1); }
    const r = await pg('POST', '/rest/v1/stock_register', chunk);
    if (r.status >= 300) { console.error('  register insert failed', r.status, r.raw.slice(0, 300)); process.exit(1); }
    ins += Array.isArray(r.body) ? r.body.length : chunk.length;
    console.log('  register inserted so far:', ins);
  }

  // ---- stock_items: upsert aggregate rows (computed earlier) ----
  console.log('\nupserting stock_items (', aggArr.length, ')');
  const ST_BATCH = 300;
  for (let i = 0; i < aggArr.length; i += ST_BATCH) {
    const chunk = aggArr.slice(i, i + ST_BATCH);
    const r = await pg('POST', '/rest/v1/stock_items?on_conflict=centreId,item', chunk);
    if (r.status >= 300) console.error('  stock_items upsert failed', r.status, r.raw.slice(0, 300));
  }
  console.log('stock_items upserted');

  console.log('\nDONE. records:', records.length, '| items:', itemNames.length, '| centres used:', dbByName ? Object.keys(dbByName).length : 0);
  if (warnings.length) {
    console.log('\nA!=B rows (for review):', warnings.length);
    warnings.slice(0, 40).forEach((w) => console.log('  ' + w));
  }
})().catch((e) => { console.error('FATAL', e); process.exit(1); });