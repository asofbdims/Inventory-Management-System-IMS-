// Vercel build: publishes the IMS single-file app from the repo root.
// - Copies stock-management-system.html -> out/index.html
// - Copies public/config.local.js (PUBLIC anon key only) -> out/config.local.js
// - Copies public/downloads/*.docx -> out/downloads/ (SCI official form templates)
// Vercel serves ONLY "out/" (see vercel.json -> outputDirectory), so backend/,
// supabase/ migrations, scripts/ etc. are never published. The service-role key
// never enters this pipeline (it lives only in the gitignored root config.local.js).
import { mkdirSync, copyFileSync, statSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const repoRoot = join(dirname(fileURLToPath(import.meta.url)), '..');
const outDir = join(repoRoot, 'out');

mkdirSync(outDir, { recursive: true });
copyFileSync(join(repoRoot, 'stock-management-system.html'), join(outDir, 'index.html'));
copyFileSync(join(repoRoot, 'public', 'config.local.js'), join(outDir, 'config.local.js'));

const dlSrc = join(repoRoot, 'public', 'downloads');
const dlOut = join(outDir, 'downloads');
let dlCount = 0;
try {
  mkdirSync(dlOut, { recursive: true });
  for (const f of readdirSync(dlSrc)) {
    const lf = f.toLowerCase();
    if (lf.endsWith('.pdf')) { copyFileSync(join(dlSrc, f), join(dlOut, f)); dlCount++; }
  }
} catch (e) {
  console.warn('downloads copy skipped:', e.message);
}

const kb = Math.round(statSync(join(outDir, 'index.html')).size / 1024);
console.log(`Built out/index.html (${kb} KB) + out/config.local.js + out/downloads (${dlCount} files) for Vercel.`);