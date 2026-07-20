#!/usr/bin/env bash
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

PORT=3333
BASE_URL="http://localhost:$PORT"
SERVER_BIN="./server_test"
SERVER_PID=""
FAILURES=0

cleanup() {
  if [ -n "$SERVER_PID" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
    kill "$SERVER_PID" 2>/dev/null
    wait "$SERVER_PID" 2>/dev/null
  fi
  rm -f "$SERVER_BIN"
}
trap cleanup EXIT

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }

echo "Building test server binary..."
g++ -std=c++17 -O2 -Wall -Wextra -I third_party -pthread \
  src/*.cpp -o "$SERVER_BIN"

if [ ! -x "$SERVER_BIN" ]; then
  echo "error: build failed" >&2
  exit 1
fi

echo "Starting server on port $PORT..."
"$SERVER_BIN" &
SERVER_PID=$!

# Wait for server to come up
READY=0
for _ in $(seq 1 50); do
  if curl -s -o /dev/null "$BASE_URL/health"; then
    READY=1
    break
  fi
  sleep 0.1
done

if [ "$READY" -ne 1 ]; then
  echo "error: server did not start in time" >&2
  exit 1
fi

# --- Test: GET /health ---
health_status=$(curl -s -o /tmp/health_body.$$ -w "%{http_code}" "$BASE_URL/health")
health_body=$(cat /tmp/health_body.$$); rm -f /tmp/health_body.$$

if [ "$health_status" = "200" ]; then
  pass "GET /health returns 200"
else
  fail "GET /health returns 200 (got $health_status)"
fi

if echo "$health_body" | grep -q '"status": "ok"'; then
  pass "GET /health body contains status ok"
else
  fail "GET /health body contains status ok (got: $health_body)"
fi

# --- Test: GET /current_time ---
time_status=$(curl -s -o /tmp/time_body.$$ -w "%{http_code}" "$BASE_URL/current_time")
time_body=$(cat /tmp/time_body.$$); rm -f /tmp/time_body.$$

if [ "$time_status" = "200" ]; then
  pass "GET /current_time returns 200"
else
  fail "GET /current_time returns 200 (got $time_status)"
fi

if echo "$time_body" | grep -q '"timezone": "UTC"'; then
  pass "GET /current_time body contains timezone UTC"
else
  fail "GET /current_time body contains timezone UTC (got: $time_body)"
fi

if echo "$time_body" | grep -Eq '"current_time": "[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z"'; then
  pass "GET /current_time body contains ISO8601 timestamp"
else
  fail "GET /current_time body contains ISO8601 timestamp (got: $time_body)"
fi

echo
if [ "$FAILURES" -eq 0 ]; then
  echo "All tests passed."
  exit 0
else
  echo "$FAILURES test(s) failed."
  exit 1
fi
