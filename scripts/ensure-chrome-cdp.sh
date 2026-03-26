#!/bin/bash
# Chrome CDP がポート 9222 で起動しているか確認し、未起動なら起動する

PORT=9222
CDP_URL="http://localhost:$PORT/json/version"
USER_DATA_DIR="/tmp/chrome-cdp-profile"

# 1. ポートチェック
if curl -s --max-time 2 "$CDP_URL" > /dev/null 2>&1; then
  echo "Chrome CDP already running on port $PORT"
  exit 0
fi

# 2. OS 検出 → Chrome パス解決
case "$(uname -s)" in
  Darwin)
    CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    ;;
  Linux)
    CHROME=$(which google-chrome || which chromium-browser || which chromium)
    ;;
  *)
    echo "ERROR: Unsupported OS" >&2
    exit 1
    ;;
esac

if [ "$(uname -s)" = "Darwin" ] && [ ! -f "$CHROME" ]; then
  echo "ERROR: Chrome not found at $CHROME" >&2
  exit 1
fi

if [ "$(uname -s)" = "Linux" ] && [ -z "$CHROME" ]; then
  echo "ERROR: Chrome/Chromium not found in PATH" >&2
  exit 1
fi

# 3. バックグラウンド起動
"$CHROME" --remote-debugging-port=$PORT --user-data-dir="$USER_DATA_DIR" &>/dev/null &
disown

# 4. ヘルスチェック（最大 10 秒）
for i in $(seq 1 10); do
  if curl -s --max-time 1 "$CDP_URL" > /dev/null 2>&1; then
    echo "Chrome CDP started on port $PORT"
    exit 0
  fi
  sleep 1
done

echo "ERROR: Chrome CDP failed to start within 10 seconds" >&2
exit 1
