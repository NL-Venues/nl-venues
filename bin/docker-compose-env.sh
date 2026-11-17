#!/usr/bin/env bash

# Environment for the docker compose dev harness. Sourced by bin/dc.
#
# In a git worktree the repo directory name differs from the primary checkout's, so the worktree gets its
# own development and test databases (BTR_WORKTREE_DB_SUFFIX, read by config/database.yml) instead of
# sharing, and dropping or migrating, the primary checkout's. In the primary checkout the suffix is empty.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repo_basename="$(basename "$repo_root")"
git_common_dir="$(git -C "$repo_root" rev-parse --git-common-dir)"
primary_repo_root="$(cd "$(dirname "$git_common_dir")" && pwd)"
primary_repo_basename="$(basename "$primary_repo_root")"

sanitize_slug() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/_/g; s/^_+//; s/_+$//'
}

if [[ "$repo_basename" == "$primary_repo_basename" ]]; then
  worktree_db_suffix=""
else
  worktree_db_suffix="_$(sanitize_slug "$repo_basename")"
fi

canonical_ce_repo=""
for candidate in \
  "$primary_repo_root/../../better-together/community-engine-rails" \
  "$primary_repo_root/../community-engine-rails" \
  "/home/rob/projects/better-together/community-engine-rails"
do
  if [[ -d "$candidate" ]]; then
    canonical_ce_repo="$(cd "$candidate" && pwd)"
    break
  fi
done

# Postgres limits identifiers to 63 characters; a long worktree name would be silently truncated and
# could collide, so set BTR_WORKTREE_DB_SUFFIX to a short value yourself in that case.
export BTR_WORKTREE_DB_SUFFIX="${BTR_WORKTREE_DB_SUFFIX:-$worktree_db_suffix}"
export COMMUNITY_ENGINE_PATH="${COMMUNITY_ENGINE_PATH:-$canonical_ce_repo}"

# Reuse the compose project of the existing db container so every checkout shares one network.
existing_project="$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' nl-venues-db 2>/dev/null || true)"
export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-${existing_project:-nl-venues}}"
