#!/usr/bin/env bash
#
# create-b2-rclone-key.sh
#
# Sets up an isolated Python venv, installs the official `b2` CLI into it,
# authorizes with your MASTER B2 application key, and mints a new,
# narrowly-scoped application key suitable for `rclone sync --b2-hard-delete`.
#
# The new key gets: listBuckets, listFiles, writeFiles, deleteFiles
# It deliberately does NOT get: readFiles (so it can never download/read
# object contents — the closest B2 gets to "write only" while still
# working with rclone's sync/list logic).
#
# By default the key is restricted to a single bucket. Pass --all-buckets
# instead of a bucket name to mint an ACCOUNT-WIDE key with those same
# capabilities across every bucket on the account (present and future).
# B2 has no concept of "these specific N buckets" in one key — it's one
# bucket, or all of them — so --all-buckets is the only way to cover more
# than one bucket with a single key. Prefer running this script once per
# bucket instead unless you specifically need one key for many buckets.
#
# Usage:
#   ./create-b2-rclone-key.sh <bucket-name|--all-buckets> [key-name]
#
# Example:
#   ./create-b2-rclone-key.sh my-bucket-name rclone-sync-key
#   ./create-b2-rclone-key.sh --all-buckets rclone-sync-key-all
#
# You'll be prompted interactively for your MASTER applicationKeyId and
# applicationKey (from backblaze.com -> App Keys -> the "master" row).
# Nothing is written to disk in plaintext except the final output the
# script prints to your terminal.

set -euo pipefail

# ---- Args -------------------------------------------------------------
BUCKET_NAME="${1:-}"
KEY_NAME="${2:-rclone-sync-key}"
ALL_BUCKETS=false

if [[ -z "$BUCKET_NAME" ]]; then
  echo "Usage: $0 <bucket-name|--all-buckets> [key-name]" >&2
  echo "Example: $0 my-bucket-name rclone-sync-key" >&2
  echo "         $0 --all-buckets rclone-sync-key-all" >&2
  exit 1
fi

if [[ "$BUCKET_NAME" == "--all-buckets" ]]; then
  ALL_BUCKETS=true
  KEY_NAME="${2:-rclone-sync-key-all}"
fi

# ---- Venv setup ---------------------------------------------------------
VENV_DIR="${VENV_DIR:-$HOME/.venvs/b2cli}"

echo "==> Creating venv at $VENV_DIR (if it doesn't already exist)"
python3 -m venv "$VENV_DIR"

# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

echo "==> Installing/upgrading b2 CLI inside the venv"
pip install --quiet --upgrade pip
pip install --quiet --upgrade b2

echo "==> b2 CLI version: $(b2 version)"

# ---- Authorize with the MASTER key -------------------------------------
# We authorize interactively (not via env vars/CLI args) so the master
# secret never ends up in shell history or process listings.
echo ""
echo "==> Authorize with your MASTER application key (from the B2 web UI's"
echo "    App Keys page — the very first key listed, tied to your account)."
b2 account authorize

# ---- Create the scoped key ----------------------------------------------
echo ""
if [[ "$ALL_BUCKETS" == true ]]; then
  echo "==> Creating ACCOUNT-WIDE key '$KEY_NAME' — valid for ALL buckets on"
  echo "    this account, including any created later. Capabilities:"
  echo "    listBuckets,listFiles,writeFiles,deleteFiles"
  echo ""

  KEY_OUTPUT="$(b2 key create \
    "$KEY_NAME" \
    listBuckets,listFiles,writeFiles,deleteFiles)"
else
  echo "==> Creating scoped key '$KEY_NAME' restricted to bucket '$BUCKET_NAME'"
  echo "    Capabilities: listBuckets,listFiles,writeFiles,deleteFiles"
  echo ""

  KEY_OUTPUT="$(b2 key create \
    --bucket "$BUCKET_NAME" \
    "$KEY_NAME" \
    listBuckets,listFiles,writeFiles,deleteFiles)"
fi

echo "$KEY_OUTPUT"

# The b2 CLI prints "<keyID> <applicationKey>" on the last line of output
# (any warnings/notices it emits come before that). Pull the two values
# apart so we can label them instead of leaving two bare strings.
KEY_LINE="$(echo "$KEY_OUTPUT" | tail -n 1)"
read -r KEY_ID APP_KEY <<< "$KEY_LINE"

echo ""
if [[ -n "$KEY_ID" && -n "$APP_KEY" ]]; then
  echo "==> New application key:"
  echo ""
  echo "    Key ID (B2_ACCOUNT):           $KEY_ID"
  echo "    Application Key (B2_KEY):      $APP_KEY"
else
  echo "==> Could not parse the key ID / application key from the output"
  echo "    above (unrecognized b2 CLI output format) — copy them from"
  echo "    the raw output printed above instead."
fi

echo ""
echo "==> Done. Copy the keyID and applicationKey above into your rclone"
echo "    command, e.g.:"
echo ""
if [[ "$ALL_BUCKETS" == true ]]; then
  echo "    rclone sync /app/repo :b2:<bucket-name> \\"
else
  echo "    rclone sync /app/repo :b2:$BUCKET_NAME \\"
fi
echo "      --b2-account '${KEY_ID:-<keyID from above>}' \\"
echo "      --b2-key '${APP_KEY:-<applicationKey from above>}' \\"
echo "      --fast-list --b2-hard-delete --transfers 10"
echo ""
echo "    Note: this application key CANNOT be listed again later — if you"
echo "    lose the applicationKey value, you'll need to create a new key."

deactivate