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
MAITIAN_PROJECTS=./projects
```

`MAITIAN_WEB_KEY` 必须和 `config.json` 的 `web.key` 一致。没有 dtk API key 时留空 `DTK_API_KEY`，麦田仍走原有页面采集流程。

## 启动

```bash
docker compose up -d --build
docker compose ps
docker compose logs -f chrome-unified
```

`maitian`、`playwriter-relay` 与 `chrome-unified` 共用网络命名空间，因此 CDP 使用 `http://127.0.0.1:9222`。Chrome 的调试端口和 noVNC 只绑定服务器本机，不直接对外开放。

日常打开统一 Chrome：登录麦田网页，进入 **系统 → 打开远程 Chrome**。这个入口走麦田的 `8789` 端口和现有登录态，同源反向代理到 noVNC，不需要 SSH 隧道，也不会额外暴露 `6080`。远程桌面可用于扫码登录、处理验证和查看页面；登录态保存在服务器浏览器 Profile 中。

CreatorHub 是独立项目。它自己的 Docker 部署文档保留独立访问方式：容器内 `127.0.0.1:8000`，通过 SSH 隧道从工作站访问 `http://127.0.0.1:8001/`。CreatorHub 可以共用统一 Chrome 的 CDP 和 X display，但不应共用浏览器 Profile/cookies：它按账号隔离 Profile、代理和 storage state，强行指向麦田 Profile 会破坏账号隔离，并让两个自动化控制器争用同一个用户数据目录。

Chrome 策略会在首次启动时自动安装这两个扩展：

- 麦田发布助手：`eaaipbilkhibicihiollecmbpneikpnj`
- PlayWriter：`jfeammnjpkecdekppnclgkkffahnhfhe`

安装完成后，在统一 Chrome 中登录 B站、抖音、小红书、视频号、YouTube、X、Instagram 等平台。登录态写入 `maitian-chrome-profile` 数据卷，容器重启不会丢失。

系统页新增平台管理和集成管理：

- 「平台」逐家检查、打开登录页、停用或启用。停用平台不再体检、保活、发布和采粉丝。
- 「集成」保存飞书 webhook、测试发送、切换验证码登录；保存知识站配置、测试连接、开关知识站。
- 配置写在 `maitian-data` 卷内的 `config.json`，容器启动不会覆盖已有配置。

## 七个模块

| 模块 | 现状 | Agent 能不能自动执行 |
|---|---|---|
| 写文案 | `skills/maitian-publish/SKILL.md` 定义发布素材格式；Agent 可生成文案、标签、封面建议和 `publish.json` | 能。由 Agent 生成文件；成片、封面和最终选题要人确认 |
| 排计划 | `hub plan` 扫描 `publish.json`，写入分发计划；守护进程按定时触发 | 能。生成工程后可执行 `hub plan`；改期、删期要人决定 |
| 发布助手 | 麦田助手扩展在统一 Chrome 里填写各平台上传页；国内四家填写后停下等人点发布，X/YouTube/Instagram/站点可自动提交 | 部分。填表、防重、自动提交可做；登录扫码、验证码、国内平台最后发布由人完成 |
| 数据回来 | `hub metrics`、`hub followers` 由守护进程每天采集；新一期头 72 小时加密采样 | 能。采集、入库、日报自动执行；平台页面结构变化时要人修适配器 |
| 自动复盘 | `review.mjs` 在发布后第 1/3/7 天出单期复盘，每周一出周报 | 能。无需人参与；数据不足时报告会标注或留空 |
| 算转化 | `site_daily` 与 `site_campaigns` 记录注册、会员、订单、收入和 `utm_campaign` 归因；需要配置知识站 | 能。站点接口可用时自动采、自动归因；站点接口和登录态要人配置与维护 |
| 出事提醒 | 飞书通知覆盖发布开始/结束、异常、登录过期、待发布提醒、体检、日报、复盘和周报 | 能。通知自动发送；webhook 和是否启用飞书登录由人配置 |

操作顺序：

```text
看片/定题（人）
  → Agent 写发布素材、生成 publish.json
  → 人确认封面与文案
  → Agent 执行 hub plan
  → 守护进程 hub run（统一 Chrome 填写；必要时等人点发布）
  → 守护进程 sync / metrics / followers / review / weekly
  → 网页和飞书看结果
```

## X 长文 + 引用视频

不建议在当前的 Docker 方案里实现。上游实现不是 `review` 功能，而是发布链路里的 `publish.json` 模式 `x.mode = "article+quote"`。它要求：

- `config.plugin = "local"`，即作者本机插件环境；
- 插件目录里有 `tools/x-article-quote.mjs`；
- macOS 的 `open` 和 `caffeinate`；
- 日常 Chrome 里的插件开发桥 `tools/bridge-server.mjs` 和端口 `8765`。

当前方案使用服务器统一 Chrome 和商店版插件，没有这套本机开发桥。强行移植需要把插件仓库和桥接服务也塞进容器，并改写启动脚本；收益只有 X 的一种特殊发帖格式。普通 X 视频帖已经由发布助手支持，数据侧 `metrics.mjs` 也能读取长文链接并合并统计。建议保持普通视频帖模式，不整合长文自动发帖。

PlayWriter 扩展连接地址：

```text
http://127.0.0.1:19988
```

口令填 `.env` 中的 `PLAYWRITER_TOKEN`。

## 验收

```bash
docker exec chrome-unified curl -fsS http://127.0.0.1:9222/json/version
docker exec chrome-unified sh -c 'find /chrome-profile/Default/Extensions -maxdepth 1 -mindepth 1 -type d'
curl -fsS http://127.0.0.1:19988/version
docker exec --env PLAYWRITER_HOST=http://127.0.0.1:19988 --env PLAYWRITER_TOKEN="maitian-pw-local-20261119" playwriter-relay playwriter browser list
docker exec maitian curl -fsS http://127.0.0.1:9222/json/version
docker exec maitian node src/hub.mjs doctor
```

麦田网页：

```text
http://192.168.123.11:8789/?key=<MAITIAN_WEB_KEY>
```

## dtk

`Douyin_TikTok_Download_API` 只提供数据读取，不是 cookies 来源，也不能替代浏览器登录。默认不启用。需要时再在 `config.json` 填 `dtk.base` 和 `dtk.apiKey`；留空时麦田保留原来的页面采集方式。

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
