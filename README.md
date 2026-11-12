# Vibe-Astock Docker

这是 [simonlin1212/vibe-astock](https://github.com/simonlin1212/vibe-astock) v2.x 的单容器 Docker 打包项目。

v2.x 已从旧版 Python `server.py + frontend` 迁移到：

- Node.js 22.18+ 编排器：`orchestrator/src/api.ts`；
- Vite/React 前端：`desktop/`；
- Python 数据脚本：`.agents/skills/data-access/scripts/`；
- 单一 Web 入口：Vite preview 监听容器 `8080`，并把 `/api` 代理到容器内 `8770`。

## 群晖 NAS 部署

```bash
mkdir -p /volume1/docker/vibe-astock
cd /volume1/docker/vibe-astock
curl -fsSL https://raw.githubusercontent.com/matrixhawk/Vibe-Astock-docker/main/docker-compose.yml -o docker-compose.yml
docker compose up -d
```

打开 `http://NAS地址:5898`。如果 GHCR 包是私有的，先执行：

```bash
docker login ghcr.io
docker compose pull
docker compose up -d
```

也可以在 Container Manager 中导入本仓库的 `docker-compose.yml`。

数据保存在命名卷 `vibe_astock_data`，容器内路径为 `/data`，其中 `/data/.local` 是 v2 产品数据、配置和 API token。

## 环境变量

复制 `.env.example` 为 `.env` 后按需填写。全部变量都是可选的，默认 Compose 可以直接启动。

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `IMAGE_NAME` | `ghcr.io/matrixhawk/vibe-astock-docker:latest` | 要运行的镜像 |
| `HOST_PORT` | `5898` | NAS 对外端口 |
| `VRA_API_TOKEN` | 自动生成 | 容器内部 API token；留空会保存到 `/data/.local/api.token` |
| `VRA_PROVIDER` | 空 | 后台默认 AI 来源，如 `mimo`、`deepseek`、`kimi`、`qwen` |
| `MIMO_API_KEY` 等 | 空 | 对应 provider 的后台 API key；也可以只在 WebUI 配置 |
| `VRA_REMOTE` | 空 | 设为 `1` 后启用访问口令模式 |
| `VRA_ACCESS_TOKEN` | 空 | `VRA_REMOTE=1` 时使用，至少 32 位 |
| `VRA_PUBLIC_URL` | 空 | 远程访问时用于生成分享链接的公网根地址 |
| `VRA_SCHEDULER` | `on` | 是否启用后台定时任务；设为 `off` 可关闭 |

支持的 API key 环境变量包括：`DEEPSEEK_API_KEY`、`ZAI_API_KEY`、`MOONSHOT_API_KEY`、`MIMO_API_KEY`、`OPENAI_API_KEY`、`DASHSCOPE_API_KEY`、`SELFHOSTED_API_KEY`。

## AI 配置

v2.x 不再读取旧版的 `~/.config/mimo/mimo.env`，也不再应用 v1.x 的 MiMo 补丁。

- 页面上的「接入 AI」配置保存在当前浏览器，可直接选择 provider、填写 Base URL、API key 和模型；
- 需要后台默认 AI 时，同时设置 `VRA_PROVIDER` 和对应的 API key；
- MiMo Token Plan 等自定义端点，可在 WebUI 的 Base URL 中填写 `https://token-plan-cn.xiaomimimo.com/v1`；
- 需要后台长期使用自定义 Base URL 时，在 `/data/.local/providers/mimo.json` 放置 provider 覆盖文件。

不要把真实 API key 提交到 GitHub。WebUI 配置和 API key 不会写入镜像。

## 本地构建

```bash
cp .env.example .env
IMAGE_NAME=vibe-astock:local ./scripts/build.sh
IMAGE_NAME=vibe-astock:local ./scripts/run.sh
```

指定上游分支、标签或完整提交：

```bash
VIBE_ASTOCK_REF=v2.1.5 IMAGE_NAME=vibe-astock:local ./scripts/build.sh
```

构建过程会先执行 `scripts/check-upstream-v2.sh`。如果上游目录再次发生不兼容变化，构建会在安装依赖前停止，而不是发布一个不可运行的镜像。

## 镜像发布

`.github/workflows/publish-image.yml` 会：

- 读取上游 `main` 的完整 SHA，并以该 SHA 构建；
- 从上游 `desktop/package.json` 读取版本号，同时发布 `v<version>`、`<version>`、上游版本+SHA 和控制仓库提交 SHA 标签；
- 上游 SHA 未变化时跳过定时构建；
- 上游结构契约不通过时停止；
- 构建并发布 `linux/amd64` 与 `linux/arm64`；
- 构建成功后保存 SHA 标记；同一上游 SHA 构建失败时，定时任务不会每 6 小时无限重试；
- 支持手动指定上游 tag 或 commit 重新构建。

默认镜像：

```text
ghcr.io/matrixhawk/vibe-astock-docker:latest
ghcr.io/matrixhawk/vibe-astock-docker:v2.1.5
ghcr.io/matrixhawk/vibe-astock-docker:2.1.5
ghcr.io/matrixhawk/vibe-astock-docker:upstream-2.1.5-e0d08d19848b
```

其中版本号标签会随上游版本自动更新；`upstream-<version>-<sha12>` 和 `sha-<控制仓库提交>` 标签用于精确回滚，`latest` 继续指向默认分支最近一次成功发布。

## 许可

本仓库只负责 Docker 打包、运行入口和发布流程。应用源码、数据源许可及免责声明以 [上游项目](https://github.com/simonlin1212/vibe-astock) 为准。
