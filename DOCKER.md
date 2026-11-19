# Docker 部署（统一 Chrome）

这套部署用一个长期运行的 Chrome 容器保存各平台登录态。麦田中控通过 CDP 控制同一个 Chrome，PlayWriter Relay 控制同一个 Chrome。三者共享 cookies，不复制、不导入浏览器资料。

## 端口

| 端口 | 用途 | 监听 |
|---|---|---|
| `8789` | 麦田网页 | `0.0.0.0`（可用 `MAITIAN_WEB_PORT` 修改） |
| `9222` | Chrome CDP | `127.0.0.1` |
| `6080` | noVNC，安装插件和扫码登录 | `127.0.0.1` |
| `19988` | PlayWriter Relay（0.12.0 默认端口） | `127.0.0.1` |

已有 `browserless` 容器保持不变。它不保存这套系统需要的登录资料，也不参与麦田发布流程。

## 准备

```bash
git clone https://github.com/KnowHunters/mdldm-maitian.git
cd mdldm-maitian
cp config.docker.example.json config.json
mkdir -p projects
```

创建 `.env`：

```env
MAITIAN_WEB_PORT=8789
MAITIAN_WEB_KEY=<网页访问口令>
PLAYWRITER_TOKEN=<PlayWriter Relay 口令>
DTK_BASE=http://192.168.123.11:8000
DTK_API_KEY=<dtk API key>
MAITIAN_PROJECTS=./projects
```

`MAITIAN_WEB_KEY` 必须和 `config.json` 的 `web.key` 一致。没有 dtk API key 时留空 `DTK_API_KEY`，麦田仍走原有页面采集流程。

## 启动

```bash
docker compose up -d --build
docker compose ps
docker compose logs -f chrome-unified
```

`maitian`、`playwriter-relay` 与 `chrome-unified` 共用网络命名空间，因此 CDP 使用 `http://127.0.0.1:9222`。Chrome 的调试端口和 noVNC 只绑定本机，远程访问 noVNC 请用 SSH 隧道：

```bash
ssh -L 6080:127.0.0.1:6080 root@192.168.123.11
```

浏览器打开 `http://127.0.0.1:6080/`。在 Chrome 中安装：

- 麦田发布助手：`eaaipbilkhibicihiollecmbpneikpnj`
- PlayWriter：`jfeammnjpkecdekppnclgkkffahnhfhe`

接着登录 B站、抖音、小红书、视频号、YouTube、X、Instagram 等平台。登录态写入 `maitian-chrome-profile` 数据卷，容器重启不会丢失。

PlayWriter 扩展连接地址：

```text
http://127.0.0.1:19988
```

口令填 `.env` 中的 `PLAYWRITER_TOKEN`。

## 验收

```bash
docker exec chrome-unified node -v
docker exec chrome-unified curl -fsS http://127.0.0.1:9222/json/version
docker exec playwriter-relay node -v
docker exec playwriter-relay curl -fsS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:19988/version
docker exec maitian curl -fsS http://127.0.0.1:9222/json/version
docker exec -it maitian node src/hub.mjs doctor
```

麦田网页：

```text
http://192.168.123.11:8789/?key=<MAITIAN_WEB_KEY>
```

## dtk

`Douyin_TikTok_Download_API` 只提供数据读取，不是 cookies 来源，也不能替代浏览器登录。配置好 API key 后，抖音数据优先走 dtk；未配置时保留原来的页面采集方式。

```bash
curl -H "X-API-Key: <key>" http://192.168.123.11:8000/api/v1/system/status
```

## 数据与备份

- `maitian-chrome-profile`：Chrome 登录态、插件数据。
- `maitian-data`：数据库、运行时配置和缩略图缓存。
- `./projects`：发布工程、成片、封面、发布档案。

升级：

```bash
git fetch --all
git reset --hard origin/main
docker compose up -d --build
```

不要删除 `maitian-chrome-profile` 数据卷，否则要重新登录所有平台。
