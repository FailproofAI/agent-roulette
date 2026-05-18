#!/usr/bin/env bash
# Usage: ./serve.sh [topic name]
# With no argument: opens the picker normally (random spins).
# With a topic: opens the picker pre-rigged to always land on that topic.
#
# Examples:
#   ./serve.sh
#   ./serve.sh "Chain of thought"
#   ./serve.sh "Agent audit trail"

set -euo pipefail

PORT="${PORT:-8787}"
DIR="$(cd "$(dirname "$0")" && pwd)"

# Encode the topic for a URL query string
if [[ $# -gt 0 && -n "$1" ]]; then
  TOPIC="$1"
  ENCODED=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$TOPIC")
  URL="http://localhost:${PORT}/topic-picker.html?topic=${ENCODED}"
  echo "  topic : $TOPIC"
else
  URL="http://localhost:${PORT}/topic-picker.html"
  echo "  topic : (random)"
fi

echo "  server: http://localhost:${PORT}"
echo "  url   : $URL"
echo ""

# Kill any existing server on the same port
lsof -ti tcp:"$PORT" | xargs -r kill -9 2>/dev/null || true

# Start server in background, suppress output
python3 -m http.server "$PORT" --directory "$DIR" &>/dev/null &
SERVER_PID=$!

# Brief pause to let the server bind
sleep 0.4

# Open in browser — supports WSL, macOS, and Linux
if command -v wslview &>/dev/null; then
  wslview "$URL"
elif command -v xdg-open &>/dev/null; then
  xdg-open "$URL" &>/dev/null &
elif command -v open &>/dev/null; then
  open "$URL"
else
  echo "  (open $URL in your browser)"
fi

echo "  press Ctrl+C to stop"
echo ""

trap "kill $SERVER_PID 2>/dev/null; echo '  server stopped'" EXIT
wait "$SERVER_PID"
