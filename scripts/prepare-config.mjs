import fs from 'node:fs';

const file = process.argv[2] || '/data/maitian/config.json';
const cfg = JSON.parse(fs.readFileSync(file, 'utf8'));
cfg.web = cfg.web || {};
cfg.web.port = Number(process.env.MAITIAN_WEB_PORT || cfg.web.port || 8789);
cfg.web.key = process.env.MAITIAN_WEB_KEY || cfg.web.key || 'CHANGE_ME';
cfg.dtk = cfg.dtk || {};
cfg.dtk.base = process.env.DTK_BASE || cfg.dtk.base || 'http://dtk-api-1:8000';
cfg.dtk.apiKey = process.env.DTK_API_KEY || cfg.dtk.apiKey || '';
fs.writeFileSync(file, JSON.stringify(cfg, null, 2) + '\n');
