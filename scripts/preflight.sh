#!/usr/bin/env bash
set -euo pipefail

required=(aws terraform kubectl helm gh git)
for c in "${required[@]}"; do
  command -v "$c" >/dev/null || { echo "Missing required command: $c"; exit 1; }
done

: "${AWS_PROFILE:=leviathan-admin}"
: "${AWS_REGION:=ap-south-1}"

echo "AWS profile: $AWS_PROFILE"
echo "AWS region : $AWS_REGION"
aws sts get-caller-identity --profile "$AWS_PROFILE" >/dev/null
echo "AWS authentication: OK"

gh auth status >/dev/null
echo "GitHub CLI: OK"

repo="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
if [[ "$repo" != "Naveenbana5250/Project-Leviathan" ]]; then
  echo "WARNING: current GitHub repo is $repo"
  echo "Expected Naveenbana5250/Project-Leviathan"
fi

echo "Preflight passed."
