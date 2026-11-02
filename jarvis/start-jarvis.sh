#!/usr/bin/env bash
# J.A.R.V.I.S. — macOS / Linux: lokalny serwer + panel w trybie aplikacji (Chrome/Edge)
cd "$(dirname "$0")"
PORT=8765
URL="http://localhost:$PORT/"
if ! curl -s -o /dev/null "$URL"; then
  python3 -m http.server "$PORT" --bind 127.0.0.1 >/dev/null 2>&1 &
  sleep 1
fi
if [[ "$OSTYPE" == darwin* ]]; then
  open -na "Google Chrome" --args --app="$URL" --autoplay-policy=no-user-gesture-required 2>/dev/null || open -na "Microsoft Edge" --args --app="$URL" --autoplay-policy=no-user-gesture-required 2>/dev/null || open "$URL"
else
  for b in google-chrome chromium chromium-browser microsoft-edge; do
    command -v "$b" >/dev/null && { "$b" --app="$URL" --autoplay-policy=no-user-gesture-required >/dev/null 2>&1 & exit 0; }
  done
  xdg-open "$URL"
fi
