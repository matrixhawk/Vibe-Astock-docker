# Vibe-Astock Docker

这是 [simonlin1212/vibe-astock](https://github.com/simonlin1212/vibe-astock) 的单镜像 Docker 打包项目，结构参考 [Vibe-Research Docker](https://github.com/matrixhawk/Vibe-Research-docker)。

镜像在构建阶段拉取上游源码，完成 React 前端构建并安装 Python 后端；运行时由 Nginx 对外提供单一入口：

- `/` 提供 Vite/React 前端。
- `/api/*` 反向代理到容器内 `8910` 端口的 FastAPI 后端。
- `/data` volume 保存复盘、热度、持仓和缓存数据。

## 快速开始

```bash
cp .env.example .env
docker compose up -d
```

上游 v0.2.0 默认从 `~/.config/mimo/mimo.env` 读取 MiMo 凭据。Compose 会将宿主机的 `~/.config/mimo` 目录以只读方式挂载到容器内的 `/data/.config/mimo`；如果目录不在默认位置，请在 `.env` 中设置 `MIMO_CONFIG_DIR` 为宿主机上的绝对路径。也可以直接在 `.env` 中填写 `MIMO_API_KEY`、`MIMO_BASE_URL` 和 `MIMO_MODEL`，不依赖凭据文件。

打开 <http://localhost:5898>。

默认 Compose 镜像为：

```text
ghcr.io/matrixhawk/vibe-astock-docker:latest
```

如果你把本项目发布到其他 GitHub 账号，请在 `.env` 中修改 `IMAGE_NAME`。

GHCR 镜像包的可见性与 GitHub 仓库分开管理。如果拉取镜像时收到 `401`，先登录 GHCR：

```bash
docker login ghcr.io
docker compose up -d
```

查看日志和停止服务：

```bash
docker compose logs -f vibe-astock
docker compose down
```

删除容器并同时删除本地数据：

```bash
docker compose down -v
```

修改访问端口：

```bash
HOST_PORT=8088 docker compose up -d
```

## 本地构建

```bash
./scripts/build.sh
./scripts/run.sh
```

也可以构建上游指定分支、标签或提交：

```bash
VIBE_ASTOCK_REF=main ./scripts/build.sh
```

构建参数：

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `VIBE_ASTOCK_REPO` | `https://github.com/simonlin1212/vibe-astock.git` | 构建时拉取的上游仓库 |
| `VIBE_ASTOCK_REF` | `main` | 构建时 checkout 的上游 ref |
| `IMAGE_NAME` | `vibe-astock:local` | `scripts/build.sh` 的本地镜像标签 |
| `HOST_PORT` | `5898` | `scripts/run.sh` 暴露到本机的端口 |

## 配置

Compose 会把常用配置传入容器：

| 变量 | 作用 |
| --- | --- |
| `VR_API_KEY` | 给盘面数据接口增加可选的 Bearer key 校验 |
| `VR_ALLOW_ORIGINS` | 盘面数据接口的 CORS 来源白名单 |
| `VIBE_ALLOW_HOSTS` | 允许写操作的 Host 白名单 |
| `MIMO_CONFIG_DIR` | 宿主机 MiMo 凭据目录，默认 `$HOME/.config/mimo` |
| `MIMO_API_KEY` / `MIMO_BASE_URL` / `MIMO_MODEL` | 可选的 OpenAI 兼容 LLM 配置 |
| `IWENCAI_API_KEY` | 可选的同花顺问财题材数据 key |
| `VIBE_MARKET_PROXY` / `VIBE_MARKET_DIRECT` | 市场数据源的代理/直连回退开关 |
| `UVICORN_WORKERS` | Uvicorn worker 数量，建议保持 `1` 以避免本地缓存竞争 |

`MIMO_CONFIG_DIR` 默认指向宿主机的 `$HOME/.config/mimo`，容器以只读方式将它挂载为 `/data/.config/mimo`，其中的 `mimo.env` 会被上游读取。如果使用 `MIMO_*` 环境变量直接配置，则无需该文件；两种方式都不要把真实 API key 提交到仓库。

不要把真实 API key 写入仓库；`.env` 已被 `.gitignore` 忽略。容器默认没有安装本机 Claude/Codex 等 CLI，LLM 建议通过 API 配置使用。

## 数据持久化

Compose 将 `/data` 挂载到 `vibe_astock_data` 命名卷。通过 `HOME=/data`，上游默认的以下目录都会持久化：

- `/data/.duanxian-agents/`：复盘、周报和缓存。
- `/data/.vibe-research/`：持仓、资讯和盘面数据。
- `/data/.vibe-astock/`：自定义 prompt 等用户配置。
- `/data/.config/mimo/mimo.env`：宿主机 MiMo 凭据目录中的文件，以只读方式挂载，不由数据卷保存。

## 镜像发布

`.github/workflows/publish-image.yml` 会在 `main` 变更容器文件时构建发布，并每 6 小时检查一次上游 `main`：

- 上游 SHA 没有变化：跳过构建和推送。
- 上游 SHA 发生变化：构建并发布新镜像。
- 本仓库 `main` 有相关文件变更，或手动运行 workflow：仍会强制构建发布。

- `linux/amd64`
- `linux/arm64`
- `ghcr.io/<GitHub 用户名>/vibe-astock-docker:latest`
- `ghcr.io/<GitHub 用户名>/vibe-astock-docker:sha-<提交短哈希>`

也可以在 GitHub Actions 页面手动运行，并指定 `VIBE_ASTOCK_REF` 来构建上游特定 ref。

## 说明与许可

本仓库只负责 Docker 打包和运行入口；应用源码、数据源和免责声明以 [上游 Vibe-Astock](https://github.com/simonlin1212/vibe-astock) 为准。使用前请阅读上游项目的许可和免责声明，市场数据及 AI 输出不构成投资建议。
