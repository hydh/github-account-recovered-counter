#!/usr/bin/env bash
# 制限中(プライマリメール未認証)はアカウントの GitHub Actions 自体が無効化される
# ため、Actions では restricted 状態を観測できない。このスクリプトはローカルから
# 同じ観測を行い、さらに workflow dispatch が 422 で拒否されること自体も証跡として
# 記録する。解除後は Actions 側のワークフローが観測を引き継ぐ。
#
# 必要スコープ: user:email (gh auth refresh -h github.com -s user:email)
set -euo pipefail
cd "$(dirname "$0")/.."

response=$(gh api user/emails)
login=$(gh api user --jq .login)

primary_verified=$(echo "$response" | jq '[.[] | select(.primary == true)][0].verified')
primary_domain=$(echo "$response" | jq -r '[.[] | select(.primary == true)][0].email | split("@")[1]')
timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
response_hash=$(echo "$response" | shasum -a 256 | cut -d' ' -f1)

# Actions が動かせるかも観測する(制限中は HTTP 422 "Actions has been disabled
# for this user" が返る。これは GitHub 側の挙動であり自己申告ではない)
repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null || echo "")
dispatch_error=""
if [ -n "$repo" ]; then
  dispatch_error=$(gh workflow run "Check primary email verification" -R "$repo" 2>&1 >/dev/null || true)
fi

if [ "$primary_verified" = "true" ]; then
  state="unrestricted"
  message="OAuth login enabled (primary email verified)"
  color="brightgreen"
else
  state="restricted"
  message="OAuth login restricted (primary email unverified)"
  color="red"
fi

jq -n \
  --arg message "$message" \
  --arg color "$color" \
  '{schemaVersion: 1, label: "GitHub 3rd-party login", message: $message, color: $color}' \
  > badge.json

jq -cn \
  --arg ts "$timestamp" \
  --arg login "$login" \
  --arg state "$state" \
  --arg domain "$primary_domain" \
  --argjson verified "$primary_verified" \
  --arg hash "$response_hash" \
  --arg dispatch_error "$dispatch_error" \
  '{timestamp: $ts, login: $login, state: $state, primary_email_domain: $domain, primary_email_verified: $verified, api_response_sha256: $hash, observer: "local", actions_dispatch_error: (if $dispatch_error == "" then null else $dispatch_error end)}' \
  >> evidence.ndjson

git add badge.json evidence.ndjson
if git diff --cached --quiet; then
  echo "No state change (state: ${state})"
else
  git commit --allow-empty-message -m ''
  git push
  echo "Recorded state: ${state} at ${timestamp}"
fi
