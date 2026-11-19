import fs from 'node:fs';

const source = process.argv[2] || process.argv[3] || '/data/maitian/config.json';
const file = process.argv[3] || source;
const cfg = JSON.parse(fs.readFileSync(source, 'utf8'));
cfg.web = cfg.web || {};
cfg.web.port = Number(process.env.MAITIAN_WEB_PORT || cfg.web.port || 8789);
cfg.web.key = process.env.MAITIAN_WEB_KEY || cfg.web.key || 'CHANGE_ME';
cfg.dtk = cfg.dtk || {};
cfg.dtk.base = process.env.DTK_BASE || cfg.dtk.base || 'http://dtk-api-1:8000';
cfg.dtk.apiKey = process.env.DTK_API_KEY || cfg.dtk.apiKey || '';
cfg.cdpUrl = process.env.CDP_URL || cfg.cdpUrl || 'http://chrome-unified:9222';
cfg.chromeProfile = process.env.CHROME_PROFILE || cfg.chromeProfile || '/data/chrome-profile';
fs.writeFileSync(file, JSON.stringify(cfg, null, 2) + '\n');
