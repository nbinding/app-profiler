#!/usr/bin/env bash
# Deploy index.html (and the design system copy in ds/) from main to the `public` branch -> GitHub Pages.
# public carries ONLY index.html and ds/, so prd.md/README stay off the live site.
set -euo pipefail

git diff --quiet && git diff --cached --quiet || { echo "Commit or stash your changes first."; exit 1; }

branch=$(git rev-parse --abbrev-ref HEAD)
git push origin "$branch"
git checkout public
git checkout "$branch" -- index.html ds
if git commit -q -m "deploy $(date -u +%FT%TZ)"; then
  git push origin public
  echo "Deployed. Live in ~1 min: https://nbinding.github.io/app-profiler/"
else
  echo "index.html and ds/ unchanged — nothing to deploy."
fi
git checkout "$branch"
