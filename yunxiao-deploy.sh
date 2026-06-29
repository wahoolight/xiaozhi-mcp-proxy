#!/usr/bin/env bash
# 云效部署：解压制品并 pm2 启动（放在 fork 仓库根目录）
set -euo pipefail

APP_DIR="${DEPLOY_PATH:-/data/www/xiaozhi-mcp-proxy}"
TGZ="${PROXY_TGZ:-xiaozhi-mcp-proxy.tgz}"
PYTHON="${PYTHON_BIN:-python3.11}"

mkdir -p "$APP_DIR"
cd "$APP_DIR"

echo "==> deploy xiaozhi-mcp-proxy at $APP_DIR"

# 云效只下载 tgz；artifact/ 二次打包时可能嵌套同名 tgz，需解到出现 mcp_pipe.py
if [[ ! -f mcp_pipe.py ]]; then
  if [[ ! -f "$TGZ" ]]; then
    echo "artifact not found: $APP_DIR/$TGZ" >&2
    exit 1
  fi
  tar -zxvf "$TGZ"
  if [[ ! -f mcp_pipe.py && -f "$TGZ" ]]; then
    echo "==> nested artifact detected, extracting inner $TGZ"
    tar -zxvf "$TGZ"
  fi
  rm -f "$TGZ"
fi

if [[ ! -f mcp_pipe.py ]]; then
  echo "mcp_pipe.py not found after extract" >&2
  exit 1
fi

if ! command -v "$PYTHON" >/dev/null 2>&1; then
  echo "$PYTHON not found" >&2
  exit 1
fi

"$PYTHON" -m pip install --upgrade pip -i https://pypi.tuna.tsinghua.edu.cn/simple
"$PYTHON" -m pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
"$PYTHON" -c "import aiohttp, websockets; print('python deps ok')"

export PATH=/usr/local/node20/bin:/usr/local/bin:${PATH:-}
if [[ -z "${MCP_ENDPOINT:-}" && -n "${XIAOZHI_MCP_ENDPOINT:-}" ]]; then
  export MCP_ENDPOINT="$XIAOZHI_MCP_ENDPOINT"
fi
export MCP_URL="${MCP_URL:-http://127.0.0.1:3100/mcp}"
export PYTHON_BIN="$PYTHON"

if [[ -z "${MCP_ENDPOINT:-}" ]]; then
  echo "Missing XIAOZHI_MCP_ENDPOINT" >&2
  exit 1
fi

if ! command -v pm2 >/dev/null 2>&1; then
  echo "pm2 not found" >&2
  exit 1
fi

curl -sf "http://127.0.0.1:${MCP_HTTP_PORT:-3100}/health" >/dev/null || \
  echo "WARN: paco-mcp-server health check failed" >&2

pm2 startOrReload ecosystem.config.cjs --update-env
pm2 save
pm2 status xiaozhi-proxy

echo "==> deploy ok"
