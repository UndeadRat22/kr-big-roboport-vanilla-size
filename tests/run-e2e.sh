#!/bin/sh
# E2E test for kr-big-roboport-vanilla-size with the base game only.
# Krastorio 2 is absent, so the mod must load and do nothing.
#
# Usage: tests/run-e2e.sh
# Env:   FACTORIO_BIN=/path/to/factorio
#        E2E_WORK_DIR=/tmp/krb-e2e-base
set -e
MOD_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FACTORIO="${FACTORIO_BIN:-$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio}"
WORK="${E2E_WORK_DIR:-/tmp/krb-e2e-base}"

rm -rf "$WORK"
mkdir -p "$WORK/mods"
ln -sfn "$MOD_DIR" "$WORK/mods/kr-big-roboport-vanilla-size"
ln -sfn "$MOD_DIR/tests/e2e-mod" "$WORK/mods/krb-e2e"

cat > "$WORK/server-settings.json" <<'EOF'
{
  "name": "krb-e2e-base", "description": "", "tags": [], "max_players": 0,
  "visibility": { "public": false, "lan": false },
  "user_password": "", "game_password": "",
  "require_user_verification": false,
  "max_upload_in_kilobytes_per_second": 0, "minimum_latency_in_ticks": 0,
  "ignore_player_limit_for_returning_players": false,
  "allow_commands": "admins-only",
  "autosave_interval": 10, "autosave_slots": 1,
  "afkt_autokick_interval": 0, "auto_pause": false
}
EOF

"$FACTORIO" --create "$WORK/e2e.zip" --mod-directory "$WORK/mods" > "$WORK/create.log" 2>&1

"$FACTORIO" --start-server "$WORK/e2e.zip" --mod-directory "$WORK/mods" \
  --server-settings "$WORK/server-settings.json" > "$WORK/server.log" 2>&1 &
PID=$!
sleep "${E2E_SECONDS:-30}"
kill "$PID" 2>/dev/null || true
wait "$PID" 2>/dev/null || true

grep -E "E2E" "$WORK/server.log" || true
FAILS=$(grep -c "E2E FAIL" "$WORK/server.log" || true)
DONE=$(grep -c "E2E DONE" "$WORK/server.log" || true)
if [ "$FAILS" != "0" ] || [ "$DONE" != "1" ]; then
  echo "E2E FAILED ($FAILS failures, done=$DONE). Logs in $WORK"
  exit 1
fi
echo "E2E PASSED. Logs in $WORK"
