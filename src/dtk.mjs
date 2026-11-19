import { config } from './feishu.mjs';

const DTK = config.dtk;
const sleep = (ms) => new Promise(r => setTimeout(r, ms));

async function api(path, init = {}) {
  if (!DTK || !DTK.base) return null;
  const headers = { ...(init.headers || {}) };
  if (DTK.apiKey) headers['X-API-Key'] = DTK.apiKey;
  const r = await fetch(`${String(DTK.base).replace(/\/$/, '')}${path}`, {
    ...init,
    headers,
    signal: AbortSignal.timeout(40000),
  });
  const body = await r.json().catch(() => null);
  if (!body || body.success === false) throw new Error(body?.error?.message || `dtk HTTP ${r.status}`);
  return body.data;
}

async function settled(taskId) {
  const deadline = Date.now() + 60000;
  for (;;) {
    const data = await api(`/api/v1/tasks/${encodeURIComponent(taskId)}`);
    if (data?.state === 'done') return data.data;
    if (data?.state === 'failed') throw new Error(data.error?.message || 'dtk 任务失败');
    if (Date.now() > deadline) throw new Error('dtk 任务超时');
    await sleep(2000);
  }
}

export const dtkEnabled = () => !!(DTK && DTK.base && DTK.apiKey);

export async function dtkVideo(platform, { url, id }) {
  if (!dtkEnabled()) return null;
  const q = new URLSearchParams();
  if (url) q.set('url', url);
  if (id) q.set('aweme_id', id);
  if (![...q].length) return null;
  const data = await api(`/api/v1/${platform}/video?${q}`);
  const out = data?.task_id ? await settled(data.task_id) : data;
  const stats = out?.statistics || out?.stats || out?.video?.statistics || {};
  const num = (v) => (v == null ? null : Number(String(v).replace(/,/g, '')) || null);
  return {
    views: num(stats.play_count ?? stats.playCount ?? stats.view_count ?? stats.views),
    likes: num(stats.digg_count ?? stats.diggCount ?? stats.like_count ?? stats.likes),
    comments: num(stats.comment_count ?? stats.commentCount ?? stats.comments),
    favorites: num(stats.collect_count ?? stats.collectCount ?? stats.favorite_count ?? stats.favorites),
    shares: num(stats.share_count ?? stats.shareCount ?? stats.shares),
    extra: { source: 'dtk' },
  };
}
