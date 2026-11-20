import fs from 'node:fs';

const source = process.argv[2] || process.argv[3] || '/data/maitian/config.json';
const file = process.argv[3] || source;
const read = (f) => { try { return JSON.parse(fs.readFileSync(f, 'utf8')); } catch { return null; } };
const existing = read(file);
const cfg = existing || read(source) || {};
if (!existing && fs.existsSync(source)) fs.copyFileSync(source, file);
cfg.web = cfg.web || {};
cfg.web.port = Number(process.env.MAITIAN_WEB_PORT || cfg.web.port || 8789);
cfg.web.key = process.env.MAITIAN_WEB_KEY || cfg.web.key || 'CHANGE_ME';
cfg.dtk = cfg.dtk || {};
if (process.env.DTK_BASE !== undefined) {
  cfg.dtk.base = process.env.DTK_BASE;
} else if (!cfg.dtk.base) {
  cfg.dtk.base = '';
}
cfg.dtk.apiKey = process.env.DTK_API_KEY || cfg.dtk.apiKey || '';
cfg.cdpUrl = process.env.CDP_URL || cfg.cdpUrl || 'http://chrome-unified:9222';
cfg.chromeProfile = process.env.CHROME_PROFILE || cfg.chromeProfile || '/data/chrome-profile';
fs.writeFileSync(file, JSON.stringify(cfg, null, 2) + '\n');
